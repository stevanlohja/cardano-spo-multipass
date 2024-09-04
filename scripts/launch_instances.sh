#!/bin/bash
for i in {1..2}; do
    multipass launch -n cn$i -c 2 -m 4G -d 20G
done