#!/bin/sh

prog=telnet.sna

./_make.sh
if [ $? -eq 0 ];then
 ./_run.sh
else
 rm $prog
fi
