#!/bin/bash
set -o errexit
v2ray_conf="./config.json"
UUID=$(cat /proc/sys/kernel/random/uuid)
url_path="/${UUID:0:8}"
email=""
domains=($1)

export V2RAY_HOST="${domains[0]}"
export LETSENCRYPT_EMAIL="${email}"

function checkInput()
{
    if [ -z $1 ]; then
    read -p "Enter your domain > " domains[0]
    echo
    export V2RAY_HOST="${domains[0]}"
    fi
    if [ "${domains[0]}" == "" ]; then
    echo 'Error: unknow domain.' >&2
    exit 1
    fi
    if [ -n "$2" ];then url_path=$2;fi
    if [ -n "$3" ];then UUID=$3;fi
}

function checkDocker()
{
    if ! [ -x "$(command -v docker-compose)" ]; then
    echo 'Error: docker-compose is not installed.' >&2
    exit 1
    fi

    if ! [ -x "$(command -v docker)" ]; then
    echo 'Error: docker is not installed.' >&2
    exit 1
    fi

    rm -rf .env
}

function downContainers()
{
    #down running dockers
    if [ -n "$(docker-compose ps -q)" ]; then 
    docker-compose down --volumes; 
    fi
}

function editConfigile()
{
    sed -i "s?\"id\".*\"?\"id\"\: \"${UUID}\"?g" $v2ray_conf
    sed -i "s?\"path\".*\"?\"path\"\: \"${url_path}\"?g" $v2ray_conf
}

function dockerUp()
{
    docker-compose pull
    echo
    #docker-compose up -d
    docker-compose up -d v2ray
    sleep 1
    docker-compose up -d nginx-proxy
    sleep 2
    docker-compose up -d letsencrypt
}

function linkFile()
{
    rm -rf /etc/nginx/
    mkdir -p /etc/nginx/
    rm -rf /usr/share/nginx/
    mkdir -p /usr/share/nginx/

    ln -s /var/lib/docker/volumes/docker-v2ray-tls_conf/_data /etc/nginx/conf.d
    ln -s /var/lib/docker/volumes/docker-v2ray-tls_vhost/_data /etc/nginx/vhost.d
    ln -s /var/lib/docker/volumes/docker-v2ray-tls_html/_data /usr/share/nginx/html
    ln -s /var/lib/docker/volumes/docker-v2ray-tls_dhparam/_data /etc/nginx/dhparam
    ln -s /var/lib/docker/volumes/docker-v2ray-tls_certs/_data /etc/nginx/certs

    sleep 10 && touch /etc/nginx/vhost.d/${V2RAY_HOST} &
}

function qrcode()
{
    #qr image output
    qr_config=$(cat<<-EOF
{
"v": "2",
"ps": "",
"add": "$V2RAY_HOST",
"port": "443",
"id": "${UUID}",
"aid": "64",
"net": "ws",
"type": "none",
"host": "",
"path": "${url_path}",
"tls": "tls"
}
EOF
)

    export VMESS_LINK="vmess://$(echo $qr_config | base64 -w 0)"
    echo Generating QR image
    echo

    #info output
    echo '"add"':  ${V2RAY_HOST}
    echo '"port"': 443
    echo '"id"':   ${UUID}
    echo '"aid"':  64
    echo '"net"':  ws
    echo '"type"': none
    echo '"path"': ${url_path}
    echo '"tls"':  tls
    echo
    echo "$VMESS_LINK"
    echo
    sleep 1
    #docker run --rm bxggs/qrencode -t utf8 -o - ${VMESS_LINK}
    docker-compose up qrencode
    #docker-compose logs qrencode
}

function writeEnv()
{
    echo V2RAY_HOST=${V2RAY_HOST} > .env
    echo LETSENCRYPT_EMAIL=${LETSENCRYPT_EMAIL} >> .env
    echo VMESS_LINK=${VMESS_LINK} >> .env
}


checkInput $@
checkDocker

downContainers

echo
editConfigile

dockerUp
linkFile

echo
qrcode

echo
writeEnv