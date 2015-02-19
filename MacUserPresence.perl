#!/usr/bin/perl
#
# Description:  Tell Homematc CCU that Mac is beeing used (in a specefic room). It finds that out by 
#               - are the displays active
#                   - which displays are connected
#               or  - which ethernet addresses are visible on Thunderbolt Ethernet
#
#               In my case that means that I'm in the office.
#               Background: If connected to ethernet the Mac is in the office
#
#
# HowTo:	1. Set the $ccunetworkaddress variable to the ip-address/name your CCU has.
#			2. Set the ccupresencevariable variable to the name the variable that presents
#				the status of the mac on the ccu. This variable will be created if needed.
#			3. If your Mac is stationary skip 3.*
#				3.1	If the presence variable should be set only when a specific display is 
#				connected or ethernet addresses are seen on the ethernet ( wlan or other 
#				networks will be ignored ) you need to set the $ethernetneighbours and 
#				$knowndisplays accordingly. 
#				Find out your ethernet partners via the 'arp -an' command line
#				Find out your displays edids with 'ioreg -lw0 |grep -A 15 -B 5 -i IODisplayEDID' 
#			4. Start the script in the command line with the $debug variable to 1 to see if it
#				works.
#			5. Add the script to your crontab with an entry like:
#				SHELL=/bin/zsh
#				*/3 * * * *	/usr/bin/perl /Users/jolly/Binaries/MacUserPresence.perl >/dev/null 2>&1
#			
#			To see what's happening you can call the script with --debug option
#
use strict;

my $ccunetworkaddress	= "hausautomation.jinx.eu";
my $ccupresencevariable	= "presence.mac.officeuser";

my $ethernetneighbours  = undef;            # will be checked if set
my $knowndisplays       = undef;            # will be checked if set


###
#	examples for ethernet neighbours. Find out what to set with 'arp -an'
#
#my $ethernetneighbours  = "(8:96:d7:25:f8:71|a8:20:66:1:3:42|0:f:6f:3:3:bf|28:37:37:42:8b:cd|0:1a:22:4:51:9a|14:10:9f:d8:99:ff)";	# plt
#my $ethernetneighbours  = "(5C:F9:38:C5:98:C1|00:1A:22:04:9D:C4|3C:77:E6:61:DC:9E|00:1B:63:A2:88:F9|00:1C:B3:7A:35:BD|C8:02:10:05:D6:04|C0:25:06:77:36:31)";	# bgb
#
#
#	examples for display edids. Find out what to set with  'ioreg -lw0 |grep -A 15 -B 5 -i IODisplayEDID'
#my $knowndisplays       = "(00ffffffffffff0006102192d96201020e1201038040287828fe85a3574a9c2513505400000001010101010101010101010101010101bc1b00a0502017303020360081912100001ab06800a0a0402e603020360081912100001a000000ff004359383134303056584d500a00000000fc0043696e656d6120484|00ffffffffffff0006101e926c00fe020e0f010380311f782ecfb5a355499925105054000000d1000101010101010101010101010101253c80a070b0234030203600ef361100001a000000fc0043696e656d6120484420446973000000fc00706c61790a0000000000000000000000000000000000000000000)";
#


#
# nothing needs to be changed below this line
#
my $debug               = grep(/^\-?\-?debug$/i,@ARGV);
my $macusedinoffice     = 0;

CCU2::createBoolVariableIfNeeded($ccunetworkaddress,$ccupresencevariable);

if( displayisactive() )
{
    print "Display is active.\n" if $debug;
    

    if( $ethernetneighbours && $knowndisplays )
    {
    	print "Will check for known ethernet neighbours and known displays...\n" if $debug;
        $macusedinoffice = knownneighboursonethernet($ethernetneighbours) && knowndisplaysareconnected($knowndisplays);
        print "...".($macusedinoffice?"both found":"did not find them both")."\n" if $debug;
    }
    elsif( $ethernetneighbours )
    {
    	print "Will check for known ethernet neighbours ...\n" if $debug;
        $macusedinoffice = knownneighboursonethernet($ethernetneighbours);
        print "...".($macusedinoffice?"found":"did not find")." them.\n" if $debug;
    }
    elsif( $knowndisplays )
    {
    	print "Will check if known displays are attached ...\n" if $debug;
        $macusedinoffice = knowndisplaysareconnected($knowndisplays);
        print "...".($macusedinoffice?"found":"did not find")." them.\n" if $debug;
    }
    else
    {
        $macusedinoffice = 1;
    }
}
else
{
    print "Display not active\n" if $debug;
}

print "Resulting mac office user state: is ".($macusedinoffice?'':' not ')."active \n" if $debug;

sendmacuserstate($macusedinoffice);

exit;



sub displayisactive
{
    my $displayisactive     = `/usr/sbin/ioreg -r  -c IODisplayWrangler |grep -o '"CurrentPowerState"=4'`;
    return length $displayisactive == 0 ? 0: 1
}

sub knowndisplaysareconnected
{

    my $connecteddisplays = `/usr/sbin/ioreg -r -c IODisplay |grep 'IODisplayEDID'`;

    print "\tdisplays:".$connecteddisplays."\n" if $debug>1;

    if( $connecteddisplays =~ /$knowndisplays/ )
    {
        print "\tFound display\n" if $debug;
        return 1;
    }
    return 0;
}


sub knownneighboursonethernet
{
    my ($ethernetneighbours) = @_;
    my $arpoutput   = `/usr/sbin/arp -an`;

    if( $arpoutput =~ /$ethernetneighbours/i )
    {
        my $networksetupoutput  = `/usr/sbin/networksetup -listnetworkserviceorder`;

        $networksetupoutput =~ s/^(\(\d+\).*?)\n\(/\1\(/gm;

        foreach my $networksetupline (split(/\n+/,$networksetupoutput))
        {                    
            #print "\t".'$networksetupline='.$networksetupline."\n" if $debug;
            
            if( $networksetupline =~ /^\((\d+)\)\s*(.*?)\s*\([^\(\)]+Device:\s*(\S+\d+)\s*\)/ )
            {
                my($order,$networkinterfacename,$devicename) = ($1,$2,$3);
            
                print "\t".'($order,$networkport,$devicename)=',$order,$networkinterfacename,$devicename."\n" if $debug>1;
                if(  $networkinterfacename =~ /Ethernet/i )
                {
                    print "Found \t".'($order,$networkport,$devicename)='.$order.','.$networkinterfacename.','.$devicename."\n" if $debug > 1;
                    if( $arpoutput =~ /\s$ethernetneighbours\s+on\s+$devicename\s/i )
                    {
                        print "\tFound Ethernet to be correct in office: $& $devicename\n" if $debug;
                        return 1;
                    }
                }
            }
        }
    }
    return 0;
}


sub sendmacuserstate
{
    my($macuserstate) = @_;

    my $wgetreturn=`/usr/bin/curl "http://$ccunetworkaddress:8181/rega.exe?state=dom.GetObject('$ccupresencevariable').State($macusedinoffice)" 2>/dev/null` ; # |egrep -o '<state>(false|true)</state></xml>$'`;
    print "\ncurl return: $wgetreturn\n" if $debug;
}

package CCU2;

sub getVariable
{
    my($ccuaddress,$variablename) = @_;

	my $curlresult = `/usr/bin/curl -D - "http://$ccuaddress:8181/rega.exe?state=dom.GetObject('$variablename').State()" 2>/dev/null`;
	
	if( $curlresult =~ m#<state>(.*)</state></xml>$# )
	{
		return undef	if $1 =~ /^null$/i;
		return 1		if $1 =~/^true$/i;
		return 0		if $1 =~/^false$/i;
		return $1;
	}
	else
	{
		print STDERR "Did not get correct result from request to ccu: $curlresult\n"
	}
	return undef
}



sub createBoolVariableIfNeeded()
{
    my($ccuaddress,$variablename) = @_;

	my $value = CCU2::getVariable($ccuaddress,$variablename);
	if( undef == $value )
	{
		my $postbody="string v='$variablename';boolean f=true;string i;foreach(i,dom.GetObject(ID_SYSTEM_VARIABLES).EnumUsedIDs()){if(v==dom.GetObject(i).Name()){f=false;}};if(f){object s=dom.GetObject(ID_SYSTEM_VARIABLES);object n=dom.CreateObject(OT_VARDP);n.Name(v);s.Add(n.ID());n.ValueType(ivtBinary);n.ValueSubType(2);n.DPInfo(v#' is ');n.ValueName1('true');n.ValueName0('false');n.State(false);dom.RTUpdate(0);}";
		
		system('/usr/bin/curl','--data',$postbody,"http://$ccuaddress/tclrega.exe","2>/dev/nulL") || die "Cant execute curl";	
	    return CCU2::getVariable($ccuaddress,$variablename);
	}
	return $value;
}



