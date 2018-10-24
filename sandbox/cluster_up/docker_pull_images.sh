#!/usr/bin/env bash

images=( $@ )

for i in "${images[@]}"
do
   echo "$i"
   docker pull $i
done
