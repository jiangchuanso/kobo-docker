# Dockerfile
FROM --platform=$BUILDPLATFORM python:3.9-slim as builder

# 构建参数
ARG TARGETPLATFORM
ARG BUILDPLATFORM
ARG TARGETARCH

# 安装系统依赖
RUN apt-get update && apt-get install -y \
    build-essential \
    libpq-dev \
    libxml2-dev \
    libxslt1-dev \
    libffi-dev \
    libssl-dev \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# 设置工作目录
WORKDIR /app

# 复制依赖文件
COPY requirements.txt .
COPY requirements/ requirements/

# 安装Python依赖
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# 生产阶段
FROM python:3.9-slim

# 安装运行时依赖
RUN apt-get update && apt-get install -y \
    libpq5 \
    libxml2 \
    libxslt1.1 \
    libffi7 \
    libssl1.1 \
    gettext \
    curl \
    && rm -rf /var/lib/apt/lists/*

# 创建非root用户
RUN groupadd -r kobo && useradd -r -g kobo kobo

# 设置工作目录
WORKDIR /app

# 从构建阶段复制已安装的包
COPY --from=builder /usr/local/lib/python3.9/site-packages /usr/local/lib/python3.9/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# 复制应用代码
COPY . .

# 设置权限
RUN chown -R kobo:kobo /app

# 切换到非root用户
USER kobo

# 健康检查
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health/ || exit 1

# 暴露端口
EXPOSE 8000

# 启动命令
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
