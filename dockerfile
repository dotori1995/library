# 베이스 이미지는 매트릭스에서 제공된 DietPi ARM64 및 ARMv7 이미지를 기반으로 합니다.
ARG BASE_IMAGE
FROM ${BASE_IMAGE} AS builder

# CPU 아키텍처 및 추가 설정
ARG CPU_ARCH
ARG DEBIAN_FRONTEND=noninteractive

# 빌드 환경 설정
RUN apt-get update -y --allow-releaseinfo-change && \
    apt-get install -y --no-install-recommends --no-install-suggests \
    curl \
    libwebkit2gtk-4.1-dev \
    build-essential \
    libssl-dev \
    libgtk-3-dev \
    libayatana-appindicator3-dev \
    librsvg2-dev \
    patchelf \
    libfuse2 \
    file \
    jq \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Rust 설치
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Node.js 설치
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash && \
    apt-get install -y nodejs && apt-get clean && rm -rf /var/lib/apt/lists/*

# 작업 디렉토리 설정
WORKDIR /app

# 소스 코드 복사
COPY . .

# npm 설치 및 빌드 실행
RUN npm install && npm run tauri build -- --verbose

# 앱 번들 추출
RUN echo "APP_VERSION=$(jq -r .version src-tauri/tauri.conf.json)" && \
    mkdir -p /output/deb /output/rpm /output/appimage && \
    cp -r src-tauri/target/release/bundle/deb/*.deb /output/deb && \
    cp -r src-tauri/target/release/bundle/rpm/*.rpm /output/rpm && \
    cp -r src-tauri/target/release/bundle/appimage/*.AppImage /output/appimage

# 최종 이미지는 빌드된 파일만 포함
FROM debian:bookworm-slim AS final

# 빌드 아티팩트 복사
COPY --from=builder /output /output

# 작업 디렉토리 설정
WORKDIR /output

# 기본 커맨드 설정
CMD ["ls", "-l", "/output"]
