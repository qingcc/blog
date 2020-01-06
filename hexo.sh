#!/bin/bash
container_name=hexo_blog
docker run -p 7000:4000 -d --name $container_name \
    -v ~/.ssh:/root/.ssh \
    -v /root/docker/hexo/source:/blog/source \
    -v /root/docker/hexo/themes/next/_config.yml:/blog/themes/next/_config.yml \
    -v /root/docker/hexo/scaffolds:/blog/scaffolds \
    -v /root/docker/hexo/_config.yml:/blog/_config.yml \
qingcc/hexo_blog:v1.0.0

git clone https://github.com/iissnan/hexo-theme-next && docker cp /root/docker/hexo/hexo-theme-next $container_name:/blog/themes/next
docker exec $container_name hexo g
    #你的用户文件夹路径
    #你的用户文件夹路径
    #你的博客主题路径
    #你的博客路径
    #你的博客主配置路径
