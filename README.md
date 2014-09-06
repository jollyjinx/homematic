Homematic Scripts
-----------------

The following are scripts I use in conjunction with my Homematic installation. I do tend not to use additional modules / software on my systems, so things should work without additions.


Router Presence Script (presencedetection.sh)
------------------------

A script for routers to detect presence of specific devices (by ethernetaddress) or IP ranges (e.g. guests). On detection it will call a URL with a presence flag.
Presence is detected by using the arp table of the device and will call given URLs in the event a presence changes. Only changes will be transmitted so very low traffic is generated. No presence detections are lost as the script retries if the destination is not ready for reception.
This script runs on my router (a fritz!box, but should work on any unix based router).  Currently the script sets presence variables on a HomeMatic CCU2, but could be used for other systems as well.


Inventory.hms (homematic script)
-------------
Creates a inventory of your devices (in english or german) like this:

	104 Kanaele in 12 Geraeten 6 Geraetetypen:
	1x HM-RCV-50(CCU2 System), 7x HM-CC-RT-DN(Funk-Heizkoerperthermostat), 1x HM-LC-Sw4-SM(Funk-Schaltaktor 4-fach), 1x HM-LC-Sw1PBU-FM(Funk-Schaltaktor 1-fach fuer Markenschalter), 1x HM-ES-PMSw1-Pl(Funk-Schaltaktor mit Leistungsmessung), 1x HM-Sec-SC-2(Funk-Tuer-/ Fensterkontakt)



TurnHeatingOn.hms (homematic script)
-----------------------
This script automtically finds out all heating thermostats and turns the main switch for the heating system on depending on the actual and set temperatures as well as valve states of the thermostats.


ThermostatModeSwitch.hms (homematic script)
-----------------------
This script finds out all heating thermostats and sets them all to manual off state or auto mode depending on a switch state. So a single main switch can turn off all thermostats.


TurnBoilerOnAfterVacation.hms (homematic script)
-----------------------
This script turns my boiler when someone arrives at home and the boiler has not been turned on for 24 hours.
Usually that is the case after a vacation, then I want to make sure I can take a  shower instantly.
