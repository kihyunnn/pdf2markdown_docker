import { NextRequest, NextResponse } from 'next/server';
import { readFile, stat } from 'fs/promises';
import { existsSync } from 'fs';
import path from 'path';
import { lookup } from 'mime-types';

const UPLOAD_DIR = process.env.UPLOAD_DIR || "/app/uploads";

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ path: string[] }> }
) {
  try {
    const resolvedParams = await params;
    const filePath = resolvedParams.path.join('/');
    const fullPath = path.join(UPLOAD_DIR, filePath);

    // 보안: 디렉토리 트래버설 방지
    if (!fullPath.startsWith(UPLOAD_DIR)) {
      return new NextResponse('Forbidden', { status: 403 });
    }

    // 파일 존재 확인
    if (!existsSync(fullPath)) {
      return new NextResponse('File not found', { status: 404 });
    }

    // 파일 통계 확인
    const stats = await stat(fullPath);
    if (!stats.isFile()) {
      return new NextResponse('Not a file', { status: 400 });
    }

    // 파일 읽기
    const fileBuffer = await readFile(fullPath);
    
    // MIME 타입 결정
    const mimeType = lookup(fullPath) || 'application/octet-stream';

    // 응답 헤더 설정
    const headers = new Headers();
    headers.set('Content-Type', mimeType);
    headers.set('Content-Length', stats.size.toString());
    headers.set('Cache-Control', 'public, max-age=31536000'); // 1년 캐시

    return new NextResponse(fileBuffer, {
      status: 200,
      headers,
    });
  } catch (error) {
    console.error('File serving error:', error);
    return new NextResponse('Internal Server Error', { status: 500 });
  }
} 