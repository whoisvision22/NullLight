> Ab v0.2.11 ist der neue Standard 3 × 60 RGBW-Pixel pro Bar. Die folgende ursprüngliche WS2815-Konfiguration bleibt als älteres RGB-Profil unterstützt. Aktuelle RGBW-Belegung und Mapping-Bedienung: README.md, Abschnitt „RGBW und drei Streifen pro Bar“.

# Null Labs WS2815-Pixelbars

Geplant sind zehn Bars mit je 60 adressierbaren RGB-Pixeln bei 12 V. Unter **Lichter → Null Labs · Pixelbars** wird dieser Plan als Geräteprofil angelegt. Die Ausgabe erfolgt an einen Art-Net-Pixelcontroller, der Art-Net in das WS2815-Signal umsetzt. Ein passiver RJ45-Adapter oder reiner DMX-Node kann dieses serielle Pixelsignal nicht erzeugen.

Standardplan mit Art-Net-Portadressen ab 0:

| Bars | Pixel-Universum | Startkanäle |
| --- | --- | --- |
| 1–2 | 1 | 1 und 181 |
| 3–4 | 2 | 1 und 181 |
| 5–6 | 3 | 1 und 181 |
| 7–8 | 4 | 1 und 181 |
| 9–10 | 5 | 1 und 181 |

Jede Bar belegt 180 Kanäle. Das normale DMX-Hauptuniversum bleibt im Standardplan 0. Pixel-Universen dürfen dieses Hauptuniversum und Ziele des Art-Net-Mappings nicht überschreiben. Namen, Universen, Startadressen und die RGB-Kanalreihenfolge lassen sich vor dem Anlegen einzeln ändern. Die Kanalfolge muss zur Konfiguration des Pixelcontrollers passen. Die App steuert weder die Spannung noch die elektrische Versorgung.

Im Aufbau werden die Bars wie andere Lichter platziert. In Szenen färben die schnellen Farbfelder die gesamte ausgewählte Bar. Unter **Einzelne Pixel** lässt sich eine einzelne LED auswählen und einfärben. Bei mehreren ausgewählten Bars wird derselbe Pixel auf diesen Bars geändert. Die 2D-/3D-Symbole zeigen die einzelnen Pixel als Farbstreifen.

Die Ausgabe folgt Master, Master-Gruppen, Blackout, White und Flash. Beim Stoppen, beim Entfernen eines Universums und nach ausbleibenden Browser-Frames werden die abonnierten Universen abgedunkelt. Der Controller muss die passenden Art-Net-Universen abonnieren und ArtPollReply unterstützen. Hardwaretests stehen aus.

# KI-Szenenassistent

Der Assistent steht unter **Szenen → KI-Szenenassistent** in der Mac-App und auf dem Pi zur Verfügung. Die Browser-Dateidemo kann keine KI-Anfragen senden.

1. Im API-Zugang den eigenen OpenAI-API-Schlüssel für die aktuelle Sitzung eingeben. Er wird nur im lokalen App-Prozess gehalten und nicht in Shows oder Browser-Speicher geschrieben. Nach einem Neustart muss er erneut eingegeben werden. Auf dem Pi kann stattdessen `OPENAI_API_KEY` in der Serverumgebung gesetzt werden; Schlüssel über entfernte LAN-Browser werden nicht angenommen.
2. Gewünschte Lichter auswählen. Ohne Auswahl werden die im aktuellen Aufbau platzierten Lichter verwendet. Laser und Nebelgeräte gehören nicht zum KI-Generator.
3. Beschreibung eingeben, zum Beispiel: „Auf den Pixelbars einen blauen Laufpunkt von links nach rechts, danach alle Bars violett, in einer Schleife.“
4. **Szenenvorschlag erstellen** sendet den Auftrag sowie IDs, Namen und Typen dieser Lichter an OpenAI. Die API-Nutzung kann Kosten verursachen. Der Standard ist `gpt-4.1-mini`; ein anderer kompatibler Modellname kann über `OPENAI_MODEL` gesetzt werden.
5. Die Step-Tasten im Vorschlag zeigen eine reine Visualizer-Vorschau. Sie verändern die gespeicherte Show und die DMX-Ausgabe nicht.
6. **Als neue Szene übernehmen** legt eine bearbeitbare Szene in der gewählten Bank an. Erst **Szene in dieser Bank speichern** gibt sie für Perform frei. Die KI startet keine Szene automatisch.

Antworten werden strukturiert angefordert und auf bekannte Licht-IDs, Farbwerte, Pixelgrenzen und Zeitbereiche geprüft. Ein zwischenzeitlicher Aufbauwechsel oder entfernte Geräte verhindern das Übernehmen veralteter Vorschläge. Die Integration ist automatisiert mit simulierten API-Antworten geprüft. Ein echter OpenAI-Aufruf benötigt den Schlüssel des Benutzers und wurde beim Paketbau nicht ausgeführt.

Technische Referenzen: [Responses API](https://developers.openai.com/api/reference/resources/responses/methods/create), [Structured Outputs](https://developers.openai.com/api/docs/guides/structured-outputs), [GPT-4.1 mini](https://developers.openai.com/api/docs/models/gpt-4.1-mini).
