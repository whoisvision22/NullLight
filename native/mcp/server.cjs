'use strict';
// MCP stdio transport: one JSON-RPC message per line, stdout contains only protocol.
const readline=require('node:readline'),fs=require('node:fs'),path=require('node:path'),os=require('node:os');
const version=require('../../package.json').version;
const schema=(properties={})=>({type:'object',properties,required:Object.keys(properties),additionalProperties:false});
const tools=[
 {name:'nulllight_status',description:'Read Art-Net/CDJ status and the active browser show: scenes, fixtures, playback and master.',inputSchema:schema(),annotations:{readOnlyHint:true}},
 {name:'nulllight_play_scene',description:'Start an existing programmed scene by its ID. This can turn on connected lights. Requires remote control enabled in the active UI.',inputSchema:schema({sceneId:{type:'string',pattern:'^[-a-zA-Z0-9]+$'}})},
 {name:'nulllight_blackout',description:'Set manual blackout until a scene is started or blackout is released in the UI.',inputSchema:schema()},
 {name:'nulllight_stop',description:'Stop playback and set manual blackout.',inputSchema:schema()},
 {name:'nulllight_set_master',description:'Set master brightness from 0 to 100 percent.',inputSchema:schema({level:{type:'number',minimum:0,maximum:100}})}
];
let initialized=false,ready=false;
function connection(){
 const url=new URL(process.env.NULLLIGHT_URL||'http://127.0.0.1:49365');
 if(!['http:','https:'].includes(url.protocol)||url.username||url.password||url.search||url.hash||url.pathname!=='/')throw new Error('NULLLIGHT_URL muss eine HTTP(S)-Basisadresse ohne Sitzungsschlüssel sein.');
 const keyFile=process.env.NULLLIGHT_SESSION_FILE||path.join(os.homedir(),'.local','state','nulllight','session.key');
 const token=process.env.NULLLIGHT_SESSION||fs.readFileSync(keyFile,'utf8').trim();
 if(!/^[a-f0-9]{64}$/.test(token))throw new Error('Ungültiger NullLight-Sitzungsschlüssel.');
 return {url,token};
}
async function api(route,body){
 const {url,token}=connection();
 const response=await fetch(new URL(route,url),{method:body?'POST':'GET',redirect:'error',headers:{'Content-Type':'application/json','X-Lichtpult-Session':token},body:body?JSON.stringify(body):undefined,signal:AbortSignal.timeout(6000)});
 const result=await response.json();
 if(!response.ok)throw new Error(result.error||'NullLight-Verbindung fehlgeschlagen.');
 if(result.error)throw new Error(result.error);
 return result;
}
function validate(name,args){
 const tool=tools.find(item=>item.name===name);
 if(!tool)throw new Error('Unbekanntes Werkzeug.');
 if(!args||typeof args!=='object'||Array.isArray(args))throw new Error('Argumente müssen ein Objekt sein.');
 if(Object.keys(args).some(key=>!Object.hasOwn(tool.inputSchema.properties,key)))throw new Error('Unbekanntes Argument.');
 if(name==='nulllight_play_scene'&&(typeof args.sceneId!=='string'||!/^[-a-zA-Z0-9]+$/.test(args.sceneId)))throw new Error('Ungültige Szenen-ID.');
 if(name==='nulllight_set_master'&&(!Number.isFinite(args.level)||args.level<0||args.level>100))throw new Error('Ungültige Helligkeit.');
}
async function handle(request){
 if(!request||request.jsonrpc!=='2.0'||typeof request.method!=='string'||Array.isArray(request))return {jsonrpc:'2.0',id:request?.id??null,error:{code:-32600,message:'Invalid Request'}};
 if(!Object.hasOwn(request,'id')){
  if(request.method==='notifications/initialized'&&initialized)ready=true;
  return null;
 }
 const reply=result=>({jsonrpc:'2.0',id:request.id,result});
 const fail=(code,message)=>({jsonrpc:'2.0',id:request.id,error:{code,message}});
 if(request.method==='initialize'){
  if(initialized)return fail(-32600,'Already initialized');
  if(typeof request.params?.protocolVersion!=='string')return fail(-32602,'protocolVersion required');
  initialized=true;
  return reply({protocolVersion:'2025-06-18',capabilities:{tools:{listChanged:false}},serverInfo:{name:'nulllight',version},instructions:'Read status before controlling the show. Acknowledge that actions affect real lights. Remote control must be enabled in the active NullLight UI.'});
 }
 if(request.method==='ping')return reply({});
 if(!ready)return fail(-32000,'Initialize first');
 if(request.method==='tools/list')return reply({tools});
 if(request.method==='tools/call'){
  try{
   const {name,arguments:args={}}=request.params||{};validate(name,args);
   const result=name==='nulllight_status'?await api('/api/control/status'):await api('/api/control',{action:name.replace('nulllight_',''),args});
   return reply({content:[{type:'text',text:JSON.stringify(result)}],isError:false});
  }catch(error){return reply({content:[{type:'text',text:error.message}],isError:true});}
 }
 return fail(-32601,'Method not found');
}
if(require.main===module){
 const input=readline.createInterface({input:process.stdin,crlfDelay:Infinity});
 const write=value=>{if(value)process.stdout.write(JSON.stringify(value)+'\n');};
 input.on('line',line=>{
  if(Buffer.byteLength(line)>65536){write({jsonrpc:'2.0',id:null,error:{code:-32600,message:'Request too large'}});return;}
  let request;try{request=JSON.parse(line);}catch{write({jsonrpc:'2.0',id:null,error:{code:-32700,message:'Parse error'}});return;}
  handle(request).then(write).catch(()=>write({jsonrpc:'2.0',id:request?.id??null,error:{code:-32603,message:'Internal error'}}));
 });
}
module.exports={handle,validate,tools};
