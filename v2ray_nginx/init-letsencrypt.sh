#!/bin/bash
v2ray_conf="./v2ray/config.json"
nginx_conf="./nginx/conf.d/app.conf"
UUID=$(cat /proc/sys/kernel/random/uuid)
url_path="/${UUID:0:8}"
rsa_key_size=4096
data_path="./certbot"
email="" # Adding a valid address is strongly recommended
staging=1 # Set to 1 if you're testing your setup to avoid hitting request limits

domains=($1)
if [ -z $1 ]; then
read -p "Enter your domain > " domains[0]
echo
fi
if [ $domains[0] == "" ]; then
  echo 'Error: unknow domain.' >&2
  exit 1
fi
if [ -n "$2" ];then url_path=$2;fi
if [ -n "$3" ];then UUID=$3;fi
if [ -n "$4" ];then staging=$4;fi


if ! [ -x "$(command -v docker-compose)" ]; then
  echo 'Error: docker-compose is not installed.' >&2
  exit 1
fi

if [ -d "$data_path" ]; then
  read -p "Existing data found for $domains. Continue and replace existing certificate? (y/N) " decision
  if [ "$decision" != "Y" ] && [ "$decision" != "y" ]; then
    exit
  fi
fi

#down running dockers
if [ -n "$(docker-compose ps -q)" ]; then docker-compose down; fi

# Downloading recommended TLS parameters
if [ ! -e "$data_path/letsencrypt/options-ssl-nginx.conf" ] || [ ! -e "$data_path/letsencrypt/ssl-dhparams.pem" ]; then
  echo "### Downloading recommended TLS parameters ..."
  mkdir -p "$data_path/letsencrypt"
  curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot-nginx/certbot_nginx/_internal/tls_configs/options-ssl-nginx.conf > "$data_path/letsencrypt/options-ssl-nginx.conf"
  curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot/certbot/ssl-dhparams.pem > "$data_path/letsencrypt/ssl-dhparams.pem"
  echo
fi

#Creating dummy certificate and link
echo "### Creating dummy certificate for $domains ..."
pem_path="/etc/letsencrypt/live/$domains"
rm -Rf $data_path/letsencrypt/live
mkdir -p "$data_path/letsencrypt/live/$domains"
docker-compose run --rm --entrypoint "/bin/sh -c ' \
  openssl req -x509 -nodes -newkey rsa:1024 -days 1 \
    -keyout $pem_path/privkey.pem \
    -out $pem_path/fullchain.pem \
    -subj /CN=localhost && \
  ln -s $pem_path/privkey.pem /etc/letsencrypt/live/privkey.pem && \
  ln -s $pem_path/fullchain.pem /etc/letsencrypt/live/fullchain.pem'" certbot >/dev/null

# Start nginx
echo "### Starting nginx ..."
docker-compose run -d --service-ports --entrypoint "nginx -g 'daemon off;'" nginx
echo

# Delete dummy certificate
echo "### Deleting dummy certificate for $domains ..."
docker-compose run --rm --entrypoint "\
  rm -Rf /etc/letsencrypt/live/$domains && \
  rm -Rf /etc/letsencrypt/archive/$domains && \
  rm -Rf /etc/letsencrypt/renewal/$domains.conf" certbot
echo
echo

# Request certificate
echo "### Requesting Let's Encrypt certificate for $domains ..."
#Join $domains to -d args
domain_args=""
for domain in "${domains[@]}"; do
  domain_args="$domain_args -d $domain"
done

# Select appropriate email arg
case "$email" in
  "") email_arg="--register-unsafely-without-email" ;;
  *) email_arg="--email $email" ;;
esac

# Enable staging mode if needed
if [ $staging != "0" ]; then staging_arg="--staging"; fi

docker-compose run --rm --entrypoint "\
  certbot certonly --webroot -w /var/www/certbot \
    $staging_arg \
    $email_arg \
    $domain_args \
    --rsa-key-size $rsa_key_size \
    --agree-tos \
    --force-renewal" certbot
if [ $? != 0 ];then
docker-compose down
echo -e "\033[31m certbot Error \033[0m" >&2
exit 1
fi
echo

echo "### Reloading nginx ..."
#docker-compose exec nginx nginx -s reload
docker-compose down
sed -i "s?\"id\".*\"?\"id\"\: \"${UUID}\"?g" $v2ray_conf
sed -i "s?\"path\".*\"?\"path\"\: \"${url_path}\"?g" $v2ray_conf
sed -i "/#v2ray/{n;s?location \/..* {?location ${url_path} \{?;}" $nginx_conf

docker-compose up -d
echo
echo
#info output
echo '"add"':  $1
echo '"port"': 443
echo '"id"':   ${UUID}
echo '"aid"':  64
echo '"net"':  ws
echo '"type"': none
echo '"path"': ${url_path}
echo '"tls"':  tls
echo 

#qr image output
qr_config=$(cat<<-EOF
{
"v": "2",
"ps": "",
"add": "$1",
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
vmess_link="vmess://$(echo $qr_config | base64 -w 0)"
echo
echo
echo Generating QR image
docker run --rm centos \
/bin/sh -c "yum install qrencode -qy >/dev/null 2>&1 && qrencode -t utf8 -o - ${vmess_link}"