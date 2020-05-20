#!/usr/bin/env bash

path=../ansible/roles
paths=""

find ${path} -name **.adoc -print0 |
    while IFS= read -r -d '' line; do
        echo "$paths include::$line[]"
    done

sed -i -e 's/INCLUDES/'"${paths}"'/g' ./asciidoctor/all.adoc

echo ${paths}
