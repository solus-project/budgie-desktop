#!/bin/sh
tx pull -a --minimum-perc=46

cd po
rm LINGUAS

for i in *.po ; do
    echo `echo $i|sed 's/.po$//'` >> LINGUAS
done
