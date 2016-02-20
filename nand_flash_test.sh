#!/bin/bash

LIMIT=10

while ((1))
do
    for ((a = 1; a <= LIMIT; a++))
    do
        echo "I Like $a"
        sleep 1
    done
done

