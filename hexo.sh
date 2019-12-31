#!/bin/bash
docker run -p 7000:4000 -d --name hexo_server \
    -v ~/.ssh:/root/.ssh \
    -v /root/docker/hexo/source:/blog/source \
    -v /root/docker/hexo/themes:/blog/themes \
    -v /root/docker/hexo/scaffolds:/blog/scaffolds \
    -v /root/docker/hexo/_config.yml:/blog/_config.yml \
qingcc/hexo_blog:v1.0.0
    #你的用户文件夹路径
    #你的用户文件夹路径
    #你的博客主题路径
    #你的博客路径
    #你的博客主配置路径
