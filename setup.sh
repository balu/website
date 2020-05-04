#!/bin/sh
if test ! -f html
then
    mkdir html
    mkdir html/programming\
          html/free-software\
          html/cweet\
          html/research\
          html/teaching
    cp -r data html/
fi
