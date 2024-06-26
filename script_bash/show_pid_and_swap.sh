#!/bin/bash
SUM=0
OVERALL=0
for DIR in `find /proc/ -maxdepth 1 -type d -regex "^/proc/[0-9]+"`
do
PID=`echo $DIR | cut -d / -f 3`
PROGNAME=`ps -p $PID -o comm --no-headers`
for SWAP in `grep VmSwap $DIR/status 2>/dev/null | awk '{ print $2 }'`
do
let SUM=$SUM+$SWAP
done
if (( $SUM > 0 )); then
PrintLn=$(ps auxw|grep $PID)
MB=#$(echo $SUM/1024|bc)
echo "PID=$PrintLn swapped $MB MB ($PROGNAME)"
fi
let OVERALL=$OVERALL+$SUM
SUM=0
done
MBSUM=$(echo $OVERALL/1024|bc)
echo "Overall swap used: $MBSUM MB"
