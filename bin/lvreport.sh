#!/bin/bash
for I in $( pvs -o pv_name --noheadings  ) ; do 
	echo $I \($(lsblk ${I/[0-9]/}  -d  -o MODEL,REV,SIZE -n )\)
	pvs $I --all  --noheadings --segment --nosuffix --units m -o seg_size,vg_name,lv_name | sed 's/_[^ ]*//;s/\[//;s/ *$//' \
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
				printf("\t%s/%s\t%9i\t%4.1f%\n",vg,item, QTE[item], 100*QTE[item]/tot) 
		} '|sort 
done
