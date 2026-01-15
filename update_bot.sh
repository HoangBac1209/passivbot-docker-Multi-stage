#!/bin/bash

CONTAINER_NAME="passivbot-docker-passivbot-1"

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
    /venv_pbgui/bin/python -m pip uninstall -y ansible ansible-core llvmlite && \
    /venv_pb7/bin/python -m pip uninstall -y maturin mkdocs mkdocs-material pylint flake8 prospector astroid isort babel pyecharts openpyxl && \
    /venv_pbgui/bin/python -m pip cache purge && \
    /venv_pb7/bin/python -m pip cache purge && \
    find /app -name '*.pyc' -delete && \
    find /app -name '__pycache__' -delete"

echo "--- 5. Khởi động lại Container ---"
docker compose restart

echo "Waiting 20s for container to stabilize..."
sleep 20

echo "--- 6. Khởi động lại Background Services (PBRun & PBCoinData) ---"
docker exec -t $CONTAINER_NAME bash -c "
    # Giết các tiến trình cũ để tránh xung đột
    pkill -f PBRun.py || true
    pkill -f PBCoinData.py || true

    # Chạy lại bằng đường dẫn tuyệt đối của venv để an toàn tuyệt đối
    cd /app/pbgui && \
    /venv_pbgui/bin/python PBRun.py > /dev/null 2>&1 & \
    /venv_pbgui/bin/python PBCoinData.py > /dev/null 2>&1 &

    echo 'Services PBRun and PBCoinData are now running in background.'"

echo "--- 7. Dọn dẹp rác hệ thống (Final Cleanup) ---"
docker system prune -f && docker builder prune -a -f

echo "Xong! Hệ thống đã được cập nhật, nén gọn .git và khởi động lại dịch vụ."
