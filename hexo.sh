#!/bin/bash
container_name=hexo_blog
docker-compose up -d

docker exec $container_name hexo c
docker exec $container_name hexo g
docker exec $container_name hexo s
    #你的用户文件夹路径
    #你的用户文件夹路径
    #你的博客主题路径
    #你的博客路径
    #你的博客主配置路径
