# NullLight

Lichtsteuerung mit violetter Oberfläche, Szenenprogrammierung und einer 2D-/3D-Vorschau. Aktuelle Version: **v17**.

## Herunterladen

**[Aktuelle Downloads für Mac und Windows-Demo](https://github.com/whoisvision22/NullLight/releases/latest)**

- **Mac-App:** ZIP entpacken und NullLight.app in Programme kopieren. Enthält Art-Net-Ausgabe und Updates über GitHub. Die App ist ad-hoc signiert und nicht von Apple notarisiert; beim ersten Start gegebenenfalls Rechtsklick → Öffnen verwenden.
- **Windows-Demo:** ZIP vollständig entpacken und NullLight-starten.cmd öffnen. Alternativ NullLight.html im Browser öffnen. Keine Installation nötig. Diese Demo sendet keine echten DMX-/Art-Net-Daten.

Der Code lässt sich ebenfalls direkt ausprobieren: NullLight-starten.cmd im Repository startet demo/NullLight.html.

## Updates und neue Versionen

In der Mac-App: **Updates → Updates prüfen → Herunterladen und vorbereiten → Jetzt neu starten**. Die Dateien werden mit SHA-256 geprüft und erst vollständig vorbereitet übernommen. Die Show wird vor dem Neustart gespeichert, vorherige Versionen bleiben erhalten. Ein fehlgeschlagener Download ersetzt die vorhandene Version nicht. App-Starts benötigen keine Internetverbindung.

Dieses erste GitHub-Updatepaket benötigt die neue Mac-App einmalig als Download. Die Dateidemo unter Windows wird durch Herunterladen der neuen Demo ersetzt.

Jeder geprüfte neue Versionsstand auf main wird durch GitHub Actions gebaut. Wenn version.json eine neue Versionsnummer enthält, veröffentlicht der Workflow automatisch Mac-App, Windows-Demo und Update-Dateien. Ein bereits vorhandenes Release wird nicht überschrieben. Die verbindlichen Arbeitsschritte für künftige Änderungen stehen in AGENTS.md.

## Funktionen

- Einzelne Geräte mit manueller DMX-Adresse und Kanalfolge; Symbole für PAR, Panel, Strobo, Moving Head und LED-Streifen.
- Einstellbare Grundfläche und 0,5-m-Raster; Geräte aus dem Aufbau entfernen und wieder hinzufügen.
- Szenen und Steps, sechs zuletzt gewählte Farben und Dunkelphase nach einem Step.
- ⌘/Strg + Klick für mehrere Steps und gemeinsame Zeitänderungen.
- 48 nummerierte Performance-Plätze mit einstellbaren Buttonfarben.
- Mehrfachauswahl, gespeicherte Wiedergabegruppen und Reihenfolgen sowie Zufallswiedergabe.
- Einklappbare Master-Gruppen zur gemeinsamen Helligkeitssteuerung.
- Keine KI-Hilfen.

Shows bleiben im jeweiligen Browser bzw. der Mac-App gespeichert. Unter **Verbindung → Show exportieren / Show laden** lassen sie sich sichern und übertragen.

## Entwicklung

Node.js 22 oder neuer, keine npm-Abhängigkeiten:

```sh
npm test
npm run test:demo
npm run build:demo
```

Mac-Prüfung und Paketbau:

```sh
/usr/bin/ruby tests/updater-check.rb
/usr/bin/ruby scripts/build-mac.rb
```

Die Mac-App nutzt das mit macOS gelieferte Ruby; WEBrick wird mitgeliefert. Mindestversion für das Paket ist macOS 12. Der ausführbare Launcher wird nur durch einen neuen kompletten Mac-Download aktualisiert. Die Update-Quelle ist fest an dieses NullLight-Repository gebunden. Prüfsummen schützen die Übertragung, ersetzen aber keine Entwickler-Signatur.

- app/: Oberfläche der installierten App mit leerem Patch.
- demo/: eigenständige Browser-Demo mit Beispielgeräten.
- native/macos/: Mac-Fenster, Art-Net, Mapping und GitHub-Updater.
- scripts/: Paketbau.
- tests/: Prüfungen für Szenen, Gruppen, Wiedergabe und Update-Sicherheit.
