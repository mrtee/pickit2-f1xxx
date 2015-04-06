#!/bin/sh
grep PIC thecode/lib_v2/lib/pic14_f1_device_datas.rb |cut -d '"' -f 2|sed  '1,2d'
