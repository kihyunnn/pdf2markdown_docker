#!/bin/bash

# PDF2MD 파일 권한 설정 스크립트
# 사용법: sudo ./scripts/setup-permissions.sh [DATA_PATH]

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# 기본 데이터 경로
DEFAULT_DATA_PATH="/opt/pdf2md-data"
DATA_PATH=${1:-$DEFAULT_DATA_PATH}

# 루트 권한 확인
if [ "$EUID" -ne 0 ]; then
    log_error "이 스크립트는 root 권한으로 실행해야 합니다."
    echo "사용법: sudo $0 [DATA_PATH]"
    exit 1
fi

# 원래 사용자 확인
if [ -z "$SUDO_USER" ]; then
    log_error "SUDO_USER 환경 변수를 찾을 수 없습니다."
    echo "sudo로 실행해주세요."
    exit 1
fi

REAL_USER=$SUDO_USER
REAL_USER_ID=$(id -u $REAL_USER)
REAL_GROUP_ID=$(id -g $REAL_USER)

log_info "사용자: $REAL_USER (UID: $REAL_USER_ID, GID: $REAL_GROUP_ID)"
log_info "데이터 경로: $DATA_PATH"

# Docker에서 사용하는 nextjs 사용자의 UID/GID 확인
# 일반적으로 nextjs 사용자는 UID 1001을 사용
NEXTJS_UID=1001
NEXTJS_GID=1001

log_info "Docker nextjs 사용자 UID/GID: $NEXTJS_UID/$NEXTJS_GID"

# 데이터 디렉토리 생성
create_directories() {
    log_info "디렉토리 생성 중..."
    
    mkdir -p "$DATA_PATH"
    mkdir -p "$DATA_PATH/uploads"
    mkdir -p "$DATA_PATH/logs"
    mkdir -p "$DATA_PATH/backups"
    
    log_success "디렉토리 생성 완료"
}

# 권한 설정
set_permissions() {
    log_info "권한 설정 중..."
    
    # 방법 1: Docker 컨테이너의 nextjs 사용자와 호스트 사용자를 매핑
    # 이 방법은 가장 안전하고 권장됩니다
    
    # 소유권을 실제 사용자로 설정 (Docker에서 user mapping 사용)
    chown -R $REAL_USER_ID:$REAL_GROUP_ID "$DATA_PATH"
    
    # 디렉토리는 755, 파일은 644 권한
    find "$DATA_PATH" -type d -exec chmod 755 {} \;
    find "$DATA_PATH" -type f -exec chmod 644 {} \;
    
    # 업로드 디렉토리는 쓰기 권한 필요
    chmod 755 "$DATA_PATH/uploads"
    chmod 755 "$DATA_PATH/logs"
    chmod 755 "$DATA_PATH/backups"
    
    log_success "권한 설정 완료"
}

# Docker Compose 파일 업데이트
update_docker_compose() {
    log_info "Docker Compose 사용자 매핑 설정..."
    
    local compose_file="docker-compose.server.yml"
    
    if [ ! -f "$compose_file" ]; then
        log_warning "$compose_file이 없습니다. 수동으로 user 설정을 추가하세요."
        return
    fi
    
    # user 설정이 이미 있는지 확인
    if grep -q "user:" "$compose_file"; then
        log_info "user 설정이 이미 있습니다."
    else
        log_info "Docker Compose에 user 매핑 추가 중..."
        
        # pdf2md 서비스에 user 설정 추가
        sed -i "/container_name: pdf2md/a\\    user: \"$REAL_USER_ID:$REAL_GROUP_ID\"" "$compose_file"
        
        log_success "user 매핑이 추가되었습니다."
    fi
}

# 권한 확인
verify_permissions() {
    log_info "권한 확인 중..."
    
    # 디렉토리 존재 확인
    for dir in "$DATA_PATH" "$DATA_PATH/uploads" "$DATA_PATH/logs" "$DATA_PATH/backups"; do
        if [ -d "$dir" ]; then
            local perms=$(stat -c "%a" "$dir")
            local owner=$(stat -c "%U:%G" "$dir")
            log_success "$dir: $perms ($owner)"
        else
            log_error "$dir이 존재하지 않습니다."
        fi
    done
    
    # 테스트 파일 생성
    local test_file="$DATA_PATH/uploads/test_write.txt"
    if su - $REAL_USER -c "echo 'test' > '$test_file'" 2>/dev/null; then
        log_success "쓰기 권한 테스트 성공"
        rm -f "$test_file"
    else
        log_error "쓰기 권한 테스트 실패"
    fi
}

# 권한 문제 해결 가이드
print_troubleshooting() {
    echo
    echo "======================================"
    echo "🔧 권한 문제 해결 가이드"
    echo "======================================"
    echo
    echo "1. 컨테이너에서 권한 오류 발생 시:"
    echo "   docker-compose.server.yml에 다음 추가:"
    echo "   user: \"$REAL_USER_ID:$REAL_GROUP_ID\""
    echo
    echo "2. 여전히 문제가 있다면:"
    echo "   chmod 777 $DATA_PATH/uploads  # 임시 해결책"
    echo "   chmod 777 $DATA_PATH/logs     # 임시 해결책"
    echo
    echo "3. SELinux 문제 (CentOS/RHEL):"
    echo "   setsebool -P container_manage_cgroup on"
    echo "   chcon -Rt container_file_t $DATA_PATH"
    echo
    echo "4. AppArmor 문제 (Ubuntu):"
    echo "   일반적으로 문제없음, 필요시 프로파일 수정"
    echo
    echo "======================================"
}

main() {
    echo "======================================"
    echo "🔐 PDF2MD 파일 권한 설정"
    echo "======================================"
    echo
    
    create_directories
    echo
    
    set_permissions
    echo
    
    update_docker_compose
    echo
    
    verify_permissions
    echo
    
    print_troubleshooting
    
    log_success "✅ 파일 권한 설정이 완료되었습니다!"
    echo
    echo "다음 단계:"
    echo "1. docker-compose -f docker-compose.server.yml up -d"
    echo "2. docker logs pdf2md"
    echo
}

# 스크립트 실행
main "$@" 