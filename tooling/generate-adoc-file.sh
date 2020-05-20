#!/bin/bash

path=../ansible/roles
paths=""

for FILE in `find ${path} -name **.adoc`
do
  paths+="include::$FILE\n"
done

awk -v paths=$paths '{gsub(/INCLUDES/,paths)}1' ./asciidoctor/all.adoc.tmp > ./asciidoctor/all.adoc
