#!/bin/sh
# presence detection for home router (e.g. Fritzbox)
# sets variables on homematics ccu2 in this incarnation (change the wget)
# can be found on: https://github.com/jollyjinx/homematic
#
#   install this script on your router start it after reboot (on a fritzbox via debug.cfg)
#
# boolean variables on the homematic are named 'patrick' and 'guests'
# patrick is set to beeing present when his ethernet address shows up
# guests are present when there eternet addresses show up or specific network
# IP addresses 192.168.0.140-192.168.0.199 or 192.168.179.* (fritzbox guest network)
# are beeing used.
# At the start of the script variables are created on the box in case they don't exist.


hmccu2="hmccu2"                 # ip address or netowrk name of ccu2
set patrick guests              # variables to set on the ccu2 and their presence check
patrick="a:f5:90:44:24:a4"      # patricks presense detection device (iphone)
guests="5:77:4f:e8:87:77|89:0b:91:ea:d2:33|d0:8d:a6:d7:f1:5a|c9:57:54:b8:ae:c1|192.168.0.1[4-9][0-9]|192.168.179.[1-2]?[0-9]+"

ignore="<incomplete>|at[\t ]+(00:0c:29|00:50:56):"  # ignore incomplete and vmware addresses
looptime=30                                         # how often we check in seconds
countsaspresent=45                                  # how many loops until somebody is no longer present


# nothing needs to be changed below this line

for name in $@
do
    postbody="string v='$name';boolean f=true;string i;foreach(i,dom.GetObject(ID_SYSTEM_VARIABLES).EnumUsedIDs()){if(v==dom.GetObject(i).Name()){f=false;}};if(f){object s=dom.GetObject(ID_SYSTEM_VARIABLES);object n=dom.CreateObject(OT_VARDP);n.Name(v);s.Add(n.ID());n.ValueType(ivtBinary);n.ValueSubType(2);n.DPInfo(v#' is at home');n.ValueName1('anwesend');n.ValueName0('abwesend');n.State(false);dom.RTUpdate(0);}"
    postlength=$(echo $postbody | wc -c)
    echo -e "POST /tclrega.exe HTTP/1.0\r\nContent-Length: $postlength\r\n\r\n$postbody" |nc "$hmccu2" 80 >/dev/null 2>&1
    eval currentpresence$name=4
done


while true
do
    arpoutput=$(arp -an |egrep -vi "$ignore"|grep 'at')
    
    for name in $@
    do
        eval addresstocheck=\$$name
        grepoutput=$(echo $arpoutput|egrep -i "$addresstocheck")
        
        eval currentpresence=\$currentpresence$name
        eval currentstate=\$currentstate$name
        
        if [ -n "$grepoutput" ];
        then
            eval currentpresence$name=$countsaspresent
            isalive="1"
        else
            eval currentpresence$name=`expr $currentpresence - 1 \| 1 `
            isalive="0"
        fi
        
        eval newvalue=\$currentpresence$name
        
        if [ $newvalue -ne $currentpresence -a \( $newvalue -eq 1 -o $newvalue -eq $countsaspresent \) -a \( $isalive != "$currentstate" \) ]
        then
            #echo "Changing state name:$name currentpresence:$currentpresence currentstate:$currentstate isalive:$isalive newvalue:$newvalue"
            didsetvalue=$(wget -q -O - "http://$hmccu2:8181/rega.exe?state=dom.GetObject('$name').State($isalive)"|egrep '<state>(false|true)<\/state><\/xml>$')
        
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
