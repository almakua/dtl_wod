#!/bin/bash
# bin/dtlbotwod.bash

############# START #############


################ START VARIABLES' SECTION #############
# set up home dir
homedir="$(realpath $(dirname $0))/../."
# load token file
source ${homedir}/configs/telegram.vars
# telegram API base url
URL="https://api.telegram.org/bot${TOKEN}"
# logfile configurations
LOGFILE=${homedir}/logs/dtlbotwod.log
RETAIN_NUM_LINES=1000
############# END VARIABLES' SECTION #############


############# START FUNCTIONS' SECTION #############

#
function logsetup {
    TMP=$(tail -n $RETAIN_NUM_LINES $LOGFILE 2>/dev/null) && echo "${TMP}" > $LOGFILE
    exec > >(tee -a $LOGFILE)
    exec 2>&1
}

#
function log {
    echo "[$(date --rfc-3339=seconds)]: $*"
}

#
function env_setup () {
    # check if the token file exists
    if [[ -f ${homedir}/config/telegram.vars ]]; then
        log  "############# TOKEN File ${homedir}/config/telegram.vars does not exists. Exiting... #############"
        exit 1
    fi
    # create the necessary directories
    dirlist="logs work"
    for dirs in dirlist;
    do
        [[ -d ${homedir}/${dir} ]] || mkdir -p ${homedir}/${dir}
    done
    # verify if the previous check exists, if not, create it
    [[ -f ${homedir}/work/prev.check ]] || touch ${homedir}/work/prev.check
}

#
function update_chatlist () {
    log "Updating open chat list"
    mv ${homedir}/work/chat.list ${homedir}/work/chat.list.pre
    curl -s ${URL}/getUpdates | sed -e 's/[{}]/''/g' | awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | grep "\"chat\":\"id\":" | sort | uniq | cut -d: -f3 >> ${homedir}/work/chat.list.pre
    sort ${homedir}/work/chat.list.pre | uniq > ${homedir}/work/chat.list
}

#
function create_wod () {
    log "Create WOD file for ${1}"
    echo "WOD" > ${homedir}/work/new.wod
    echo >> ${homedir}/work/new.wod
    date --date="${1}"  +%A" "%d" "%B" "%y >> ${homedir}/work/new.wod
    echo >> ${homedir}/work/new.wod
    grep -B 20 "$(date --date="${1}" +%d" "%B" "%y)" ${homedir}/work/last.check | egrep -v "div|img|class|WOD" | sed -e 's/<br>//g; s/\&\#39\;/ min/g; s/<p>//g; s/<\/p>//g; s/<p//g; s/&#160;/ /g' | sed -e 's/^[ \t]*//' >> ${homedir}/work/new.wod
    echo >> ${homedir}/work/new.wod
}

#
function send_message () {
    for chat_id in $(cat ${homedir}/work/chat.list)
    do
        log "Sending WOD to ${chat_id}"
        curl -s -X POST ${URL}/sendMessage -d chat_id=${chat_id} -d text="$(cat ${homedir}/work/new.wod)"
    done
    mv /root/check_wod/new.wod /root/check_wod/old.wod
}

############# END FUNCTIONS' SECTION #############

############# START MAIN' SECTION #############
# setup env and check if something is amiss
env_setup

# setup logfile
logsetup

log "############# Starting... #############"

log "Check if a new WOD has been released"

# download a newer version of the wod page
curl -s -o ${homedir}/work/last.check https://legnano.dynamictraininglab.com/wod

# if the page is the same as last time, leave
if [[ "$(diff ${homedir}/work/last.check ${homedir}/work/prev.check 2>&1 >/dev/null; echo $?)" -eq "0" ]]; then
    log "############# No new WOD released. Exiting... #############" 
    # Cleanup
    mv ${homedir}/work/last.check /root/.trash
    exit 2
fi
log "New WOD Released"
if [[ "$(grep "$(date --date="tomorrow" +%d" "%B" "%y)" ${homedir}/work/last.check 2>&1  > /dev/null; echo $?)" -eq "0" ]]; then
    log "Created WOD description for tomorrow's WOD"
    create_wod tomorrow
else
    log "Created WOD description for today's WOD"
    create_wod today
fi

log "Notifying everyone of the new release"
send_message

log "############# Work completed. Exiting... #############"

############# END MAIN' SECTION #############

exit 0

############# END #############