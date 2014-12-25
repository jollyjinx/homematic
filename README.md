Homematic Scripts
-----------------

The following are scripts I use in conjunction with my Homematic installation. I do tend not to use additional modules / software on my systems, so things should work without additions.


WLAN Presence Script ([presencedetection.sh](presencedetection.sh))
------------------------

A script for routers to detect presence of specific devices (by ethernetaddress) or IP ranges (e.g. guests). On detection it will call a URL with a presence flag.
Presence is detected by using the arp table of the device and will call given URLs in the event a presence changes. Only changes will be transmitted so very low traffic is generated. No presence detections are lost as the script retries if the destination is not ready for reception.
This script runs on my router (a fritz!box, but should work on any unix based router).  Currently the script sets presence variables on a HomeMatic CCU2, but could be used for other systems as well.


Presence Aggregation ([presenceVariableAggregation.hms](presenceVariableAggregation.hms))
-------------------------------

Not all persons have a WLAN device to track their presence in the house. So I have variables that can be manually set, or set via a calendar/timetable.

Lets assume the following variables are set:
		
		presence.wlan.guests:		away
		presence.wlan.patrick:		PRESENT
		presence.wlan.isabel:		away
		
		presence.manual.guests:		away
		presence.manual.patrick:	away
		presence.manual.isabel:		PRESENT
	
		presence.calender.guests:	away
		presence.calender.patrick:	away
		presence.calender.isabel:	away
		.
		.
		.

The [presenceVariableAggregation.hms](presenceVariableAggregation.hms) script creates then aggregated presence variables:

		presence.any:			PRESENT			
		presence.guests:		away
		presence.patrick:		PRESENT
		presence.isabel:		PRESENT
		.
		.
		.

Those variables are the ones I use in the different scripts.



[PresenceTriggersTemperature.hms](PresenceTriggersTemperature.hms)
-------------------------------

This is the main script for my heating system. It sets the SET_TEMPERATURE on the thermostats when they are in automode. The SET_TEMPERATURE is depended if and which person is in a room, if windows or doors are open or people are presumed to be in a room cause a switch (e.g. lights, plugs) is engaged.

The script uses a table to know the preferences of the different person groups:

	presence.guests:  hall        0:00,17C   6:00,18.5C  7:30,19.5C  19:30,20C
					  living      0:00,17C               7:30,19C    19:30,20C
					  kitchen     0:00,17C   6:00,18.5C  7:30,20C    20:30,17C               
					  guests      0:00,17C               8:00:16C    21:00,17.5C             
	
	presence.patrick: hall        0:00,16C              7:30:18C    20:30,19C 
					  living      0:00,16C              7:30:17C    20:30,18C 
					  kitchen     0:00,16C              7:30,18C    20:30,17C               
					  office      0:00,16C              7:30,19.5C  19:30,16.5C             
					  sleeping    0:00,15C              8:00,10C    22:00,16C               
					  
 


[TurnHeatingOn.hms](TurnHeatingOn.hms)
-----------------------
This script automtically finds out all heating thermostats and turns the main switch for the heating system on depending on the actual and set temperatures as well as valve states of the thermostats.


[ThermostatModeSwitch.hms](ThermostatModeSwitch.hms)
-----------------------
This script finds out all heating thermostats and sets them all to manual off state or auto mode depending on a switch state. So a single main switch can turn off all thermostats.


[TurnBoilerOnAfterVacation.hms](TurnBoilerOnAfterVacation.hms)
-----------------------
This script turns my boiler when someone arrives at home and the boiler has not been turned on for 24 hours.
Usually that is the case after a vacation, then I want to make sure I can take a  shower instantly.


[Inventory.hms](Inventory.hms)
-------------
Creates a inventory of your devices (in english or german) like this:

	104 Kanaele in 12 Geraeten 6 Geraetetypen:
	1x HM-RCV-50(CCU2 System), 7x HM-CC-RT-DN(Funk-Heizkoerperthermostat), 1x HM-LC-Sw4-SM(Funk-Schaltaktor 4-fach), 1x HM-LC-Sw1PBU-FM(Funk-Schaltaktor 1-fach fuer Markenschalter), 1x HM-ES-PMSw1-Pl(Funk-Schaltaktor mit Leistungsmessung), 1x HM-Sec-SC-2(Funk-Tuer-/ Fensterkontakt)



