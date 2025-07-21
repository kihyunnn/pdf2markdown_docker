# PDF to Markdown 변환기

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Docker](https://img.shields.io/badge/Docker-Supported-blue)](https://docker.com)

> 📖 **English**: [README.md](./README.md) | **日本語**: [README-ja.md](./README-ja.md)

Mistral AI의 OCR 기능을 사용하여 PDF 파일을 Markdown으로 변환하는 강력한 Next.js 애플리케이션입니다. 이 프로젝트는 **로컬 파일 저장소를 사용하는 자체 호스팅 Docker 배포**를 위해 설계되었습니다.

## 📖 이 프로젝트에 대해

이 프로젝트는 riku ogawa의 [pdf2md](https://github.com/link2004/pdf2md)를 기반으로 다음과 같은 기능을 추가하여 개선한 버전입니다:

- 🐳 **Docker 배포 지원** - nginx 프록시와 함께
- 📁 **로컬 파일 저장소** - 클라우드 저장소 의존성 제거
- 🔧 **Nginx Proxy Manager 호환성**
- 🛡️ **프로덕션 준비 보안 구성**
- 📊 **모니터링 및 백업 기능**
- 🌏 **한국 서버 환경 최적화**

## ✨ 주요 기능

- 📄 **PDF 업로드**: 최대 100MB PDF 파일 지원
- 🤖 **AI 기반 OCR**: Mistral AI를 사용한 정확한 텍스트 추출
- 📝 **Markdown 변환**: 추출된 텍스트를 깔끔한 Markdown으로 변환
- ✏️ **실시간 편집기**: Markdown을 실시간으로 편집하고 미리보기
- 💾 **다중 내보내기 형식**: .md, .html, .pdf로 다운로드
- 🔄 **일괄 처리**: 여러 파일 동시 처리
- 🐳 **Docker 준비**: Docker Compose로 쉬운 배포

## 🚀 빠른 시작

### 🐳 Docker 배포 (자체 호스팅)

nginx proxy manager가 있는 개인 서버에 최적:

#### 사전 요구사항
- Docker & Docker Compose
- Nginx Proxy Manager (또는 유사한 리버스 프록시)
- 외부 네트워크: `npm_default`

#### 빠른 설정

1. **설정 파일 복사**
   ```bash
   cp env.server.example .env
   cp docker-compose.server.yml docker-compose.yml
   ```

2. **환경 변수 편집**
   ```bash
   nano .env
   # MISTRAL_API_KEY와 도메인 설정
   ```

3. **docker-compose.yml에서 경로 업데이트**
   ```yaml
   volumes:
     - /path/to/your/data:/app/uploads        # 데이터 경로
     - /path/to/your/data/logs:/app/logs      # 로그 경로
   
   ports:
     - '127.0.0.1:YOUR_PORT:3000'             # 포트 (예: 3002)
   ```

4. **데이터 디렉토리 생성**
   ```bash
   sudo mkdir -p /path/to/your/data/{logs,backups}
   sudo chown -R $USER:$USER /path/to/your/data
   ```

5. **배포**
   ```bash
   # 기본 서비스
   docker-compose up -d
   
   # 백업 서비스 포함
   docker-compose --profile backup up -d
   ```

6. **Nginx Proxy Manager 설정**
   - Target: `http://127.0.0.1:YOUR_PORT`
   - Domain: `your-domain.com`
   - SSL: Let's Encrypt 활성화

자세한 배포 가이드는 [README-DOCKER.md](./README-DOCKER.md)를 참조하세요.

## 🔧 개발

### 로컬 개발

```bash
# 의존성 설치
npm install

# 개발 서버 실행
npm run dev

# 프로덕션 빌드
npm run build

# 프로덕션 서버 시작
npm start
```

### 테스트

```bash
# 테스트 실행
npm test

# 감시 모드로 테스트
npm test:watch

# 통합 테스트 실행
npm run test:integration
```

## 📋 환경 변수

### 필수
- `MISTRAL_API_KEY`: Mistral AI API 키

### Docker 배포용
- `NEXT_PUBLIC_APP_URL`: 도메인 URL
- `UPLOAD_DIR`: 업로드 디렉토리 경로 (기본값: `/app/uploads`)

### 선택사항
- `NODE_ENV`: 환경 (development/production)
- `NEXT_TELEMETRY_DISABLED`: Next.js 텔레메트리 비활성화
- `BACKUP_RETENTION_DAYS`: 백업 보존 기간 (기본값: 30)

## 🏗️ 아키텍처

### 자체 호스팅 아키텍처 (Docker)
```
인터넷 → Nginx 프록시 → Next.js 컨테이너 → Mistral AI
                      ↓
                로컬 파일 시스템
```

## 📊 모니터링 및 관리

### Docker 배포 기능
- 🔍 **헬스 체크**: 자동 컨테이너 상태 모니터링
- 📊 **Prometheus 메트릭**: 선택적 모니터링 스택
- 📈 **Grafana 대시보드**: 시각적 모니터링 인터페이스
- 📝 **로그 수집**: Loki를 통한 중앙화된 로깅
- 💾 **자동 백업**: 보존 정책이 있는 일일 백업

### 관리 명령어
```bash
# 로그 보기
docker logs pdf2md

# 상태 확인
curl http://localhost:YOUR_PORT/api/health

# 수동 백업
docker-compose --profile backup run --rm backup

# 애플리케이션 업데이트
docker-compose up --build -d
```

## 🛡️ 보안 기능

- 🔐 **파일 유형 검증**: PDF 파일만 허용
- 📏 **크기 제한**: 최대 100MB 파일 크기
- 🛡️ **보안 헤더**: 포괄적인 보안 헤더
- 🚫 **속도 제한**: API 및 업로드 속도 제한
- 🔒 **SSL/TLS**: Let's Encrypt를 통한 자동 HTTPS
- 👤 **비루트 컨테이너**: 안전한 컨테이너 실행

## 🤝 기여하기

1. 저장소 포크
2. 기능 브랜치 생성 (`git checkout -b feature/amazing-feature`)
3. 변경사항 커밋 (`git commit -m 'Add amazing feature'`)
4. 브랜치에 푸시 (`git push origin feature/amazing-feature`)
5. Pull Request 열기

## 📄 라이선스

이 프로젝트는 MIT 라이선스 하에 라이선스됩니다 - 자세한 내용은 [LICENSE](LICENSE) 파일을 참조하세요.

## 🙏 감사의 말

- [riku ogawa](https://github.com/link2004/pdf2md)의 원본 프로젝트
- OCR 기능을 위한 [Mistral AI](https://mistral.ai/)
- [Next.js](https://nextjs.org/) 프레임워크
- 클라우드 호스팅 플랫폼 [Vercel](https://vercel.com/)

## 🆘 지원

- 📖 [문서](./README-DOCKER.md)
- 🐛 [이슈 신고](https://github.com/your-username/pdf2md/issues)
- 💬 [토론](https://github.com/your-username/pdf2md/discussions)

## 🗃️ 버전 히스토리

- **v1.1.0** - Docker 지원 및 로컬 파일 저장소 추가
- **v1.0.0** - 원본 Vercel 기반 배포 (by riku ogawa)

---

**🌟 이 저장소가 도움이 되었다면 스타를 눌러주세요!** 