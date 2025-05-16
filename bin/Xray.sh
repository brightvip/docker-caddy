#!/bin/bash

#根目录
path='/usr/app/lib/Xray/bin/'



conf(){
 mkdir -p /usr/app/lib/Xray/
 
cat << EOF >/usr/app/lib/Xray/XrayConfig.json.template
{
  "log": {
    "access": "none",
    "error": "none",
    "loglevel": "none"
  },
  "inbounds": [
    {
      "port": wsport,
      "listen": "wslisten",
      "protocol": "wsprotocol",
      "settings": {
        "clients": [
          {
            "id": "wsCLIENTSID",
            "level": 0
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "ws",
        "security": "none",
        "wsSettings": {
          "path": "WSPATH",
          "maxEarlyData": 1024,
          "earlyDataHeaderName": "Sec-WebSocket-Protocol",
          "acceptProxyProtocol": false
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom"
    }
  ]
}
EOF

 sync

cat << EOF >/usr/app/lib/Xray/Xrayl.caddy.template
	handle WSPATH {
    		@websocket {
    			header Connection Upgrade
    			header Upgrade websocket
    		}
    		reverse_proxy @websocket wslisten:wsport
	}
EOF

 sync

 sed -e 's/wsport/9303/'  -e 's/wsprotocol/vless/' -e 's/wslisten/127.0.0.1/' -e 's:wsCLIENTSID:'"${CLIENTSID}"':'  -e 's:WSPATH:'"${PREFIX_PATH}/wsl/"':' /usr/app/lib/Xray/XrayConfig.json.template > /usr/app/lib/Xray/Xrayl.json

 sync

 sed -e 's/wsport/9303/' -e 's/wslisten/127.0.0.1/'  -e 's:WSPATH:'"${PREFIX_PATH}/wsl/*"':' /usr/app/lib/Xray/Xrayl.caddy.template > /usr/app/lib/Xray/Xrayl.caddy

 sync

 sed -i '32 r /usr/app/lib/Xray/Xrayl.caddy' /etc/caddy/Caddyfile

 sync

}
conf

#获取最新版本
get_latest_version(){
 latest_version=`curl -X HEAD -I --user-agent "Mozilla/5.0 (Macintosh; Intel Mac OS X x.y; rv:42.0) Gecko/20100101 Firefox/42.0" 'https://github.com/XTLS/Xray-core/releases/latest' -s  | grep  'location: ' | awk -F "/" '{print $NF}'  | tr '\r' ' ' | awk '{print $1}'`
}

#运行程序
start(){
    #获取最新版本
    get_latest_version
    #判断文件夹是否存在
    if [ -n "$latest_version" ] && [ ! -d $path$latest_version ]; then
        #下载地址
        download="https://github.com/XTLS/Xray-core/releases/download/";
        file="/Xray-linux-64.zip";
        echo $download$latest_version$file
        
        #文件夹不存在
        mkdir -p $path$latest_version
        #下载文件
        curl --retry 10 --retry-max-time 60 -H "Cache-Control: no-cache" -fsSL $download$latest_version$file -o $path$latest_version/Xray-linux-64.zip
        unzip -q $path$latest_version/Xray-linux-64.zip -d $path$latest_version/
            #循环删除其他版本
            for vfile in ` ls $path | grep -v $latest_version`
            do
                
                vfilepid=`ps -ef |grep $vfile | grep -v 'grep'  | awk '{print $1}' | tr "\n" " "`
                if [ ! -z "$vfilepid" ]; then  
                    echo $vfilepid
                    kill -9 $vfilepid
                fi 
                rm -fr $path$vfile
            
            done

        nohup $path$latest_version/xray run -c /usr/app/lib/Xray/Xrayl.json  >/usr/share/caddy/Xrayl.html 2>&1 &

        echo `date`"-"$latest_version > /usr/share/caddy/v2rayversion.html
    fi
}
start


#由于不支持crontab 改用 while
#由于容器长时间无连接会被销毁 有新连接时会被创建
#基本不会通过while进行更新会在每次容器创建时更新
while true
do
    sleep 1d
    echo start
    start
    
done
