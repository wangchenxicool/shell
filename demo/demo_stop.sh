#!/bin/bash

while read line
do
      kill $line
      echo ½ø³Ì: $line  killed!
done < ./collect.sid

rm ./collect.sid
