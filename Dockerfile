# syntax=docker/dockerfile:1

# --- Stage 1: Build PB6 (Python 3.10) ---
FROM python:3.10-slim AS builder-pb6
WORKDIR /app/pb6
RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*
RUN python -m venv /venv_pb6
# Clone and Install
ARG PB6_VERSION=v6.1.4b
RUN git clone -b ${PB6_VERSION} https://github.com/enarjord/passivbot.git . \
    && /venv_pb6/bin/pip install --no-cache-dir --upgrade pip \
    && /venv_pb6/bin/pip install --no-cache-dir -r requirements.txt

# --- Stage 2: Build PB7 (Python 3.12 + Rust) ---
FROM python:3.12-slim AS builder-pb7
WORKDIR /app/pb7
RUN apt-get update && apt-get install -y git gcc curl build-essential && rm -rf /var/lib/apt/lists/*
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

RUN python -m venv /venv_pb7
ARG PB7_VERSION=master
RUN git clone -b ${PB7_VERSION} https://github.com/enarjord/passivbot.git . \
    && /venv_pb7/bin/pip install --no-cache-dir --upgrade pip \
    && /venv_pb7/bin/pip install --no-cache-dir maturin \
    && /venv_pb7/bin/pip install --no-cache-dir -r requirements.txt

# Build Rust components với biến môi trường VIRTUAL_ENV
RUN cd passivbot-rust && \
    VIRTUAL_ENV=/venv_pb7 /venv_pb7/bin/python -m maturin develop --release

# --- Stage 3: Build PBGUI (Python 3.12) ---
FROM python:3.12-slim AS builder-pbgui
WORKDIR /app/pbgui
RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*
RUN python -m venv /venv_pbgui
ARG PBGUI_VERSION=main
RUN git clone -b ${PBGUI_VERSION} https://github.com/msei99/pbgui.git . \
    && /venv_pbgui/bin/pip install --no-cache-dir --upgrade pip \
    && /venv_pbgui/bin/pip install --no-cache-dir -r requirements.txt

# --- Stage Final: Runtime ---
FROM python:3.12-slim
WORKDIR /app/pbgui

# Chỉ cài git và các thư viện runtime cần thiết, dọn dẹp ngay sau khi cài
RUN apt-get update && apt-get install -y git && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy Virtual Environments (Đây là phần nặng nhất nhưng cần thiết)
COPY --from=builder-pb6 /venv_pb6 /venv_pb6
COPY --from=builder-pb7 /venv_pb7 /venv_pb7
COPY --from=builder-pbgui /venv_pbgui /venv_pbgui

# Copy Source Code và LOẠI BỎ folder .git để giảm dung lượng
COPY --from=builder-pb6 /app/pb6 /app/pb6
RUN rm -rf /app/pb6/.git

COPY --from=builder-pb7 /app/pb7 /app/pb7
RUN rm -rf /app/pb7/.git /app/pb7/passivbot-rust/target 

COPY --from=builder-pbgui /app/pbgui /app/pbgui
RUN rm -rf /app/pbgui/.git

# Thiết lập entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8501
ENTRYPOINT ["/entrypoint.sh"]
