#!/bin/bash

path=../ansible/roles
paths=""

for FILE in `find ${path} -name **.adoc`
do
  paths+="include::$FILE[]"$'\n'
done

sed "s|INCLUDES|${paths}|g" ./asciidoctor/all.adoc.tmp > ./asciidoctor/all.adoc
