# Raspberry Pi und Pioneer CDJ-3000

NullLight v18 nutzt die vorhandene Ruby-Art-Net-Engine auch auf Linux.
Vorgesehen sind Raspberry Pi 4/5 mit Raspberry Pi OS 64-bit, Ruby und WEBrick.
Der Code wurde mit simulierten CDJ-Paketen und lokalen UDP-/HTTP-Verbindungen geprüft;
ein Test mit echtem Raspberry Pi, CDJ-3000 und Art-Net-Node steht noch aus.

## Installation und lokaler Start

Repository klonen oder Raspberry-Pi-ZIP vollständig entpacken. Im Projektordner:

```sh
sudo apt update
sudo apt install ruby ruby-webrick
sh native/raspberrypi/start.sh
```

Die ausgegebene URL mit Sitzungsschlüssel im Browser öffnen. Der Server bindet
standardmäßig an 127.0.0.1. Der Schlüssel wird mit eingeschränkten Dateirechten
unter `~/.local/state/nulllight/session.key` gespeichert und bleibt bei Neustarts gleich.
In Verbindung den Art-Net-Node und die Ethernet-Schnittstelle des Pi auswählen.
Art-Net verwendet UDP 6454. Ein Art-Net-zu-DMX-Node wird benötigt; GPIO- oder
USB-DMX-Ausgabe ist in dieser Version nicht enthalten. Der Node muss auf ArtPoll
mit einem ArtPollReply für das gewählte Universum antworten.

## Bedienung über das LAN

```sh
NULLLIGHT_BIND=0.0.0.0 sh native/raspberrypi/start.sh
```

In der ausgegebenen URL `127.0.0.1` durch die LAN-IP des Pi oder seinen
Hostnamen mit `.local` ersetzen. Den Sitzungsschlüssel beibehalten und privat
aufbewahren: Er erlaubt den Zugriff auf die Lichtsteuerung. Für einen privaten
Show-LAN-Betrieb vorgesehen; HTTP-Port nicht ins Internet freigeben.

Nur einen bedienenden Browser gleichzeitig verwenden. Shows liegen im Speicher
dieses Browsers. Show exportieren/laden überträgt sie auf ein anderes Gerät.
Ein Pi ohne Bildschirm kann den Server ausführen; für Wiedergabe und Ausgabe
muss ein Browser auf einem anderen Gerät geöffnet bleiben. Ein vollständig
autonomer Showplayer ohne Browser ist noch nicht implementiert. Browser im
Vordergrund lassen und Gerätesperre/Ruhezustand vermeiden. Bei fehlenden Frames
stoppt die Engine nach drei Sekunden mit Blackout.

## Autostart als Benutzerdienst

Als normaler Benutzer im Projektordner ausführen:

```sh
sh native/raspberrypi/install-service.sh
# Optional: Dienst auch ohne angemeldete Desktop-Sitzung starten.
sudo loginctl enable-linger "$USER"
journalctl --user -u nulllight -n 10
```

Der Dienst bindet an alle IPv4-Schnittstellen. Die URL steht im Journal.
Stoppen: `systemctl --user stop nulllight`. Entfernen:
`systemctl --user disable --now nulllight` und die selbst erzeugte
`~/.config/systemd/user/nulllight.service` löschen.
Umgebung: `NULLLIGHT_BIND`, `NULLLIGHT_PORT` (Standard 49365) und
`NULLLIGHT_STATE_DIR`. Bei geänderter Netzwerkadresse Server neu starten.

## CDJ-3000 koppeln

1. Pi/Mac und CDJ-3000 per Ethernet im selben IPv4-Netz mit einem Switch verbinden.
2. Rekordbox-analysierten Track am CDJ abspielen. UDP-Port 50001 muss frei und
   im Show-LAN erreichbar sein. Andere DJ-Link-Anwendungen können ihn belegen.
3. Unter Verbindung → Pioneer CDJ-3000 Player 1–6 wählen und Empfang starten.
   „Erster aktiver Player“ bindet sich an den ersten sendenden Player und
   wechselt erst nach mindestens drei Sekunden ohne dessen Beats.
4. „Szenen mit CDJ-Beats steuern“ aktivieren. Beats pro Step wählen:
   1, 2, 4, 8 oder 16. Eine programmierte Szene in Perform starten; ihre Steps
   und die ausgewählten Szenen der Wiedergabeliste wechseln im gewählten Raster.

Pitch-korrigierte BPM, Player und Beat im Takt werden angezeigt. Der Empfang
ist passiv und sendet keine Befehle an den CDJ. Es gibt keine automatische
Tempo-Master-Erkennung, Titelerkennung, Drop-Erkennung oder Track-Cue-Analyse.
Die Beatfolge steuert bestehende Szenen; sie erzeugt keine neue Show.
Eine programmierte Dunkelphase dauert ebenfalls das gewählte Beat-Raster.
Fade-Zeiten der Steps bleiben erhalten. Bei drei Sekunden ohne Beats pausieren
die Steps und die Ausgabe wird dunkel; nach Rückkehr beginnt das Beat-Zählen neu.
White und Blackout haben weiter Vorrang. Nach App-/Browser-Neustart ist Sync aus.

Protokollgrundlage: [Deep Symmetry, Beat-Pakete](https://djl-analysis.deepsymmetry.org/djl-analysis/beats.html).
Pioneer DJ, CDJ und PRO DJ LINK sind Marken ihrer jeweiligen Inhaber;
dies ist eine unabhängige, bislang nicht am Gerät verifizierte Integration.

## Updates

Show exportieren, Dienst stoppen, neues Paket entpacken bzw. `git pull` ausführen,
Dienst neu starten. Sitzungsschlüssel und Browser-Speicher bleiben außerhalb
des Quellcodes. Der Mac-Updater wird auf dem Pi nicht verwendet.
