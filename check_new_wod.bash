#!/bin/bash
#download version of the page
curl -o /root/check_wod/last.check https://legnano.dynamictraininglab.com/wod

# if the page is the same as last time, leave
if [[ "$(diff /root/check_wod/last.check /root/check_wod/prev.check; echo $?)" -eq "0" ]]; then
exit 1
fi

echo "WOD" > /root/check_wod/new.wod
date  +%d" "%B" "%y >> /root/check_wod/new.wod
grep -B 20 "$(date +%d" "%B" "%y)" /root/check_wod/last.check | egrep -v "div|img|class|WOD" | sed -e 's/<br>//g; s/\&\#39\;/ min/g; s/<p>//g; s/<\/p>//g; s/<p//g' | sed -e 's/^[ \t]*//' >> /root/check_wod/new.wod

if [[ "$(diff /root/check_wod/new.wod /root/check_wod/old.wod; echo $?)" -eq "0" ]]; then
    echo "WOD" > /root/check_wod/new.wod
    date --date="Tomorrow" +%d" "%B" "%y >> /root/check_wod/new.wod
    grep -B 20 "$(date --date="Tomorrow" +%d" "%B" "%y)" /root/check_wod/last.check | egrep -v "div|img|class|WOD" | sed -e 's/<br>//g; s/\&\#39\;/ min/g; s/<p>//g; s/<\/p>//g; s/<p//g' | sed -e 's/^[ \t]*//' >> /root/check_wod/new.wod
fi

exit 0