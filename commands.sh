#!/bin/bash

sudo yum update -y

sudo amazon-linux-extras install nginx1.12 -y

sudo systemctl start nginx

sudo systemctl enable nginx

sudo amazon-linux-extras enable php8.0

sudo yum clean metadata

sudo yum install php php-cli php-mysqlnd php-pdo php-common php-fpm -y

sudo yum install php-gd php-mbstring php-xml php-dom php-intl php-simplexml -y

sudo systemctl start php-fpm

sudo systemctl enable php-fpm

cat <<EOL | sudo tee /etc/nginx/conf.d/gcptips.conf
server {
    listen 80;
    server_name www.gcptips.com;
    rewrite ^ $scheme://gcptips.com$request_uri?;
}

server {
    listen 80;
    server_name gcptips.com;
    
    root /var/www/wordpress;
    index index.php;
    charset UTF-8;
    
    

    location ~ \.php$ {
        try_files $uri =404;

        include fastcgi_params;
        fastcgi_param  SCRIPT_FILENAME    $document_root$fastcgi_script_name;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_index index.php;
        # fastcgi_intercept_errors on;
        # fastcgi_keep_conn on;
        # fastcgi_read_timeout 300;

        # fastcgi_pass   127.0.0.1:9000;
        fastcgi_pass  unix:/var/run/php-fpm/www.sock;
        #for ubuntu unix:/var/run/php/php8.0-fpm.sock;

        ##
        # FastCGI cache config
        ##

        # fastcgi_cache_path /var/cache/nginx levels=1:2 keys_zone=WORDPRESS:10m max_size=1000m inactive=60m;
        # fastcgi_cache_key $scheme$host$request_uri$request_method;
        # fastcgi_cache_use_stale updating error timeout invalid_header http_500;        
        
        fastcgi_cache_valid any 30m;
    }
}
EOL

echo "<?php echo 'Hello OMNI World, my name is JAIME LUIS JULIO AVILA'; ?>" | sudo tee /usr/share/nginx/html/index.php

sudo systemctl restart nginx 


