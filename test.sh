#!/bin/bash


b="sfseeurope-sfseeurope-eu-demo376.registry.snowflakecomputing.com/spcs_app/napp/img_repo"
echo $b
a=$(echo "$b" | sed 's/\/.*//')

echo $a
