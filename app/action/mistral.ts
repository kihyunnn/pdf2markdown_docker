"use server";

import { Mistral } from "@mistralai/mistralai";
import { OCRResponse } from "@mistralai/mistralai/src/models/components/ocrresponse.js";
import { readFile } from "fs/promises";
import path from "path";

/**
 * 로컬 파일을 base64로 변환하는 함수
 */
async function convertLocalFileToBase64(filePath: string): Promise<string> {
  const UPLOAD_DIR = process.env.UPLOAD_DIR || "/app/uploads";
  
  // /uploads/로 시작하는 경로를 실제 파일 시스템 경로로 변환
  const relativePath = filePath.startsWith('/uploads/') 
    ? filePath.substring('/uploads/'.length) 
    : filePath;
  
  const fullPath = path.join(UPLOAD_DIR, relativePath);
  
  try {
    const fileBuffer = await readFile(fullPath);
    const base64Content = fileBuffer.toString('base64');
    
    // 파일 확장자에 따라 MIME 타입 결정
    const ext = path.extname(fullPath).toLowerCase();
    let mimeType = 'application/octet-stream';
    
    if (ext === '.pdf') {
      mimeType = 'application/pdf';
    } else if (ext === '.png') {
      mimeType = 'image/png';
    } else if (ext === '.jpg' || ext === '.jpeg') {
      mimeType = 'image/jpeg';
    }
    
    return `data:${mimeType};base64,${base64Content}`;
  } catch (error) {
    console.error('Error reading local file:', error);
    throw new Error(`Failed to read local file: ${filePath}`);
  }
}

/**
 * MistralAI OCR Processor
 * Performs OCR processing on a document at the specified URL or local file
 *
 * @param documentUrl URL of the document or local file path
 * @param includeImageBase64 Whether to include Base64 encoded image data
 * @returns Results of OCR processing
 */
export async function processMistralOcr(
  documentUrl: string,
  includeImageBase64: boolean = true
): Promise<OCRResponse> {
  if (!documentUrl) {
    throw new Error("Document URL is not specified");
  }

  const apiKey = process.env.MISTRAL_API_KEY;
  if (!apiKey) {
    throw new Error("MISTRAL_API_KEY is not set in environment variables");
  }

  const client = new Mistral({ apiKey });

  try {
    let documentData: string;
    
    // 로컬 파일 경로인지 확인 (HTTPS URL이 아닌 경우)
    if (!documentUrl.startsWith('https://')) {
      console.log('Converting local file to base64:', documentUrl);
      documentData = await convertLocalFileToBase64(documentUrl);
    } else {
      documentData = documentUrl;
    }

    const ocrResponse = await client.ocr.process({
      model: "mistral-ocr-latest",
      document: {
        type: "document_url",
        documentUrl: documentData,
      },
      includeImageBase64,
    });

    return ocrResponse;
  } catch (error) {
    console.error("Error occurred during OCR processing:", error);
    throw error;
  }
}

/**
 * MistralAI OCR Processor (Image URL version)
 * Performs OCR processing on the specified image URL or local file
 *
 * @param imageUrl URL of the image or local file path
 * @param includeImageBase64 Whether to include Base64 encoded image data
 * @returns Results of OCR processing
 */
export async function processMistralImageOcr(
  imageUrl: string,
  includeImageBase64: boolean = true
): Promise<OCRResponse> {
  if (!imageUrl) {
    throw new Error("Image URL is not specified");
  }

  const apiKey = process.env.MISTRAL_API_KEY;
  if (!apiKey) {
    throw new Error("MISTRAL_API_KEY is not set in environment variables");
  }

  const client = new Mistral({ apiKey });

  try {
    let imageData: string;
    
    // 로컬 파일 경로인지 확인 (HTTPS URL이 아닌 경우)
    if (!imageUrl.startsWith('https://')) {
      console.log('Converting local image to base64:', imageUrl);
      imageData = await convertLocalFileToBase64(imageUrl);
    } else {
      imageData = imageUrl;
    }

    const ocrResponse = await client.ocr.process({
      model: "mistral-ocr-latest",
      document: {
        type: "image_url",
        imageUrl: imageData,
      },
      includeImageBase64,
    });

    return ocrResponse;
  } catch (error) {
    console.error("Error occurred during OCR processing:", error);
    throw error;
  }
}

// Usage example
// const ocrResult = await processMistralOcr("https://arxiv.org/pdf/2201.04234");
// console.log(ocrResult);

// Image version usage example
// const imageOcrResult = await processMistralImageOcr("https://raw.githubusercontent.com/mistralai/cookbook/refs/heads/main/mistral/ocr/receipt.png");
// console.log(imageOcrResult);
