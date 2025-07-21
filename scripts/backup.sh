#!/bin/bash

# PDF2MD 자동 백업 스크립트
# 업로드된 파일과 SSL 인증서를 백업합니다.

set -e

# 설정
BACKUP_DIR="/backup/output"
BACKUP_DATE=$(date +"%Y%m%d_%H%M%S")
BACKUP_NAME="pdf2md_backup_${BACKUP_DATE}"
RETENTION_DAYS=${BACKUP_RETENTION_DAYS:-30}

# 로그 함수
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "PDF2MD 백업 시작: $BACKUP_NAME"

# 백업 디렉토리 생성
mkdir -p "$BACKUP_DIR"

# 임시 백업 디렉토리 생성
TEMP_DIR="/tmp/$BACKUP_NAME"
mkdir -p "$TEMP_DIR"

# 업로드된 파일 백업
if [ -d "/backup/uploads" ]; then
    log "업로드 파일 백업 중..."
    cp -r /backup/uploads "$TEMP_DIR/"
    UPLOAD_COUNT=$(find "$TEMP_DIR/uploads" -type f | wc -l)
    log "업로드 파일 $UPLOAD_COUNT개 백업 완료"
else
    log "경고: 업로드 디렉토리를 찾을 수 없습니다."
fi

# SSL 인증서 백업
if [ -d "/backup/ssl" ]; then
    log "SSL 인증서 백업 중..."
    cp -r /backup/ssl "$TEMP_DIR/"
    log "SSL 인증서 백업 완료"
else
    log "경고: SSL 디렉토리를 찾을 수 없습니다."
fi

# 백업 메타데이터 생성
cat > "$TEMP_DIR/backup_info.txt" << EOF
Backup Date: $(date)
Backup Name: $BACKUP_NAME
Server IP: ${SERVER_IP:-Unknown}
Domain: ${DOMAIN:-Unknown}
Upload Files: ${UPLOAD_COUNT:-0}
EOF

# 압축
log "백업 파일 압축 중..."
cd /tmp
tar -czf "$BACKUP_DIR/$BACKUP_NAME.tar.gz" "$BACKUP_NAME"

# 임시 디렉토리 정리
rm -rf "$TEMP_DIR"

# 백업 파일 크기 확인
BACKUP_SIZE=$(du -h "$BACKUP_DIR/$BACKUP_NAME.tar.gz" | cut -f1)
log "백업 완료: $BACKUP_NAME.tar.gz (크기: $BACKUP_SIZE)"

# 오래된 백업 파일 정리
log "오래된 백업 파일 정리 중... (보존 기간: ${RETENTION_DAYS}일)"
find "$BACKUP_DIR" -name "pdf2md_backup_*.tar.gz" -type f -mtime +$RETENTION_DAYS -delete

# 현재 백업 파일 목록
BACKUP_COUNT=$(find "$BACKUP_DIR" -name "pdf2md_backup_*.tar.gz" -type f | wc -l)
log "현재 백업 파일 개수: $BACKUP_COUNT"

log "백업 작업 완료"

# 백업 검증 (선택사항)
if command -v tar >/dev/null 2>&1; then
    if tar -tzf "$BACKUP_DIR/$BACKUP_NAME.tar.gz" >/dev/null 2>&1; then
        log "백업 파일 무결성 검증 통과"
    else
        log "오류: 백업 파일 무결성 검증 실패"
        exit 1
    fi
fi 