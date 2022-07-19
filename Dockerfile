FROM nginx:1.23.0

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

RUN echo "Asia/Shanghai" > /etc/timezone

RUN apt update && \
    apt install -y cron certbot python3-certbot-nginx python3-certbot-dns-cloudflare

COPY nginx.conf /etc/nginx/nginx.conf
COPY conf.d /etc/nginx/conf.d

ARG CLOUDFLARE_TOKEN

RUN echo "dns_cloudflare_api_token = ${CLOUDFLARE_TOKEN}" > /root/cloudflare.ini
RUN chmod 600 /root/cloudflare.ini

RUN certbot certonly -n --agree-tos -d *.viva-la-vita.org \
-m admin@viva-la-vita.org \
--dns-cloudflare --dns-cloudflare-credentials /root/cloudflare.ini \
--dns-cloudflare-propagation-seconds 60

RUN certbot install --nginx --cert-name viva-la-vita.org -d forum.viva-la-vita.org

RUN echo "nginx -s reload" > /etc/letsencrypt/renewal-hooks/deploy/reload-nginx.sh &&\
    chmod +x /etc/letsencrypt/renewal-hooks/deploy/reload-nginx.sh

RUN apt install -y wget

# container init
RUN wget -O /usr/local/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v1.2.1/dumb-init_1.2.1_amd64 && \
    chmod 755 /usr/local/bin/dumb-init

ENTRYPOINT ["/usr/local/bin/dumb-init", "--"]

CMD ["sh", "-c", "cron && nginx -g 'daemon off;'"]