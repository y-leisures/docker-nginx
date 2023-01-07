# NOTE: The builder part is nessessary to build headers more module
FROM nginx:1.23.3 as builder

ENV NGINX_VERSION 1.21.0
ENV HEADERS_MORE_VERSION 0.33

RUN apt-get update && apt-get install -y \
    wget \
    gcc \
    make \
    build-essential \
    zlib1g-dev \
    libpcre3-dev

# Download sources
RUN wget "http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz" -O nginx.tar.gz && \
    wget "https://github.com/openresty/headers-more-nginx-module/archive/v${HEADERS_MORE_VERSION}.tar.gz" -O more_headers.tar.gz

# Reuse same cli arguments as the nginx:alpine image used to build
RUN CONFARGS=$(nginx -V 2>&1 | sed -n -e 's/^.*arguments: //p') \
    tar -zxC /usr/local -f nginx.tar.gz && \
    tar -xzvf "more_headers.tar.gz" -C /usr/local/nginx-${NGINX_VERSION} && \
    echo

RUN MORE_DIR="/usr/local/nginx-${NGINX_VERSION}/headers-more-nginx-module-${HEADERS_MORE_VERSION}" && \
    cd /usr/local/nginx-${NGINX_VERSION} && \
    ./configure --with-compat $CONFARGS --add-dynamic-module=$MORE_DIR && \
    make modules && make install

FROM nginx:1.23.3

COPY --from=builder /usr/local/nginx/modules/ngx_http_headers_more_filter_module.so /usr/local/nginx/modules/ngx_http_headers_more_filter_module.so

# NOTE: NGINX_ENVSUBST_OUTPUT_DIR is /etc/nginx/conf.d as default
ENV NGINX_ENVSUBST_OUTPUT_DIR=/etc/nginx
# We should make sure to run nginx as foreground process.
# Nginx docker container runs as foreground as default.
# COPY ./nginx.conf /etc/nginx/nginx.conf
COPY ./nginx.conf /etc/nginx/templates/nginx.conf.template
