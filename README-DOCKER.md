# PDF2MD Docker 배포 가이드

PDF 파일을 Markdown으로 변환하는 Next.js 애플리케이션의 Docker 프로덕션 배포 가이드입니다.

> 📖 **English Version**: [README-DOCKER-en.md](./README-DOCKER-en.md)

## 🚀 빠른 시작

### 1. 환경 설정

```bash
# 환경 변수 파일 생성
cp env.prod.example .env

# 환경 변수 편집
nano .env
```

**필수 설정 항목:**
- `MISTRAL_API_KEY`: Mistral AI API 키
- `DOMAIN`: 도메인 이름 (예: your-domain.com)
- `SSL_EMAIL`: SSL 인증서용 이메일 주소

### 2. 배포 실행

```bash
# 배포 스크립트 실행
chmod +x scripts/deploy.sh
./scripts/deploy.sh
```

## 📋 시스템 요구사항

- **Docker**: 20.10+
- **Docker Compose**: 2.0+
- **메모리**: 최소 2GB (권장 4GB+)
- **디스크**: 최소 10GB (업로드 파일 저장용)
- **포트**: 80, 443 (HTTP/HTTPS)

## 🏗️ 아키텍처

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Internet  │───▶│    Nginx    │───▶│  Next.js    │
│             │    │ (SSL/Proxy) │    │    App      │
└─────────────┘    └─────────────┘    └─────────────┘
                           │
                   ┌───────▼───────┐
                   │  Let's Encrypt │
                   │   (Certbot)    │
                   └───────────────┘
```

## 🔧 주요 구성 요소

### 서비스

- **pdf2md**: Next.js 애플리케이션
- **nginx**: 리버스 프록시 + SSL 터미네이션
- **certbot**: Let's Encrypt SSL 인증서 자동 갱신
- **prometheus**: 모니터링 (선택사항)
- **grafana**: 대시보드 (선택사항)
- **backup**: 자동 백업

### 볼륨

- `uploads`: 업로드된 파일 저장
- `ssl`: SSL 인증서 저장
- `logs`: 애플리케이션 로그
- `backups`: 백업 파일

## 📂 디렉토리 구조

```
pdf2md/
├── docker-compose.yml          # 기본 설정
├── docker-compose.prod.yml     # 프로덕션 설정
├── Dockerfile                  # 애플리케이션 이미지
├── env.prod.example           # 환경 변수 예시
├── nginx/
│   ├── nginx.conf             # Nginx 메인 설정
│   └── conf.d/
│       └── pdf2md.conf        # 가상 호스트 설정
├── scripts/
│   ├── deploy.sh              # 배포 스크립트
│   └── backup.sh              # 백업 스크립트
└── monitoring/
    └── prometheus.yml         # 모니터링 설정
```

## 🚀 배포 명령어

### 기본 배포
```bash
# 프로덕션 서비스 시작
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

### SSL 인증서 설정
```bash
# Let's Encrypt 인증서 획득
docker-compose -f docker-compose.yml -f docker-compose.prod.yml --profile ssl run --rm certbot

# SSL 갱신 서비스 시작
docker-compose -f docker-compose.yml -f docker-compose.prod.yml --profile ssl up -d
```

### 모니터링 활성화
```bash
# Prometheus + Grafana 시작
docker-compose -f docker-compose.yml -f docker-compose.prod.yml --profile monitoring up -d
```

### 백업 실행
```bash
# 수동 백업
docker-compose -f docker-compose.yml -f docker-compose.prod.yml --profile backup run --rm backup
```

## 🔍 모니터링 & 관리

### 로그 확인
```bash
# 전체 로그
docker-compose -f docker-compose.yml -f docker-compose.prod.yml logs -f

# 특정 서비스 로그
docker-compose -f docker-compose.yml -f docker-compose.prod.yml logs -f pdf2md
docker-compose -f docker-compose.yml -f docker-compose.prod.yml logs -f nginx
```

### 서비스 상태 확인
```bash
# 컨테이너 상태
docker-compose -f docker-compose.yml -f docker-compose.prod.yml ps

# 헬스체크
curl -f http://localhost:3000/api/health
```

### 접속 URL
- **메인 사이트**: https://YOUR_DOMAIN.com
- **Grafana**: http://YOUR_DOMAIN.com:3001
- **Prometheus**: http://YOUR_DOMAIN.com:9090

## 🔐 보안 설정

### SSL/TLS
- **프로토콜**: TLS 1.2, 1.3
- **인증서**: Let's Encrypt (자동 갱신)
- **HSTS**: 활성화
- **OCSP Stapling**: 활성화

### 보안 헤더
- X-Frame-Options
- X-Content-Type-Options
- X-XSS-Protection
- Content-Security-Policy
- Strict-Transport-Security

### Rate Limiting
- API: 10 req/sec
- Upload: 2 req/sec
- Connection: 20/IP

## 🛠️ 유지보수

### 업데이트
```bash
# 애플리케이션 업데이트
git pull
docker-compose -f docker-compose.yml -f docker-compose.prod.yml build --no-cache
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

### 백업 복원
```bash
# 백업 파일 목록
ls -la backups/

# 백업 복원 (예시)
tar -xzf backups/pdf2md_backup_20241220_120000.tar.gz -C /tmp
cp -r /tmp/pdf2md_backup_20241220_120000/uploads/* uploads/
```

### SSL 인증서 수동 갱신
```bash
docker-compose -f docker-compose.yml -f docker-compose.prod.yml --profile ssl exec certbot-renew certbot renew
docker-compose -f docker-compose.yml -f docker-compose.prod.yml restart nginx
```

## 🐛 문제 해결

### 일반적인 문제

1. **포트 충돌**
   ```bash
   # 포트 사용 확인
   sudo netstat -tlnp | grep :80
   sudo netstat -tlnp | grep :443
   ```

2. **SSL 인증서 오류**
   ```bash
   # 인증서 상태 확인
   docker-compose -f docker-compose.yml -f docker-compose.prod.yml --profile ssl logs certbot
   ```

3. **메모리 부족**
   ```bash
   # 메모리 사용량 확인
   docker stats
   ```

### 로그 위치
- **Nginx**: `nginx-logs` 볼륨
- **애플리케이션**: `logs` 볼륨
- **SSL**: `certbot-logs` 볼륨

## 📞 지원

문제가 발생하면 다음을 확인하세요:

1. 환경 변수 설정 (`.env` 파일)
2. 도메인 DNS 설정
3. 방화벽 설정 (80, 443 포트)
4. Docker 서비스 상태

---

**도메인**: YOUR_DOMAIN.com  
**서버 IP**: YOUR.SERVER.IP  
**DDNS**: your-ddns-host.com 