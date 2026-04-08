FROM nginx:1.25-alpine

RUN apk add --no-cache gettext

COPY html/ /usr/share/nginx/html/
COPY scrollBoard/ /usr/share/nginx/html/scrollBoard/

COPY default.conf.template /etc/nginx/conf.d/default.conf.template
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 80 443

ENTRYPOINT ["/entrypoint.sh"]
