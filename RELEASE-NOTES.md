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
