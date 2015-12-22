#!/bin/bash
################################################################################
## VPN Killswitch
################################################################################
# Checks to make sure you are connected to a VPN. If your VPN connection is lost
# for any reason then VPN killswitch terminates your internet access by issuing
# a command to disconnect your network card. 
# 
# Requires:
#   * nmcli
#   * libnotify (notify-send)
#
################################################################################


## Set to whatever your internet device is
## if you're not sure, run "ifconfig" and see which device has your external IP
device=eth0



## How often, in minutes, to receive a reminder that you are connected to your
## VPN and that VPN Killswitch is running
alert=10

## How long (in ms) to display reminder messages
msg_timeout=5000

## Reminder alert urgency
## low|normal|critical
msg_urgency=normal

## Message Icon
## By default, libnotify looks for icons in /usr/share/icons/gnome/32x32/
## So any icon (minus the extension) in any of those subdirs should work
msg_icon_connected=security-high
msg_icon_disconnected=process-stop

## Message Category
## See: https://developer.gnome.org/notification-spec/
msg_category_connected=network.connected
msg_category_disconnected=network.disconnected






## No need to edit edit beyond this point ######################################

## Command to run that checks VPN status
check_cmd="nmcli -t -f vpn con status"

timeout=1
numchecks=0
alert_interval=$[$alert*60]

## Colors
txtred='\e[0;31m' # Red
txtgrn='\e[0;32m' # Green
txtwht='\e[0;37m' # White
txtredbld='\e[1;31m' # Red
txtgrnbld='\e[1;32m' # Green
txtwhtbld='\e[1;37m' # White
txtrst='\e[0m'    # Text Reset

appname='VPN Killswitch'


################################################################################
## Catch ctrl+c
################################################################################
control_c() {
	echo ""
	echo -e "[$appname] $(date) - $appname ${txtred}stopped${txtrst}"	
    `notify-send --icon=process-stop --expire-time=30000 --urgency=critical "$appname Stopped" "Your VPN connection is no longer being checked\n$(date)"` 
	exit $?
}
trap control_c SIGINT


################################################################################
## Make sure the script is being run as root 
## (so we can kill the network connection if the VPN disconnects)
################################################################################
if [[ $EUID -ne 0 ]]
then
    echo "$appname must be run as root so it stop your network device if you lose connection to your VPN"
    exit
fi

################################################################################
# Restore connection
################################################################################
if [ -n "$1" ] && [ $1 = "up" ]
then
    echo "[$appname] Restoring connection on $device..."
    ifconfig ${device} up
    exit
fi

################################################################################
## Make sure the user is connected to a VPN before continuing
################################################################################
if [[ ! $($check_cmd) =~ "yes" ]]
then
    echo "You do not appear to be connected to a VPN. Connect to a VPN first, and then run $appname"
    exit
fi

################################################################################
## Start monitoring the user's VPN connection
################################################################################
echo -e "[$appname] $(date) - $appname ${txtgrn}started${txtrst}. Press ctrl+c to exit."
`notify-send --icon=security-high --expire-time=5000 --urgency=normal "$appname Started" "You will receive a notification if you get disconnected from your VPN"` 

while :
do

    ## VPN is still connected
    if [[ $($check_cmd) =~ "yes" ]]
	then
		numchecks=$[$numchecks+1]

        ## Send a notification to remind the user they are connected to a VPN
        ## and that VPN Killswitch is still running
		if (( $numchecks%$alert_interval == 0 ))
		then
			`notify-send --icon=$msg_icon_connected "$appname" "VPN still connected"`
            echo -e "[$appname] $(date) - VPN connection status: ${txtgrn}Connected${txtrst}"
		fi

    ## No longer connected to VPN
	else

		## Kill the network connection
		`ifconfig $device down`
		
        ## Notify the user
		`notify-send --urgency=critical  --icon=$msg_icon_disconnected "$appname" "Disconnected from VPN\n$(date)"`
	   
        ## Print a message to stdout
        echo ""
        echo -e "${txtred}!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        echo "!!!!!                                                                      !!!!!"
        echo -e "!!!!!                           ${txtwhtbld}$appname${txtrst}${txtred}                             !!!!!"
        echo "!!!!!                                                                      !!!!!"
        echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        echo -e "${txtrst}"
        echo "$(date)"
        echo ""
        echo "It appears that you have lost connection to your VPN! To prevent your real IP"
        echo "from being revealed $appname has terminated internet connection on $device"
        echo ""
        echo "To re-enable your internet connection run the following command as root:"
        echo  ""
        echo -e "${txtgrnbld}$0 up${txtrst}"
        echo  ""
        echo -e "${txtwhtbld}Remember to reconnect to your VPN (and restart $appname) "
        echo -e "before you do anything \"sensitive\" online! ${txtrst}"
        echo ""
        echo ""
		exit
	
	fi

	sleep $timeout

done