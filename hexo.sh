#!/bin/bash
container_name=hexo_blog

while (( $# > 1 )); do case $1 in
   -c) container_name="$2";;
   *) break;
 esac; shift 2
done

#bash /root/docker/hexo/.hexo.sh
cd /root/docker/hexo && docker-compose up -d && docker exec $container_name hexo c && docker exec  $container_name g && docker exec  $container_name s