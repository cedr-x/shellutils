#!/bin/bash
# Enumerate all physical volumes and show what's the usage on each

for I in $( pvs -o pv_name --noheadings  ) ; do 
	echo $I \($(lsblk ${I/[0-9]/}  -d  -o MODEL,REV,SIZE -n )\) $( pvs $I  --noheadings --nosuffix --units g  -o pv_size,pv_used,pv_free )
	pvs $I --all  --noheadings --segment --nosuffix --units g -o seg_size,vg_name,lv_name | sed 's/_[^ ]*//;s/\[//;s/ *$//' \
	| awk '
		$3=="" {
			$3="**FREE**"
			free=$1 
			} 
		{ 
			QTE[$3]+=$1
			tot+=$1
			vg=$2 
		}  
		END { 
			for (item in QTE) 
				printf("\t%-20s  %12i  %4.1f%\n",vg"/"item, QTE[item], 100*QTE[item]/tot) 
		} '|sort 
	echo
done
