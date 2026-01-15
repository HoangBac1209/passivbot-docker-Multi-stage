# syntax=docker/dockerfile:1

# --- Stage 1: Build PB6 (Python 3.10) ---
FROM python:3.10-slim AS builder-pb6
WORKDIR /app/pb6
RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*
RUN python -m venv /venv_pb6 && \
    /venv_pb6/bin/python -m pip install --upgrade pip
ARG PB6_VERSION=v6.1.4b
RUN git clone -b ${PB6_VERSION} https://github.com/enarjord/passivbot.git . && \
    /venv_pb6/bin/python -m pip install --no-cache-dir -r requirements.txt && \
    rm -rf .git

# --- Stage 2: Build PB7 (Python 3.12 + Rust) ---
FROM python:3.12-slim AS builder-pb7
WORKDIR /app/pb7
RUN apt-get update && apt-get install -y git gcc curl build-essential && rm -rf /var/lib/apt/lists/*
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
RUN python -m venv /venv_pb7 && \
    /venv_pb7/bin/python -m pip install --upgrade pip
ARG PB7_VERSION=master
RUN export PATH="/root/.cargo/bin:${PATH}" && \
    git clone -b ${PB7_VERSION} https://github.com/enarjord/passivbot.git . && \
    /venv_pb7/bin/python -m pip install --no-cache-dir maturin -r requirements.txt && \
    cd passivbot-rust && VIRTUAL_ENV=/venv_pb7 /venv_pb7/bin/python -m maturin develop --release && cd .. && \
    # Gỡ rác PB7
    /venv_pb7/bin/python -m pip uninstall -y maturin mkdocs mkdocs-material pylint flake8 prospector astroid isort babel pyecharts openpyxl && \
    /venv_pb7/bin/python -m pip cache purge && \
    rm -rf .git passivbot-rust/target /root/.cargo /root/.rustup

# --- Stage 3: Build PBGUI (Python 3.12) ---
FROM python:3.12-slim AS builder-pbgui
WORKDIR /app/pbgui
RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*
RUN python -m venv /venv_pbgui && \
    /venv_pbgui/bin/python -m pip install --upgrade pip
ARG PBGUI_VERSION=main
RUN git clone -b ${PBGUI_VERSION} https://github.com/msei99/pbgui.git . && \
    /venv_pbgui/bin/python -m pip install --no-cache-dir -r requirements.txt && \
    # Gỡ rác PBGUI (Ansible chiếm ~1GB)
    /venv_pbgui/bin/python -m pip uninstall -y ansible ansible-core ansible-runner pyarrow numba llvmlite && \
    /venv_pbgui/bin/python -m pip cache purge && \
    rm -rf .git

# --- Stage Final: Runtime ---
FROM python:3.12-slim
WORKDIR /app/pbgui
RUN apt-get update && apt-get install -y git && apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy Venv và Code
COPY --from=builder-pb6 /venv_pb6 /venv_pb6
COPY --from=builder-pb7 /venv_pb7 /venv_pb7
COPY --from=builder-pbgui /venv_pbgui /venv_pbgui
COPY --from=builder-pb6 /app/pb6 /app/pb6
COPY --from=builder-pb7 /app/pb7 /app/pb7
COPY --from=builder-pbgui /app/pbgui /app/pbgui

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
EXPOSE 8501
ENTRYPOINT ["/entrypoint.sh"]
