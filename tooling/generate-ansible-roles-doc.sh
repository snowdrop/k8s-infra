#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
rm -f "./asciidoctor/all.adoc"
paths=""

for FILE in $(find ../ansible/roles -name '**.adoc')
do
  echo "FILE: $FILE"
  adocIncludeFiles+=$(printf '\n\n%s[]\n\n' "include::../$FILE")
done

echo "### Generate the all.adoc file containing the include:: directive for each role"
readonly AWK_TMP_FILE="asciidoctor/all.adoc.tmp"
awk -v paths="${adocIncludeFiles}" '{gsub(/INCLUDES/,paths)}1' "${AWK_TMP_FILE}" > ./asciidoctor/all.adoc

echo "### Generate the HTML asciidoctor file containing the table of the roles and each role"
mvn package -DskipTests=true
