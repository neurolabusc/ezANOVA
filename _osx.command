#!/bin/sh

#to make Lazarus for cocoa
# make LCL_PLATFORM=cocoa CPU_TARGET=x86_64 clean bigide
# lazbuild  -B --ws=cocoa ./simplelaz.lpr
# ./lazbuild  --ws=carbon --compiler="/usr/local/lib/fpc/3.0.4/ppc386" --cpu=i386 --add-package lazopenglcontext --add-package pascalscript --build-ide=
# ./lazbuild  --ws=cocoa --add-package lazopenglcontext --add-package pascalscript --build-ide=
# ./lazbuild  --ws=cocoa --compiler="/usr/local/lib/fpc/3.0.4/ppcx64" --cpu=x86_64 --add-package lazopenglcontext --add-package pascalscript --build-ide=

find /Users/rorden/Documents/osx -name ‘*.DS_Store’ -type f -delete

cd ~/Documents/pas/ezANOVA/
rm -rf lib
rm *.bak

~/Lazarus/lazbuild -B ./ezANOVA.lpr  --ws=cocoa
strip ./ezANOVA

rm -rf lib
rm *.bak
