FROM alpine

RUN apk add nodejs npm git && npm install -g hexo-cli

#Prepare work dir
RUN hexo init /blog

COPY next /blog/themes

WORKDIR /blog

RUN cd /blog & npm install

EXPOSE 4000





