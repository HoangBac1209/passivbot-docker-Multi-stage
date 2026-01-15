############################
# PB6 builder
############################
FROM python:3.10-slim AS pb6-builder
WORKDIR /build/pb6
RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*
ARG PB6_VERSION=master
RUN git clone https://github.com/enarjord/passivbot.git . && git checkout ${PB6_VERSION}
RUN python -m venv venv && \
    venv/bin/pip install --upgrade pip && \
    venv/bin/pip install --no-cache-dir -r requirements.txt


############################
# PB7 builder
############################
FROM python:3.12-slim AS pb7-builder
WORKDIR /build/pb7
RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*
ARG PB7_VERSION=master
RUN git clone https://github.com/enarjord/passivbot.git . && git checkout ${PB7_VERSION}
RUN python -m venv venv && \
    venv/bin/pip install --upgrade pip && \
    venv/bin/pip install --no-cache-dir -r requirements.txt


############################
# Runtime
############################
FROM python:3.10-slim
WORKDIR /app
ENV PYTHONUNBUFFERED=1

RUN apt-get update && apt-get install -y \
    tzdata \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy bots
COPY --from=pb6-builder /build/pb6 /app/pb6
COPY --from=pb7-builder /build/pb7 /app/pb7

# PBGUI
# Copy PBGUI
COPY --from=pbgui-builder /build/pbgui /app/pbgui

# Entrypoint
COPY base/src/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 8507
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
