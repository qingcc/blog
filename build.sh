#bin/bash
image_name=hexo_blog

if [ ! -d "/root/docker/hexo/next"]; then
  git clone https://github.com/iissnan/hexo-theme-next next
fi

echo "===> building container image"

exist=`docker images | grep $image_name`
if [ "${exist}" != "" ]; then
 docker rmi -f $image_name
fi

docker build -t $image_name  .

echo '-> ** tagging '$image_name
docker tag $image_name qingcc/$image_name

