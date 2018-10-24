#!/usr/bin/env bash

tar_file=$1
shift
var=( $@ )

for i in "${var[@]}"
do
  images+="$i "
done

echo "docker save $images > $tar_file"
docker save $images > $tar_file
