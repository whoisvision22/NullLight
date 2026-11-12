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
