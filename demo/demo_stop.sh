#!/bin/bash

while read line
do
      kill $line
      echo ����: $line  killed!
done < ./collect.sid

rm ./collect.sid
