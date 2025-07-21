#!/bin/bash

# PDF2MD 우분투 배포 사전 점검 스크립트
# 사용법: chmod +x scripts/pre-deploy-check.sh && ./scripts/pre-deploy-check.sh

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 로그 함수
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 체크 함수들
check_docker() {
    log_info "Docker 환경 확인 중..."
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker가 설치되지 않았습니다."
        echo "설치 방법: https://docs.docker.com/engine/install/ubuntu/"
        return 1
    fi
    
    DOCKER_VERSION=$(docker --version | grep -oP '\d+\.\d+\.\d+' | head -1)
    log_success "Docker 버전: $DOCKER_VERSION"
    
    if ! docker info &> /dev/null; then
        log_error "Docker 데몬이 실행되지 않았거나 권한이 없습니다."
        echo "해결 방법:"
        echo "  sudo systemctl start docker"
        echo "  sudo usermod -aG docker \$USER"
        echo "  newgrp docker"
        return 1
    fi
    
    # Docker Compose 확인
    if command -v docker-compose &> /dev/null; then
        COMPOSE_VERSION=$(docker-compose --version | grep -oP '\d+\.\d+\.\d+' | head -1)
        log_success "Docker Compose 버전: $COMPOSE_VERSION"
    elif docker compose version &> /dev/null; then
        COMPOSE_VERSION=$(docker compose version --short)
        log_success "Docker Compose 플러그인 버전: $COMPOSE_VERSION"
    else
        log_error "Docker Compose가 설치되지 않았습니다."
        return 1
    fi
}

check_network() {
    log_info "네트워크 설정 확인 중..."
    
    # npm_default 네트워크 확인
    if docker network ls | grep -q npm_default; then
        log_success "npm_default 네트워크가 존재합니다."
    else
        log_warning "npm_default 네트워크가 없습니다."
        echo "생성 방법: docker network create npm_default"
    fi
    
    # 포트 확인 (예시: 3002)
    if command -v netstat &> /dev/null; then
        if netstat -tlnp | grep -q :3002; then
            log_warning "포트 3002가 이미 사용 중입니다."
            netstat -tlnp | grep :3002
        else
            log_success "포트 3002를 사용할 수 있습니다."
        fi
    fi
}

check_resources() {
    log_info "시스템 리소스 확인 중..."
    
    # 메모리 확인
    TOTAL_MEM=$(free -m | awk 'NR==2{printf "%.0f", $2/1024}')
    if [ "$TOTAL_MEM" -lt 2 ]; then
        log_warning "메모리가 부족합니다 (현재: ${TOTAL_MEM}GB, 권장: 2GB 이상)"
    else
        log_success "메모리: ${TOTAL_MEM}GB"
    fi
    
    # 디스크 공간 확인
    DISK_AVAILABLE=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')
    if [ "$DISK_AVAILABLE" -lt 10 ]; then
        log_warning "디스크 공간이 부족합니다 (사용 가능: ${DISK_AVAILABLE}GB, 권장: 10GB 이상)"
    else
        log_success "디스크 공간: ${DISK_AVAILABLE}GB 사용 가능"
    fi
}

check_permissions() {
    log_info "파일 권한 확인 중..."
    
    # .env 파일 확인
    if [ -f ".env" ]; then
        ENV_PERMS=$(stat -c "%a" .env)
        if [ "$ENV_PERMS" != "600" ]; then
            log_warning ".env 파일 권한이 안전하지 않습니다 (현재: $ENV_PERMS, 권장: 600)"
            echo "수정 방법: chmod 600 .env"
        else
            log_success ".env 파일 권한이 안전합니다."
        fi
        
        # 필수 환경 변수 확인
        if grep -q "MISTRAL_API_KEY=your_mistral_api_key_here" .env; then
            log_error "MISTRAL_API_KEY가 설정되지 않았습니다."
            echo ".env 파일에 실제 API 키를 설정하세요."
            return 1
        else
            log_success "MISTRAL_API_KEY가 설정되어 있습니다."
        fi
    else
        log_error ".env 파일이 없습니다."
        echo "env.server.example을 .env로 복사하고 설정하세요."
        return 1
    fi
}

check_data_directory() {
    log_info "데이터 디렉토리 확인 중..."
    
    # docker-compose.yml에서 볼륨 경로 추출
    if [ -f "docker-compose.server.yml" ]; then
        DATA_PATH=$(grep -A 5 "volumes:" docker-compose.server.yml | grep -E "- /" | head -1 | cut -d':' -f1 | sed 's/.*- //' | xargs)
        
        if [ "$DATA_PATH" = "/path/to/your/data" ]; then
            log_error "데이터 경로가 플레이스홀더 상태입니다."
            echo "docker-compose.server.yml에서 실제 경로로 수정하세요."
            return 1
        fi
        
        # 실제 경로인 경우 확인
        if [[ "$DATA_PATH" =~ ^/mnt/data2TB/pdf2mark_data$ ]]; then
            log_warning "DEPLOYMENT_CONFIG.md의 실제 경로가 설정되어 있습니다."
            echo "공개 배포 전에 실제 경로를 플레이스홀더로 변경하세요."
        fi
        
        log_success "데이터 경로 설정을 확인했습니다: $DATA_PATH"
    fi
}

main() {
    echo "======================================"
    echo "🚀 PDF2MD Ubuntu 배포 사전 점검"
    echo "======================================"
    echo
    
    local errors=0
    
    check_docker || ((errors++))
    echo
    
    check_network || ((errors++))
    echo
    
    check_resources || ((errors++))
    echo
    
    check_permissions || ((errors++))
    echo
    
    check_data_directory || ((errors++))
    echo
    
    echo "======================================"
    if [ $errors -eq 0 ]; then
        log_success "✅ 모든 점검이 통과했습니다! 배포를 진행할 수 있습니다."
        echo
        echo "다음 단계:"
        echo "1. docker-compose -f docker-compose.server.yml up -d"
        echo "2. docker logs pdf2md"
        echo "3. curl http://localhost:YOUR_PORT/api/health"
    else
        log_error "❌ $errors개의 문제가 발견되었습니다. 위의 해결 방법을 참고하여 수정하세요."
        echo
        echo "자세한 가이드: UBUNTU_DEPLOYMENT_CHECKLIST.md"
        exit 1
    fi
    echo "======================================"
}

# 스크립트 실행
main "$@" 