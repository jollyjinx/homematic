#!/usr/bin/perl
#
# Description:  Tell Homematc CCU that Mac is in a specefic room. It find that out by 
#				- are the displays active
#					- which displays are connected
#				or	- which ethernet addresses are visible on Thunderbolt Ethernet
#
#               In my case that means that I'm in the office.
#               Background: If connected to ethernet the Mac is in the office
#
use strict;


my $ethernetneighbours  = "(8:96:d7:25:f8:71|a8:20:66:1:3:42|0:f:6f:3:3:bf|28:37:37:42:8b:cd|0:1a:22:4:51:9a|14:10:9f:d8:99:ff|80:ea:96:94:5a:66)";
my $knowndisplays       = "(00ffffffffffff0006102192d96201020e1201038040287828fe85a3574a9c2513505400000001010101010101010101010101010101bc1b00a0502017303020360081912100001ab06800a0a0402e603020360081912100001a000000ff004359383134303056584d500a00000000fc0043696e656d6120484|00ffffffffffff0006101e926c00fe020e0f010380311f782ecfb5a355499925105054000000d1000101010101010101010101010101253c80a070b0234030203600ef361100001a000000fc0043696e656d6120484420446973000000fc00706c61790a0000000000000000000000000000000000000000000)";
my $ccu2address         = "hmccu2";
my $hmccuvariable       = "presence.officeuser";
my $debug               = 1;


#
# nothing needs to be changed below this line
#

my $macusedinoffice     = 0;

{
    my $displayisactive = `ioreg -r  -c IODisplayWrangler |grep -o '"CurrentPowerState"=4'`;

    if( length($displayisactive) )
    {
        my $connecteddisplays = `ioreg -r -c IODisplay |grep 'IODisplayEDID'`;

        print "\tdisplays:".$connecteddisplays."\n" if $debug;

        if( $connecteddisplays =~ /$knowndisplays/ )
        {
            $macusedinoffice = 1;
        }
        else
        {
            my $arpoutput   = `arp -an`;

            if( $arpoutput =~ /$ethernetneighbours/i )
            {
                my $networksetupoutput  = `networksetup -listnetworkserviceorder`;

                $networksetupoutput =~ s/^(\(\d+\).*?)\n\(/\1\(/gm;

                foreach my $networksetupline (split(/\n+/,$networksetupoutput))
                {
                    print "\t".'$networksetupline='.$networksetupline."\n" if $debug;
                    
                    if( $networksetupline =~ /^\((\d+)\)\s*(.*?)\s*\([^\(\)]+Device:\s*(\S+\d+)\s*\)/ )
                    {
                        my($order,$networkinterfacename,$devicename) = ($1,$2,$3);
                    
                        print "\t".'($order,$networkport,$devicename)=',$order,$networkinterfacename,$devicename."\n" if $debug;
                        if(     ('Thunderbolt Ethernet' eq $networkinterfacename) )
                        {
                            if( $arpoutput =~ /\s$ethernetneighbours\s+on\s+$devicename\s/i )
                            {
                                print "Found Mac in office: $devicename\n" if $debug;
                                $macusedinoffice = 1;
                            }
                        }
                    }
                }
            }
        }
    }
}

my $wgetreturn=`curl -D - "http://$ccu2address:8181/rega.exe?state=dom.GetObject('$hmccuvariable').State($macusedinoffice)"`; # |egrep -o '<state>(false|true)</state></xml>$'`;

print "Wgetreturn: $wgetreturn\n" if $debug;

