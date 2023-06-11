# docker-v2ray-tls

快速优雅 部署v2ray WebSocket + TLS 自动续签

基于[nginx-proxy](https://github.com/nginx-proxy/docker-letsencrypt-nginx-proxy-companion)修改

一行代码能做的事

+ [nginx-proxy](https://github.com/nginx-proxy/docker-letsencrypt-nginx-proxy-companion)管理证书
+ 随机UUID
+ 随机path(路径)
+ 生成二维码
+ 方便挂载其他网站、域名

## 使用方法（直接复制）

### 一. 安装docker和docker-compose，或选择装好Docker的主机

```shell
#docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
#start docker
systemctl enable docker
systemctl start docker
```

```shell
#docker-compose
sudo curl -fsSL \
"https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
-o $HOME/.docker/cli-plugins/docker-compose
sudo chmod +x $HOME/.docker/cli-plugins/docker-compose
```

> Centos8 会安装失败，解决办法自行Google

### 二.下载文件

#### **方法1**

> Curl

```shell
mkdir docker-v2ray-tls && cd docker-v2ray-tls

curl -fsSL \
https://raw.githubusercontent.com/unclemikael/docker-v2ray-tls/master/install.sh \
-o install.sh

curl -fsSL \
https://raw.githubusercontent.com/unclemikael/docker-v2ray-tls/master/docker-compose.yml \
-o docker-compose.yml

curl -fsSL \
https://raw.githubusercontent.com/unclemikael/docker-v2ray-tls/master/config.json \
-o config.json

sudo chmod u+x install.sh

```

#### **方法2**

> Git clone

```shell
git clone https://github.com/unclemikael/docker-v2ray-tls.git
cd docker-v2ray-tls
sudo chmod u+x install.sh

```

### 三. 输入自己的域名（*）

```shell
./install.sh example.org
```

---
> Tips：自定义路径、UUID

```shell
./install.sh example.org /v2ray 8b8b1829-17c7-4e80-ad78-84160f04f363
```

## 注意事项

+ 需要占用80、443端口
+ 关闭防火墙或开启80，443端口
+ 确保dns已经正确解析
+ 默认处于```LETSENCRYPT_TEST=true```测试证书模式，会提示不安全，不影响使用
+ 可到```docker-compose.yml```修改成```LETSENCRYPT_TEST=false```正式证书

## 已测试系统

+ Centos 7 （ipv6有问题）
+ Debian 10 （√）
+ Ubuntu 20.10 （√）
