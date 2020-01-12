# docker-v2ray-tls
使用Docker 部署v2ray WebSocket + TLS + Web + certbot自动续签
Docker deploy v2ray-tls in 1 line

1 除了docker和docker-compose之外无需安装其他软件
2 避免对vps的其他服务造成干扰（需要占用80、443端口）
3 使用了最新的官方容器

##首先安装环境 Install environment
#####Centos 7：
```shell
yum install docker docker-compose git -y
systemctl enable docker
systemctl start docker
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https

git clone https://github.com/unclemikael/docker-v2ray-tls.git
cd docker-v2ray-tls/
```

------------


#####Centos 8:
```shell
yum install git yum-utils  -y
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install docker-ce --nobest -y
pip3 install docker-compose
systemctl enable --now docker
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --reload

git clone https://github.com/unclemikael/docker-v2ray-tls.git
cd docker-v2ray-tls/
```
#####Tips： firewalld 有时会不明原因只开启ipv6的端口，导致ipv4无法连接。我现在还搞不清楚。
把 /etc/firewalld/firewalld.conf 中的
FirewallBackend=nftables
改成&darr;
FirewallBackend=iptables
```shell
#使用firewall-cmd --reload会导致centos8丢失连接
#Don't use firewall-cmd --reload
systemctl restart firewalld
```

------------

------------


##nginx:
```shell
cd v2ray_nginx/
chmod u+x init-letsencrypt.sh
```

####执行初始化文件 Run init-letsencrypt.sh
```shell
#init-letsencrypt.sh 后面加上你的域名 如：
./init-letsencrypt.sh example.org
```
也可以
```shell
#init-letsencrypt.sh 域名 路径 UUID 如：
./init-letsencrypt.sh example.org /ray 11485c51-b1d4-2a7c-9dcf-c09a6550f417
```
####检查是否为up状态 Check status
```shell
docker-compose ps -a
```
#####如果失败执行
```shell
docker-compose down
```

------------

------------

##caddy

####切换到 v2ray_caddy 目录
```shell
cd v2ray_caddy/
chmod u+x qr_generate.sh
```
####在 caddy.conf 文件中修改成你的域名
```shell
vi caddy.conf
```
####最后在 v2ray_caddy 目录下执行
```shell
docker-compose up -d
```
####检查是否为up状态 Check status
```shell
docker-compose ps -a
```
#####如果失败执行
```shell
docker-compose down
```
####扫描二维码
```shell
docker-compose logs qr_generator
```