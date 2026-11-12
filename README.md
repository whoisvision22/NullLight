# NullLight

Lichtsteuerung mit violetter Oberfläche, Szenenprogrammierung und einer 2D-/3D-Vorschau. Aktueller Stand: **v16**.

## Demo starten

Unter Windows: Repository herunterladen und entpacken, dann **NullLight-starten.cmd** öffnen. Alternativ **demo/NullLight.html** im Browser öffnen. Die Demo braucht keine Installation und keine Internetverbindung.

Die Browser-Demo simuliert die Bedienung und Visualisierung. Sie sendet keine echten DMX-/Art-Net-Daten. Änderungen werden nur im jeweiligen Browser gespeichert. Shows lassen sich unter **Verbindung → Show exportieren / Show laden** übertragen.

## Funktionen

- Einzelne Geräte mit manueller DMX-Adresse und Kanalfolge; Symbole für PAR, Panel, Strobo, Moving Head und LED-Streifen.
- Einstellbare Grundfläche und 0,5-m-Raster; Geräte aus dem Aufbau entfernen und wieder hinzufügen.
- Szenen und Steps, sechs zuletzt gewählte Farben, Dunkelphase nach einem Step.
- ⌘/Strg + Klick für mehrere Steps und gemeinsame Zeitänderungen.
- 48 nummerierte Performance-Plätze; freie Plätze öffnen die Szenenprogrammierung.
- Einstellbare Buttonfarben, Mehrfachauswahl, gespeicherte Wiedergabegruppen und Reihenfolgen sowie Zufallswiedergabe.
- Einklappbare Master-Gruppen zur gemeinsamen Helligkeitssteuerung.
- Keine KI-Hilfen.

## Ordner

- **app/**: Oberfläche für die installierte App, ohne Beispielgeräte.
- **demo/**: eigenständige Browser-Demo mit Beispielgeräten.
- **native/macos/**: Mac-Fenster, Art-Net-Ausgabe, Mapping und bisheriger lokaler Updater.
- **tests/**: Prüfungen für Szenen, Raster, Ausgabe, Gruppen und Wiedergabe.
- **scripts/**: Vorbereitung der Windows-Demo als Dateipaket.

## Entwicklung und Downloads

Mit Node.js 22 oder neuer:

```sh
npm test
npm run test:demo
npm run build:demo
```

Es sind keine npm-Abhängigkeiten nötig. GitHub Actions prüft jeden Stand auf dem Hauptzweig und stellt unter **Actions → Demo pruefen und bauen → Artifacts** eine Windows-Demo bereit. Bei einem privaten Repository brauchen Empfänger entsprechend Zugriff.

Die Mac-Anbindung ist Quellcode und benötigt macOS, Ruby und WEBrick. Sie wurde hier nicht als neues Installationspaket veröffentlicht. Der GitHub-basierte automatische App-Updater ist noch nicht angebunden; der vorhandene Updater arbeitet mit einer lokalen Projektdatei. Dieses Repository allein aktiviert noch keine Online-Updates.
