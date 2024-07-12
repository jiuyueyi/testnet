#!/bin/bash

echo "
████████╗███████╗███████╗████████╗███╗   ██╗███████╗████████╗
╚══██╔══╝██╔════╝██╔════╝╚══██╔══╝████╗  ██║██╔════╝╚══██╔══╝
   ██║   █████╗  ███████╗   ██║   ██╔██╗ ██║█████╗     ██║
   ██║   ██╔══╝  ╚════██║   ██║   ██║╚██╗██║██╔══╝     ██║
   ██║   ███████╗███████║   ██║   ██║ ╚████║███████╗   ██║
   ╚═╝   ╚══════╝╚══════╝   ╚═╝   ╚═╝  ╚═══╝╚══════╝   ╚═╝
"

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

confirm() {
    echo -e -n "\033[36m[TestNet] $* \033[1;36m(Y/n)\033[0m"
    read -n 1 -s opt

    [[ "$opt" == $'\n' ]] || echo

    case "$opt" in
        'y' | 'Y' ) return 0;;
        'n' | 'N' ) return 1;;
        *) confirm "$1";;
    esac
}

info() {
    echo -e "\033[37m[TestNet] $*\033[0m"
}

warning() {
    echo -e "\033[33m[TestNet] $*\033[0m"
}

abort() {
    echo -e "\033[31m[TestNet] $*\033[0m"
    exit 1
}

trap 'onexit' INT
onexit() {
    echo
    abort "用户手动结束操作"
}

testnet_path='/data/testnet'

if [ -z "$BASH" ]; then
    abort "请用 bash 执行本脚本"
fi

if [ ! -t 0 ]; then
    abort "STDIN 不是标准的输入设备"
fi

if [ "$#" -ne 0 ]; then
    abort "当前脚本无需任何参数"
fi

info "脚本调用方式确认正常"

if ! command_exists docker; then
    warning "缺少 Docker 环境"
    if confirm "是否需要自动安装 Docker"; then
        if ! curl -sSLk https://get.docker.com/ | bash -s -- --mirror; then
            abort "Docker 安装失败，请检查网络连接或尝试手动安装"
        fi
        info "Docker 安装完成"
    else
        abort "中止安装"
    fi
fi

info "发现 Docker 环境: '$(command -v docker)'"

docker version > /dev/null 2>&1
if [ $? -ne 0 ]; then
    abort "Docker 服务工作异常"
fi
info "Docker 工作状态正常"

compose_command="docker compose"
if $compose_command version > /dev/null 2>&1; then
    info "发现 Docker Compose Plugin"
else
    warning "未发现 Docker Compose Plugin"
    compose_command="docker-compose"
    if ! command_exists "docker-compose"; then
        warning "未发现 docker-compose 组件"
        if confirm "是否需要自动安装 Docker Compose Plugin"; then
            curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
            chmod +x /usr/local/bin/docker-compose
            if [ $? -ne 0 ]; then
                abort "Docker Compose Plugin 安装失败"
            fi
            info "Docker Compose Plugin 安装完成"
            compose_command="docker compose"
        else
            abort "中止安装"
        fi
    else
        info "发现 docker-compose 组件: '$(command -v docker-compose)'"
    fi
fi

create_env_file() {
    if [ -f ".env" ]; then
        info ".env 文件已存在"
    else
        touch ".env"
        if [ $? -ne 0 ]; then
            warning "创建 .env 文件失败"
        else
            echo "创建 .env 文件成功"
            echo "REDIS_PASSWORD=$(LC_ALL=C tr -dc A-Za-z0-9 </dev/urandom | head -c 32)" >> .env
            echo "MYSQL_PASSWORD=$(LC_ALL=C tr -dc A-Za-z0-9 </dev/urandom | head -c 32)" >> .env
            echo "SUBNET_PREFIX=172.16.1" >> .env
        fi
    fi
}

create_es_data_folder() {
    if [ -d "./es_data" ]; then
        info "文件夹已存在"
    else
        mkdir "./es_data"
        if [ $? -ne 0 ]; then
            warning "创建 ./es_data 文件夹失败"
        else
            chmod 777 ./es_data
            if [ $? -ne 0 ]; then
                warning "设置 ./es_data 文件夹权限失败"
            else
                info "成功创建并设置 ./es_data 文件夹"
            fi
        fi
    fi
}

start_testnet() {
    $compose_command up -d
    warning "TestNet安装成功，请稍等2分钟打开后台登录..."
    warning "后台访问地址：https://IP:8099/"
}

stop_testnet() {
    $compose_command stop
    info "TestNet 已停止运行"
}

update_testnet_server() {
    info "开始更新 TestNet 服务端..."
    git pull
    $compose_command stop testnet-server testnet-frontend
    $compose_command rm -f testnet-server testnet-frontend
    $compose_command pull testnet-server testnet-frontend
    $compose_command up -d testnet-server testnet-frontend
    info "TestNet 服务端更新完成"
}

update_testnet_client() {
    info "开始更新 TestNet客户端..."
    if confirm "是否需要更新客户端？已安装工具需要重新安装"; then
        $compose_command stop testnet-client
        $compose_command pull testnet-client
        $compose_command up -d testnet-client
    else
        abort "取消安装运行环境"
    fi
    info "TestNet 客户端更新完成"
}

local_ips() {
    if command_exists ip; then
        ip addr show | grep -Eo 'inet ([0-9]*\.){3}[0-9]*' | awk '{print $2}'
    else
        ifconfig -a | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | awk '{print $2}'
    fi
}

ips=$(local_ips)

start_testnet_server() {
    $compose_command -f docker-compose-server.yml up -d
    warning "TestNet安装成功，请稍等2分钟打开后台登录..."
    warning "后台访问地址：https://0.0.0.0:8099/"
    for ip in $ips; do
        warning https://$ip:8099/
    done
}

start_testnet_client() {
    if [ -f ".env" ]; then
        $compose_command -f docker-compose-client.yml up -d
    else
        warning "请先复制服务端配置文件到客户端，增加一个IP=你的IP地址"
    fi
}

install_run_environment() {
    if confirm "是否需要自动安装客户端运行环境"; then
        docker exec testnet-client /bin/bash -c "cd /testnet-client && chmod +x ./start.sh && ./start.sh"
    else
        abort "取消安装运行环境"
    fi
}

echo "请选择操作："
echo "1) 一键安装 TestNet服务端 + 客户端 (testnet-server testnet-frontend testnet-client)"
echo "2) 单独安装 TestNet服务端 (testnet-server testnet-frontend)"
echo "3) 单独安装 TestNet客户端(testnet-client)"
echo "4) 更新服务端 (testnet-server testnet-frontend)"
echo "5) 更新客户端 (testnet-client)"
echo "6) 安装客户端运行环境"
read -p "输入数字选择操作: " user_choice

case $user_choice in
    1)
        create_env_file
        create_es_data_folder
        start_testnet
        install_run_environment
        ;;
    2)
        create_env_file
        create_es_data_folder
        start_testnet_server
        ;;
    3)
        start_testnet_client
        install_run_environment
        ;;
    4)
        update_testnet_server
        ;;
    5)
        update_testnet_client
        install_run_environment
        ;;
    6)
        install_run_environment
        ;;
    *)
        abort "无效选择，退出脚本"
        ;;
esac
