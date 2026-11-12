# NullLight MCP-Server

Der Server in `native/mcp/server.cjs` spricht MCP über stdio
(Protokollversion 2025-06-18) und benötigt Node.js 22 oder neuer, ohne npm-Abhängigkeiten.
Er verbindet sich mit der laufenden Mac- oder Raspberry-Pi-Engine per
authentifiziertem HTTP. Der stdio-Prozess wird durch den MCP-Client gestartet.
Er ist keine öffentliche HTTP-MCP-Schnittstelle und läuft nicht direkt in der Dateidemo.

## Client einrichten

Quellcode bzw. Raspberry-Pi-Paket lokal ablegen und im MCP-Client einen
stdio-Server mit dem absoluten Pfad zur Datei konfigurieren. Beispiel:

```json
{
  "mcpServers": {
    "nulllight": {
      "command": "node",
      "args": ["/home/pi/NullLight/native/mcp/server.cjs"],
      "env": {
        "NULLLIGHT_URL": "http://127.0.0.1:49365",
        "NULLLIGHT_SESSION_FILE": "/home/pi/.local/state/nulllight/session.key"
      }
    }
  }
}
```

Benutzernamen und Installationspfad anpassen. Auf dem Pi werden URL und
Schlüsseldatei automatisch gefunden, wenn die Standardwerte gelten und der
MCP-Prozess unter demselben Benutzer läuft. Bei einem Client auf einem anderen
Rechner `NULLLIGHT_URL` auf die LAN-IP des Pi setzen und `NULLLIGHT_SESSION`
als private Umgebungsvariable konfigurieren. Die Basisadresse darf keinen
Sitzungsschlüssel enthalten. Unter macOS den Sitzungsschlüssel aus der vom
Engine-Prozess ausgegebenen URL als `NULLLIGHT_SESSION` konfigurieren; er ändert
sich beim Neustart der Mac-App. Die MCP-Datei stammt aus diesem Quellpaket,
nicht aus dem macOS-App-Updater. Für Verbindungen im LAN gelten die Hinweise
in [RASPBERRY-PI.md](RASPBERRY-PI.md).

Keine Schlüssel in Git oder öffentliche Client-Konfigurationen übernehmen.
Der Server schreibt ausschließlich JSON-RPC auf stdout. Direktstart zur
Diagnose: `node native/mcp/server.cjs` (wartet auf MCP-Eingaben auf stdin).

## Werkzeuge

| Werkzeug | Wirkung |
| --- | --- |
| `nulllight_status` | Art-Net-/CDJ-Status, Szenen-IDs, Geräte, Wiedergabe und Master lesen |
| `nulllight_play_scene` | Vorhandene Szene über `sceneId` starten; kann reales Licht einschalten |
| `nulllight_set_master` | Helligkeit über `level` zwischen 0 und 100 ändern |
| `nulllight_blackout` | Manuellen Blackout setzen |
| `nulllight_stop` | Wiedergabe stoppen und Blackout setzen |

In Verbindung → MCP-Fernsteuerung die Fernsteuerung freigeben. Die Freigabe ist
nach jedem Browser-Neustart aus. Statusabfragen erfordern den Sitzungsschlüssel;
steuernde Befehle zusätzlich eine aktive und freigegebene Bedienoberfläche.
Befehle werden erst nach Bestätigung der Ausführung als erfolgreich gemeldet.
Ein ausgeschaltetes oder getrenntes Art-Net wird durch MCP nicht aktiviert.
Szene starten beendet manuelle Overrides; Blackout bleibt bis zur nächsten
Szene bzw. einer manuellen Freigabe aktiv. Während des CDJ-Syncs folgt die
über MCP gestartete Szene dem gewählten Beat-Raster.

Protokoll: [MCP stdio](https://modelcontextprotocol.io/specification/2025-06-18/basic/transports),
[Lifecycle](https://modelcontextprotocol.io/specification/2025-06-18/basic/lifecycle),
[Tools](https://modelcontextprotocol.io/specification/2025-06-18/server/tools).
