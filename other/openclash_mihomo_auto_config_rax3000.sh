#!/bin/bash


update(){
 /usr/share/openclash/openclash_ipdb.sh
 /usr/share/openclash/openclash_geosite.sh
 /usr/share/openclash/openclash_geoip.sh
 /usr/share/openclash/openclash_chnroute.sh
 /bin/opkg update && /bin/opkg upgrade tar `/bin/opkg list-upgradable | /usr/bin/awk '{print $1}'| /usr/bin/awk BEGIN{RS=EOF}'{gsub(/\n/," ");print}'` --force-overwrite
}

path=$(dirname $(readlink -f $0))


install_mihomo(){
 latest_version_mihomo=`curl --retry 10 --retry-max-time 360 -X HEAD -I --user-agent "Mozilla/5.0 (Macintosh; Intel Mac OS X x.y; rv:42.0) Gecko/20100101 Firefox/42.0" 'https://github.com/MetaCubeX/mihomo/releases/latest' -s  | grep  'location: ' | awk -F "/" '{print $NF}'  | tr '\r' ' ' | awk '{print $1}'`
 if [ -n "$latest_version_mihomo" ] && [ ! -d $path/mihomo$latest_version_mihomo ]; then
    rm -fr $path/mihomo*
    echo "download $path/mihomo$latest_version_mihomo"
    mkdir -p $path/mihomo$latest_version_mihomo
    curl --retry 10 --retry-max-time 360 -H "Cache-Control: no-cache" -fsSL https://github.com/MetaCubeX/mihomo/releases/download/$latest_version_mihomo/mihomo-linux-arm64-$latest_version_mihomo.gz -o $path/mihomo$latest_version_mihomo/mihomo-linux-arm64.gz
    gzip -d $path/mihomo$latest_version_mihomo/mihomo-linux-arm64.gz
    mv $path/mihomo$latest_version_mihomo/mihomo-linux-arm64 /etc/openclash/core/mihomo-linux-arm64
    chmod +x /etc/openclash/core/mihomo-linux-arm64
    chown nobody /etc/openclash/core/mihomo-linux-arm64
    if ! [ -L /etc/openclash/core/clash_meta ] ; then
       ln -s /etc/openclash/core/mihomo-linux-arm64 /etc/openclash/core/clash_meta
    fi
 fi
}

init_mihomo_config(){
    read -r -d '' mihomo_config_begin <<- 'EOF'
# port: 7890 # HTTP(S) 代理服务器端口
# socks-port: 7891 # SOCKS5 代理端口
mixed-port: 10801 # HTTP(S) 和 SOCKS 代理混合端口
redir-port: 7892 # 透明代理端口，用于 Linux 和 MacOS

# Transparent proxy server port for Linux (TProxy TCP and TProxy UDP)
tproxy-port: 7893

allow-lan: true # 允许局域网连接
bind-address: "*" # 绑定 IP 地址，仅作用于 allow-lan 为 true，'*'表示所有地址
authentication: # http,socks入口的验证用户名，密码
  - "username:password"
skip-auth-prefixes: # 设置跳过验证的IP段
  - 127.0.0.1/8
  - ::1/128
lan-allowed-ips: # 允许连接的 IP 地址段，仅作用于 allow-lan 为 true, 默认值为 0.0.0.0/0 和::/0
  - 0.0.0.0/0
  - ::/0
lan-disallowed-ips: # 禁止连接的 IP 地址段，黑名单优先级高于白名单，默认值为空

#  find-process-mode has 3 values:always, strict, off
#  - always, 开启，强制匹配所有进程
#  - strict, 默认，由 mihomo 判断是否开启
#  - off, 不匹配进程，推荐在路由器上使用此模式
find-process-mode: strict

mode: rule

#自定义 geodata url
#  geox-url:
#    geoip: "https://fastly.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@release/geoip.dat"
#    geosite: "https://fastly.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@release/geosite.dat"
#    mmdb: "https://fastly.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@release/geoip.metadb"

geo-auto-update: false # 是否自动更新 geodata
#  geo-update-interval: 24 # 更新间隔，单位：小时

# Matcher implementation used by GeoSite, available implementations:
# - succinct (default, same as rule-set)
# - mph (from V2Ray, also `hybrid` in Xray)
geosite-matcher: succinct

log-level: error # 日志等级 silent/error/warning/info/debug

ipv6: true # 开启 IPv6 总开关，关闭阻断所有 IPv6 链接和屏蔽 DNS 请求 AAAA 记录

#tls:
#  certificate: string # 证书 PEM 格式，或者 证书的路径
#  private-key: string # 证书对应的私钥 PEM 格式，或者私钥路径
#  custom-certifactes:
#    - |
#      -----BEGIN CERTIFICATE-----
#      format/pem...
#      -----END CERTIFICATE-----

external-controller: 0.0.0.0:9093 # RESTful API 监听地址
#external-controller-tls: 0.0.0.0:9443 # RESTful API HTTPS 监听地址，需要配置 tls 部分配置文件
# secret: "123456" # `Authorization:Bearer ${secret}`

# RESTful API CORS标头配置
#external-controller-cors:
#  allow-origins:
#    - *
#  allow-private-network: true

# RESTful API Unix socket 监听地址（ windows版本大于17063也可以使用，即大于等于1803/RS4版本即可使用 ）
# ！！！注意： 从Unix socket访问api接口不会验证secret， 如果开启请自行保证安全问题 ！！！
# 测试方法： curl -v --unix-socket "mihomo.sock" http://localhost/
# external-controller-unix: mihomo.sock

# RESTful API Windows namedpipe 监听地址
# ！！！注意： 从Windows namedpipe访问api接口不会验证secret， 如果开启请自行保证安全问题 ！！！
# external-controller-pipe: \\.\pipe\mihomo

# tcp-concurrent: true # TCP 并发连接所有 IP, 将使用最快握手的 TCP

# 配置 WEB UI 目录，使用 http://{{external-controller}}/ui 访问
#  external-ui: /path/to/ui/folder/
#  external-ui-name: xd
#  external-ui-url: "https://github.com/MetaCubeX/metacubexd/archive/refs/heads/gh-pages.zip"

# 在RESTful API端口上开启DOH服务器
# ！！！该URL不会验证secret， 如果开启请自行保证安全问题 ！！！
#external-doh-server: /dns-query

# interface-name: en0 # 设置出口网卡

# 全局 TLS 指纹，优先低于 proxy 内的 client-fingerprint
# 可选： "chrome","firefox","safari","ios","random","none" options.
# Utls is currently support TLS transport in TCP/grpc/WS/HTTP for VLESS/Vmess and trojan.
global-client-fingerprint: chrome

#  TCP keep alive interval
disable-keep-alive: false #目前在android端强制为true
#keep-alive-idle: 15
#keep-alive-interval: 15

# routing-mark:6666 # 配置 fwmark 仅用于 Linux
experimental:
  # Disable quic-go GSO support. This may result in reduced performance on Linux.
  # This is not recommended for most users.
  # Only users encountering issues with quic-go's internal implementation should enable this,
  # and they should disable it as soon as the issue is resolved.
  # This field will be removed when quic-go fixes all their issues in GSO.
  # This equivalent to the environment variable QUIC_GO_DISABLE_GSO=1.
  #quic-go-disable-gso: true

# 类似于 /etc/hosts, 仅支持配置单个 IP
hosts:

EOF

    read -r -d '' mihomo_config_hosts <<- 'EOF'
# '*.mihomo.dev': 127.0.0.1
# '.dev': 127.0.0.1
# 'alpha.mihomo.dev': '::1'
# test.com: [1.1.1.1, 2.2.2.2]
# home.lan: lan # lan 为特别字段，将加入本地所有网卡的地址
# baidu.com: google.com # 只允许配置一个别名

profile: # 存储 select 选择记录
  store-selected: false

  # 持久化 fake-ip
  store-fake-ip: false

# Tun 配置
tun:
  enable: false
  stack: system # gvisor/mixed
  dns-hijack:
    - 0.0.0.0:53 # 需要劫持的 DNS
  # auto-detect-interface: true # 自动识别出口网卡
  # auto-route: true # 配置路由表
  # mtu: 9000 # 最大传输单元
  # gso: false # 启用通用分段卸载，仅支持 Linux
  # gso-max-size: 65536 # 通用分段卸载包的最大大小
  auto-redirect: false # 自动配置 iptables 以重定向 TCP 连接。仅支持 Linux。带有 auto-redirect 的 auto-route 现在可以在路由器上按预期工作，无需干预。
  # strict-route: true # 将所有连接路由到 tun 来防止泄漏，但你的设备将无法其他设备被访问
  # disable-icmp-forwarding: true # 禁用 ICMP 转发，防止某些情况下的 ICMP 环回问题，ping 将不会显示真实的延迟
  route-address-set: # 将指定规则集中的目标 IP CIDR 规则添加到防火墙, 不匹配的流量将绕过路由, 仅支持 Linux，且需要 nftables，`auto-route` 和 `auto-redirect` 已启用。
    - ruleset-1
    - ruleset-2
  route-exclude-address-set: # 将指定规则集中的目标 IP CIDR 规则添加到防火墙, 匹配的流量将绕过路由, 仅支持 Linux，且需要 nftables，`auto-route` 和 `auto-redirect` 已启用。
    - ruleset-3
    - ruleset-4
  route-address: # 启用 auto-route 时使用自定义路由而不是默认路由
    - 0.0.0.0/1
    - 128.0.0.0/1
    - "::/1"
    - "8000::/1"
  # inet4-route-address: # 启用 auto-route 时使用自定义路由而不是默认路由（旧写法）
  #   - 0.0.0.0/1
  #   - 128.0.0.0/1
  # inet6-route-address: # 启用 auto-route 时使用自定义路由而不是默认路由（旧写法）
  #   - "::/1"
  #   - "8000::/1"
  # endpoint-independent-nat: false # 启用独立于端点的 NAT
  # include-interface: # 限制被路由的接口。默认不限制，与 `exclude-interface` 冲突
  #   - "lan0"
  # exclude-interface: # 排除路由的接口，与 `include-interface` 冲突
  #   - "lan1"
  # include-uid: # UID 规则仅在 Linux 下被支持，并且需要 auto-route
  # - 0
  # include-uid-range: # 限制被路由的的用户范围
  # - 1000:9999
  # exclude-uid: # 排除路由的的用户
  #- 1000
  # exclude-uid-range: # 排除路由的的用户范围
  # - 1000:9999

  # Android 用户和应用规则仅在 Android 下被支持
  # 并且需要 auto-route

  # include-android-user: # 限制被路由的 Android 用户
  # - 0
  # - 10
  # include-package: # 限制被路由的 Android 应用包名
  # - com.android.chrome
  # exclude-package: # 排除被路由的 Android 应用包名
  # - com.android.captiveportallogin


# 嗅探域名 可选配置
sniffer:
  enable: false
  ## 对 redir-host 类型识别的流量进行强制嗅探
  ## 如：Tun、Redir 和 TProxy 并 DNS 为 redir-host 皆属于
  # force-dns-mapping: false
  ## 对所有未获取到域名的流量进行强制嗅探
  # parse-pure-ip: false
  # 是否使用嗅探结果作为实际访问，默认 true
  # 全局配置，优先级低于 sniffer.sniff 实际配置
  override-destination: false
  sniff: # TLS 和 QUIC 默认如果不配置 ports 默认嗅探 443
    QUIC:
    #  ports: [ 443 ]
    TLS:
    #  ports: [443, 8443]

    # 默认嗅探 80
    HTTP: # 需要嗅探的端口
      ports: [80, 8080-8880]
      # 可覆盖 sniffer.override-destination
      override-destination: true
  force-domain:
    - +.v2ex.com
  # skip-src-address: # 对于来源ip跳过嗅探
  #   - 192.168.0.3/32
  # skip-dst-address: # 对于目标ip跳过嗅探
  #   - 192.168.0.3/32
  ## 对嗅探结果进行跳过
  # skip-domain:
  #   - Mijia Cloud
  # 需要嗅探协议
  # 已废弃，若 sniffer.sniff 配置则此项无效
  sniffing:
    - tls
    - http
  # 强制对此域名进行嗅探

  # 仅对白名单中的端口进行嗅探，默认为 443，80
  # 已废弃，若 sniffer.sniff 配置则此项无效
  port-whitelist:
    - "80"
    - "443"
    # - 8000-9999

#tunnels: # one line config
  #- tcp/udp,127.0.0.1:6553,114.114.114.114:53,proxy
  #- tcp,127.0.0.1:6666,rds.mysql.com:3306,vpn
  # full yaml config
  #- network: [tcp, udp]
  #  address: 127.0.0.1:7777
  #  target: target.com
  #  proxy: proxy

# DNS配置
dns:
  cache-algorithm: arc
  enable: true # 关闭将使用系统 DNS
  prefer-h3: false # 是否开启 DoH 支持 HTTP/3，将并发尝试
  listen: 0.0.0.0:53 # 开启 DNS 服务器监听
  ipv6: true # false 将返回 AAAA 的空结果
  ipv6-timeout: 300 # 单位：ms，内部双栈并发时，向上游查询 AAAA 时，等待 AAAA 的时间，默认 100ms
  # 用于解析 nameserver，fallback 以及其他DNS服务器配置的，DNS 服务域名
  # 只能使用纯 IP 地址，可使用加密 DNS
  default-nameserver:
    - tcp://1.1.1.1
    - tcp://8.8.8.8
  enhanced-mode: fake-ip # fake-ip or redir-host

  fake-ip-range: 198.18.0.1/16 # fake-ip 池设置
  fake-ip-range6: fdfe:dcba:9876::1/64 # fake-ip6 池设置

  # 配置不使用 fake-ip 的域名
  fake-ip-filter:
    - '*.lan'
    - localhost.ptlogin2.qq.com
    # fakeip-filter 为 rule-providers 中的名为 fakeip-filter 规则订阅，
    # 且 behavior 必须为 domain/classical，当为 classical 时仅会生效域名类规则
    #- rule-set:fakeip-filter
    # fakeip-filter 为 geosite 中名为 fakeip-filter 的分类（需要自行保证该分类存在）
    #- geosite:fakeip-filter
  # 配置fake-ip-filter的匹配模式，默认为blacklist，即如果匹配成功不返回fake-ip
  # 可设置为whitelist，即只有匹配成功才返回fake-ip
  fake-ip-filter-mode: blacklist
  # 配置fakeip查询返回的TTL，非必要情况下请勿修改
  fake-ip-ttl: 1

  use-hosts: false # 查询 hosts

  # 配置后面的nameserver、fallback和nameserver-policy向dns服务器的连接过程是否遵守遵守rules规则
  # 如果为false（默认值）则这三部分的dns服务器在未特别指定的情况下会直连
  # 如果为true，将会按照rules的规则匹配链接方式（走代理或直连），如果有特别指定则任然以指定值为准
  # 仅当proxy-server-nameserver非空时可以开启此选项, 强烈不建议和prefer-h3一起使用
  # 此外，这三者配置中的dns服务器如果出现域名会采用default-nameserver配置项解析，也请确保正确配置default-nameserver
  respect-rules: true

  # DNS主要域名配置
  # 支持 UDP，TCP，DoT，DoH，DoQ
  # 这部分为主要 DNS 配置，影响所有直连，确保使用对大陆解析精准的 DNS
  nameserver:
    - tcp://1.1.1.1
    - tcp://8.8.8.8

  # 当配置 fallback 时，会查询 nameserver 中返回的 IP 是否为 CN，非必要配置
  # 当不是 CN，则使用 fallback 中的 DNS 查询结果
  # 确保配置 fallback 时能够正常查询
  fallback:
    - 'tcp://8.8.8.8#PROXY'
    - 'tcp://1.1.1.1#PROXY'

  # 指定 DNS 过代理查询，ProxyGroupName 为策略组名或节点名，过代理配置优先于配置出口网卡，当找不到策略组或节点名则设置为出口网卡

  # 专用于节点域名解析的 DNS 服务器，非必要配置项
  proxy-server-nameserver:
    - tcp://1.1.1.1
    - tcp://8.8.8.8

  # 专用于direct出口域名解析的 DNS 服务器，非必要配置项，如果不填则遵循nameserver-policy、nameserver和fallback的配置
  direct-nameserver:
    - dhcp://eth1
    #- system://
  direct-nameserver-follow-policy: false # 是否遵循nameserver-policy，默认为不遵守，仅当direct-nameserver不为空时生效



  # 配置 fallback 使用条件
  fallback-filter:
    geoip: true # 配置是否使用 geoip
    geoip-code: CN # 当 nameserver 域名的 IP 查询 geoip 库为 CN 时，不使用 fallback 中的 DNS 查询结果
  #   配置强制 fallback，优先于 IP 判断，具体分类自行查看 geosite 库
  #   geosite:
  #     - gfw
  #   如果不匹配 ipcidr 则使用 nameservers 中的结果
  #   ipcidr:
  #     - 240.0.0.0/4
    domain:
      - '+.facebook.com'
      - '+.google.com'
      - '+.gstatic.com'
      - '+.google.co.jp'
      - '+.youtube.com'
      - '+.ytimg.com'
      - '+.googlevideo.com'
      - '+.goog'
      - '+.googleapis.com'
      - '+.ggpht.com'
      - '+.googleusercontent.com'
      - '+.googleapis-cn.com'
      - '+.doubleclick.net'
      - '+.googleadservices.com'
      - '+.googlesyndication.com'
      - '+.openwrt.org'
      - '+.openai.com'
      - '+.chatgpt.com'
      - '+.x.ai'
      - '+.grok.com'
      - '+.twitter.com'
      - '+.twimg.com'
      - '+.x.com'
      - '+.returnyoutubedislikeapi.com'
      - '+.ajay.app'
      - '+.v2fly.org'
      - '+.v2ray.com'
      - '+.microsoft.com'

  # 配置查询域名使用的 DNS 服务器
  nameserver-policy:
    #   'www.baidu.com': '114.114.114.114'
    #   '+.internal.crop.com': '10.0.0.1'
    #"geosite:cn,private,apple":
    #  - https://doh.pub/dns-query
    #   - https://dns.alidns.com/dns-query
    #"geosite:category-ads-all": rcode://success
    #"www.baidu.com,+.google.cn": [223.5.5.5, https://dns.alidns.com/dns-query]
    ## global，dns 为 rule-providers 中的名为 global 和 dns 规则订阅，
    ## 且 behavior 必须为 domain/classical，当为 classical 时仅会生效域名类规则
    # "rule-set:global,dns": 8.8.8.8

proxies: 
  # vmess
  # cipher支持 auto/aes-128-gcm/chacha20-poly1305/none


EOF


    read -r -d '' mihomo_config_rules <<- 'EOF'

#proxy-providers:


rules:

EOF


    read -r -d '' mihomo_config_end <<- 'EOF'
  #- AND,((IP-CIDR6,::/0),(NETWORK,UDP),(DST-PORT,443),(OR,((DOMAIN-KEYWORD,youtube),(DOMAIN-KEYWORD,goog)))),REJECT
  - IN-USER,username,PROXY
  - DOMAIN-SUFFIX,.cn,DIRECT
  - DOMAIN-SUFFIX,baidu.com,DIRECT
  - DOMAIN-SUFFIX,baidubcr.com,DIRECT
  - DOMAIN-SUFFIX,bdstatic.com,DIRECT
  - DOMAIN-SUFFIX,yunjiasu-cdn.net,DIRECT
  - DOMAIN-SUFFIX,taobao.com,DIRECT
  - DOMAIN-SUFFIX,alicdn.com,DIRECT
  - DOMAIN,blzddist1-a.akamaihd.net,DIRECT
  - DOMAIN,cdn.angruo.com,PROXY
  - DOMAIN,download.jetbrains.com,DIRECT
  - DOMAIN,file-igamecj.akamaized.net,DIRECT
  - DOMAIN,images-cn.ssl-images-amazon.com,DIRECT
  - DOMAIN,officecdn-microsoft-com.akamaized.net,DIRECT
  - DOMAIN,speedtest.macpaw.com,DIRECT
  - DOMAIN-SUFFIX,126.net,DIRECT
  - DOMAIN-SUFFIX,127.net,DIRECT
  - DOMAIN-SUFFIX,163.com,DIRECT
  - DOMAIN-SUFFIX,163yun.com,DIRECT
  - DOMAIN-SUFFIX,21cn.com,DIRECT
  - DOMAIN-SUFFIX,343480.com,DIRECT
  - DOMAIN-SUFFIX,360buyimg.com,DIRECT
  - DOMAIN-SUFFIX,360in.com,DIRECT
  - DOMAIN-SUFFIX,51ym.me,DIRECT
  - DOMAIN-SUFFIX,71.am.com,DIRECT
  - DOMAIN-SUFFIX,8686c.com,DIRECT
  - DOMAIN-SUFFIX,abchina.com,DIRECT
  - DOMAIN-SUFFIX,accuweather.com,DIRECT
  - DOMAIN-SUFFIX,acgvideo.com,DIRECT
  - DOMAIN-SUFFIX,acm.org,DIRECT
  - DOMAIN-SUFFIX,acs.org,DIRECT
  - DOMAIN-SUFFIX,aicoinstorge.com,DIRECT
  - DOMAIN-SUFFIX,aip.org,DIRECT
  - DOMAIN-SUFFIX,air-matters.com,DIRECT
  - DOMAIN-SUFFIX,air-matters.io,DIRECT
  - DOMAIN-SUFFIX,aixifan.com,DIRECT
  - DOMAIN-SUFFIX,akadns.net,DIRECT
  - DOMAIN-SUFFIX,alibaba.com,DIRECT
  - DOMAIN-SUFFIX,alikunlun.com,DIRECT
  - DOMAIN-SUFFIX,alipay.com,DIRECT
  - DOMAIN-SUFFIX,amap.com,DIRECT
  - DOMAIN-SUFFIX,amd.com,DIRECT
  - DOMAIN-SUFFIX,ams.org,DIRECT
  - DOMAIN-SUFFIX,animebytes.tv,DIRECT
  - DOMAIN-SUFFIX,annualreviews.org,DIRECT
  - DOMAIN-SUFFIX,aps.org,DIRECT
  - DOMAIN-SUFFIX,ascelibrary.org,DIRECT
  - DOMAIN-SUFFIX,asm.org,DIRECT
  - DOMAIN-SUFFIX,asme.org,DIRECT
  - DOMAIN-SUFFIX,astm.org,DIRECT
  - DOMAIN-SUFFIX,autonavi.com,DIRECT
  - DOMAIN-SUFFIX,awesome-hd.me,DIRECT
  - DOMAIN-SUFFIX,b612.net,DIRECT
  - DOMAIN-SUFFIX,baduziyuan.com,DIRECT
  - DOMAIN-SUFFIX,battle.net,PROXY
  - DOMAIN-SUFFIX,bdatu.com,DIRECT
  - DOMAIN-SUFFIX,beitaichufang.com,DIRECT
  - DOMAIN-SUFFIX,biliapi.com,DIRECT
  - DOMAIN-SUFFIX,biliapi.net,DIRECT
  - DOMAIN-SUFFIX,bilibili.com,DIRECT
  - DOMAIN-SUFFIX,bilibili.tv,DIRECT
  - DOMAIN-SUFFIX,bjango.com,DIRECT
  - DOMAIN-SUFFIX,blizzard.com,PROXY
  - DOMAIN-SUFFIX,bmj.com,DIRECT
  - DOMAIN-SUFFIX,booking.com,DIRECT
  - DOMAIN-SUFFIX,broadcasthe.net,DIRECT
  - DOMAIN-SUFFIX,bstatic.com,DIRECT
  - DOMAIN-SUFFIX,cailianpress.com,DIRECT
  - DOMAIN-SUFFIX,cambridge.org,DIRECT
  - DOMAIN-SUFFIX,camera360.com,DIRECT
  - DOMAIN-SUFFIX,cas.org,DIRECT
  - DOMAIN-SUFFIX,ccgslb.com,DIRECT
  - DOMAIN-SUFFIX,ccgslb.net,DIRECT
  - DOMAIN-SUFFIX,cctv.com,DIRECT
  - DOMAIN-SUFFIX,cctvpic.com,DIRECT
  - DOMAIN-SUFFIX,chdbits.co,DIRECT
  - DOMAIN-SUFFIX,chinanetcenter.com,DIRECT
  - DOMAIN-SUFFIX,chinaso.com,DIRECT
  - DOMAIN-SUFFIX,chua.pro,DIRECT
  - DOMAIN-SUFFIX,chuimg.com,DIRECT
  - DOMAIN-SUFFIX,chunyu.mobi,DIRECT
  - DOMAIN-SUFFIX,chushou.tv,DIRECT
  - DOMAIN-SUFFIX,clarivate.com,DIRECT
  - DOMAIN-SUFFIX,classix-unlimited.co.uk,DIRECT
  - DOMAIN-SUFFIX,cmbchina.com,DIRECT
  - DOMAIN-SUFFIX,cmbimg.com,DIRECT
  - DOMAIN-SUFFIX,com-hs-hkdy.com,DIRECT
  - DOMAIN-SUFFIX,ctrip.com,DIRECT
  - DOMAIN-SUFFIX,czybjz.com,DIRECT
  - DOMAIN-SUFFIX,dandanzan.com,DIRECT
  - DOMAIN-SUFFIX,dfcfw.com,DIRECT
  - DOMAIN-SUFFIX,didialift.com,DIRECT
  - DOMAIN-SUFFIX,didiglobal.com,DIRECT
  - DOMAIN-SUFFIX,dingtalk.com,DIRECT
  - DOMAIN-SUFFIX,docschina.org,DIRECT
  - DOMAIN-SUFFIX,douban.com,DIRECT
  - DOMAIN-SUFFIX,doubanio.com,DIRECT
  - DOMAIN-SUFFIX,douyu.com,DIRECT
  - DOMAIN-SUFFIX,duokan.com,DIRECT
  - DOMAIN-SUFFIX,dxycdn.com,DIRECT
  - DOMAIN-SUFFIX,dytt8.net,DIRECT
  - DOMAIN-SUFFIX,eastmoney.com,DIRECT
  - DOMAIN-SUFFIX,ebscohost.com,DIRECT
  - DOMAIN-SUFFIX,emerald.com,DIRECT
  - DOMAIN-SUFFIX,empornium.me,DIRECT
  - DOMAIN-SUFFIX,engineeringvillage.com,DIRECT
  - DOMAIN-SUFFIX,eudic.net,DIRECT
  - DOMAIN-SUFFIX,feiliao.com,DIRECT
  - DOMAIN-SUFFIX,feng.com,DIRECT
  - DOMAIN-SUFFIX,fengkongcloud.com,DIRECT
  - DOMAIN-SUFFIX,fjhps.com,DIRECT
  - DOMAIN-SUFFIX,frdic.com,DIRECT
  - DOMAIN-SUFFIX,futu5.com,DIRECT
  - DOMAIN-SUFFIX,futunn.com,DIRECT
  - DOMAIN-SUFFIX,gandi.net,DIRECT
  - DOMAIN-SUFFIX,gazellegames.net,DIRECT
  - DOMAIN-SUFFIX,geilicdn.com,DIRECT
  - DOMAIN-SUFFIX,getpricetag.com,PROXY
  - DOMAIN-SUFFIX,gifshow.com,DIRECT
  - DOMAIN-SUFFIX,godic.net,DIRECT
  - DOMAIN-SUFFIX,gtimg.com,DIRECT
  - DOMAIN-SUFFIX,hdbits.org,DIRECT
  - DOMAIN-SUFFIX,hdchina.org,DIRECT
  - DOMAIN-SUFFIX,hdhome.org,DIRECT
  - DOMAIN-SUFFIX,hdsky.me,DIRECT
  - DOMAIN-SUFFIX,hdslb.com,DIRECT
  - DOMAIN-SUFFIX,hicloud.com,DIRECT
  - DOMAIN-SUFFIX,hitv.com,DIRECT
  - DOMAIN-SUFFIX,hongxiu.com,DIRECT
  - DOMAIN-SUFFIX,hostbuf.com,DIRECT
  - DOMAIN-SUFFIX,huxiucdn.com,DIRECT
  - DOMAIN-SUFFIX,huya.com,DIRECT
  - DOMAIN-SUFFIX,icetorrent.org,DIRECT
  - DOMAIN-SUFFIX,icevirtuallibrary.com,DIRECT
  - DOMAIN-SUFFIX,iciba.com,DIRECT
  - DOMAIN-SUFFIX,idqqimg.com,DIRECT
  - DOMAIN-SUFFIX,ieee.org,DIRECT
  - DOMAIN-SUFFIX,iesdouyin.com,DIRECT
  - DOMAIN-SUFFIX,igamecj.com,DIRECT
  - DOMAIN-SUFFIX,imf.org,DIRECT
  - DOMAIN-SUFFIX,infinitynewtab.com,DIRECT
  - DOMAIN-SUFFIX,iop.org,DIRECT
  - DOMAIN-SUFFIX,ip-cdn.com,DIRECT
  - DOMAIN-SUFFIX,ip.la,DIRECT
  - DOMAIN-SUFFIX,ipip.net,DIRECT
  - DOMAIN-SUFFIX,ipv6-test.com,DIRECT
  - DOMAIN-SUFFIX,iqiyi.com,DIRECT
  - DOMAIN-SUFFIX,iqiyipic.com,DIRECT
  - DOMAIN-SUFFIX,ithome.com,DIRECT
  - DOMAIN-SUFFIX,jamanetwork.com,DIRECT
  - DOMAIN-SUFFIX,java.com,DIRECT
  - DOMAIN-SUFFIX,jd.com,DIRECT
  - DOMAIN-SUFFIX,jd.hk,DIRECT
  - DOMAIN-SUFFIX,jdpay.com,DIRECT
  - DOMAIN-SUFFIX,jhu.edu,DIRECT
  - DOMAIN-SUFFIX,jidian.im,DIRECT
  - DOMAIN-SUFFIX,jpopsuki.eu,DIRECT
  - DOMAIN-SUFFIX,jstor.org,DIRECT
  - DOMAIN-SUFFIX,jstucdn.com,DIRECT
  - DOMAIN-SUFFIX,kaiyanapp.com,DIRECT
  - DOMAIN-SUFFIX,karger.com,DIRECT
  - DOMAIN-SUFFIX,kaspersky-labs.com,DIRECT
  - DOMAIN-SUFFIX,keepcdn.com,DIRECT
  - DOMAIN-SUFFIX,keepfrds.com,DIRECT
  - DOMAIN-SUFFIX,kkmh.com,DIRECT
  - DOMAIN-SUFFIX,ksosoft.com,DIRECT
  - DOMAIN-SUFFIX,kuyunbo.club,DIRECT
  - DOMAIN-SUFFIX,libguides.com,DIRECT
  - DOMAIN-SUFFIX,livechina.com,DIRECT
  - DOMAIN-SUFFIX,lofter.com,DIRECT
  - DOMAIN-SUFFIX,loli.net,DIRECT
  - DOMAIN-SUFFIX,luojilab.com,DIRECT
  - DOMAIN-SUFFIX,m-team.cc,PROXY
  - DOMAIN-SUFFIX,madsrevolution.net,DIRECT
  - DOMAIN-SUFFIX,maoyan.com,DIRECT
  - DOMAIN-SUFFIX,maoyun.tv,DIRECT
  - DOMAIN-SUFFIX,meipai.com,DIRECT
  - DOMAIN-SUFFIX,meitu.com,DIRECT
  - DOMAIN-SUFFIX,meituan.com,DIRECT
  - DOMAIN-SUFFIX,meituan.net,DIRECT
  - DOMAIN-SUFFIX,meitudata.com,DIRECT
  - DOMAIN-SUFFIX,meitustat.com,DIRECT
  - DOMAIN-SUFFIX,meixincdn.com,DIRECT
  - DOMAIN-SUFFIX,mgtv.com,DIRECT
  - DOMAIN-SUFFIX,mi-img.com,DIRECT
  - DOMAIN-SUFFIX,copilot.microsoft.com,PROXY
  - DOMAIN-SUFFIX,copilot.microsoft.com,PROXY
  - DOMAIN-SUFFIX,copilot-copilot-msft-com.trafficmanager.net,PROXY
  - DOMAIN-SUFFIX,copilot.microsoft.com.edgekey.net.edgekey.net,PROXY
  - DOMAIN-SUFFIX,e107108.dscx.akamaiedge.net,PROXY
  - AND,((DOMAIN-KEYWORD,copilot),(DOMAIN-KEYWORD,-)),PROXY
  - DOMAIN-SUFFIX,akamaiedge.net,DIRECT
  - DOMAIN-SUFFIX,microsoft.com,DIRECT
  - DOMAIN-SUFFIX,microsoftonline.com,DIRECT
  - DOMAIN-SUFFIX,onedrive.live.com,PROXY
  - DOMAIN-SUFFIX,live.com,DIRECT
  - DOMAIN-SUFFIX,office.com,DIRECT
  - DOMAIN-SUFFIX,miui.com,DIRECT
  - DOMAIN-SUFFIX,miwifi.com,DIRECT
  - DOMAIN-SUFFIX,mobike.com,DIRECT
  - DOMAIN-SUFFIX,moke.com,DIRECT
  - DOMAIN-SUFFIX,morethan.tv,DIRECT
  - DOMAIN-SUFFIX,mpg.de,DIRECT
  - DOMAIN-SUFFIX,msecnd.net,DIRECT
  - DOMAIN-SUFFIX,mubu.com,DIRECT
  - DOMAIN-SUFFIX,mxhichina.com,DIRECT
  - DOMAIN-SUFFIX,myanonamouse.net,DIRECT
  - DOMAIN-SUFFIX,myapp.com,DIRECT
  - DOMAIN-SUFFIX,myilibrary.com,DIRECT
  - DOMAIN-SUFFIX,myqcloud.com,DIRECT
  - DOMAIN-SUFFIX,myzaker.com,DIRECT
  - DOMAIN-SUFFIX,nanyangpt.com,DIRECT
  - DOMAIN-SUFFIX,nature.com,DIRECT
  - DOMAIN-SUFFIX,ncore.cc,DIRECT
  - DOMAIN-SUFFIX,netease.com,DIRECT
  - DOMAIN-SUFFIX,netspeedtestmaster.com,DIRECT
  - DOMAIN-SUFFIX,nim-lang-cn.org,DIRECT
  - DOMAIN-SUFFIX,nvidia.com,DIRECT
  - DOMAIN-SUFFIX,oecd-ilibrary.org,DIRECT
  - DOMAIN-SUFFIX,office365.com,DIRECT
  - DOMAIN-SUFFIX,open.cd,DIRECT
  - DOMAIN-SUFFIX,oracle.com,DIRECT
  - DOMAIN-SUFFIX,osapublishing.org,DIRECT
  - DOMAIN-SUFFIX,oup.com,DIRECT
  - DOMAIN-SUFFIX,ourbits.club,DIRECT
  - DOMAIN-SUFFIX,ourdvs.com,DIRECT
  - DOMAIN-SUFFIX,outlook.com,DIRECT
  - DOMAIN-SUFFIX,ovid.com,DIRECT
  - DOMAIN-SUFFIX,oxfordartonline.com,DIRECT
  - DOMAIN-SUFFIX,oxfordbibliographies.com,DIRECT
  - DOMAIN-SUFFIX,oxfordmusiconline.com,DIRECT
  - DOMAIN-SUFFIX,passthepopcorn.me,DIRECT
  - DOMAIN-SUFFIX,paypal.com,DIRECT
  - DOMAIN-SUFFIX,paypalobjects.com,DIRECT
  - DOMAIN-SUFFIX,pnas.org,DIRECT
  - DOMAIN-SUFFIX,privatehd.to,DIRECT
  - DOMAIN-SUFFIX,proquest.com,DIRECT
  - DOMAIN-SUFFIX,pstatp.com,DIRECT
  - DOMAIN-SUFFIX,pterclub.com,DIRECT
  - DOMAIN-SUFFIX,qdaily.com,DIRECT
  - DOMAIN-SUFFIX,qhimg.com,DIRECT
  - DOMAIN-SUFFIX,qhres.com,DIRECT
  - DOMAIN-SUFFIX,qidian.com,DIRECT
  - DOMAIN-SUFFIX,qq.com,DIRECT
  - DOMAIN-SUFFIX,wechat.com,DIRECT
  - DOMAIN-SUFFIX,dns.pub,DIRECT
  - DOMAIN-SUFFIX,doh.pub,DIRECT
  - DOMAIN-SUFFIX,qyer.com,DIRECT
  - DOMAIN-SUFFIX,qyerstatic.com,DIRECT
  - DOMAIN-SUFFIX,raychase.net,DIRECT
  - DOMAIN-SUFFIX,redacted.ch,DIRECT
  - DOMAIN-SUFFIX,ronghub.com,DIRECT
  - DOMAIN-SUFFIX,rsc.org,DIRECT
  - DOMAIN-SUFFIX,ruguoapp.com,DIRECT
  - DOMAIN-SUFFIX,s-microsoft.com,DIRECT
  - DOMAIN-SUFFIX,s-reader.com,DIRECT
  - DOMAIN-SUFFIX,sagepub.com,DIRECT
  - DOMAIN-SUFFIX,sankuai.com,DIRECT
  - DOMAIN-SUFFIX,sciencedirect.com,DIRECT
  - DOMAIN-SUFFIX,sciencemag.org,PROXY
  - DOMAIN-SUFFIX,scomper.me,DIRECT
  - DOMAIN-SUFFIX,scopus.com,DIRECT
  - DOMAIN-SUFFIX,seafile.com,DIRECT
  - DOMAIN-SUFFIX,servicewechat.com,DIRECT
  - DOMAIN-SUFFIX,siam.org,DIRECT
  - DOMAIN-SUFFIX,sina.com,DIRECT
  - DOMAIN-SUFFIX,sm.ms,DIRECT
  - DOMAIN-SUFFIX,smzdm.com,DIRECT
  - DOMAIN-SUFFIX,snapdrop.net,DIRECT
  - DOMAIN-SUFFIX,snssdk.com,DIRECT
  - DOMAIN-SUFFIX,snwx.com,DIRECT
  - DOMAIN-SUFFIX,sogo.com,DIRECT
  - DOMAIN-SUFFIX,sogou.com,DIRECT
  - DOMAIN-SUFFIX,sogoucdn.com,DIRECT
  - DOMAIN-SUFFIX,sohu-inc.com,DIRECT
  - DOMAIN-SUFFIX,sohu.com,DIRECT
  - DOMAIN-SUFFIX,sohucs.com,DIRECT
  - DOMAIN-SUFFIX,soku.com,DIRECT
  - DOMAIN-SUFFIX,spiedigitallibrary.org,DIRECT
  - DOMAIN-SUFFIX,springer.com,DIRECT
  - DOMAIN-SUFFIX,springerlink.com,DIRECT
  - DOMAIN-SUFFIX,springsunday.net,DIRECT
  - DOMAIN-SUFFIX,sspai.com,DIRECT
  - DOMAIN-SUFFIX,staticdn.net,DIRECT
  - DOMAIN-SUFFIX,steam-chat.com,DIRECT
  - DOMAIN-SUFFIX,steamcdn-a.akamaihd.net,DIRECT
  - DOMAIN-SUFFIX,steamcontent.com,DIRECT
  - DOMAIN-SUFFIX,steamgames.com,DIRECT
  - DOMAIN-SUFFIX,steampowered.com,DIRECT
  - DOMAIN-SUFFIX,steamstat.us,DIRECT
  - DOMAIN-SUFFIX,steamstatic.com,DIRECT
  - DOMAIN-SUFFIX,steamusercontent.com,DIRECT
  - DOMAIN-SUFFIX,takungpao.com,DIRECT
  - DOMAIN-SUFFIX,tandfonline.com,DIRECT
  - DOMAIN-SUFFIX,teamviewer.com,PROXY
  - DOMAIN-SUFFIX,tencent-cloud.net,DIRECT
  - DOMAIN-SUFFIX,tencent.com,DIRECT
  - DOMAIN-SUFFIX,tenpay.com,DIRECT
  - DOMAIN-SUFFIX,test-ipv6.com,DIRECT
  - DOMAIN-SUFFIX,tianyancha.com,DIRECT
  - DOMAIN-SUFFIX,tjupt.org,DIRECT
  - DOMAIN-SUFFIX,tmall.com,DIRECT
  - DOMAIN-SUFFIX,tmall.hk,DIRECT
  - DOMAIN-SUFFIX,totheglory.im,DIRECT
  - DOMAIN-SUFFIX,toutiao.com,DIRECT
  - DOMAIN-SUFFIX,udache.com,DIRECT
  - DOMAIN-SUFFIX,udacity.com,DIRECT
  - DOMAIN-SUFFIX,un.org,DIRECT
  - DOMAIN-SUFFIX,uni-bielefeld.de,DIRECT
  - DOMAIN-SUFFIX,uning.com,DIRECT
  - DOMAIN-SUFFIX,v-56.com,DIRECT
  - DOMAIN-SUFFIX,visualstudio.com,DIRECT
  - DOMAIN-SUFFIX,vmware.com,DIRECT
  - DOMAIN-SUFFIX,wangsu.com,DIRECT
  - DOMAIN-SUFFIX,weather.com,DIRECT
  - DOMAIN-SUFFIX,webofknowledge.com,DIRECT
  - DOMAIN-SUFFIX,weibo.com,DIRECT
  - DOMAIN-SUFFIX,weibocdn.com,DIRECT
  - DOMAIN-SUFFIX,weico.cc,DIRECT
  - DOMAIN-SUFFIX,weidian.com,DIRECT
  - DOMAIN-SUFFIX,westlaw.com,DIRECT
  - DOMAIN-SUFFIX,whatismyip.com,DIRECT
  - DOMAIN-SUFFIX,wiley.com,DIRECT
  - DOMAIN-SUFFIX,windows.com,DIRECT
  - DOMAIN-SUFFIX,windowsupdate.com,DIRECT
  - DOMAIN-SUFFIX,worldbank.org,DIRECT
  - DOMAIN-SUFFIX,worldscientific.com,DIRECT
  - DOMAIN-SUFFIX,xiachufang.com,DIRECT
  - DOMAIN-SUFFIX,xiami.com,DIRECT
  - DOMAIN-SUFFIX,xiami.net,DIRECT
  - DOMAIN-SUFFIX,xiaomi.com,DIRECT
  - DOMAIN-SUFFIX,xiaohongshu.com,DIRECT
  - DOMAIN-SUFFIX,xhscdn.com,DIRECT
  - DOMAIN-SUFFIX,ximalaya.com,DIRECT
  - DOMAIN-SUFFIX,xinhuanet.com,DIRECT
  - DOMAIN-SUFFIX,xmcdn.com,DIRECT
  - DOMAIN-SUFFIX,yangkeduo.com,DIRECT
  - DOMAIN-SUFFIX,ydstatic.com,DIRECT
  - DOMAIN-SUFFIX,youku.com,DIRECT
  - DOMAIN-SUFFIX,zhangzishi.cc,DIRECT
  - DOMAIN-SUFFIX,zhihu.com,DIRECT
  - DOMAIN-SUFFIX,zhimg.com,DIRECT
  - DOMAIN-SUFFIX,zhuihd.com,DIRECT
  - DOMAIN-SUFFIX,zimuzu.io,DIRECT
  - DOMAIN-SUFFIX,zimuzu.tv,DIRECT
  - DOMAIN-SUFFIX,zmz2019.com,DIRECT
  - DOMAIN-SUFFIX,zmzapi.com,DIRECT
  - DOMAIN-SUFFIX,zmzapi.net,DIRECT
  - DOMAIN-SUFFIX,zmzfile.com,DIRECT
  - DOMAIN-SUFFIX,manmanbuy.com,DIRECT
  - DOMAIN,www-cdn.icloud.com.akadns.net,DIRECT
  - DOMAIN-SUFFIX,aaplimg.com,DIRECT
  - DOMAIN-SUFFIX,apple-cloudkit.com,DIRECT
  - DOMAIN-SUFFIX,apple.co,DIRECT
  - DOMAIN-SUFFIX,apple.com,DIRECT
  - DOMAIN-SUFFIX,apple.news,DIRECT
  - DOMAIN-SUFFIX,apple.com.cn,DIRECT
  - DOMAIN-SUFFIX,appstore.com,DIRECT
  - DOMAIN-SUFFIX,cdn-apple.com,DIRECT
  - DOMAIN-SUFFIX,crashlytics.com,DIRECT
  - DOMAIN-SUFFIX,icloud-content.com,DIRECT
  - DOMAIN-SUFFIX,icloud.com,DIRECT
  - DOMAIN-SUFFIX,icloud.com.cn,DIRECT
  - DOMAIN-SUFFIX,me.com,DIRECT
  - DOMAIN-SUFFIX,mzstatic.com,DIRECT
  - DOMAIN-SUFFIX,v2ex.com,PROXY
  - DOMAIN-SUFFIX,scdn.co,PROXY
  - DOMAIN-SUFFIX,line.naver.jp,PROXY
  - DOMAIN-SUFFIX,line.me,PROXY
  - DOMAIN-SUFFIX,line-apps.com,PROXY
  - DOMAIN-SUFFIX,line-cdn.net,PROXY
  - DOMAIN-SUFFIX,line-scdn.net,PROXY
  - DOMAIN-KEYWORD,blogspot,PROXY
  - DOMAIN-SUFFIX,google.com,PROXY
  - DOMAIN-SUFFIX,google.co.jp,PROXY
  - DOMAIN-SUFFIX,googlevideo.com,PROXY
  - DOMAIN-SUFFIX,returnyoutubedislikeapi.com,PROXY
  - DOMAIN-SUFFIX,.goog,PROXY
  - DOMAIN-SUFFIX,googleapis.com,PROXY
  - DOMAIN-SUFFIX,googleusercontent.com,PROXY
  - DOMAIN-SUFFIX,googleapis-cn.com,PROXY
  - DOMAIN-SUFFIX,googleadservices.com,PROXY
  - DOMAIN-SUFFIX,googlesyndication.com,PROXY
  - DOMAIN-KEYWORD,google,PROXY
  - DOMAIN-SUFFIX,abc.xyz,PROXY
  - DOMAIN-SUFFIX,admin.recaptcha.net,PROXY
  - DOMAIN-SUFFIX,ampproject.org,PROXY
  - DOMAIN-SUFFIX,android.com,PROXY
  - DOMAIN-SUFFIX,androidify.com,PROXY
  - DOMAIN-SUFFIX,appspot.com,PROXY
  - DOMAIN-SUFFIX,autodraw.com,PROXY
  - DOMAIN-SUFFIX,blogger.com,PROXY
  - DOMAIN-SUFFIX,capitalg.com,PROXY
  - DOMAIN-SUFFIX,certificate-transparency.org,PROXY
  - DOMAIN-SUFFIX,chrome.com,PROXY
  - DOMAIN-SUFFIX,chromeexperiments.com,PROXY
  - DOMAIN-SUFFIX,chromestatus.com,PROXY
  - DOMAIN-SUFFIX,chromium.org,PROXY
  - DOMAIN-SUFFIX,creativelab5.com,PROXY
  - DOMAIN-SUFFIX,debug.com,PROXY
  - DOMAIN-SUFFIX,deepmind.com,PROXY
  - DOMAIN-SUFFIX,dialogflow.com,PROXY
  - DOMAIN-SUFFIX,firebaseio.com,PROXY
  - DOMAIN-SUFFIX,getmdl.io,PROXY
  - DOMAIN-SUFFIX,getoutline.org,PROXY
  - DOMAIN-SUFFIX,ggpht.com,PROXY
  - DOMAIN-SUFFIX,gmail.com,PROXY
  - DOMAIN-SUFFIX,gmodules.com,PROXY
  - DOMAIN-SUFFIX,godoc.org,PROXY
  - DOMAIN-SUFFIX,golang.org,PROXY
  - DOMAIN-SUFFIX,gstatic.com,PROXY
  - DOMAIN-SUFFIX,gv.com,PROXY
  - DOMAIN-SUFFIX,gvt0.com,PROXY
  - DOMAIN-SUFFIX,gvt1.com,PROXY
  - DOMAIN-SUFFIX,gvt3.com,PROXY
  - DOMAIN-SUFFIX,gwtproject.org,PROXY
  - DOMAIN-SUFFIX,itasoftware.com,PROXY
  - DOMAIN-SUFFIX,madewithcode.com,PROXY
  - DOMAIN-SUFFIX,material.io,PROXY
  - DOMAIN-SUFFIX,polymer-project.org,PROXY
  - DOMAIN-SUFFIX,recaptcha.net,PROXY
  - DOMAIN-SUFFIX,shattered.io,PROXY
  - DOMAIN-SUFFIX,synergyse.com,PROXY
  - DOMAIN-SUFFIX,telephony.goog,PROXY
  - DOMAIN-SUFFIX,tensorflow.org,PROXY
  - DOMAIN-SUFFIX,tfhub.dev,PROXY
  - DOMAIN-SUFFIX,tiltbrush.com,PROXY
  - DOMAIN-SUFFIX,waveprotocol.org,PROXY
  - DOMAIN-SUFFIX,waymo.com,PROXY
  - DOMAIN-SUFFIX,webmproject.org,PROXY
  - DOMAIN-SUFFIX,webrtc.org,PROXY
  - DOMAIN-SUFFIX,whatbrowser.org,PROXY
  - DOMAIN-SUFFIX,widevine.com,PROXY
  - DOMAIN-SUFFIX,x.company,PROXY
  - DOMAIN-SUFFIX,xn--ngstr-lra8j.com,PROXY
  - DOMAIN-SUFFIX,youtu.be,PROXY
  - DOMAIN-SUFFIX,yt.be,PROXY
  - DOMAIN-SUFFIX,youtube.com,PROXY
  - DOMAIN-SUFFIX,ytimg.com,PROXY
  - DOMAIN-SUFFIX,clubhouseapi.com,PROXY
  - DOMAIN-SUFFIX,clubhouse.pubnub.com,PROXY
  - DOMAIN-SUFFIX,joinclubhouse.com,PROXY
  - DOMAIN-SUFFIX,ap3.agora.io,PROXY
  - DOMAIN-KEYWORD,aka,PROXY
  - DOMAIN-KEYWORD,facebook,PROXY
  - DOMAIN-KEYWORD,youtube,PROXY
  - DOMAIN-KEYWORD,twitter,PROXY
  - DOMAIN-SUFFIX,instagram.com,PROXY
  - DOMAIN-SUFFIX,cdninstagram.com,PROXY
  - DOMAIN-KEYWORD,instagram,PROXY
  - DOMAIN-SUFFIX,instagr.am,PROXY
  - DOMAIN-KEYWORD,gmail,PROXY
  - DOMAIN-KEYWORD,pixiv,PROXY
  - DOMAIN-SUFFIX,fb.com,PROXY
  - DOMAIN-SUFFIX,meta.com,PROXY
  - DOMAIN-SUFFIX,twimg.com,PROXY
  - DOMAIN-SUFFIX,x.com,PROXY
  - DOMAIN-SUFFIX,t.co,PROXY
  - DOMAIN-SUFFIX,kenengba.com,PROXY
  - DOMAIN-SUFFIX,akamai.net,PROXY
  - DOMAIN-SUFFIX,whatsapp.net,PROXY
  - DOMAIN-SUFFIX,whatsapp.com,PROXY
  - DOMAIN-SUFFIX,snapchat.com,PROXY
  - DOMAIN-SUFFIX,amazonaws.com,PROXY
  - DOMAIN-SUFFIX,angularjs.org,PROXY
  - DOMAIN-SUFFIX,akamaihd.net,PROXY
  - DOMAIN-SUFFIX,amazon.com,PROXY
  - DOMAIN-SUFFIX,bit.ly,PROXY
  - DOMAIN-SUFFIX,bitbucket.org,PROXY
  - DOMAIN-SUFFIX,blog.com,PROXY
  - DOMAIN-SUFFIX,blogcdn.com,PROXY
  - DOMAIN-SUFFIX,blogsmithmedia.com,PROXY
  - DOMAIN-SUFFIX,box.net,PROXY
  - DOMAIN-SUFFIX,bloomberg.com,PROXY
  - DOMAIN-SUFFIX,cl.ly,PROXY
  - DOMAIN-SUFFIX,cloudfront.net,PROXY
  - DOMAIN-SUFFIX,cloudflare.com,PROXY
  - DOMAIN-SUFFIX,cocoapods.org,PROXY
  - DOMAIN-SUFFIX,dribbble.com,PROXY
  - DOMAIN-SUFFIX,dropbox.com,PROXY
  - DOMAIN-SUFFIX,dropboxstatic.com,PROXY
  - DOMAIN-SUFFIX,dropboxusercontent.com,PROXY
  - DOMAIN-SUFFIX,docker.com,PROXY
  - DOMAIN-SUFFIX,duckduckgo.com,PROXY
  - DOMAIN-SUFFIX,digicert.com,PROXY
  - DOMAIN-SUFFIX,dnsimple.com,PROXY
  - DOMAIN-SUFFIX,edgecastcdn.net,PROXY
  - DOMAIN-SUFFIX,engadget.com,PROXY
  - DOMAIN-SUFFIX,eurekavpt.com,PROXY
  - DOMAIN-SUFFIX,fb.me,PROXY
  - DOMAIN-SUFFIX,fbcdn.net,PROXY
  - DOMAIN-SUFFIX,fc2.com,PROXY
  - DOMAIN-SUFFIX,feedburner.com,PROXY
  - DOMAIN-SUFFIX,fabric.io,PROXY
  - DOMAIN-SUFFIX,flickr.com,PROXY
  - DOMAIN-SUFFIX,fastly.net,PROXY
  - DOMAIN-SUFFIX,github.com,PROXY
  - DOMAIN-SUFFIX,github.io,PROXY
  - DOMAIN-SUFFIX,githubusercontent.com,PROXY
  - DOMAIN-KEYWORD,github,PROXY
  - DOMAIN-SUFFIX,goo.gl,PROXY
  - DOMAIN-SUFFIX,godaddy.com,PROXY
  - DOMAIN-SUFFIX,gravatar.com,PROXY
  - DOMAIN-SUFFIX,imageshack.us,PROXY
  - DOMAIN-SUFFIX,imgur.com,PROXY
  - DOMAIN-SUFFIX,jshint.com,PROXY
  - DOMAIN-SUFFIX,ift.tt,PROXY
  - DOMAIN-SUFFIX,j.mp,PROXY
  - DOMAIN-SUFFIX,kat.cr,PROXY
  - DOMAIN-SUFFIX,linode.com,PROXY
  - DOMAIN-SUFFIX,lithium.com,PROXY
  - DOMAIN-SUFFIX,megaupload.com,PROXY
  - DOMAIN-SUFFIX,mobile01.com,PROXY
  - DOMAIN-SUFFIX,modmyi.com,PROXY
  - DOMAIN-SUFFIX,nytimes.com,PROXY
  - DOMAIN-SUFFIX,name.com,PROXY
  - DOMAIN-SUFFIX,openvpn.net,PROXY
  - DOMAIN-SUFFIX,openwrt.org,PROXY
  - DOMAIN-KEYWORD,openwrt,PROXY
  - DOMAIN-SUFFIX,ow.ly,PROXY
  - DOMAIN-SUFFIX,pinboard.in,PROXY
  - DOMAIN-SUFFIX,ssl-images-amazon.com,PROXY
  - DOMAIN-SUFFIX,sstatic.net,PROXY
  - DOMAIN-SUFFIX,stackoverflow.com,PROXY
  - DOMAIN-SUFFIX,staticflickr.com,PROXY
  - DOMAIN-SUFFIX,squarespace.com,PROXY
  - DOMAIN-SUFFIX,symcd.com,PROXY
  - DOMAIN-SUFFIX,symcb.com,PROXY
  - DOMAIN-SUFFIX,symauth.com,PROXY
  - DOMAIN-SUFFIX,ubnt.com,PROXY
  - DOMAIN-SUFFIX,thepiratebay.org,PROXY
  - DOMAIN-SUFFIX,tumblr.com,PROXY
  - DOMAIN-SUFFIX,twitch.tv,PROXY
  - DOMAIN-SUFFIX,twitter.com,PROXY
  - DOMAIN-SUFFIX,wikipedia.com,PROXY
  - DOMAIN-SUFFIX,wikipedia.org,PROXY
  - DOMAIN-SUFFIX,wikimedia.org,PROXY
  - DOMAIN-SUFFIX,wordpress.com,PROXY
  - DOMAIN-SUFFIX,wsj.com,PROXY
  - DOMAIN-SUFFIX,wsj.net,PROXY
  - DOMAIN-SUFFIX,wp.com,PROXY
  - DOMAIN-SUFFIX,vimeo.com,PROXY
  - DOMAIN-SUFFIX,tapbots.com,PROXY
  - DOMAIN-SUFFIX,ykimg.com,DIRECT
  - DOMAIN-SUFFIX,medium.com,PROXY
  - DOMAIN-SUFFIX,fast.com,PROXY
  - DOMAIN-SUFFIX,nflxvideo.net,PROXY
  - DOMAIN-SUFFIX,linkedin.com,PROXY
  - DOMAIN-SUFFIX,licdn.com,PROXY
  - DOMAIN-SUFFIX,bing.com,PROXY
  - DOMAIN-SUFFIX,zoom.us,PROXY
  - DOMAIN-SUFFIX,soundcloud.com,PROXY
  - DOMAIN-SUFFIX,sndcdn.com,PROXY
  - DOMAIN,api.statsig.com,PROXY
  - DOMAIN,browser-intake-datadoghq.com,PROXY
  - DOMAIN,chat.openai.com.cdn.cloudflare.net,PROXY
  - DOMAIN,o33249.ingest.sentry.io,PROXY
  - DOMAIN,openai-api.arkoselabs.com,PROXY
  - DOMAIN,openaicom-api-bdcpf8c6d2e9atf6.z01.azurefd.net,PROXY
  - DOMAIN,openaicomproductionae4b.blob.core.windows.net,PROXY
  - DOMAIN,production-openaicom-storage.azureedge.net,PROXY
  - DOMAIN,static.cloudflareinsights.com,PROXY
  - DOMAIN-KEYWORD,openaicom-api,PROXY
  - DOMAIN-SUFFIX,algolia.net,PROXY
  - DOMAIN-SUFFIX,auth0.com,PROXY
  - DOMAIN-SUFFIX,cdn.cloudflare.net,PROXY
  - DOMAIN-SUFFIX,challenges.cloudflare.com,PROXY
  - DOMAIN-SUFFIX,chatgpt.livekit.cloud,PROXY
  - DOMAIN-SUFFIX,client-api.arkoselabs.com,PROXY
  - DOMAIN-SUFFIX,events.statsigapi.net,PROXY
  - DOMAIN-SUFFIX,featuregates.org,PROXY
  - DOMAIN-SUFFIX,host.livekit.cloud,PROXY
  - DOMAIN-SUFFIX,identrust.com,PROXY
  - DOMAIN-SUFFIX,intercom.io,PROXY
  - DOMAIN-SUFFIX,intercomcdn.com,PROXY
  - DOMAIN-SUFFIX,launchdarkly.com,PROXY
  - DOMAIN-SUFFIX,oaistatic.com,PROXY
  - DOMAIN-SUFFIX,oaiusercontent.com,PROXY
  - DOMAIN-SUFFIX,observeit.net,PROXY
  - DOMAIN-SUFFIX,chatgpt.com,PROXY
  - DOMAIN-SUFFIX,openai.com,PROXY
  - DOMAIN-SUFFIX,openaiapi-site.azureedge.net,PROXY
  - DOMAIN-SUFFIX,openaicom.imgix.net,PROXY
  - DOMAIN-KEYWORD,openai,PROXY
  - DOMAIN-SUFFIX,poe.com,PROXY
  - DOMAIN-SUFFIX,segment.io,PROXY
  - DOMAIN-SUFFIX,sentry.io,PROXY
  - DOMAIN-SUFFIX,stripe.com,PROXY
  - DOMAIN-SUFFIX,turn.livekit.cloud,PROXY
  - DOMAIN-SUFFIX,ajay.app,PROXY
  - DOMAIN-SUFFIX,v2fly.org,PROXY
  - DOMAIN-SUFFIX,v2ray.com,PROXY
  - DOMAIN-SUFFIX,doubleclick.net,PROXY
  - DOMAIN-SUFFIX,truepeoplesearch.net,PROXY
  - DOMAIN-SUFFIX,beenverified.com,PROXY
  - DOMAIN-SUFFIX,grok.com,PROXY
  - DOMAIN-SUFFIX,x.ai,PROXY
  - DOMAIN-SUFFIX,skk.moe,REJECT
  - DOMAIN-SUFFIX,drift.com,REJECT
  - DOMAIN-SUFFIX,ad.com,REJECT
  - DOMAIN-SUFFIX,hotjar.com,REJECT
  - IP-CIDR,24.199.123.28/32,PROXY,no-resolve
  - IP-CIDR,45.76.214.191/32,PROXY,no-resolve
  - IP-CIDR,64.23.132.171/32,PROXY,no-resolve
  - IP-CIDR,143.198.200.27/32,PROXY,no-resolve
  - IP-CIDR,159.89.204.203/32,PROXY,no-resolve
  - DOMAIN-SUFFIX,t.me,PROXY
  - DOMAIN-SUFFIX,tdesktop.com,PROXY
  - DOMAIN-SUFFIX,telegra.ph,PROXY
  - DOMAIN-SUFFIX,telegram.me,PROXY
  - DOMAIN-SUFFIX,telegram.org,PROXY
  - DOMAIN-SUFFIX,telesco.pe,PROXY
  - IP-CIDR,91.108.4.0/22,PROXY,no-resolve
  - IP-CIDR,91.108.8.0/22,PROXY,no-resolve
  - IP-CIDR,91.108.12.0/22,PROXY,no-resolve
  - IP-CIDR,91.108.16.0/22,PROXY,no-resolve
  - IP-CIDR,91.108.56.0/22,PROXY,no-resolve
  - IP-CIDR,109.239.140.0/24,PROXY,no-resolve
  - IP-CIDR,149.154.160.0/20,PROXY,no-resolve
  - IP-CIDR6,2001:B28:F23D::/48,PROXY,no-resolve
  - IP-CIDR6,2001:B28:F23F::/48,PROXY,no-resolve
  - IP-CIDR6,2001:67C:4E8::/48,PROXY,no-resolve
  - DOMAIN-SUFFIX,dnsleaktest.com,PROXY
  - DOMAIN-SUFFIX,dnsleak.com,PROXY
  - DOMAIN-SUFFIX,expressvpn.com,PROXY
  - DOMAIN-SUFFIX,nordvpn.com,PROXY
  - DOMAIN-SUFFIX,surfshark.com,PROXY
  - DOMAIN-SUFFIX,ipleak.net,PROXY
  - DOMAIN-SUFFIX,perfect-privacy.com,PROXY
  - DOMAIN-SUFFIX,browserleaks.com,PROXY
  - DOMAIN-SUFFIX,browserleaks.org,PROXY
  - DOMAIN-SUFFIX,vpnunlimited.com,PROXY
  - DOMAIN-SUFFIX,whoer.net,PROXY
  - DOMAIN-SUFFIX,whrq.net,PROXY
  #- SRC-IP-CIDR,192.168.1.201/32,DIRECT
  # optional param "no-resolve" for IP rules (GEOIP, IP-CIDR, IP-CIDR6)
  #- IP-CIDR6,::/0,DIRECT,no-resolve
  #- IP-CIDR6,::/0,DIRECT
  - IP-CIDR,127.0.0.0/8,DIRECT,no-resolve
  - IP-CIDR,127.0.0.0/8,DIRECT
  - IP-CIDR,17.0.0.0/8,DIRECT
  - IP-CIDR,192.168.0.0/16,DIRECT
  - IP-CIDR,10.0.0.0/8,DIRECT
  - IP-CIDR,172.16.0.0/12,DIRECT
  - GEOIP,CN,DIRECT
  - GEOIP,US,PROXY
  - GEOIP,DE,PROXY
  - GEOIP,JP,PROXY
  #- DST-PORT,80,DIRECT
  #- SRC-PORT,7777,DIRECT
  #- RULE-SET,apple,REJECT # Premium only
  #- GEOSITE,gfw,PROXY
  #- GEOSITE,CN,DIRECT
  - MATCH,DIRECT
EOF

    read -r -d '' mihomo_config_proxy_groups <<- 'EOF'

proxy-groups:
  # 代理链，目前 relay 可以支持 udp 的只有 vmess/vless/trojan/ss/ssr/tuic
  # wireguard 目前不支持在 relay 中使用，请使用 proxy 中的 dialer-proxy 配置项
  # Traffic: mihomo <-> http <-> vmess <-> ss1 <-> ss2 <-> Internet
  - name: "PROXY"
    type: url-test
    proxies:
    %proxies_domains
    url: "https://www.youtube.com/generate_204"
    interval: 300
    tolerance: 30
    lazy: true
    timeout: 5000



EOF


}


auto_mihomo_config(){
    read -r -d '' mihomo_config_proxie_ws <<- 'EOF'

  - name: vmess-ws_%s
    type: vless
    server: %s
    port:  
    uuid: 
    encryption: ""
    flow: xtls-rprx-vision
    alterId: 0
    cipher: auto
    udp: true
    tls: true
    skip-cert-verify: false
    servername: 
    network: ws
    ech-opts:
      enable: false
      #config: 
    ws-opts:
       path: 
       headers:
           Host: 
       #max-early-data: 1024
       #early-data-header-name: Sec-WebSocket-Protocol

EOF

    domains='developers.cloudflare.com blog.cloudflare.com cloudflareinsights.com auth.openai.com polestar.com'

    
    if [ -n "$domains" ] ; then

      mihomo_config_proxie_domains=''
      for domain in $domains
      do 
          mihomo_config_proxie_domains="$mihomo_config_proxie_domains

  ${mihomo_config_proxie_ws//%s/$domain}"
      done


      proxies_domains=''
      for domain in $domains
      do 
          proxies_domains="$proxies_domains   - vmess-ws_$domain
    "
      done


      rules_cf_ip=''
#      for cf_ip in `curl  --retry 10 --retry-max-time 360 -H "Cache-Control: no-cache" -fsSL https://www.cloudflare.com/ips-v6/#`
#      do 
#          rules_cf_ip="$rules_cf_ip  - IP-CIDR6,$cf_ip,DIRECT
#"
#      done

#      for cf_ip in `curl  --retry 10 --retry-max-time 360 -H "Cache-Control: no-cache" -fsSL https://www.cloudflare.com/ips-v4/#`
#      do 
#          rules_cf_ip="$rules_cf_ip  - IP-CIDR,$cf_ip,DIRECT
#"
#      done


      echo "${mihomo_config_begin}
${mihomo_config_hosts}${mihomo_config_proxie_domains}

${mihomo_config_proxy_groups//%proxies_domains/$proxies_domains}

${mihomo_config_rules}
${rules_cf_ip}${mihomo_config_end}" > /etc/openclash/config/config.yaml

	
    fi


    if ! [ -L /www/config.yaml ] ; then                                               
       ln -s /etc/openclash/config/config.yaml /www/config.yaml
    fi
}


download_openclash(){
 latest_version_openclash=`curl --retry 10 --retry-max-time 360 -X GET  --user-agent "Mozilla/5.0 (Macintosh; Intel Mac OS X x.y; rv:42.0) Gecko/20100101 Firefox/42.0" 'https://api.github.com/repos/vernesong/OpenClash/tags' -s | awk '/name/{print $0; exit;}' | awk '/name/{print $0; exit;}' | awk -F '"' '{print $4}'`
 current_version_openclash="v`opkg find luci-app-openclash* | awk -F ' ' '{print $3}'`"
 echo "$latest_version_openclash $current_version_openclash"
  if [ -n "$current_version_openclash" ] && [ -n "$latest_version_openclash" ] && [ "$latest_version_openclash" != "$current_version_openclash" ]
  then
    rm -fr $path/openclashv*
    echo "download $path/openclash$latest_version_openclash"
    mkdir $path/openclash$latest_version_openclash
    curl --retry 10 --retry-max-time 360 -H "Cache-Control: no-cache" -fsSL https://github.com/vernesong/OpenClash/releases/download/$latest_version_openclash/luci-app-openclash_`echo $latest_version_openclash | awk '{print substr($1,2)}'`_all.ipk -o $path/openclash$latest_version_openclash/luci-app-openclash_`echo $latest_version_openclash | awk '{print substr($1,2)}'`_all.ipk
    if [ -f $path/openclash$latest_version_openclash/luci-app-openclash_`echo $latest_version_openclash | awk '{print substr($1,2)}'`_all.ipk ]; then
      /etc/init.d/openclash stop
      echo "$path/openclash$latest_version_openclash/luci-app-openclash_`echo $latest_version_openclash | awk '{print substr($1,2)}'`_all.ipk"
      ulimit -v unlimited 2>/dev/null
      opkg install $path/openclash$latest_version_openclash/luci-app-openclash_`echo $latest_version_openclash | awk '{print substr($1,2)}'`_all.ipk
      uci -q set openclash.config.enable=1
      echo "$latest_version_openclash" > /tmp/openclash_last_version
      echo "" > /usr/share/openclash/openclash_version.sh
      echo "" > /usr/lib/lua/luci/view/openclash/developer.htm
      echo "" > /usr/lib/lua/luci/view/openclash/myip.htm
      sed -i '/entry({"admin", "services", "openclash", "announcement"}, call("action_announcement"))/d' /usr/lib/lua/luci/controller/openclash.lua
      rm -fr /usr/share/openclash/ui/yacd
      rm -fr /usr/share/openclash/ui/metacubexd
      rm -fr /usr/share/openclash/ui/xd
      rm -fr /usr/share/openclash/ui/zashboard

      /etc/init.d/openclash restart
    fi
  fi

  begin_line=`awk '/^start_run_core()/{print NR; exit;}' /etc/init.d/openclash`
  end_line=`awk 'NR>'$begin_line' && /^}/ {print NR; exit;}' /etc/init.d/openclash`

  add_oom_score_adjust_line=`awk 'NR>'$begin_line' && NR<'$end_line' && /procd_set_param oom_score_adjust -1000/ {print NR}' /etc/init.d/openclash`
  procd_close_instance_line=`awk 'NR>'$begin_line' && NR<'$end_line' && /procd_close_instance/ {print NR-1}' /etc/init.d/openclash`
  if [ -z "$add_oom_score_adjust_line" ] && [ -n "$procd_close_instance_line" ]; then
    sed -i ''$procd_close_instance_line'i\   procd_set_param oom_score_adjust -1000' /etc/init.d/openclash
    sed -i ''$procd_close_instance_line'i\   procd_set_param env SAFE_PATHS=$CLASH_CONFIG:/usr/share/openclash/ui/' /etc/init.d/openclash
  fi

  update_procd_limits_line=`awk 'NR>'$begin_line' && NR<'$end_line' && /procd_set_param limits nproc="unlimited" as="unlimited" memlock="unlimited" nofile="1000000 1000000"/ {print NR}' /etc/init.d/openclash`
  if [ -n "$update_procd_limits_line" ]; then
    sed -i ''$update_procd_limits_line' s/procd_set_param limits nproc="unlimited" as="unlimited" memlock="unlimited" nofile="1000000 1000000"/procd_set_param limits nproc="unlimited" as="unlimited" memlock="204800" nofile="1000000 1000000"/' /etc/init.d/openclash
  fi

  update_ulimit_v_line=`awk 'NR>'$begin_line' && NR<'$end_line' && /ulimit -v unlimited 2>\/dev\/null/ {print NR}' /etc/init.d/openclash`
  if [ -n "$update_ulimit_v_line" ]; then
    sed -i ''$update_ulimit_v_line' s/ulimit -v unlimited 2>\/dev\/null/ulimit -v `free -k | awk '"'NR==2{print \$2 * 3}'"'` 2>\/dev\/null/' /etc/init.d/openclash
  fi

  update_ulimit_u_line=`awk 'NR>'$begin_line' && NR<'$end_line' && /ulimit -u unlimited 2>\/dev\/null/ {print NR}' /etc/init.d/openclash`
  if [ -n "$update_ulimit_u_line" ]; then
    sed -i ''$update_ulimit_u_line' s/ulimit -u unlimited 2>\/dev\/null/ulimit -u 65535 2>\/dev\/null/' /etc/init.d/openclash
  fi


  if [ -z "$add_oom_score_adjust_line" ] || [ -n "$update_ulimit_v_line" ] || [ -n "$update_ulimit_u_line" ]; then
    uci -q set openclash.config.enable=1
    /etc/init.d/openclash restart
    end_line=`awk 'NR>'$begin_line' && /^}/ {print NR; exit;}' /etc/init.d/openclash`
  fi
  
  awk 'NR>'$begin_line'&&NR<'$end_line'+1{print $0}' /etc/init.d/openclash

}

update
init_mihomo_config
install_mihomo
/etc/init.d/openclash restart
auto_mihomo_config
/etc/init.d/openclash restart
download_openclash
#/etc/init.d/network restart
#opkg update
#opkg remove dnsmasq wpad-basic-wolfssl
#opkg install kmod-tcp-bbr  wpad-openssl tar
#0 20 * * * /root/openclash_auto_config/openclash_mihomo_auto_config.sh > /root/openclash_auto_config/start.log 2>&1


#/cdn-cgi/trace
