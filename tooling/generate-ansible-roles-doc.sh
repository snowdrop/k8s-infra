#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

readonly PATH="${PATH}:-../ansible/roles"
paths=""

for FILE in $(find ${PATH} -name '**.adoc')
do
  paths+="include::../$FILE[]\n\n"
done

echo "### Generate the all.adoc file containing the include:: directive for each role"
readonly AWK_TMP_FILE=$(mktemp)
awk -v paths="${paths}" '{gsub(/INCLUDES/,paths)}1' "${AWK_TMP_FILE}" > ./asciidoctor/all.adoc
rm "${AWK_TMP_FILE}"

echo "### Generate the HTML asciidoctor file containing the table of the roles and each role"
mvn clean package -DskipTests=true
