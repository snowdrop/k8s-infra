#!/bin/bash


path=../ansible/roles
paths=""

for FILE in `find ${path} -name **.adoc`
do
  paths+="include::../$FILE[]\n\n"
done

echo "### Generate the all.adoc file containing the include:: directive for each role"
awk -v paths=$paths '{gsub(/INCLUDES/,paths)}1' ./asciidoctor/all.adoc.tmp > ./asciidoctor/all.adoc

echo "### Generate the HTML asciidoctor file containing the table of the roles and each role"
mvn clean package -DskipTests=true
