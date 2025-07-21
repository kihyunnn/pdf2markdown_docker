"use server";

import { writeFile, mkdir, unlink, readdir, stat } from "fs/promises";
import { existsSync } from "fs";
import path from "path";
import { v4 as uuidv4 } from "uuid";

// 업로드 디렉토리 설정 (Docker 볼륨 마운트 경로)
const UPLOAD_DIR = process.env.UPLOAD_DIR || "/app/uploads";

/**
 * 업로드 디렉토리가 존재하지 않으면 생성
 */
async function ensureUploadDir(subDir?: string): Promise<string> {
  const targetDir = subDir ? path.join(UPLOAD_DIR, subDir) : UPLOAD_DIR;
  
  if (!existsSync(targetDir)) {
    await mkdir(targetDir, { recursive: true });
  }
  
  return targetDir;
}

/**
 * Function to upload PDF files to local file system
 * @param file PDF file to upload
 * @param folderName Folder name (default: 'pdfs')
 * @param filePath File path (if not specified, a UUID-based filename will be generated)
 * @returns Upload result (includes path when successful)
 */
export async function uploadPdfToVercelBlob(
  file: File,
  folderName: string = "pdfs",
  filePath?: string
): Promise<{ url: string | null; error: Error | null }> {
  try {
    // Check file format
    if (!file.type.includes("pdf")) {
      throw new Error("Only PDF files can be uploaded.");
    }

    // Check file size (100MB limit)
    const MAX_FILE_SIZE = 100 * 1024 * 1024; // 100MB in bytes
    if (file.size > MAX_FILE_SIZE) {
      throw new Error("File size exceeds the 100MB limit. Please upload a smaller file.");
    }

    // 업로드 디렉토리 생성
    const uploadDir = await ensureUploadDir(folderName);
    
    // Generate filename using UUID if filePath not specified
    const fileName = filePath || `${uuidv4()}_${file.name}`;
    const fullPath = path.join(uploadDir, path.basename(fileName));
    
    // Convert File to Buffer
    const arrayBuffer = await file.arrayBuffer();
    const buffer = Buffer.from(arrayBuffer);
    
    // Write file to local filesystem
    await writeFile(fullPath, buffer);
    
    // Return public URL (Docker 컨테이너 내부에서 접근 가능한 경로)
    const publicUrl = `/uploads/${folderName}/${path.basename(fileName)}`;
    
    console.log("File saved to:", fullPath);
    console.log("Public URL:", publicUrl);

    return { url: publicUrl, error: null };
  } catch (error) {
    console.error("PDF upload error:", error);
    return {
      url: null,
      error: error instanceof Error ? error : new Error("An unknown error occurred"),
    };
  }
}

/**
 * Function to upload image files to local file system
 * @param file Image file to upload
 * @param folderName Folder name (default: 'images')
 * @param filePath File path (if not specified, a UUID-based filename will be generated)
 * @returns Upload result (includes path when successful)
 */
export async function uploadImageToVercelBlob(
  file: File,
  folderName: string = "images",
  filePath?: string
): Promise<{ url: string | null; error: Error | null }> {
  try {
    // Check file format
    const validImageTypes = ["image/jpeg", "image/png"];
    if (!validImageTypes.includes(file.type)) {
      throw new Error("Only image files (JPEG, PNG) can be uploaded.");
    }

    // Check file size (100MB limit)
    const MAX_FILE_SIZE = 100 * 1024 * 1024; // 100MB in bytes
    if (file.size > MAX_FILE_SIZE) {
      throw new Error("File size exceeds the 100MB limit. Please upload a smaller file.");
    }

    // 업로드 디렉토리 생성
    const uploadDir = await ensureUploadDir(folderName);
    
    // Generate filename using UUID if filePath not specified
    const fileName = filePath || `${uuidv4()}_${file.name}`;
    const fullPath = path.join(uploadDir, path.basename(fileName));
    
    // Convert File to Buffer
    const arrayBuffer = await file.arrayBuffer();
    const buffer = Buffer.from(arrayBuffer);
    
    // Write file to local filesystem
    await writeFile(fullPath, buffer);
    
    // Return public URL
    const publicUrl = `/uploads/${folderName}/${path.basename(fileName)}`;

    return { url: publicUrl, error: null };
  } catch (error) {
    console.error("Image upload error:", error);
    return {
      url: null,
      error: error instanceof Error ? error : new Error("An unknown error occurred"),
    };
  }
}

/**
 * Function to get the public URL of an image file
 * @param path File path
 * @returns Public URL
 */
export async function getImagePublicUrl(path: string): Promise<string> {
  // 로컬 파일 시스템의 경우 상대 경로 반환
  return path.startsWith('/uploads') ? path : `/uploads/${path}`;
}

/**
 * Function to delete a file from local file system
 * @param filePath File path (relative to uploads directory)
 * @returns Delete result
 */
export async function deleteFileFromVercelBlob(
  filePath: string
): Promise<{ success: boolean; error: Error | null }> {
  try {
    // filePath가 /uploads로 시작하면 제거
    const relativePath = filePath.startsWith('/uploads/') 
      ? filePath.substring('/uploads/'.length) 
      : filePath;
      
    const fullPath = path.join(UPLOAD_DIR, relativePath);
    
    // 파일 존재 확인
    if (!existsSync(fullPath)) {
      throw new Error("File not found");
    }
    
    await unlink(fullPath);
    return { success: true, error: null };
  } catch (error) {
    console.error("File deletion error:", error);
    return {
      success: false,
      error: error instanceof Error ? error : new Error("An unknown error occurred"),
    };
  }
}

/**
 * Function to list files in a folder
 * @param prefix Folder prefix
 * @returns List of files
 */
export async function listFilesInVercelBlob(
  prefix: string
): Promise<{ files: string[]; error: Error | null }> {
  try {
    const targetDir = path.join(UPLOAD_DIR, prefix);
    
    if (!existsSync(targetDir)) {
      return { files: [], error: null };
    }
    
    const files = await readdir(targetDir);
    const fileList = [];
    
    for (const file of files) {
      const filePath = path.join(targetDir, file);
      const stats = await stat(filePath);
      
      if (stats.isFile()) {
        fileList.push(path.join(prefix, file));
      }
    }
    
    return { files: fileList, error: null };
  } catch (error) {
    console.error("File listing error:", error);
    return {
      files: [],
      error: error instanceof Error ? error : new Error("An unknown error occurred"),
    };
  }
}
