# NullLight

Lichtsteuerung mit violetter Oberfläche, Szenenprogrammierung und einer 2D-/3D-Vorschau. Entwicklungsstand: **v0.2.6**.

## Herunterladen

**[Aktuelle Downloads für Mac und Windows-Demo](https://github.com/whoisvision22/NullLight/releases/latest)**

- **Mac-App:** ZIP entpacken und NullLight.app in Programme kopieren. Enthält Art-Net-Ausgabe und Updates über GitHub. Die App ist ad-hoc signiert und nicht von Apple notarisiert; beim ersten Start gegebenenfalls Rechtsklick → Öffnen verwenden.
- **Windows-Demo:** ZIP vollständig entpacken und NullLight-starten.cmd öffnen. Alternativ NullLight.html im Browser öffnen. Keine Installation nötig. Diese Demo sendet keine echten DMX-/Art-Net-Daten.
- **Raspberry Pi:** Linux-Server mit Art-Net-Ausgabe, Bedienung im lokalen oder entfernten Browser und optionalem Benutzerdienst. Installation und CDJ-3000-Verbindung: [Raspberry-Pi-Anleitung](docs/RASPBERRY-PI.md).

v18 ergänzt passiven Pioneer-CDJ-3000-Beatempfang und einen MCP-Server zur
Fernsteuerung bestehender Szenen. [MCP einrichten](docs/MCP.md).
Pi-/CDJ-Unterstützung ist mit simulierten Paketen geprüft; der Gerätetest steht noch aus.
Die Downloads werden nach Übernahme und Veröffentlichung einer neuen Version aktualisiert.

Der Code lässt sich ebenfalls direkt ausprobieren: NullLight-starten.cmd im Repository startet demo/NullLight.html.

## Updates und neue Versionen

In der Mac-App: **Updates → Nach Updates suchen → Herunterladen und neu starten**. Ein eigener Dialog zeigt Prüfung, Download-Fortschritt und Vorbereitung. Schließen / Abbrechen stoppt einen laufenden Download vor der Aktivierung. Die Dateien werden mit SHA-256 geprüft und erst vollständig vorbereitet übernommen. Die Show wird vor dem Neustart gespeichert, vorherige Versionen bleiben erhalten. Ein fehlgeschlagener Download ersetzt die vorhandene Version nicht. App-Starts benötigen keine Internetverbindung.

Dieses erste GitHub-Updatepaket benötigt die neue Mac-App einmalig als Download. Die Dateidemo unter Windows wird durch Herunterladen der neuen Demo ersetzt.

Jeder geprüfte neue Versionsstand auf main wird durch GitHub Actions gebaut. Wenn version.json eine neue Versionsnummer enthält, veröffentlicht der Workflow automatisch Mac-App, Windows-Demo und Update-Dateien. Ein bereits vorhandenes Release wird nicht überschrieben. Die verbindlichen Arbeitsschritte für künftige Änderungen stehen in AGENTS.md.

## Neuer Arbeitsablauf

Laser und Nebelmaschine sind eigene Gerätearten. Für universelle Laser stehen
freie Kanäle (`U`) zur Verfügung; die Kanalzahl lässt sich anpassen. Bei der
Nebelmaschine bezeichnet `F` den Ausstoß, weitere Kanäle können frei belegt
werden. In Szenen erhält jeder Kanal einen Regler von 0 bis 255. Die Bedeutung
und Wertebereiche richten sich nach dem Gerätehandbuch. Die Werte bleiben pro
Step gespeichert. **Ausgabe auf null** stoppt die ausgewählten Effektgeräte;
Blackout nullt alle Kanäle. White/Flash aktiviert Laser und Nebelmaschine nicht.

Unter **Lichter** zeigt jede Zeile ein Gerät. Das **+** öffnet den Geräteeditor;
die Kanalfolgen-Auswahl richtet sich nach der Geräteart. Unter **Aufbau → + Bühne**
lässt sich eine Bühne mit eigenen Maßen und Höhe ergänzen, in 2D ziehen oder per
Pfeiltaste im 0,5-m-Raster verschieben. Die Bühne bleibt im jeweiligen Aufbau
gespeichert und ist auch in der 3D-Vorschau sichtbar.

Im rechten Kasten Szene werden Bank, nummerierte Szenentasten, Name und Speichern gemeinsam angezeigt. Neue Szenen entstehen in der ausgewählten Bank. Ungespeicherte Step-Änderungen erscheinen oben mit direktem Speichern-Knopf. Rückgängig/Wiederholen umfasst Show-Änderungen und Farbentwürfe; Texteingaben behalten ihre üblichen Tastenkürzel. Rückgängig und Wiederherstellen sind bei aktiver echter Ausgabe gesperrt.

Steps können gezogen oder mit den Pfeilen sortiert werden. Alt/Option beim Ablegen kopiert einen Step. Unter Verbindung bzw. über Sicherungen sind die letzten zehn lokalen Sicherungsstände zugänglich. Automatische Sicherungen erfolgen bei Änderungen spätestens nach 30 Sekunden; bitte wichtige Shows zusätzlich exportieren. Die Sicherungen liegen im selben Browser/App-Speicher und ersetzen keine externe Sicherung.

## Funktionen

- Einzelne Geräte mit manueller DMX-Adresse und Kanalfolge; Symbole für PAR, Panel, Strobo, Moving Head und LED-Streifen.
- Einstellbare Grundfläche und 0,5-m-Raster; Geräte aus dem Aufbau entfernen und wieder hinzufügen.
- Szenen und Steps, sechs zuletzt gewählte Farben und Dunkelphase nach einem Step.
- ⌘/Strg + Klick für mehrere Steps und gemeinsame Zeitänderungen.
- 48 nummerierte Performance-Plätze mit einstellbaren Buttonfarben.
- Mehrfachauswahl, gespeicherte Wiedergabegruppen und Reihenfolgen sowie Zufallswiedergabe.
- Einklappbare Master-Gruppen zur gemeinsamen Helligkeitssteuerung.
- Keine KI-Hilfen.
- CDJ-Beatsteuerung für vorhandene Szenen: 1, 2, 4, 8 oder 16 Beats pro Step, Playerwahl und Blackout bei Signalausfall.
- MCP über stdio: Status, Szenenstart, Master, Blackout und Stopp mit Freigabe in der Oberfläche.

Shows bleiben im jeweiligen Browser bzw. der Mac-App gespeichert. Unter **Verbindung → Show exportieren / Show laden** lassen sie sich sichern und übertragen.

## Entwicklung

Node.js 22 oder neuer, keine npm-Abhängigkeiten:

```sh
npm test
npm run test:demo
npm run build:demo
npm run build:pi
```

Mac-Prüfung und Paketbau:

```sh
/usr/bin/ruby tests/updater-check.rb
/usr/bin/ruby scripts/build-mac.rb
```

Pi-/Server-Prüfung mit Ruby und WEBrick: `npm run test:pi`.
Start auf dem Pi: `sh native/raspberrypi/start.sh`.
Der MCP-Client startet `node native/mcp/server.cjs` als stdio-Prozess.

Die Mac-App nutzt das mit macOS gelieferte Ruby; WEBrick wird mitgeliefert. Mindestversion für das Paket ist macOS 12. Der ausführbare Launcher wird nur durch einen neuen kompletten Mac-Download aktualisiert. Die Update-Quelle ist fest an dieses NullLight-Repository gebunden. Prüfsummen schützen die Übertragung, ersetzen aber keine Entwickler-Signatur.

- app/: Oberfläche der installierten App mit leerem Patch.
- demo/: eigenständige Browser-Demo mit Beispielgeräten.
- native/macos/: Mac-Fenster, Art-Net, Mapping und GitHub-Updater.
- native/raspberrypi/: Linux-Start und optionaler systemd-Benutzerdienst.
- native/mcp/: MCP-stdio-Server; nutzt die authentifizierte Engine-API.
- scripts/: Paketbau.
- tests/: Prüfungen für Szenen, Gruppen, Wiedergabe und Update-Sicherheit.

Das neue Ring-Logo wird mit der Mac-App als Dock-Symbol ausgeliefert. Dafür die aktuelle Mac-App einmal vollständig herunterladen und ersetzen; Inhaltsupdates ändern das Bundle-Symbol nicht.

Jeder Aufbau verwaltet eigene Banks, Szenen und Wiedergabegruppen. Alte gemeinsame Szenen werden in vorhandene Aufbauten kopiert. Wechseln stoppt die laufende Szene. Geräte bleiben gemeinsam. Der Master bietet Ausblenden, Flash (mit Master-Gruppen und Blackout-Vorrang), Tempo-Faktoren und Sperre. Bei CDJ-Sync gibt der Player das Tempo vor.
