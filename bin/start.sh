#!/bin/bash


mkdir -p /etc/caddy/

#/etc/caddy/Caddyfile

if [ -z "$HTTP_PORT" ]; then
    export HTTP_PORT=8080
fi
echo "HTTP_PORT=: $HTTP_PORT"
if [ -z "$HTTPS_PORT" ]; then
    export HTTPS_PORT=8443
fi
echo "HTTPS_PORT=: $HTTPS_PORT"

if [ -z "$CADDY_SSL" ];then
 cat << EOF >/etc/caddy/Caddyfile
{
	http_port    $HTTP_PORT
	https_port   $HTTPS_PORT

	log default {
		level ERROR
		output stdout
		format console
	}

	auto_https disable_certs

	servers {
		protocols h1 h2 h2c h3
	}

}


http:// {

	handle {
		redir https://github.com
	}	
	
	handle_path /html/* {
		root * /usr/share/caddy
		file_server
	}




	
}
EOF
else
 mkdir -p /usr/app/ssl/
 cat << EOF >/usr/app/ssl/server.crt
$SSLCERTIFICATE
EOF
 sed -i 's/ /\n/g' /usr/app/ssl/server.crt
 sed -i '1,2d' /usr/app/ssl/server.crt
 sed -i '$d' /usr/app/ssl/server.crt
 sed -i '$d' /usr/app/ssl/server.crt
 sed -i '1i\-----BEGIN CERTIFICATE-----' /usr/app/ssl/server.crt
 sed -i '$a\-----END CERTIFICATE-----' /usr/app/ssl/server.crt
 
 cat << EOF >/usr/app/ssl/server.key
$SSLCERTIFICATEKEY
EOF
 sed -i 's/ /\n/g' /usr/app/ssl/server.key
 sed -i '1,3d' /usr/app/ssl/server.key
 sed -i '$d' /usr/app/ssl/server.key
 sed -i '$d' /usr/app/ssl/server.key
 sed -i '$d' /usr/app/ssl/server.key
 sed -i '1i\-----BEGIN PRIVATE KEY-----' /usr/app/ssl/server.key
 sed -i '$a\-----END PRIVATE KEY-----' /usr/app/ssl/server.key
 
 cat << EOF >/etc/caddy/Caddyfile
{
	http_port    $HTTP_PORT
	https_port   $HTTPS_PORT

	log default {
		level ERROR
		output stdout
		format console
	}

	auto_https disable_certs

	servers {
		protocols h1 h2 h2c h3
	}

}

$SERVERNAME {
	
	tls /usr/app/ssl/server.crt /usr/app/ssl/server.key

	handle {
		redir https://github.com
	}	
	
	handle_path /html/* {
		root * /usr/share/caddy
		file_server
	}



	
}
EOF
fi

sync

#Other
for file in /usr/app/bin/*; do
    if [ `basename $file` != start.sh ];
    then
	   cat $file | tr -d '\r'  | bash  >/usr/share/caddy/`basename $file`.html 2>&1 &
	   sync
    fi
done

sync
