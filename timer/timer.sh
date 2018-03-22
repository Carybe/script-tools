#!/bin/bash

MINUTES=$1

clear
for m in $(seq $MINUTES | sort -rn)
do
		(( m-- ))
        for s in {59..0}
        do
                echo -ne "$m minutes $s seconds "'\r'
                sleep 1
        done
done

zenity --warning --title="" --text="<span foreground='red' size='200000'>CHANGE\!</span>"
