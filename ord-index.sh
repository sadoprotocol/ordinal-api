#!/bin/bash

if ps -fu $UID | grep "ord" | grep "index-sats index"
then 
   echo "Still running..";
else
   echo "Begin indexing..";
   ord@afwcxx --index-sats index
fi

