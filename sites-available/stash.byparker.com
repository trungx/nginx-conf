# THIS FILE IS AUTO-GENERATED by nginx-conf-gen. DO NOT EDIT.
# Redirect HTTP to HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name stash.byparker.com;
    return 301 https://$host$request_uri;
}






# Serve the site.
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name stash.byparker.com;

    
    # Show me the files.
    root /var/www/parkr/stash.byparker.com;
    error_page 404 = /404.html;
    etag on;
    

    # optional: turn on session resumption, using a 10 min cache shared across nginx processes
    # as recommended by http://nginx.org/en/docs/http/configuring_https_servers.html
    keepalive_timeout   70;

    # SSL Configuration.
    ssl_certificate /etc/letsencrypt/live/stash.byparker.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/stash.byparker.com/privkey.pem;
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:50m;
    ssl_session_tickets off;
    ssl_protocols TLSv1.1 TLSv1.2 TLSv1.3;
    ssl_ciphers "ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!3DES:!MD5:!PSK";
    ssl_prefer_server_ciphers on;
    ssl_dhparam /opt/nginx/ssl/stash.byparker.com/dhparams.pem;

    # HSTS (ngx_http_headers_module is required) (15768000 seconds = 6 months)
    add_header Strict-Transport-Security max-age=15768000;

    # OCSP Stapling -- fetch OCSP records from URL in ssl_certificate and cache them
    ssl_stapling on;
    ssl_stapling_verify on;
    ssl_trusted_certificate /etc/letsencrypt/live/stash.byparker.com/chain.pem;

    # Make @konklone happy
    add_header X-Konklone-Force-HTTPS TRUE;

    # Handle all requests.
    location / {
        try_files $uri $uri.html $uri/index.html index.html;
        
    }

    ## All static files will be served with a bit more nuance.
    location ~* ^.+\.(?:css|cur|js|jpe?g|gif|htc|ico|png|html|xml|otf|ttf|eot|woff|svg|woff2)$ {
        access_log off;
        expires 30d;
        add_header Cache-Control "public, must-revalidate, proxy-revalidate";
        add_header X-Konklone-Force-HTTPS TRUE;
        etag on;

        
        ## No need to bleed constant updates. Send the all shebang in one
        ## fell swoop.
        tcp_nodelay off;

        ## Set the OS file cache.
        open_file_cache max=3000 inactive=120s;
        open_file_cache_valid 45s;
        open_file_cache_min_uses 2;
        open_file_cache_errors off;
        
    }
}

# vim: syn=nginx
