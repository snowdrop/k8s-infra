#!/usr/bin/env bash

tar_file=$1
images=( ${@:2} )


docker save ${images} > $tar_file
