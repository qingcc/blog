#bin/bash
image_name=hexo_blog

git clone https://github.com/iissnan/hexo-theme-next next

echo "===> building container image"

if [docker images | grep $image_name == $image_name]; then
 docker rmi -f $image_name
fi

docker build -t $image_name  .

echo '-> ** tagging '$image_name
docker tag $image_name qingcc/$image_name

