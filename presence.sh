#!/bin/sh
# presence detection for home router (e.g. Fritzbox)
# sets variables on homematics ccu2 in this incarnation (change the wget)
# can be found on: https://github.com/jollyjinx/homematic
#
#	install this script on a fritzbox and start it after reboot via debug.cfg
#

hmccu2="hmccu2"					# ip address of ccu2
set patrick guests				# variables to set on the ccu2 and their presence check
patrick="a:f5:90:44:24:a4"
guests="5:77:4f:e8:87:77|89:0b:91:ea:d2:33|d0:8d:a6:d7:f1:5a|c9:57:54:b8:ae:c1|192.168.0.1[5-8][0-9]"

looptime=30	# how often we check in seconds
presence=45	# how many loops until somebody is no longer present


for name in $@
do
	eval oldpresence$name=4  # on startup should quickly tell if a person is not present
done

while true
do
        arpoutput=$(arp -an |grep at)

        for name in $@
        do
                eval addresstocheck=\$$name
                grepoutput=$(echo $arpoutput|egrep -i "$addresstocheck")

               	eval oldvalue=\$oldpresence$name
				eval oldstate=\$oldstate$name

               	if [ -n "$grepoutput" ];
                then
                		eval oldpresence$name=$presence
                        isalive=1
                else
                		eval oldpresence$name=`expr $oldvalue - 1 \| 1 `
                        isalive=0
                fi

               	eval newvalue=\$oldpresence$name

				if [ $newvalue != $oldvalue -a \( $newvalue = 1 -o $newvalue = $presence \) -a \( $isalive != "$oldstate" \) ] ;
                then
					#echo "Changing state: $name $isalive $newvalue $oldstate"
					wget -q -O /dev/null "http://$hmccu2:8181/rega.exe?state=dom.GetObject('$name').State($isalive)"
					eval oldstate$name=$isalive
                fi
        done

        sleep $looptime
done

