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
maximumcounter=45                                   # how many loops of looptime until somebody is no longer present
intialcounter=4                                     # default counter for each presence variable at start
variableprefix="presence.wlan."                     # prefix for the variables on the ccu2
someonename="any"                                   # variable name if someone is present
debug=false
$debug && looptime=5

#
# There is nothing below this line that needs to be changed 
#
#
RETURN_FAILURE=1
RETURN_SUCCESS=0


getorsetpresenceVariableState()
{
    local name=$1
    local setstate=$2
    
    if [ "$setstate" != "" ]
    then
        local currentstate=`getorsetpresenceVariableState $name`
        if [ "$currentstate" == "$setstate" ]
        then
            echo -n "$currentstate"
            return $RETURN_SUCCESS
        fi
    fi
    local wgetreturn=$(wget -q -O - "http://$ccu2address:8181/rega.exe?state=dom.GetObject('$variableprefix$name').State($setstate)"|egrep -o '<state>(false|true)</state></xml>$')

    if [ "<state>true</state></xml>" == "$wgetreturn" ]
    then
        echo -n "1"
        return $RETURN_SUCCESS
    fi
    
    if [ "<state>false</state></xml>" == "$wgetreturn" ]
    then
        echo -n "0"
        return $RETURN_SUCCESS
    fi
    echo -n "-1"
    return $RETURN_FAILURE
}

createPresenceVariableOnCCUIfNeeded()
{
    local name=$1

    getorsetpresenceVariableState $name >/dev/null  && return $RETURN_SUCCESS
    
    if [ ! -f /usr/bin/nc ]
    then
        echo "WARNING: /usr/bin/nc does not exist you need to create $variableprefix$name on CCU2 manually"
        return $RETURN_FAILURE
    fi
    
    local postbody="string v='$variableprefix$name';boolean f=true;string i;foreach(i,dom.GetObject(ID_SYSTEM_VARIABLES).EnumUsedIDs()){if(v==dom.GetObject(i).Name()){f=false;}};if(f){object s=dom.GetObject(ID_SYSTEM_VARIABLES);object n=dom.CreateObject(OT_VARDP);n.Name(v);s.Add(n.ID());n.ValueType(ivtBinary);n.ValueSubType(2);n.DPInfo(v#' is at home');n.ValueName1('anwesend');n.ValueName0('abwesend');n.State(false);dom.RTUpdate(0);}"
    local postlength=$(echo "$postbody" | wc -c)
    echo -e "POST /tclrega.exe HTTP/1.0\r\nContent-Length: $postlength\r\n\r\n$postbody" |nc "$ccu2address" 80 >/dev/null 2>&1

    getorsetpresenceVariableState $name >/dev/null
}


#
# main
#

for name in $@ $someonename
do
    createPresenceVariableOnCCUIfNeeded $name
    eval personcounter$name=$intialcounter
    eval ccupersonstate$name=`getorsetpresenceVariableState $name`
    eval samestatecounter$name=1
done


#
# This is the main loop to check if somebody is present
#
while true
do
    anygrepoutput=""
    arpoutput=$(arp -an |egrep -vi "$ignore"|grep 'at')

    for name in $@ $someonename
    do
        $debug && echo "Name: $name"
        
        if [ $name != $someonename ]
        then
            eval addresstocheck=\$$name
            grepoutput=$(echo "$arpoutput"|egrep -io "$addresstocheck")
        else
            grepoutput=$anygrepoutput
        fi
        
       
        if [ -n "$grepoutput" ];
        then
            $debug && echo "    Found in grepoutput"
            anygrepoutput=$anygrepoutput','$name
            newcounter=$maximumcounter
            newstate="1"
        else
            $debug && echo "    Did not find in grepoutput"
            eval currentcounter=\$personcounter$name
            newcounter=`expr $currentcounter - 1 \| 1`
            newstate="0"
        fi
        
        $debug && echo "    newcounter:$newcounter newstate:$newstate"

        if [ $newcounter -eq 1 -o $newcounter -eq $maximumcounter ]     
        then            
            eval oldstate=\$ccupersonstate$name

            $debug && echo "    oldstate: $oldstate"

            if [ "$newstate" != "$oldstate" ]
            then
                $debug && echo "    State differs setting on CCU immediately"
                
                eval ccupersonstate$name=`getorsetpresenceVariableState $name $newstate`
                eval samestatecounter$name=$maximumcounter
            else
                $debug && echo "    State same, counting 2nd Variable"
                
                eval samestatecounter=\$samestatecounter$name
                samestatecounter=`expr $samestatecounter - 1 \| 1`

                $debug && echo "    samestatecounter:$samestatecounter" 

                if [ $samestatecounter -eq 1 ]
                then
                    $debug && echo "    setting state:$newstate on CCU"
                    
                    eval ccupersonstate$name=`getorsetpresenceVariableState $name $newstate`
                    eval samestatecounter$name=$maximumcounter
                else
                    eval samestatecounter$name=$samestatecounter
                fi
            fi
        fi
        eval personcounter$name=$newcounter
    done
    
    sleep $looptime
    $debug && echo ; echo;
done




