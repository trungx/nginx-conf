server {
  listen 80;
  listen [::]:80;
  server_name ping.parkermoo.re;
  return 302 https://$host$request_uri;
}

server {
  # 'http2' requires nginx 1.9.5+. If using older nginx, replace with 'spdy'.
  listen 443 ssl http2;
  listen [::]:443 ssl http2;
  server_name ping.parkermoo.re;

  ssl_certificate /etc/letsencrypt/live/ping.parkermoo.re/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/ping.parkermoo.re/privkey.pem;
  ssl_trusted_certificate /etc/letsencrypt/live/gossip.parkermoo.re/chain.pem;
  ssl_session_timeout 5m;
  ssl_session_cache shared:SSL:50m;

  # modern configuration. tweak to your needs.
  ssl_protocols TLSv1.1 TLSv1.2;
  ssl_ciphers 'ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!3DES:!MD5:!PSK';
  ssl_prefer_server_ciphers on;
  ssl_dhparam /opt/nginx/ssl/ping.parkermoo.re/dhparam.pem;

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
  etag on;

  location / {
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $remote_addr;
    proxy_set_header Host $host;
    proxy_pass       http://localhost:8972;

    # optional: tell browsers to require SSL (warning: difficult to change your mind)
    add_header Strict-Transport-Security max-age=31536000;

    # optional: make @konklone happy
    add_header X-Konklone-Force-HTTPS TRUE;
  }
}