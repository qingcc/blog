#!/bin/bash
container_name=hexo_blog

exist=`docker ps -a | $container_name`

if [ "${exist}" != "" ]; then
  docker rm -f $container_name
fi

while (( $# > 1 )); do case $1 in
   -c) container_name="$2";;
   *) break;
 esac; shift 2
done

#bash /root/docker/hexo/.hexo.sh
cd /root/docker/hexo && docker-compose up -d
./update