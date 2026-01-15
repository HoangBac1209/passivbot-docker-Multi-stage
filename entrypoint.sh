#!/bin/bash
set -e

# Link các venv vào PATH để có thể gọi lệnh trực tiếp
export PATH="/venv_pbgui/bin:/venv_pb7/bin:/venv_pb6/bin:$PATH"

# Khởi tạo thư mục data nếu mount volume bị trống
mkdir -p /app/pbgui/data /app/pb6/configs /app/pb7/configs

echo "Starting Passivbot GUI..."
# Sử dụng trực tiếp python từ venv pbgui để chạy streamlit
exec /venv_pbgui/bin/python -m streamlit run ./pbgui.py --server.port=8501 --server.address=0.0.0.0
#docker compose down && docker system prune -a --volumes -f && docker builder prune -a -f && docker compose build --no-cache && docker compose up -d
