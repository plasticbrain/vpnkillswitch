#!/bin/bash

################################################################################
## VPN Check
################################################################################
#  A simple script that uses nmcli to determine if there's an active VPN
#  connection. If not, an alert is sent through notify-send.
################################################################################


## How often, in minutes, to receive an alert if you aren't connected to a VPN
alert=5

## Alert level
## low|normal|critical
msg_urgency=normal

## How long to display the messages
## Uusing "critical" above will make the messages sticky, overriding this value
msg_timeout=10000

## Message Icon
## By default, libnotify looks for icons in /usr/share/icons/gnome/32x32/
## So any icon (minus the extension) in any of those subdirs should work
msg_icon=dialog-error

## Message Category
## See: https://developer.gnome.org/notification-spec/
msg_category=network.disconnected



## Don't edit beyond here ######################################################


timeout=1
numfails=0
alert_interval=$[$alert*60]
appname='VPN Check'

while :
do

    ## Use nmcli to see if there are any active VPN connections
    VPNSTATUS=`nmcli -t -f vpn con status`

    if [[ ! ${VPNSTATUS[*]} =~ "yes" ]]
    then
        numfails=$[$numfails+1]

        if [ $numfails = 1 ] || (( $numfails%$alert_interval == 0 ))
        then
            `notify-send --icon=$msg_icon --expire-time=$msg_timeout --urgency=$msg_urgency --category=$msg_category "No VPN Detected!" "You do not appear to be connected to a VPN \n$(date)"` 
        fi
    fi

    sleep $timeout

done