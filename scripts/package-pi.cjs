'use strict';
const fs=require('node:fs'),path=require('node:path');
const target=path.join('dist','NullLight-Raspberry-Pi');
fs.mkdirSync(target,{recursive:true});
for(const entry of ['app','native','docs','package.json','version.json','README.md','RELEASE-NOTES.md']){
 fs.cpSync(entry,path.join(target,entry),{recursive:true});
}
for(const script of ['start.sh','install-service.sh'])fs.chmodSync(path.join(target,'native','raspberrypi',script),0o755);
console.log('Raspberry-Pi-Paket vorbereitet: '+target);
