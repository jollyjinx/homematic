#!/bin/sh
#
# presence detection for home router (e.g. Fritzbox)
# It sets variables to true/falso on the CCU2 depending on the presence of that person/group
# This script can be found on: https://github.com/jollyjinx/homematic
#
# You need to adjust the script to your network setup, so read on:
#
# 1. Adjust the network addresses and names for the persons in this script
# 2. Install this script on your router, so it starts after reboot (on a fritzbox via debug.cfg)
# 4. enjoy
#
# Ajusting this script
# --------------------
# I'm using variables on the CCU2 for presence detection:
# 
# presence.patrick  is set to beeing present when his ethernet address shows up
# presence.guests   is set when their ethernet addresses show up or devices in a network range
# presence.any      is set when patrick or guests is set.
# 
# My local network is set up to be in 192.168.0.0 - 192.168.0.255 
# Stationary devices are in the range 192.168.0.0-192.168.0.139 and 192.168.0.200-192.168.0.255
# Guests are either in the guest network 192.168.179.* or in the range 192.168.0.140-192.168.0.199
#
# As my network setup is different than yours you have to adjust the variable regular expressions
# to your needs
#
#
# At the start of the script presence variables are created on the box in case they don't exist.
# This script uses 'nc' for creating the presense variables on the CCU2 and wget to setting the variables 
#
#
# Variables for you to change:
#
ccu2address="hmccu2"                                # ip address or network name of CCU2
set patrick guests                                  # variables to set on the CCU2 and their presence check
patrick="80:ea:96:94:5a:66"                         # patricks presence detection device (iphone)
guests="d0:8d:a6:d7:f1:5a|c9:57:54:b8:ae:c1|192.168.0.1[4-9][0-9]|192.168.179.[1-2]?[0-9]+"

#
# The next variables are usually nothing you need to change
#
ignore="<incomplete>|at[\t ]+(00:0c:29|00:50:56):"  # ignore incomplete and vmware addresses
looptime=30                                         # how often we check in seconds
countsaspresent=45                                  # how many loops of looptime until somebody is no longer present
intialpresencecount=4                               # default counter for each presence variable at start
variableprefix="presence.wlan."                     # prefix for the variables on the ccu2
someonename="any"                                   # variable name if someone is present
 
#
# There is nothing below this line that needs to be changed 
#
# creating variables on CCU2 if they don't exist and set currentpresence to initialpresense
#
for name in $@ $someonename
do
    postbody="string v='$variableprefix$name';boolean f=true;string i;foreach(i,dom.GetObject(ID_SYSTEM_VARIABLES).EnumUsedIDs()){if(v==dom.GetObject(i).Name()){f=false;}};if(f){object s=dom.GetObject(ID_SYSTEM_VARIABLES);object n=dom.CreateObject(OT_VARDP);n.Name(v);s.Add(n.ID());n.ValueType(ivtBinary);n.ValueSubType(2);n.DPInfo(v#' is at home');n.ValueName1('anwesend');n.ValueName0('abwesend');n.State(false);dom.RTUpdate(0);}"
    postlength=$(echo "$postbody" | wc -c)
    echo -e "POST /tclrega.exe HTTP/1.0\r\nContent-Length: $postlength\r\n\r\n$postbody" |nc "$ccu2address" 80 >/dev/null 2>&1
    eval currentpresence$name=$intialpresencecount
done

#
# This is the main loop to check if somebody is present
#
while true
do
    anyoutput=""
    arpoutput=$(arp -an |egrep -vi "$ignore"|grep 'at')

    for name in $@ $someonename
    do
        if [ $name != $someonename ]
        then
            eval addresstocheck=\$$name
            grepoutput=$(echo "$arpoutput"|egrep -i "$addresstocheck")
            # echo "Found $name found:$grepoutput"
        else
            grepoutput=$anyoutput
        fi
        
        eval currentpresence=\$currentpresence$name
        eval currentstate=\$currentstate$name
        
        if [ -n "$grepoutput" ];
        then
            eval currentpresence$name=$countsaspresent
            anyoutput="1"
            isalive="1"
        else
            eval currentpresence$name=`expr $currentpresence - 1 \| 1 `
            isalive="0"
        fi
        
        eval newvalue=\$currentpresence$name
        
        if [ $newvalue -ne $currentpresence -a \( $newvalue -eq 1 -o $newvalue -eq $countsaspresent \) -a \( $isalive != "$currentstate" \) ]
        then
            # echo "Changing state name:$name currentpresence:$currentpresence currentstate:$currentstate isalive:$isalive newvalue:$newvalue"
            didsetvalue=$(wget -q -O - "http://$ccu2address:8181/rega.exe?state=dom.GetObject('$variableprefix$name').State($isalive)"|egrep '<state>(false|true)<\/state><\/xml>$')
        
            if [ -n "$didsetvalue" ];
            then
                eval currentstate$name=$isalive
            else
                eval currentpresence$name=$currentpresence
            fi
        fi
    done
    
    sleep $looptime
done
