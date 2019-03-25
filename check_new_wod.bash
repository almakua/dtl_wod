#!/bin/bash

# VARIABLES
TOKEN="800535467:AAF4PhStyrQU9T_HXjKSNWxw9_WwEphRnwo"
URL="https://api.telegram.org/bot${TOKEN}/sendMessage"
CHAT_ID="22423698"


#download version of the page
curl -o /root/check_wod/last.check https://legnano.dynamictraininglab.com/wod

# if the page is the same as last time, leave
if [[ "$(diff /root/check_wod/last.check /root/check_wod/prev.check 2>&1 >/dev/null; echo $?)" -eq "0" ]]; then
mv /root/check_wod/last.check /root/.trash
exit 1
fi

# start by putting the header into the file
echo "WOD" > /root/check_wod/today.wod
# add the date in the format like (monday 25 march 19) in the file
date  +%A" "%d" "%B" "%y >> /root/check_wod/today.wod
# do some magic with grep and sed to pull out the latest wod and put it into DA file
grep -B 20 "$(date +%d" "%B" "%y)" /root/check_wod/last.check | egrep -v "div|img|class|WOD" | sed -e 's/<br>//g; s/\&\#39\;/ min/g; s/<p>//g; s/<\/p>//g; s/<p//g' | sed -e 's/^[ \t]*//' >> /root/check_wod/today.wod

# now compare the wod with the latest one sent to the bot, if the same, 
if [[ "$(diff /root/check_wod/today.wod /root/check_wod/old.wod 2>&1 > /dev/null; echo $?)" -eq "0" ]]; then
    if [[ "$(grep "$(date --date="Tomorrow" +%d" "%B" "%y)" last.check 2>&1  > /dev/null; echo $?)" -eq "0" ]]; then 
        echo "WOD" > /root/check_wod/tomorrow.wod
        date --date="Tomorrow" +%A" "%d" "%B" "%y >> /root/check_wod/tomorrow.wod
        grep -B 20 "$(date --date="Tomorrow" +%d" "%B" "%y)" /root/check_wod/last.check | egrep -v "div|img|class|WOD" | sed -e 's/<br>//g; s/\&\#39\;/ min/g; s/<p>//g; s/<\/p>//g; s/<p//g' | sed -e 's/^[ \t]*//' >> /root/check_wod/tomorrow.wod
        cp -prf /root/check_wod/tomorrow.wod /root/check_wod/new.wod
        MESSAGE="$(cat /root/check_wod/new.wod)"
        # send message to telegram bot
        curl -s -X POST ${URL} -d chat_id=${CHAT_ID} -d text="${MESSAGE}"
        mv /root/check_wod/new.wod /root/check_wod/old.wod
    fi

else
    cp -prf /root/check_wod/today.wod /root/check_wod/new.wod
    MESSAGE="$(cat /root/check_wod/new.wod)"
    # send message to telegram bot
    curl -s -X POST ${URL} -d chat_id=${CHAT_ID} -d text="${MESSAGE}"
    mv /root/check_wod/new.wod /root/check_wod/old.wod
fi

exit 0