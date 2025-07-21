#!/bin/bash

# PDF2MD 프로덕션 배포 스크립트
# 사용법: ./scripts/deploy.sh

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 로그 함수
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1"
}

error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1"
    exit 1
}

# 환경 확인
check_requirements() {
    log "시스템 요구사항 확인 중..."
    
    # Docker 확인
    if ! command -v docker &> /dev/null; then
        error "Docker가 설치되어 있지 않습니다."
    fi
    
    # Docker Compose 확인
    if ! command -v docker-compose &> /dev/null; then
        error "Docker Compose가 설치되어 있지 않습니다."
    fi
    
    # 환경 변수 파일 확인
    if [ ! -f ".env" ]; then
        warn ".env 파일이 없습니다. env.prod.example을 복사해서 설정하세요."
        echo "cp env.prod.example .env"
        echo "nano .env  # 환경 변수 설정"
        exit 1
    fi
    
    log "시스템 요구사항 확인 완료"
}

# 필요한 디렉토리 생성
create_directories() {
    log "필요한 디렉토리 생성 중..."
    
    mkdir -p uploads
    mkdir -p ssl
    mkdir -p backups
    mkdir -p logs
    mkdir -p nginx/ssl
    
    # 권한 설정
    chmod 755 uploads ssl backups logs
    chmod +x scripts/backup.sh
    
    log "디렉토리 생성 완료"
}

# 기본 SSL 인증서 생성 (임시용)
create_default_ssl() {
    if [ ! -f "nginx/ssl/default.crt" ]; then
        log "기본 SSL 인증서 생성 중..."
        
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout nginx/ssl/default.key \
            -out nginx/ssl/default.crt \
            -subj "/CN=default/O=PDF2MD" \
            2>/dev/null
        
        log "기본 SSL 인증서 생성 완료"
    fi
}

# 애플리케이션 빌드
build_application() {
    log "애플리케이션 빌드 중..."
    
    # 이전 이미지 정리 (선택사항)
    docker-compose -f docker-compose.yml -f docker-compose.prod.yml down --remove-orphans
    
    # 새 이미지 빌드
    docker-compose -f docker-compose.yml -f docker-compose.prod.yml build --no-cache
    
    log "애플리케이션 빌드 완료"
}

# SSL 인증서 획득
setup_ssl() {
    log "SSL 인증서 설정 중..."
    
    # Let's Encrypt 인증서 획득
    docker-compose -f docker-compose.yml -f docker-compose.prod.yml --profile ssl run --rm certbot
    
    log "SSL 인증서 설정 완료"
}

# 애플리케이션 시작
start_application() {
    log "애플리케이션 시작 중..."
    
    # 기본 서비스 시작
    docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
    
    # SSL 갱신 서비스 시작
    docker-compose -f docker-compose.yml -f docker-compose.prod.yml --profile ssl up -d
    
    log "애플리케이션 시작 완료"
}

# 상태 확인
check_health() {
    log "서비스 상태 확인 중..."
    
    sleep 10  # 서비스 시작 대기
    
    # 컨테이너 상태 확인
    docker-compose -f docker-compose.yml -f docker-compose.prod.yml ps
    
    # 헬스체크
    if curl -f -s http://localhost:3000/api/health > /dev/null; then
        log "✅ 애플리케이션이 정상 작동 중입니다."
    else
        warn "⚠️ 애플리케이션 헬스체크 실패. 로그를 확인하세요."
    fi
    
    # HTTPS 확인
    if curl -f -s -k https://localhost > /dev/null; then
        log "✅ HTTPS가 정상 작동 중입니다."
    else
        warn "⚠️ HTTPS 접속 실패. SSL 설정을 확인하세요."
    fi
}

# 로그 표시
show_logs() {
    log "서비스 로그 표시 (Ctrl+C로 종료):"
    docker-compose -f docker-compose.yml -f docker-compose.prod.yml logs -f --tail=50
}

# 메인 함수
main() {
    log "🚀 PDF2MD 프로덕션 배포 시작"
    
    check_requirements
    create_directories
    create_default_ssl
    build_application
    setup_ssl
    start_application
    check_health
    
    log "🎉 배포 완료!"
    echo ""
    echo "📝 접속 정보:"
    echo "   - HTTP:  http://YOUR_DOMAIN.com"
    echo "   - HTTPS: https://YOUR_DOMAIN.com"
    echo "   - 모니터링: http://YOUR_DOMAIN.com:3001 (Grafana)"
    echo ""
    echo "🔧 유용한 명령어:"
    echo "   - 로그 보기: docker-compose -f docker-compose.yml -f docker-compose.prod.yml logs -f"
    echo "   - 서비스 중지: docker-compose -f docker-compose.yml -f docker-compose.prod.yml down"
    echo "   - 백업 실행: docker-compose -f docker-compose.yml -f docker-compose.prod.yml --profile backup run --rm backup"
    echo ""
    
    read -p "로그를 실시간으로 보시겠습니까? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        show_logs
    fi
}

# 스크립트 실행
main "$@" 