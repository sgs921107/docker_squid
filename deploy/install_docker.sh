#!/bin/bash
#########################################################################
# File Name: deploy.sh
# Author: 
# mail: 
# Created Time: Thu 19 Sep 2019 04:10:20 PM CST
#########################################################################

# 移除旧版本docker
# yum remove docker  docker-common docker-selinux docker-engine

# 判断docker是否已安装
if ! which docker;
then
    echo "未安装docker服务, 即将进行安装"
    # 更新yum
    yum update -y
    
    # 安装依赖
    yum install -y yum-utils device-mapper-persistent-data lvm2
    # 添加docker源 
    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    # 安装docker
    yum install -y docker-ce
    # 安装命令补全
    yum install -y bash-completion
    echo "docker安装完成"
fi

# 启动docker配置开机自启
systemctl start docker
systemctl enable docker

# 判断docker-compose是否已安装
if ! which docker-compose;
then
    echo "未安装docker-compose, 即将进行安装"
    # 安装docker-compose
    # 下载docker-compose
    curl -L "https://get.daocloud.io/docker/compose/releases/download/1.29.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose \
        || { echo "安装docker-compose失败: 下载失败"; exit 1; }
    # 添加可执行权限
    chmod +x /usr/local/bin/docker-compose
    # 创建软连接
    ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
    echo "docker-compose安装完成"
fi
