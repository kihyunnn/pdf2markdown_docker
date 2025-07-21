# Ubuntu 배포 시 발생 가능한 문제점 및 해결 방안

> 🔍 **실제 우분투 서버에서 Docker 배포 시 발생할 수 있는 모든 문제점들과 해결 방안**

## 🚨 중요한 발견 사항들

### ✅ 검증 완료 항목들
- ✅ API 헬스체크 엔드포인트 구현됨 (`/api/health`)
- ✅ 로컬 파일 시스템 지원 완전 구현
- ✅ 환경 변수 설정 구조 완료
- ✅ Docker 보안 설정 (비루트 사용자)

### ⚠️ 잠재적 문제점들

## 1. 🐳 Docker 환경 문제

### 문제 1-1: Docker Compose 버전 호환성
**증상**: `version: '3.8'` 필드가 deprecated 경고 발생
**해결**: 이미 수정 완료 (주석 처리)

### 문제 1-2: 베이스 이미지 혼동
**증상**: 주석과 실제 이미지 불일치
**해결**: Dockerfile 주석 수정 완료 (Debian 11 Bullseye 명시)

### 문제 1-3: 헬스체크 의존성
**증상**: `curl` 명령어가 컨테이너에 없을 수 있음
**해결**: Dockerfile에서 `curl` 설치 확인됨
```dockerfile
RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    && rm -rf /var/lib/apt/lists/*
```

## 2. 🔐 파일 권한 문제

### 문제 2-1: UID/GID 매핑 불일치
**증상**: 
- Docker 컨테이너의 `nextjs` 사용자 (UID 1001)와 호스트 사용자 UID 불일치
- 업로드된 파일에 접근 불가
- 로그 파일 생성 실패

**해결 방안**:
```bash
# 1. 권한 설정 스크립트 실행
sudo ./scripts/setup-permissions.sh /opt/pdf2md-data

# 2. Docker Compose에 user 매핑 추가
user: "1000:1000"  # 실제 사용자 UID:GID

# 3. 데이터 디렉토리 소유권 설정
sudo chown -R 1000:1000 /opt/pdf2md-data
```

### 문제 2-2: 볼륨 마운트 권한
**증상**: 
- `/app/uploads` 디렉토리 쓰기 권한 없음
- 백업 디렉토리 접근 불가

**해결 방안**:
```bash
# 디렉토리 생성 및 권한 설정
sudo mkdir -p /opt/pdf2md-data/{uploads,logs,backups}
sudo chmod 755 /opt/pdf2md-data/{uploads,logs,backups}
sudo chown -R $USER:$USER /opt/pdf2md-data
```

## 3. 🌐 네트워크 문제

### 문제 3-1: npm_default 네트워크 부재
**증상**: 
- `network npm_default declared as external, but could not be found`
- Nginx Proxy Manager와 연결 실패

**해결 방안**:
```bash
# 네트워크 생성
docker network create npm_default

# 또는 기존 네트워크 사용
docker network create --driver bridge npm_default
```

### 문제 3-2: 포트 충돌
**증상**: 
- 포트 3002가 이미 사용 중
- `bind: address already in use`

**해결 방안**:
```bash
# 포트 사용 확인
sudo netstat -tlnp | grep :3002
sudo ss -tlnp | grep :3002

# 사용 중인 프로세스 종료 또는 다른 포트 사용
# docker-compose.server.yml에서 포트 변경
ports:
  - '127.0.0.1:3003:3000'  # 3003으로 변경
```

### 문제 3-3: 방화벽 차단
**증상**: 
- 외부에서 서비스 접근 불가
- UFW가 포트 차단

**해결 방안**:
```bash
# UFW 포트 허용
sudo ufw allow 3002

# 방화벽 상태 확인
sudo ufw status verbose
```

## 4. 💾 리소스 부족 문제

### 문제 4-1: 메모리 부족
**증상**: 
- Next.js 빌드 중 `ENOMEM` 오류
- 컨테이너 OOM Killed

**해결 방안**:
```bash
# 메모리 확인
free -h

# swap 설정 (메모리 < 2GB인 경우)
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Docker 메모리 제한 설정
deploy:
  resources:
    limits:
      memory: 1G
    reservations:
      memory: 512M
```

### 문제 4-2: 디스크 공간 부족
**증상**: 
- Docker 이미지 빌드 실패
- `no space left on device`

**해결 방안**:
```bash
# 디스크 공간 확인
df -h

# Docker 정리
docker system prune -a
docker volume prune

# 로그 크기 제한
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
```

## 5. 🔑 환경 변수 및 보안 문제

### 문제 5-1: MISTRAL_API_KEY 누락
**증상**: 
- OCR 처리 실패
- `MISTRAL_API_KEY is not set` 오류

**해결 방안**:
```bash
# .env 파일 확인
grep MISTRAL_API_KEY .env

# 환경 변수 설정
echo "MISTRAL_API_KEY=your_actual_api_key_here" >> .env
chmod 600 .env
```

### 문제 5-2: .env 파일 권한 문제
**증상**: 
- 다른 사용자가 API 키 열람 가능
- 보안 취약점

**해결 방안**:
```bash
# 안전한 권한 설정
chmod 600 .env
chown $USER:$USER .env

# 권한 확인
ls -la .env
# 출력: -rw------- 1 user user ... .env
```

## 6. 🚀 애플리케이션 특정 문제

### 문제 6-1: 첫 시작 지연
**증상**: 
- 컨테이너 시작 후 응답까지 오래 걸림
- Next.js 최적화 과정

**해결 방안**:
```bash
# 헬스체크 대기 시간 증가
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=5

# 워밍업 요청
sleep 30 && curl -f http://localhost:3002/api/health
```

### 문제 6-2: 파일 업로드 크기 제한
**증상**: 
- 100MB 이상 파일 업로드 실패
- 파일 크기 제한 오류

**해결 방안**:
```bash
# nginx 설정 (필요시)
client_max_body_size 100M;

# Next.js 설정은 이미 100MB로 설정됨
const MAX_FILE_SIZE = 100 * 1024 * 1024; // 100MB
```

### 문제 6-3: OCR 처리 시간 초과
**증상**: 
- 큰 PDF 파일 처리 중 타임아웃
- Mistral AI API 응답 지연

**해결 방안**:
```bash
# 타임아웃 설정 증가 (필요시)
# nginx proxy timeout 설정
proxy_read_timeout 300s;
proxy_connect_timeout 300s;
```

## 7. 🔧 일반적인 트러블슈팅

### 로그 확인 방법
```bash
# 컨테이너 로그
docker logs pdf2md -f

# 시스템 로그
sudo journalctl -u docker.service -f

# 애플리케이션 로그
tail -f /opt/pdf2md-data/logs/app.log
```

### 상태 확인 방법
```bash
# 컨테이너 상태
docker ps
docker stats pdf2md

# 헬스체크
curl -f http://localhost:3002/api/health

# 리소스 사용량
htop
df -h
free -h
```

### 재시작 및 복구 방법
```bash
# 컨테이너 재시작
docker-compose -f docker-compose.server.yml restart

# 완전 재배포
docker-compose -f docker-compose.server.yml down
docker-compose -f docker-compose.server.yml up --build -d

# 데이터 복구 (백업이 있는 경우)
sudo cp -r /backup/pdf2md-data/* /opt/pdf2md-data/
```

## 8. 📋 배포 전 필수 체크리스트

### 시스템 요구사항
- [ ] Ubuntu 20.04+ (22.04 권장)
- [ ] Docker 20.10+
- [ ] Docker Compose 2.0+
- [ ] 메모리 2GB+ (4GB 권장)
- [ ] 디스크 10GB+ (50GB 권장)

### 네트워크 설정
- [ ] npm_default 네트워크 존재
- [ ] 포트 충돌 없음 (3002 등)
- [ ] UFW 방화벽 설정
- [ ] DNS 해상도 정상

### 파일 시스템
- [ ] 데이터 디렉토리 생성
- [ ] 올바른 권한 설정 (755)
- [ ] 충분한 디스크 공간
- [ ] 백업 디렉토리 설정

### 환경 변수
- [ ] .env 파일 생성
- [ ] MISTRAL_API_KEY 설정
- [ ] 파일 권한 600
- [ ] 실제 경로로 수정

### 보안 설정
- [ ] 비루트 사용자 실행
- [ ] 안전한 파일 권한
- [ ] 환경 변수 보안
- [ ] 방화벽 설정

## 9. 🆘 긴급 상황 대응

### 서비스 다운 시
```bash
# 1. 상태 확인
docker ps -a
curl -I http://localhost:3002

# 2. 로그 확인
docker logs pdf2md --tail 50

# 3. 재시작 시도
docker-compose restart

# 4. 완전 재배포
docker-compose down && docker-compose up -d
```

### 데이터 손실 시
```bash
# 1. 백업 확인
ls -la /opt/pdf2md-data/backups/

# 2. 백업 복원
sudo tar -xzf backup_file.tar.gz -C /opt/pdf2md-data/

# 3. 권한 복구
sudo chown -R $USER:$USER /opt/pdf2md-data
```

### 메모리/디스크 부족 시
```bash
# 1. 리소스 정리
docker system prune -a
sudo apt autoremove
sudo apt autoclean

# 2. 로그 정리
sudo journalctl --vacuum-size=100M

# 3. 임시 파일 정리
sudo rm -rf /tmp/*
sudo rm -rf /var/tmp/*
```

---

## 📞 추가 지원

문제가 지속되는 경우:

1. **로그 수집**: 모든 관련 로그 파일 수집
2. **환경 정보**: 시스템 사양, Docker 버전 등
3. **재현 단계**: 문제 발생까지의 정확한 단계
4. **오류 메시지**: 정확한 오류 메시지 전문

**🔧 자동 점검 스크립트**: `./scripts/pre-deploy-check.sh`  
**🔐 권한 설정 스크립트**: `sudo ./scripts/setup-permissions.sh`  
**📋 상세 가이드**: `UBUNTU_DEPLOYMENT_CHECKLIST.md` 