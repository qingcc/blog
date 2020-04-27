FROM alpine

RUN apk add nodejs npm git && npm install -g hexo-cli

#Prepare work dir
COPY next /blog/themes

RUN hexo init /blog

WORKDIR /blog

EXPOSE 4000





