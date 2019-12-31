FROM alpine

RUN apk add nodejs npm git && npm install -g hexo-cli

#Prepare work dir
RUN hexo init /blog
WORKDIR /blog

RUN cd /blog & npm install

EXPOSE 4000

CMD ["hexo", "server"]




