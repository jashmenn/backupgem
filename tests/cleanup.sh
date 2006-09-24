#!/usr/bin/bash
LOOK_IN="/var/local/backups/mediawiki/sons"; COUNT=`ls -1 $LOOK_IN | wc -l`; MAX=14; if (( $COUNT > $MAX )); then let "OFFSET=$COUNT-$MAX"; i=1; for f in `ls -1 $LOOK_IN | sort`; do if (( $i <= $OFFSET )); then CMD="rm $LOOK_IN/$f"; echo $CMD; $CMD; fi; echo "$i $f"; let "i=$i + 1"; done; else true; fi
