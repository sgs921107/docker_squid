#########################################################################
# File Name: deploy.sh
# Author: qiezi
# mail: qiezi@gmail.com
# Created Time: Wed 19 Feb 2020 12:29:13 PM CST
#########################################################################
#!/bin/bash


conf_dir=/etc/squid
source $conf_dir/.env


# 声明变量
install_docker_script=./install_docker.sh
squid_conf=$conf_dir/squid.conf
squid_users=$conf_dir/ncsa_users

# 生成用户认证信息
encrypt_ret=`curl -XPOST -L -H "referer:https://tool.lu/htpasswd/" https://tool.lu/htpasswd/ajax.html -d "username=$squid_username&password=$squid_password&type=md5"`
encrypt_content=`echo $encrypt_ret | grep true | awk -F ': ?"' '{print $2}' | awk -F '"}' '{print $1}'`
if [ -z "$encrypt_content" ]
then
    echo "添加认证用户信息失败,请检查网络后重新部署"
    exit
fi
echo $encrypt_content > $squid_users

# 检查/安装docker和docker-compose
sh $install_docker_script

echo "SQUID_VERSION=$SQUID_VERSION
REAL_SQUID_PORT=$REAL_SQUID_PORT

SQUID_CONF=$squid_conf
SQUID_USERS=$squid_users
SQUID_LOG_DIR=$SQUID_LOG_DIR
" > .env

echo "http_port 3128

# auth
auth_param basic program /usr/lib/squid/basic_ncsa_auth /etc/squid/ncsa_users
auth_param basic realm proxy # 认证提示
auth_param basic realm Squid proxy-caching web server # 认证提示的内容
auth_param basic children $squid_children # 认证进程
auth_param basic credentialsttl 2 hours # 认证有效期
auth_param basic casesensitive off # 用户名不区分大小写

acl manager proto cache_object
# acl all src all
acl localnet src 10.0.0.0/8     # RFC1918 possible internal network
acl localnet src 172.16.0.0/12  # RFC1918 possible internal network
acl localnet src 192.168.0.0/16 # RFC1918 possible internal network
acl localnet src fc00::/7
acl localnet src fe80::/10
acl ncsa_users proxy_auth REQUIRED
acl SSL_ports port 443
acl Safe_ports port 80 8080
acl Safe_ports port 21
acl Safe_ports port 443
acl CONNECT method CONNECT

acl OverConnLimit maxconn $squid_maxconn
http_access deny OverConnLimit

http_access allow manager localhost
http_access deny manager
http_access deny !Safe_ports
http_access deny CONNECT !SSL_ports
http_access allow localnet
http_access allow localhost
http_access allow ncsa_users
http_access deny all

# 配置高匿名
request_header_access Via deny all
request_header_access X-Forwarded-For deny all

cache_dir aufs /var/spool/squid 128 16 256
coredump_dir /var/spool/squid
cache_mem 128 MB
refresh_pattern ^ftp:           1440    20%     10080
refresh_pattern ^gopher:        1440    0%      1440
refresh_pattern -i (/cgi-bin/|\?) 0     0%      0
refresh_pattern \.(jpg|png|gif|mp3|xml) 1440    50%     2880    ignore-reload
refresh_pattern .               0       20%     4320" > $squid_conf

# 启动服务
docker-compose up -d
firewall-cmd --permanent --add-port=$REAL_SQUID_PORT/tcp

# 重新加载防火墙
firewall-cmd --reload
