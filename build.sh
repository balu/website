#!/bin/sh
srcdir="src/"
htmldir="html/"
templatedir="template/"
default_template=$templatedir"default.html5"
files="index contact cv programming/auto programming/lifetimes \
programming/const cweet/home cweet/doc cweet/learncweet \
research/index free-software/index free-software/programs \
free-software/privacy free-software/commands programming/index \
tak takman"

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
           --toc\
           --self-contained\
           $srcpre.rst
done
pandoc --from=rst+smart src/cv.rst\
       --metadata-file=src/cv.yaml\
       -o html/data/cv.pdf
