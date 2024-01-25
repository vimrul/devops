nginx:

include log-json.conf
access_log /var/log/nginx/access.json json;

sample-block:
server {
        
        listen 80 default_server;
        listen [::]:80 default_server;
#        root /var/www/html;

        # Add index.php to the list if you are using PHP
        index index.html index.htm index.nginx-debian.html;

        server_name apps.ecs.gov.bd;
        access_log /var/log/nginx/access.json json;

        #=========EMS=========

        location / {
              return 404;
        }
Sample-block-2:
        location /api/v1 {
                # First attempt to serve request as file, then
                # as directory, then fall back to displaying a 404.
                proxy_pass http://ec-user-app;
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_http_version 1.1; 
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto $scheme;
                proxy_set_header Upgrade $http_upgrade;
                proxy_set_header Connection "upgrade";
#               access_log /var/log/nginx/access.json custom_json;
                access_log /var/log/nginx/access.json json;
        }

filebeat sample:
# ============================== Filebeat inputs ==================================
filebeat.inputs:
  - type: log
    paths:
      - /var/log/nginx/access.json
    fields:
      document_type: nginx_access

  - type: log
    paths:
      - /var/log/nginx/*.json
    tags: ["nginx", "json"]
    json:
      keys_under_root: true
      add_error_key: true

filter-nginx.conf location: /etc/logstash/conf.d
log-json.conf location: /etc/nginx
