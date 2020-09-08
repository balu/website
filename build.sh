#!/bin/sh
srcdir="src/"
htmldir="html/"
templatedir="template/"
default_template=$templatedir"default.html5"
files="index contact cv programming/auto programming/lifetimes \
programming/const research/index teaching/index teaching/turing_machine \
teaching/toc2020 \
free-software/index  programming/index"

for item in $files
do
    srcpre=$srcdir$item
    outpre=$htmldir$item
    template=$templatedir$item.html5
    if test ! -f $template
    then template=$default_template
    fi
    pandoc --output=$outpre.html\
           --template=$template\
           --metadata-file=$srcpre.yaml\
           --highlight-style=pygments\
           --toc\
           --self-contained\
           $srcpre.rst
done
pandoc --from=rst+smart src/cv.rst\
       --metadata-file=src/cv.yaml\
       -o html/data/cv.pdf
cp data/thesis.pdf html/data/
cp data/bkomarath_public_key.txt html/data/
cp data/toc.tar.gz html/data/toc.tar.gz
