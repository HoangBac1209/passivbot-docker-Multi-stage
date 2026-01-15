Dockerized Passivbot with pbgui (Storage Optimized)
This project provides an optimized Docker environment for running Passivbot (v6, v7) and PBGUI. The image is designed using Multi-stage Builds, reducing the size from 4.6GB to approximately ~3GB, making it ideal for low-storage VPS providers.

🚀 Key Features
Multi-stage Architecture: Separates the Build process (requires Rust, GCC) from the Runtime process, eliminating system bloat.

Isolated Environments:

PB6: Runs on a stable Python 3.10 environment.

PB7 & PBGUI: Runs on the latest Python 3.12.

Extreme Storage Optimization:

Completely removes Ansible, PyArrow, and Ansible-runner (~1GB of overhead).

Automatically cleans up Rust compilers (Cargo), build tools, and Pip caches immediately after the build.

WebSocket Support: Pre-configured for Streamlit to ensure a smooth web interface.

🛠 Quick Start
1. Clone and Configure
Bash

git clone https://github.com/LeonSpors/passivbot-docker.git
cd passivbot-docker
Open the .env file and set your data path:

Bash

USERDATA=./pb_userdata
2. Setup Directory Structure (Linux)
Grant permissions and run the script to create the required data folders:

Bash

chmod +x ./tools/setup.sh
./tools/setup.sh
3. Build and Run
Use the following command for the cleanest build, avoiding residual cache:

Bash

docker compose build --no-cache && docker compose up -d
🔄 Updating the Bot
Since the system is optimized to save space, clicking the Update button on the Web GUI might re-install "bloat" libraries (like Ansible). To update safely while maintaining the small footprint, use the provided script:

Bash

chmod +x update_bot.sh
./update_bot.sh
This script will: Pull the latest code -> Rebuild the Rust module (if needed) -> Automatically "de-bloat" the environment.

❓ FAQ
Q: How do I check the current Image size? Run: docker images | grep passivbot. The optimized version should be around 2.8GB - 3.1GB.

Q: Why can't I use pip directly inside the container? To avoid path conflicts, call pip through the corresponding virtual environment:

Bash

docker exec -it <container_id> /venv_pbgui/bin/python -m pip list
Q: My Nginx shows "Connection Error" repeatedly? You must add WebSocket support to your Nginx configuration:

Nginx

proxy_set_header Upgrade $http_upgrade;
proxy_set_header Connection "upgrade";
📁 Data Structure (Volumes)
All critical data is stored in the directory defined in your USERDATA variable:

configs/: Contains api-keys.json, pbgui.ini, and secrets.toml.

pb6/ & pb7/: Contains backtests, optimization results, and caches.

Note for 20GB VPS: Regularly run docker system prune -f after updates to release storage from old image layers.
