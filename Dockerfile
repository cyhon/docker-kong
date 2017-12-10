FROM docker.finogeeks.club/base/alpine:3.7
MAINTAINER linhaitao@finogeeks.com 

ENV KONG_VERSION 0.11.2

RUN apk add --no-cache --virtual .build-deps wget tar ca-certificates \
	&& apk add --no-cache libgcc openssl pcre perl tzdata \
	&& wget -O kong.tar.gz "https://bintray.com/kong/kong-community-edition-alpine-tar/download_file?file_path=kong-community-edition-$KONG_VERSION.apk.tar.gz" \
	&& tar -xzf kong.tar.gz -C /tmp \
	&& rm -f kong.tar.gz \
	&& cp -R /tmp/usr / \
	&& rm -rf /tmp/usr \
	&& cp -R /tmp/etc / \
	&& rm -rf /tmp/etc \
	&& apk del .build-deps tar wget \
    && export https_proxy=http://10.135.186.25:3128 \
    && luarocks install nginx-lua-prometheus

# redirect logs
RUN mkdir -p /usr/local/kong/logs \
    && ln -sf /dev/stdout /usr/local/kong/logs/admin_access.log \
    && ln -sf /dev/stdout /usr/local/kong/logs/access.log \
    && ln -sf /dev/stderr /usr/local/kong/logs/error.log

# sysctl optimized
COPY etc/sysctl.conf /etc/sysctl.conf

COPY entrypoint.sh /entrypoint.sh
COPY nginx_kong.lua /usr/local/share/lua/5.1/kong/templates/nginx_kong.lua

ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 8000 8443 8001 8444

STOPSIGNAL SIGTERM

CMD ["/usr/local/openresty/nginx/sbin/nginx", "-c", "/usr/local/kong/nginx.conf", "-p", "/usr/local/kong/"]
