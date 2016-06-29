server {
  listen 80;
  server_name pages.byparker.com;
  return 301 https://pages.byparker.com$request_uri;
}

server {
  listen 443 ssl http2;
  server_name pages.byparker.com;

  # required: path to certificate and private key
  ssl_certificate /etc/letsencrypt/live/pages.byparker.com-0001/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/pages.byparker.com-0001/privkey.pem;
  ssl_trusted_certificate /etc/letsencrypt/live/pages.byparker.com-0001/chain.pem;
  ssl_session_timeout 5m;
  ssl_session_cache shared:SSL:50m;

  # modern configuration. tweak to your needs.
  ssl_protocols TLSv1.1 TLSv1.2;
  ssl_ciphers 'ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!3DES:!MD5:!PSK';
  ssl_prefer_server_ciphers on;

  # HSTS (ngx_http_headers_module is required) (15768000 seconds = 6 months)
  add_header Strict-Transport-Security max-age=15768000;

  # OCSP Stapling ---
  # fetch OCSP records from URL in ssl_certificate and cache them
  ssl_stapling on;
  ssl_stapling_verify on;

  # optional: make @konklone happy
  add_header X-Konklone-Force-HTTPS TRUE;

  # optional: turn on session resumption, using a 10 min cache shared across nginx processes
  # as recommended by http://nginx.org/en/docs/http/configuring_https_servers.html
  keepalive_timeout   70;

  # e-tag for caching
  etag on;

  location / {
    proxy_pass        http://localhost:7523;
    proxy_set_header  X-Real-IP  $remote_addr;
  }

  ## All static files will be served directly.
  location ~* ^.+\.(?:css|cur|js|jpe?g|gif|htc|ico|png|html|xml|otf|ttf|eot|woff|svg|woff2)$ {
    access_log off;
    expires 30d;
    add_header Cache-Control "public, must-revalidate, proxy-revalidate";
    ## No need to bleed constant updates. Send the all shebang in one
    ## fell swoop.
    tcp_nodelay off;
    ## Set the OS file cache.
    open_file_cache max=3000 inactive=120s;
    open_file_cache_valid 45s;
    open_file_cache_min_uses 2;
    open_file_cache_errors off;
    add_header X-Konklone-Force-HTTPS TRUE;
    etag on;
  }
}