FROM node:19.1.0-slim

# 设置应用目录
ARG APP_HOME=/home/node/app

RUN apt-get update && apt-get install tini git python3 python3-pip bash dos2unix findutils tar curl sudo -y

# Add cloudflare gpg key
run mkdir -p --mode=0755 /usr/share/keyrings
run curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null

# Add this repo to your apt repositories
run echo 'deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared any main' | tee /etc/apt/sources.list.d/cloudflared.list
# install cloudflared
run apt-get update && apt-get install cloudflared -y

# 安装系统依赖

RUN pip3 install --no-cache-dir requests webdavclient3

# 确保正确处理内核信号
ENTRYPOINT [ "tini", "--" ]

# 创建应用目录
WORKDIR ${APP_HOME}

# 设置NODE_ENV为production
ENV NODE_ENV=production

# 设置登录凭证环境变量
ENV USERNAME="admin"
ENV PASSWORD="password"

# 克隆官方SillyTavern仓库（最新版本）
RUN git clone https://github.com/SillyTavern/SillyTavern.git .

# 安装依赖
RUN echo "*** 安装npm包 ***" && \
    npm install && npm cache clean --force

# 添加启动脚本和数据同步脚本
COPY launch.sh sync_data.sh ./
RUN chmod +x launch.sh sync_data.sh && \
    dos2unix launch.sh sync_data.sh

# 安装生产依赖
RUN echo "*** 安装生产npm包 ***" && \
    npm i --no-audit --no-fund --loglevel=error --no-progress --omit=dev && npm cache clean --force

# 创建配置目录
RUN mkdir -p "config" || true && \
    rm -f "config.yaml" || true && \
    ln -s "./config/config.yaml" "config.yaml" || true

# 清理不必要的文件
RUN echo "*** 清理 ***" && \
    mv "./docker/docker-entrypoint.sh" "./" && \
    rm -rf "./docker" && \
    echo "*** 使docker-entrypoint.sh可执行 ***" && \
    chmod +x "./docker-entrypoint.sh" && \
    echo "*** 转换行尾为Unix格式 ***" && \
    dos2unix "./docker-entrypoint.sh" || true

# 修改入口脚本，添加自定义启动脚本
RUN sed -i 's/# Start the server/.\/launch.sh/g' docker-entrypoint.sh

# 创建临时备份目录和数据目录
RUN mkdir -p /tmp/sillytavern_backup && \
    mkdir -p ${APP_HOME}/data && \
	mkdir -p ${APP_HOME}/temp

# 设置权限
RUN chmod -R 777 ${APP_HOME} && \
    chmod -R 777 /tmp/sillytavern_backup && \
    chmod -R 777 ${APP_HOME}/temp

# 暴露端口
EXPOSE 8000

# 启动命令
CMD [ "./launch.sh" ] 