Hallo Miteinander,

ich stelle hier mal meine Homematic Steuerung vor, vielleicht interessiert es ja den Ein oder Anderen. Meine Heizungsteuerung ist Anwesenheitsbasiert. D.h. wenn jemand im  Raum ist ( weil z.B. der Lichtschalter gedrückt wurde ) oder er zeitlich meist dort ist (z.B. Morgens in der Küche), dann wird die Heizung entsprechend gesteuert. 

Die Scripte laufen auf einer unveränderten CCU2 - sowie die Anwesenheitserkennung des WLANs auf einer Fritzbox. Alle meine Scripte finden sich unter [url]https://github.com/jollyjinx/homematic[/url].


Heizungssteuerung Hauptschalter
-------------------------------

Angefangen habe ich mit Homematic, da ich eine gebrauchte Gasbrennwertheizung bei mir eingebaut habe. Ein ganz einfaches Modell mit Brenner und Boiler. Die Gasheizung hat natürlich keinen HomeMatic Anschluss ;-( und noch schlimmer die Gasheizung hat nur ein einziges Führungstermostat. Das ist dafür vorgesehen um einen Raum (meist das Wohnzimmer) der Heizung mitzuteilen ob sie nun heizen soll oder nicht.

Da ich zu Hause arbeite trifft das mit dem Führungsraum aber auf mich nicht zu. Tagsüber bin ich im Büro und Abends im Wohnzimmer - kein einzelner Führungsraum. Deshalb habe ich mir mal das original Thermostat der Heizung mal  genauer angesehen. Das ist einfach nur ein potentialfreies Relais. Da wusste ich schon mal, dass ich mit einem HM-LC-Sw4-SM das Thermostat des Führungraums ersetzen kann.

An die Heizköper habe ich die normalen HM-CC-RT-DN Thermostate angeschraubt. Mit einem einfachen Script [url]https://github.com/jollyjinx/homematic/blob/master/TurnHeatingOn.hms[/url] schalte ich nun seit letzten März die Heizung entsprechend ein oder aus. Die Heizung erkennt selbtständig an Vor- und Rücklauf und wieviel der Brenner brennen muss, da habe ich nichts geändert. Ich übernehme mit dem Script nur die Simulation des Führungsthermostaten. Das Script wertet  die Soll/Ist Temperaturen sowie die Ventilstellung der HM-CC-RT-DN Thermostate aus um die Heizung ein oder auszustellen.



Anwesenheitserkennung mit WLAN
-------------------------------

Auf meiner Fritzbox läuft ein Script [url]https://github.com/jollyjinx/homematic/blob/master/presencedetection.sh[/url], mit dem ich die Anwesenheit von Geräte in meinem WLAN feststelle. Moderne SmartPhones versuchen ständig eine Internetverbindung aufrecht zu erhalten (z.B. für Push-Nachrichten) und sind damit dem Router immer bekannt. Das Script schaut also nur die ARP Tabelle an und pingt Geräte nicht an, dadurch ändert sich an der Batterielaufzeit der Geräte nichts !

Bestimmte Geräte sind bestimmten Leuten zugeordnet und somit werden Variblen auf der CCU2 durch das Script gesetzt. Also z.B. presence.wlan.patrick, oder presence.wlan.guests.


Anwesenheitsaggregation
-------------------------------

Da nicht alle Leute mit einem Gerät im WLAN einbuchen, gibt es noch manuell setzbare Variablen in der CCU2 z.B. presence.manual.guests. Diese werden mit dem script [url]https://github.com/jollyjinx/homematic/blob/master/presenceVariableAggregation.hms[/url] mit den anderen Anwesenheitserkennungen zusammengefasst in die variablen: presence.any, presence.guests, presence.patrick, usw.


Anwesenheits Thermostatsteuerung
-------------------------------

Die ganze Anwesenheitserkennung mache ich nur, damit ich die Solltemperaturen der Thermostate einstellen kann. So hängt die Solltemperatur der Räume von den Leuten ab die im Haus sind und deren Vorlieben, das habe ich einer Tabelle aus dem Script eingefügt:

	presence.guests:  hall        0:00,17C   6:00,18.5C  7:30,19.5C  19:30,20C
					  living      0:00,17C               7:30,19C    19:30,20C
					  kitchen     0:00,17C   6:00,18.5C  7:30,20C    20:30,17C               
					  guests      0:00,17C               8:00:16C    21:00,17.5C             
	
	presence.patrick: hall        0:00,16C              7:30:18C    20:30,19C 
					  living      0:00,16C              7:30:17C    20:30,18C 
					  kitchen     0:00,16C              7:30,18C    20:30,17C               
					  office      0:00,16C              7:30,19.5C  19:30,16.5C             
					  sleeping    0:00,15C              8:00,10C    22:00,16C               


Das Script [url]https://github.com/jollyjinx/homematic/blob/master/PresenceTriggersTemperature.hms[/url] wertet diese Tabelle aus, überprüft die Anwesenheit der Personen im Haus, wertet aus ob ein Fenster eine Tür im Raum geöffnet ist oder ob Heizungsrelevante Schalter im Raum aktiv sind. So geht das Script davon aus, dass wenn Licht im Raum brennt, wohl auch jemand anwesend ist.
Das Script setzt dann die Solltemperatur falls die aktuelle Solltemperatur nicht der berechneten übereinstimmt und das Thermostat im Automatikmodus läuft. Man kann also durch umstellen auf manuellen Thermostatmodus auch die Temperatur manuell verändern.

Das Script habe ich gestern mal zusammengeschrieben, hat aber z.Z. noch die Unzulänglichkeit, dass man die Thermostate erst auf manuell stellen muss, wenn man mal für ein paar Stunden die Automatik nicht greifen lassen will.


Heizungssteuerung Boiler
-------------------------------

Ich habe mir dann auch noch die Boilersteuerung der Heizung angesehen. Die Heizung erkennt die Boilertemperatur über einen Heissleiter. Ich habe dann mal ausprobiert ob ein einfaches überbrücken des Widerstandes ausreicht der Heizung klar zu machen dass der Boiler heiss ist, aber da meldet die Heizung (korrekterweise) dass der Widerstand defekt sei. 
Naja zufälligerweise lagen der Heizung noch ein paar Widerstände der Heizung bei mit denen ich (parallel zum Heisswiderstand geschaltet) eine rund 20 Grad höhere Temperatur vorgaukeln kann. Ich habe dann das zweite potentialfreie Relais vom HM-LC-Sw4-SM daran angeschlossen und kann damit den Boiler nun an und ausstellen.
Da ich, um den Boiler auszustellen der Heizung eine 20 Grad höhere Temperatur im Boiler vorgaukle, ist klar, dass ich den Frostschutz der Heizung damit ausheble und die Heizung evtl. Frost nicht erkennen könnte. Da es bei mir im Reihenhauskeller nicht fröstelt, habe ich damit kein Problem.


Wenn jemand zu Hause ist, wird der Boiler einmal am Tag um 6:15 Uhr angeschaltet. Wenn ich also übers Wochenende nicht da bin, wird der Boiler auch nicht erhitzt. 
Der Boiler wird über ein weiteres Script immer nach einer halben Stunde ausgeschaltet. So kann man den Boiler auch mal zwischendurch manuell anschalten und er schaltet automatisch nach einer halben Stunde aus. Für Gaeste gibt es noch einen Schalter (HM-Sec-SCo:Funk- Tuer-/Fensterkontakt) an der Dusche, der den Boiler automatisch anschaltet sobald Gäste im Haus sind und geduscht wird (damit ist für den nächsten Duschenden auch warmes Wasser bereit). Und zu guter letzt, da ich gerne, wenn ich nach einem Urlaub nach Hause komme, Dusche, habe ich noch ein kleines Script laufen, welches den Boiler einschaltet wenn ich nach einem Urlaub nach Hause komme. [url]https://github.com/jollyjinx/homematic/blob/master/TurnBoilerOnAfterVacation.hms[/url] 


Hoffe es gibt Euch Anregungen. Falls Ihr Sachen verbessert, könnt Ihr einfach einen Push Request auf GitHub machen.

Frohe Weihnachten - Patrick