#!/bin/bash
add=$(sed -n "/^\S*\.\S*.*{/p" Caddyfile | sed "s? ??g" | sed "s?{.*??g" | sed "s?:.*??g")
alterId=$(sed -n "/\"alterId\".*:/p" config.json | sed "s? ??g" | sed "s?\"id\":??" | sed "s?\"??g" | sed "s?,??g")
[ ! $alterId ] && alterId=0
UUID=$(sed -n "/\"id\".*:/p" config.json | sed "s? ??g" | sed "s?\"id\":??" | sed "s?\"??g" | sed "s?,??g")
url_path=$(sed -n "/\"path\".*:/p" config.json | sed "s? ??g" | sed "s?\"path\":??" | sed "s?\"??g" | sed "s?,??g")

qr_config="{\"v\":\"2\",\"ps\":\"${add}\",\"add\":\"${add}\",\"port\":\"443\",\"id\":\"${UUID}\",\"aid\":\"${alterId}\",\"net\":\"ws\",\"type\":\"none\",\"host\":\"\",\"path\":\"${url_path}\",\"tls\":\"tls\"}"

vmess_link="vmess://$(echo $qr_config | base64 -w 0)"

yum install qrencode -qy >/dev/null 2>&1
qrencode -t utf8 -o - ${vmess_link}
