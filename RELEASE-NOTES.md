# v0.2.14 – Pixel wieder deutlich sichtbar

- Quadratische Kästchen in der Pixel-Lupe. „Pixel groß“ vergrößert die gemeinsame 2D-Bühne; Hintergrund ziehen verschiebt sie, „Übersicht“ passt wieder alles ein.
- Große Pixel-Vorschau direkt oben im LED-Bar-Reiter; die 180 LEDs erscheinen als drei große Reihen vor der Aufbau-Übersicht.
- Bar-Symbole haben drei höhere Pixelreihen statt winziger flacher Felder. Positionen und Drehungen bleiben gemeinsam und unverändert.
- Nach dem ersten Anlegen von Bars im LED-Reiter werden diese für die Vorschau ausgewählt.
- Gemeinsame Bühne, Studio-Anordnung und Streifen-Modi bleiben erhalten.

# v0.2.13 – Gemeinsamer Visualizer und drei Streifen

- LED-Bar-Reiter wieder mit Bars links, Vorschau und Effekten in der Mitte, Speichern rechts.
- Alle Bereiche nutzen denselben 2D-/3D-Visualizer mit derselben Bühnenprojektion, Position und Drehung. Pixelbars werden überall mit derselben Länge dargestellt.
- „Bars mit Abstand anordnen“ verteilt die Bars mit 1,5 m Abstand im gemeinsamen Aufbau; Grundfläche wird bei Bedarf erweitert.
- Alle Effekte können die drei Streifen gemeinsam, mit Versatz oder einen einzelnen Streifen steuern. Inaktive Streifen bleiben auch auf dem Weißkanal dunkel.
- Pixel-Lupe und zusätzliche aktive Effekte bleiben erhalten.

# v0.2.12 – LED-Bar-Clip-Pult und Pixel-Lupe

- Schlankes Clip-Pult: Effekt-Clips links, Aufbau-Vorschau mit Pixel-Lupe in der Mitte, Regler und Speichern rechts.
- LED Bars folgen Positionen, Z-Drehung und Grundfläche des aktuellen Aufbaus. Die Ansicht lässt sich bis 400 % vergrößern.
- Eine Bar anklicken: alle 180 Pixel in drei großen Reihen; Pixelnummer und Streifennummer sind einzeln auswählbar.
- Sechs zusätzliche aktive Effekte: Meteor/Schweif, Scanner, Mehrfach-Lauflicht, Funkeln, Blitzer und laufende Punkte. Sparkle/Lauflicht stehen im Vordergrund; Farbflächen sind eingeklappt.
- Gespeicherte LED-Szenen sind als Clips ladbar. Vorschau bleibt von der Perform-Ausgabe getrennt.

# v0.2.11 – RGBW, drei Streifen und räumliches Pixel-Mapping

- Neue Pixelbars haben 3 × 60 RGBW-LEDs / 180 Pixel; alle drei Streifen sind einzeln sichtbar.
- Im LED-Bar-Studio Bars auf einer schwarzen Mapping-Fläche ziehen und in 90°-Schritten drehen. Effekte entlang X/Y oder radial über die Anordnung abbilden.
- 720 RGBW-Kanäle pro Bar: Ausgabe über zwei Art-Net-Universen mit 512 Kanälen, 128 + 52 Pixel. Zehn Bars nutzen standardmäßig 20 Universen. Controller auf RGBW, passende Kanalfolge und fortlaufende Universen einstellen. Ältere RGB-Profile behalten 510 Kanäle je Universum.
- Separate Weißsteuerung im Szenen- und LED-Bar-Editor. RGBW-Geräte bekommen einen eigenen W-Kanal; RGB-Geräte mischen Weiß. Bestehende Geräteadressen und manuell gewählte Profile bleiben erhalten.
- Vorhandene Profile bleiben erhalten. „Auf 3 × 60 umstellen“ aktualisiert sie bei gestoppter Ausgabe und behält Geräte-IDs sowie Szenen.
- Mapping-Koordinaten, Winkel und Effekte bleiben mit der Perform-Szene des jeweiligen Aufbaus gespeichert.

# v0.2.10 – LED-Bar-Effektstudio

- Neuer Reiter „LED Bars“ mit eigenständigem Effekteditor statt Step-Programmierung.
- Acht laufende Pixel-Effekte mit Farben, Größe/Dichte, Helligkeit, Richtung und Tempo/BPM.
- Durchgehende Lichtlinie oder parallele Bars; Reihenfolge und umgedrehte Montage pro Bar einstellbar.
- Animierte Vorschau ohne Live-Ausgabe; Effekte als eigene Szenen des aktuellen Aufbaus in Perform speichern, laden und bearbeiten.
- Prozedurale Art-Net-Pixelausgabe berücksichtigt Master, Gruppen, Blackout und White.

NullLight v0.2.9 – Null Labs Pixelbars und KI-Szenenassistent

- Eigenes WS2815-Profil für die geplanten zehn 12-V-Pixelbars mit jeweils 60 RGB-Pixeln. Einrichtungsdialog mit einzeln editierbaren Universen, Adressen und Kanalfolgen. Zwei Bars pro Universum ab Kanal 1/181; Standardplan über fünf Universen.
- Einzelpixel-Editor, Pixelvorschau und Art-Net-Pixelausgabe zusätzlich zum bisherigen DMX-Universum. Stoppen, Verbindungsverlust und entfernte Universen senden Blackout. Benötigt einen passenden Art-Net-Pixelcontroller; die App erzeugt kein direktes WS2815-Signal.
- Optionaler OpenAI-Szenenassistent: eigener API-Schlüssel pro Sitzung, Beschreibung eingeben, strukturierte Steps und Pixelmuster prüfen und als neue Szene übernehmen. Keine automatische Showänderung oder Live-Ausgabe durch die KI. Schlüssel werden nicht in Shows oder Browser-Speicher geschrieben. Auf dem Pi ist OPENAI_API_KEY verfügbar.
- Tests mit echter lokaler UDP-Kommunikation über fünf Pixel-Universen, zusätzlichen Softwaretests für Pixel-Adressierung und KI-Proposalvalidierung. KI-API-Tests verwenden simulierte Antworten, keine kostenpflichtigen Live-Aufrufe. Tests mit der noch zu bauenden Hardware stehen aus.

NullLight v0.2.8 – Abgleich der Effektgeräte-Vorschau

- Die Flash-Vorschau zeigt Laser und Nebel dunkel, passend zu ihrer tatsächlichen DMX-Ausgabe.
- Der Strobe-Regler zeigt auch bei gespeicherten direkten Kanalwerten den tatsächlich ausgegebenen Wert.
- Enthält Woodwarths in v0.2.7 übernommenen Pull Request mit kompakter Geräteverwaltung und Bühnenflächen sowie die bei der Prüfung ergänzten Kanal-Korrekturen.

NullLight v0.2.7 – Geräte übersichtlich verwalten und Bühne platzieren

- Laser und Nebelmaschine als eigene Geräte mit Symbolen, universeller Kanalzahl und DMX-Reglern pro Step. F = Nebelausstoß, U = freier Kanal. White/Flash schaltet diese Geräte nicht ein; Blackout nullt alle Kanäle.
- Einzeilige Geräte, Plus-Taste zum Hinzufügen und Geräteeditor als Dialog nur bei Bedarf. Kürzere Reiternamen Lichter und Szenen.
- Kanalfolgen-Auswahl passend zum gewählten Gerätetyp; vorhandene Profile bleiben auswählbar.
- Eigene Bühne mit Breite, Tiefe und Höhe im Aufbau: im 2D-Raster verschieben, in 3D sichtbar und je Aufbau gespeichert.
- Einklappbare Gerätegruppen in Patch, Aufbau und Programmierung. Mehrere Geräte im Patch auswählen und gemeinsam einer Gruppe zuweisen.
- Geräteliste und Bearbeitungsformular scrollen unabhängig; Speichern und Abbrechen bleiben im Editor sichtbar. Listenposition bleibt beim Bearbeiten erhalten.
- Auswahl gängiger DMX-Kanalfolgen mit eigener Kanalfolge als Alternative. Vorhandene Profile bleiben erhalten.
- Neue Strobos starten mit zwei Kanälen: Dimmer und Strobe (D,S), alternativ S,D. Der Strobe-DMX-Wert ist pro Step einstellbar; Blackout setzt alle Kanäle auf null.

NullLight v0.2.6 – Szenenliste 1 bis 48

- Im Feld Szene ersetzt eine einspaltige nummerierte Liste die quadratischen Tasten. Sie zeigt die Plätze 1 bis 48 des aktuellen Aufbaus mit Szenenname und Bank.
- Bestehende Einträge laden die zugehörige Szene samt Bank. Ein leerer Platz legt eine Szene mit genau dieser Perform-Nummer in der ausgewählten Bank an.

NullLight v0.2.5

- Jeder Aufbau hat eigene Banks, Szenen, Wiedergabegruppen und Tempo-Faktoren. Neue Aufbauten beginnen mit einer leeren Szene, Kopien sind unabhängig. Alte gemeinsame Szenen bleiben durch Kopien in den bestehenden Aufbauten erhalten.
- Farbentwürfe bleiben beim Wechsel erhalten. Aufbauwechsel stoppt die laufende Szene und dunkelt die Ausgabe ab.
- Schwarzer Visualizer-Hintergrund.
- Master: sanftes Ausblenden, momentaner Weiß-Flash, Tempo halbieren/verdoppeln, Bediensperre und Statusanzeige. Blackout überstimmt Flash; Blackout und Stopp bleiben bei Sperre erreichbar.

NullLight v0.2.4 – Update-Dialog im Aufbau des CVR Tools

- Eigener Update-Dialog mit installierter Version, manueller Prüfung, Download und Neustart in einem Ablauf, Fortschrittsanzeige und Schließen/Abbrechen. Der aktuelle Reiter bleibt geöffnet.
- Hintergrund-Download mit Abbruchprüfung vor dem Aktivieren; fehlgeschlagene oder abgebrochene Vorgänge ersetzen keine Version. Show und Farbentwürfe werden vor dem Neustart gespeichert.
- Alle auswählen direkt bei den Steps für gemeinsame Zeitänderungen. Keine blaue Textauswahl beim Klicken/Ziehen im Visualizer; ausgewählte Lampen haben einen dünnen violetten Rahmen.
- Der automatische Updatepfad aktualisiert weiterhin die geprüften App-Inhalte. Änderungen am nativen Starter oder App-Symbol benötigen einen vollständigen Mac-Download; der Dialog verlinkt diesen.

NullLight v0.2.3 – Nummerierte Szenenübersicht

- Im bisherigen Kasten Szene: Bankauswahl, nummerierte Szenentasten, Name, Wiederholung und Speichern gemeinsam an einem Ort.
- Dock-Symbol zusätzlich ausdrücklich beim Start setzen; auch das Standard-Applet-Symbol wird ersetzt. Diese Version benötigt einmalig den neuen Mac-Download.
- Sichtbare Version und Downloadnamen verwenden v0.2.3. Der interne Updatezähler bleibt zur Erkennung neuerer Versionen fortlaufend.

NullLight v23 – Bank- und Szenenauswahl, neues Logo

- Fester Bereich Bank & Szene beim Programmieren: Bank wählen, Szene laden, neue Szene/Bank anlegen und direkt in Perform speichern. Farbentwürfe bleiben beim Wechsel erhalten.
- Weißer Leuchtring auf violettem Grund als neues App-Logo und Mac-Dock-Symbol. Für das Dock-Symbol die neue Mac-App herunterladen und die bisherige App ersetzen; das normale Inhaltsupdate ändert das Bundle-Symbol nicht.

NullLight v22 – Einfacher programmieren und sicherer arbeiten

- Eine zentrale Szenenauswahl beim Programmieren, sichtbare ungespeicherte Step-Farben und direkter Speichern-Knopf.
- Rückgängig/Wiederholen für Show-Änderungen und Farbentwürfe, auch per ⌘/Strg+Z und Umschalt+⌘/Strg+Z. Während echter Ausgabe gesperrt.
- Steps ziehen zum Sortieren, Alt/Option beim Ablegen zum Kopieren; zusätzliche Pfeile und Kopieren-Taste. Mehrfarbige Vorschau pro Step.
- Optionale Szenennamen unter den Perform-Zahlen; Anzeige von aktivem Step, Fortschritt und nächster Szene. CDJ-Sync zeigt Beats statt geschätzter Sekunden.
- Bis zu 64 gleiche Geräte in einem Vorgang, fortlaufende manuell änderbare DMX-Adressen und gemeinsame Konfliktprüfung vor dem Anlegen.
- Zehn lokale automatische/manuelle Sicherungen inklusive Farbentwürfen, Wiederherstellung und Sicherung vor dem Wiederherstellen. Export bleibt für geräteübergreifende Sicherungen nötig.
- Vorschau, echte DMX-Ausgabe, Blackout und Verbindungsfehler werden in jedem Reiter angezeigt.

NullLight v21 – Szenennamen auswählen

- Beim Speichern in Perform ist Name der Taste eine Auswahlliste der vorhandenen Szenennamen. Die bearbeitete Szene wird ebenfalls mit ihrem Namen angezeigt.
- Enthält die Anordnung aus v20: Banks unter dem Master.

NullLight v20 – Banks unter Master

- Im Perform-Bereich stehen die Banks jetzt unter dem Master. Beide Bereiche nutzen die volle Breite der rechten Seitenleiste.

NullLight v19 – Szenen und mehrere Aufbauten

- Performance Buttons heißen jetzt Szenen; die bearbeitete Szene lässt sich beim Speichern direkt wählen.
- Einklappbare Aufbauten mit Speichern, Kopieren und Wechseln. Grundfläche, Positionen und X-/Y-/Z-Ausrichtung bleiben pro Aufbau erhalten.
- Farbe der Auswahl über der Lichterliste; getrennte Aktionen für Farbe auf null und Alles abwählen.
- Banks links neben dem Master; höherer, schmalerer Perform-Visualiser mit Szenentasten darunter.
- Enthält Woodwarths Raspberry-Pi-, CDJ-3000- und MCP-Erweiterungen aus v18. Reale Hardwaretests stehen noch aus.

Downloads: NullLight-Mac-v19.zip, NullLight-Windows-Demo-v19.zip und NullLight-Raspberry-Pi-v19.zip.

NullLight v18 – Raspberry Pi, Pioneer CDJ-3000 und MCP

- Raspberry-Pi-/Linux-Server mit echter Art-Net-Ausgabe, geschützter Browser-Bedienung im LAN und optionalem systemd-Benutzerdienst.
- Passiver Pro-DJ-Link-Empfang für CDJ-3000: Playerwahl, pitch-korrigierte BPM und Beat-Anzeige. Vorhandene Szenen wechseln nach 1, 2, 4, 8 oder 16 Beats pro Step. Bei Signalausfall pausieren die Steps und die Ausgabe wird dunkel.
- MCP-Server über stdio für Status, Szenenstart, Master, Blackout und Stopp. Steuernde Befehle brauchen eine aktive, freigegebene Oberfläche und werden erst nach deren Ausführungsbestätigung als erfolgreich gemeldet.
- Zusätzliche Tests für CDJ-UDP-Pakete, HTTP-Sitzungsschutz, MCP-Protokoll und Befehlsbestätigung. Pull Requests führen Prüfungen aus, ohne Releases zu veröffentlichen.

Raspberry Pi benötigt Ruby/WEBrick und einen Art-Net-zu-DMX-Node. Die Show läuft im geöffneten Browser; ein autonomer Showplayer ohne Browser ist nicht enthalten. MCP benötigt zusätzlich Node.js 22 oder neuer und die Serverdatei aus dem Quell-/Pi-Paket.

Die CDJ-Integration wurde mit simulierten Paketen geprüft. Tests mit echtem Raspberry Pi, CDJ-3000 und Art-Net-Node stehen noch aus. Keine automatische Tempo-Master-Erkennung, Track-/Drop-Erkennung oder Showgenerierung.

Downloads nach Veröffentlichung:
- **NullLight-Mac-v18.zip**: installierte Mac-App mit Art-Net-Ausgabe und GitHub-Updater.
- **NullLight-Windows-Demo-v18.zip**: Offline-Demo im Browser, ohne Installation und ohne echte DMX-Ausgabe.
- **NullLight-Raspberry-Pi-v18.zip**: Linux-Server, MCP-Server und Einrichtungsanleitungen.

Mac-Updates: Updates prüfen → Herunterladen und vorbereiten → Jetzt neu starten. Die Show bleibt im lokalen App-Speicher erhalten. Die ältere Version bleibt als Rückfall erhalten. Eine vorhandene ältere Mac-Demo muss einmalig durch diesen Download ersetzt werden.

Die Mac-App ist ad-hoc signiert und nicht von Apple notarisiert. Beim ersten Start kann macOS eine Freigabe über Rechtsklick → Öffnen verlangen.
