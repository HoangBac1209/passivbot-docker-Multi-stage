#!/bin/bash

CONTAINER_NAME="pass-docker-main-passivbot-1"

# Hàm cập nhật thông minh
update_repo() {
    local path=$1
    local url=$2
    local branch=$3
    echo "--- Cập nhật $path ---"
    docker exec -t $CONTAINER_NAME bash -c "
        cd $path && \
        if [ ! -d .git ]; then
            git init && git remote add origin $url && git fetch && git reset --hard origin/$branch;
        else
            git pull origin $branch;
        fi && \
        # Nén thư mục .git để tiết kiệm dung lượng thay vì xóa hẳn
        git gc --prune=now --aggressive
    "
}

# 1. Cập nhật PBGUI
update_repo "/app/pbgui" "https://github.com/msei99/pbgui.git" "main"

# 2. Cập nhật PB7
update_repo "/app/pb7" "https://github.com/enarjord/passivbot.git" "master"

# 3. Build Rust & Requirements (Giữ nguyên các bước hút mỡ của bạn)
echo "--- 3. Cập nhật thư viện & Build Rust cho PB7 ---"
docker exec -t $CONTAINER_NAME bash -c "
    /venv_pb7/bin/python -m pip install maturin -r /app/pb7/requirements.txt && \
    cd /app/pb7/passivbot-rust && \
    VIRTUAL_ENV=/venv_pb7 /venv_pb7/bin/python -m maturin develop --release && \
    rm -rf target"

echo "--- 4. Cài đặt thư viện cho PBGUI & Hút mỡ ---"
docker exec -t $CONTAINER_NAME bash -c "
    /venv_pbgui/bin/python -m pip install -r /app/pbgui/requirements.txt && \
    /venv_pbgui/bin/python -m pip uninstall -y ansible ansible-core ansible-runner paramiko bcrypt pyarrow && \
    /venv_pb7/bin/python -m pip uninstall -y maturin mkdocs mkdocs-material pylint flake8 prospector astroid isort babel pyecharts openpyxl && \
    /venv_pbgui/bin/python -m pip cache purge && \
    /venv_pb7/bin/python -m pip cache purge && \
    find /app -name '*.pyc' -delete && \
    find /app -name '__pycache__' -delete"

echo "--- 5. Khởi động lại ---"
docker compose restart

echo "Xong! Hệ thống đã được nén gọn .git và cập nhật nhanh."
