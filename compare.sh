#!/bin/bash

clear

echo

echo "Value Compare:"
number1=101
number2=101
if (( number1 == number2 )); then
    echo "is true"
else
    echo "is false"
fi

echo

echo "String Compare:"
number=Linux
if [ "$number" == "Linux" ]; then
    echo "is true"
else
    echo "is false"
fi

echo
