#########################################################################
# File Name: deploy.sh
# Author: 
# mail: 
# Created Time: Thu 19 Sep 2019 04:10:20 PM CST
#########################################################################
#!/bin/bash


<<!
判断服务是否已安装
参数    是否必须
服务名  是
返回值  1/0(是否存在)
!
function is_exist(){
    ret=`$1 --version`
    echo $ret
    if [ -n "$ret" ]
    then
        return 1
    else
        return 0
    fi
}
                                        

# 移除旧版本docker
# yum remove docker  docker-common docker-selinux docker-engine

# 判断docker是否已安装
is_exist docker
if [ $? = 0 ]
then
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
fi

# 启动docker配置开机自启
systemctl start docker
systemctl enable docker

# 判断docker-compose是否已安装
is_exist docker-compose
if [ $? = 0 ]
then
    # 安装docker-compose
    yum -y install epel-release
    yum -y install python-pip
    yum -y install python-devel
    yum -y groupinstall 'Development Tools'
    
    yum clean all && rm -rf /var/cache/yum/* && rm -rf /tmp/*
    # 安装docker-compose  
    pip install --no-cache-dir docker-compose 
fi


