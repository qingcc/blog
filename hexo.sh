#!/bin/bash
container_name=hexo_blog
docker run -p 7000:4000 -dit --name $container_name \
    -v ~/.ssh:/root/.ssh \
    -v /root/docker/hexo/source:/blog/source \
    -v /root/docker/hexo/themes:/blog/themes \
    -v /root/docker/hexo/scaffolds:/blog/scaffolds \
    -v /root/docker/hexo/_config.yml:/blog/_config.yml \
qingcc/hexo_blog:latest

docker exec $container_name hexo g 
docker exec $container_name hexo s
    #你的用户文件夹路径
    #你的用户文件夹路径
    #你的博客主题路径
    #你的博客路径
    #你的博客主配置路径
