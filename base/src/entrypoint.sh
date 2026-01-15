#!/bin/bash
set -e

# Link các venv vào PATH để có thể gọi lệnh trực tiếp
export PATH="/venv_pbgui/bin:/venv_pb7/bin:/venv_pb6/bin:$PATH"

# (Tùy chọn) Kiểm tra nếu folder config trống thì copy file mẫu hoặc khởi tạo
if [ ! -d "/app/pbgui/data" ]; then
    echo "Initializing data directory..."
    mkdir -p /app/pbgui/data
fi

echo "Starting Passivbot GUI..."
exec streamlit run ./pbgui.py --server.port=8501 --server.address=0.0.0.0
