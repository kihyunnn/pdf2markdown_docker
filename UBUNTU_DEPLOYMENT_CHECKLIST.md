# Ubuntu 배포 사전 점검 체크리스트

> ⚠️ **주의**: 이 파일은 우분투 서버 배포 전 필수 점검사항들을 정리한 문서입니다.

## 🔍 1. Docker 환경 호환성 검증

### ✅ 필수 요구사항
```bash
# Docker 버전 확인 (20.10+ 권장)
docker --version

# Docker Compose 버전 확인 (2.0+ 권장)
docker-compose --version
# 또는 최신 버전
docker compose version

# Docker 서비스 상태 확인
sudo systemctl status docker
```

### 🛠️ Docker 설치 (Ubuntu 22.04)
```bash
# 기존 Docker 제거 (필요시)
sudo apt-get remove docker docker-engine docker.io containerd runc

# Docker 공식 GPG 키 추가
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Docker 저장소 추가
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Docker 설치
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin

# 현재 사용자를 docker 그룹에 추가
sudo usermod -aG docker $USER
newgrp docker
```

### ⚠️ 잠재적 문제점
1. **Docker Compose 버전 호환성**
   - `version: '3.8'` 필드가 최신 Docker Compose에서 deprecated
   - 해결: 최신 버전에서는 version 필드 제거 가능

2. **베이스 이미지 혼동**
   - Dockerfile 주석에 "Ubuntu 22.04 기반"이라고 되어 있지만 실제로는 Debian 11 (Bullseye)
   - 해결: 주석 수정 필요

## 🔐 2. 파일 시스템 권한 검증

### ✅ 데이터 디렉토리 생성 및 권한 설정
```bash
# 데이터 디렉토리 생성 (실제 경로로 변경)
sudo mkdir -p /mnt/data2TB/pdf2mark_data/{logs,backups}

# 권한 설정 (중요!)
sudo chown -R $USER:$USER /mnt/data2TB/pdf2mark_data
sudo chmod -R 755 /mnt/data2TB/pdf2mark_data

# 권한 확인
ls -la /mnt/data2TB/pdf2mark_data
```

### ⚠️ 잠재적 문제점
1. **권한 부족**
   - Docker 컨테이너에서 파일 생성/수정 실패
   - 해결: 올바른 소유권 및 권한 설정

2. **SELinux 문제** (CentOS/RHEL에서 주로 발생)
   - Ubuntu에서는 일반적으로 문제없음
   - 필요시: `sudo setsebool -P container_manage_cgroup on`

## 🌐 3. 네트워크 및 포트 설정 검증

### ✅ npm_default 네트워크 확인
```bash
# 외부 네트워크 존재 확인
docker network ls | grep npm_default

# 네트워크가 없다면 생성
docker network create npm_default
```

### ✅ 포트 충돌 확인
```bash
# 사용할 포트 확인 (예: 3002)
sudo netstat -tlnp | grep :3002
sudo ss -tlnp | grep :3002

# 방화벽 설정 확인
sudo ufw status
```

### ⚠️ 잠재적 문제점
1. **npm_default 네트워크 미존재**
   - Nginx Proxy Manager가 설치되지 않은 경우
   - 해결: 수동으로 네트워크 생성

2. **포트 충돌**
   - 다른 서비스가 동일한 포트 사용
   - 해결: 다른 포트 사용 또는 기존 서비스 중지

3. **방화벽 차단**
   - UFW가 포트를 차단하는 경우
   - 해결: `sudo ufw allow 3002`

## 💾 4. 리소스 및 성능 검증

### ✅ 시스템 리소스 확인
```bash
# 메모리 확인 (최소 2GB 권장)
free -h

# 디스크 공간 확인 (최소 10GB 권장)
df -h

# CPU 정보 확인
nproc
lscpu
```

### ✅ 성능 최적화 설정
```bash
# Docker 로그 크기 제한 설정
sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF

# Docker 서비스 재시작
sudo systemctl restart docker
```

### ⚠️ 잠재적 문제점
1. **메모리 부족**
   - Next.js 빌드 시 메모리 부족으로 실패
   - 해결: 최소 2GB RAM 확보 또는 swap 설정

2. **디스크 공간 부족**
   - Docker 이미지 빌드 실패
   - 해결: 충분한 디스크 공간 확보

## 🔒 5. 보안 및 환경 설정 검증

### ✅ 환경 변수 보안 설정
```bash
# .env 파일 권한 설정
chmod 600 .env

# 환경 변수 확인
grep -v "^#" .env | grep -v "^$"
```

### ✅ 필수 환경 변수 체크
```bash
# 필수 환경 변수 확인
if [ -z "$MISTRAL_API_KEY" ]; then
    echo "⚠️ MISTRAL_API_KEY가 설정되지 않았습니다!"
fi
```

### ⚠️ 잠재적 문제점
1. **환경 변수 누락**
   - MISTRAL_API_KEY 미설정
   - 해결: .env 파일에 올바른 API 키 설정

2. **권한 문제**
   - .env 파일이 다른 사용자에게 노출
   - 해결: `chmod 600 .env`

## 🚀 6. 배포 전 테스트

### ✅ 단계별 테스트
```bash
# 1. 이미지 빌드 테스트
docker-compose -f docker-compose.server.yml build

# 2. 컨테이너 시작 테스트
docker-compose -f docker-compose.server.yml up -d

# 3. 헬스체크 테스트
curl -f http://localhost:YOUR_PORT/api/health

# 4. 로그 확인
docker logs pdf2md

# 5. 정리
docker-compose -f docker-compose.server.yml down
```

### ⚠️ 잠재적 문제점
1. **빌드 실패**
   - 네트워크 연결 문제로 npm install 실패
   - 해결: 안정적인 인터넷 연결 확인

2. **컨테이너 시작 실패**
   - 포트 충돌, 권한 문제 등
   - 해결: 로그 확인 후 해당 문제 해결

## 🔧 7. 일반적인 문제 해결

### Docker 관련 문제
```bash
# Docker 데몬 재시작
sudo systemctl restart docker

# Docker 로그 확인
sudo journalctl -u docker.service

# 미사용 Docker 리소스 정리
docker system prune -a
```

### 권한 관련 문제
```bash
# Docker 소켓 권한 확인
sudo chmod 666 /var/run/docker.sock

# 사용자 그룹 확인
groups $USER
```

### 네트워크 관련 문제
```bash
# DNS 확인
nslookup google.com

# 방화벽 상태 확인
sudo ufw status verbose
```

## 📋 최종 체크리스트

배포 전 다음 항목들을 모두 확인하세요:

- [ ] Docker 및 Docker Compose 설치 완료
- [ ] 데이터 디렉토리 생성 및 권한 설정 완료
- [ ] npm_default 네트워크 존재 확인
- [ ] 포트 충돌 없음 확인
- [ ] 충분한 시스템 리소스 확보
- [ ] .env 파일 설정 및 권한 설정 완료
- [ ] 방화벽 설정 확인
- [ ] 테스트 빌드 및 실행 성공

## 🆘 문제 발생 시 대응

1. **로그 확인**
   ```bash
   docker logs pdf2md
   docker-compose logs
   ```

2. **시스템 로그 확인**
   ```bash
   sudo journalctl -xe
   ```

3. **리소스 사용량 확인**
   ```bash
   docker stats
   htop
   ```

---

**📝 참고**: 이 체크리스트를 따라하면 대부분의 배포 문제를 사전에 방지할 수 있습니다. 