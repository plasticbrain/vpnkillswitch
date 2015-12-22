# VPN Killswitch Bash Script

VPN Killswitch is a simple bash script that prevents your real IP address and Internet activities from being revealed if you lose connection to your VPN. 



### How does it work?
VPN Killswitch uses `nmcli` to check the status of your VPN connection. In the event that connection is lost, `ifconfig down` is used to disconnect your ethernet adapter.



### Requirements
 * `nmcli` 
 * `libnotify`



### Setup & Usage

##### 1. Set the `device` variable:
````
device=eth0
````
(If you're not sure what to use, run `ifconfig` and use whichever device shows your external IP)


##### 2. Make the script executable:
````
sudo chmod +x vpnkillswitch.sh
````

##### 3. Run VPN Killswitch
````
sudo vpnkillswitch
````
VPN Killswitch needs to be run as `root` so it can disable your ethernet adapter.


### Restoring Internet Connection
To restore your internet connection run VPN Killswitch with the `up` parameter:
````
sudo vpnkillswitch up
````