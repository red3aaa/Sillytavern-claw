FROM python:3.11-slim
copy start.sh .

WORKDIR /app

run pip install webdavclient3 requests
run apt-get update && apt-get install -y wget git curl

run wget https://codeberg.org/forgejo/forgejo/releases/download/v11.0.0/forgejo-11.0.0-linux-amd64
run chmod +x forgejo-11.0.0-linux-amd64

copy sync_data.sh . 
copy start.sh . 

run chmod +x sync_data.sh
run chmod +x start.sh
run chmod 777 /app
run chmod +x ./forgejo-11.0.0-linux-amd64

run mkdir -p --mode=0755 /usr/share/keyrings
run curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null
run echo 'deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared any main' | tee /etc/apt/sources.list.d/cloudflared.list
run apt-get update
run apt-get install cloudflared -y
run apt-get install sudo -y

ARG USERNAME=git
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN groupadd --gid $USER_GID $USERNAME && \
    useradd --uid $USER_UID --gid $USER_GID -m $USERNAME --shell /bin/bash

# 配置 sudoers，允许无密码执行所有命令
# 创建一个新文件到 /etc/sudoers.d/ 下是推荐的做法，避免直接修改 /etc/sudoers
RUN mkdir -p /etc/sudoers.d && \
    echo "$USERNAME ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/$USERNAME && \
    chmod 0440 /etc/sudoers.d/$USERNAME

# 切换到新创建的非 root 用户
USER $USERNAME

cmd "/app/start.sh"