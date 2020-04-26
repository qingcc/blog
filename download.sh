#!/bin/bash
git="https://github.com/iissnan/hexo-theme-next"
container_name=hexo_blog

while (( $# > 1 )); do case $1 in
   -c) container_name="$2";;
   -git) git="$2";;
   *) break;
 esac; shift 2
done

#bash /root/docker/hexo/.hexo.sh
cd /root/docker/hexo && docker-compose up -d && git clone $git next && docker exec $container_name cp next /blog/themes && docker exec $container_name hexo c && docker exec  $container_name g && docker exec  $container_name s