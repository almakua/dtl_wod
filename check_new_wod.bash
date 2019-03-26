#!/bin/bash

source /root/dtl_wod/.telegram.vars

# VARIABLES
URL="https://api.telegram.org/bot${TOKEN}"
CHAT_LIST="$(curl ${URL}/getUpdates | sed -e 's/[{}]/''/g' | awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | grep "\"chat\":\"id\":" | sort | uniq | cut -d: -f3)"


#download version of the page
#curl -o /root/check_wod/last.check https://legnano.dynamictraininglab.com/wod

# if the page is the same as last time, leave
if [[ "$(diff /root/check_wod/last.check /root/check_wod/prev.check 2>&1 >/dev/null; echo $?)" -eq "0" ]]; then
mv /root/check_wod/last.check /root/.trash
exit 1
fi

# start by putting the header into the file
echo "WOD" > /root/check_wod/today.wod
# add the date in the format like (monday 25 march 19) in the file
date  +%A" "%d" "%B" "%y >> /root/check_wod/today.wod
echo
# do some magic with grep and sed to pull out the latest wod and put it into DA file
grep -B 20 "$(date +%d" "%B" "%y)" /root/check_wod/last.check | egrep -v "div|img|class|WOD" | sed -e 's/<br>//g; s/\&\#39\;/ min/g; s/<p>//g; s/<\/p>//g; s/<p//g' | sed -e 's/^[ \t]*//' >> /root/check_wod/today.wod

# now compare the wod with the latest one sent to the bot, if the same, 
if [[ "$(diff /root/check_wod/today.wod /root/check_wod/old.wod 2>&1 > /dev/null; echo $?)" -eq "0" ]]; then
    if [[ "$(grep "$(date --date="Tomorrow" +%d" "%B" "%y)" /root/check_wod/last.check 2>&1  > /dev/null; echo $?)" -eq "0" ]]; then 
        echo "WOD" > /root/check_wod/tomorrow.wod
        date --date="Tomorrow" +%A" "%d" "%B" "%y >> /root/check_wod/tomorrow.wod
        grep -B 20 "$(date --date="Tomorrow" +%d" "%B" "%y)" /root/check_wod/last.check | egrep -v "div|img|class|WOD" | sed -e 's/<br>//g; s/\&\#39\;/ min/g; s/<p>//g; s/<\/p>//g; s/<p//g' | sed -e 's/^[ \t]*//' >> /root/check_wod/tomorrow.wod
        cp -prf /root/check_wod/tomorrow.wod /root/check_wod/new.wod
        MESSAGE="$(cat /root/check_wod/new.wod)"
        # send message to telegram bot
        for CHAT_ID in ${CHAT_LIST}
            do
            curl -s -X POST ${URL}/sendMessage -d chat_id=${CHAT_ID} -d text="${MESSAGE}"
        done
        mv /root/check_wod/new.wod /root/check_wod/old.wod
    fi

else
    cp -prf /root/check_wod/today.wod /root/check_wod/new.wod
    MESSAGE="$(cat /root/check_wod/new.wod)"
    # send message to telegram bot
    for CHAT_ID in ${CHAT_LIST}
        do
        echo curl -s -X POST ${URL}/sednMessages -d chat_id=${CHAT_ID} -d text="${MESSAGE}"
    done
    mv /root/check_wod/new.wod /root/check_wod/old.wod
fi

exit 0