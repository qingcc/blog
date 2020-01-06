#!/bin/bash
str=$2
str=${str##*/}
#git clone $2
#mkdir themes/$3
cp ${str%.*}/_config.yml themes/$3/_config.yml
docker exec $1 cp ${str%.*} $1:/blog/themes/$3
#cd themes/$name && docker cp $1:/blog/themes/$name/_config.yml themes/$name/

