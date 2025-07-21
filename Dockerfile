# syntax=docker/dockerfile:1

# =========================================
# 베이스 이미지 설정 (Debian 11 Bullseye 기반 Node.js)
# =========================================
ARG NODE_VERSION=20
FROM node:${NODE_VERSION}-bullseye-slim AS base

# 작업 디렉토리 설정
WORKDIR /app

# 시스템 패키지 업데이트 및 필수 도구 설치
RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    && rm -rf /var/lib/apt/lists/*

# =========================================
# 의존성 설치 단계
# =========================================
FROM base AS deps

# package.json과 package-lock.json 복사
COPY package*.json ./

# 의존성 설치 (캐시 최적화)
RUN --mount=type=cache,target=/root/.npm \
    if [ -f package-lock.json ]; then \
        npm ci --only=production; \
    else \
        npm install --only=production; \
    fi

# =========================================
# 빌드 단계
# =========================================
FROM base AS builder

# 의존성 파일 복사
COPY package*.json ./

# 개발 의존성 포함 설치
RUN --mount=type=cache,target=/root/.npm \
    if [ -f package-lock.json ]; then \
        npm ci; \
    else \
        npm install; \
    fi && \
    npm cache clean --force

# 소스 코드 복사
COPY . .

# Next.js 빌드
RUN npm run build

# =========================================
# 프로덕션 실행 단계
# =========================================
FROM base AS runner

# 환경 변수 설정
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
ENV UPLOAD_DIR=/app/uploads

# 보안을 위한 non-root 사용자 생성
RUN groupadd --system --gid 1001 nodejs && \
    useradd --system --uid 1001 --gid nodejs nextjs

# 업로드 디렉토리 생성 및 권한 설정
RUN mkdir -p /app/uploads && \
    chown -R nextjs:nodejs /app/uploads

# 프로덕션 의존성 복사
COPY --from=deps --chown=nextjs:nodejs /app/node_modules ./node_modules

# 빌드된 애플리케이션 복사
COPY --from=builder --chown=nextjs:nodejs /app/.next ./.next
COPY --from=builder --chown=nextjs:nodejs /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/package.json ./package.json
COPY --from=builder --chown=nextjs:nodejs /app/next.config.ts ./next.config.ts

# 사용자 전환
USER nextjs

# 포트 노출
EXPOSE 3000

# 헬스체크 추가
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:3000/api/health || exit 1

# 애플리케이션 실행
CMD ["npm", "start"] 