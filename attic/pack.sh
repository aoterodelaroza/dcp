#! /bin/bash

cd new
for i in *.db ; do
    awk 'NR==1,/ref/{if ($0 ~ /ref/) next; print}' $i > ../done/$i
    cat ../doneref/$i >> ../done/$i
    awk '(doit){print} /ref/{doit = 1}' $i >> ../done/$i
done
