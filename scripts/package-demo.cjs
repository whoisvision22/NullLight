const fs=require('fs'),path=require('path');
const target=path.join('dist','NullLight-Windows-Demo');fs.mkdirSync(target,{recursive:true});
fs.copyFileSync('demo/NullLight.html',path.join(target,'NullLight.html'));
fs.writeFileSync(path.join(target,'NullLight-starten.cmd'),'@echo off\r\nstart "" "%~dp0NullLight.html"\r\nexit /b\r\n');
fs.writeFileSync(path.join(target,'LIESMICH.txt'),'NullLight Windows-Demo v16\r\n\r\nZIP vollstaendig entpacken und NullLight-starten.cmd doppelt anklicken.\r\nAlternativ NullLight.html im Browser oeffnen. Keine Installation erforderlich.\r\nOffline-Demo ohne echte DMX-Ausgabe oder automatische Updates.\r\nShows ueber Verbindung > Show exportieren sichern.\r\n');
console.log('Demo vorbereitet: '+target);
