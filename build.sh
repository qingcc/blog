#bin/bash
image_name=hexo_blog

echo "===> building container image"


docker rmi -f $image_name
docker build -t $image_name  .

echo '-> ** tagging '$image_name
docker tag $image_name qingcc/$image_name

