#!/usr/bin/env bash

path=../ansible/roles
paths=""

find ${path} -name **.adoc -print0 |
    while IFS= read -r -d '' line; do
        echo "$paths include::$line[]"
    done

sed "s|INCLUDES|${paths}|g" ./asciidoctor/all.adoc.tmp > ./asciidoctor/all.adoc

echo ${paths}
