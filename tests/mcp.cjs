'use strict';
const assert=require('node:assert/strict'),{spawn}=require('node:child_process'),http=require('node:http');
const {handle,validate}=require('../native/mcp/server.cjs');
(async()=>{
 const requests=[];
 const server=http.createServer(async(req,res)=>{
  assert.equal(req.headers['x-lichtpult-session'],'a'.repeat(64));
  let body='';for await(const chunk of req)body+=chunk;
  requests.push({url:req.url,body:body?JSON.parse(body):null});
  res.setHeader('Content-Type','application/json');
  if(req.url==='/api/control/status')res.end(JSON.stringify({connected:true,ui:{scenes:[{id:'party',name:'Party'}]}}));
  else if(JSON.parse(body).action==='play_scene')res.end(JSON.stringify({id:'ack',result:{active:'party'}}));
  else{res.statusCode=400;res.end(JSON.stringify({error:'Fernsteuerung gesperrt.'}));}
 });
 await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
 process.env.NULLLIGHT_URL='http://127.0.0.1:'+server.address().port;
 process.env.NULLLIGHT_SESSION='a'.repeat(64);
 try{
  assert.equal((await handle({jsonrpc:'2.0',id:0,method:'tools/list'})).error.code,-32000);
  const init=await handle({jsonrpc:'2.0',id:1,method:'initialize',params:{protocolVersion:'2025-06-18'}});
  assert.equal(init.result.protocolVersion,'2025-06-18');
  await handle({jsonrpc:'2.0',method:'notifications/initialized'});
  assert.equal((await handle({jsonrpc:'2.0',id:2,method:'tools/list'})).result.tools.length,5);
  const call=(name,args={})=>handle({jsonrpc:'2.0',id:3,method:'tools/call',params:{name,arguments:args}});
  assert.equal((await call('nulllight_status')).result.isError,false);
  assert.equal((await call('nulllight_play_scene',{sceneId:'party'})).result.isError,false);
  assert.equal(requests.at(-1).body.action,'play_scene');
  assert.equal((await call('nulllight_blackout')).result.isError,true);
  assert.equal((await call('nulllight_set_master',{level:101})).result.isError,true);
  assert.throws(()=>validate('nulllight_play_scene',{sceneId:'../bad'}));
  assert.throws(()=>validate('nulllight_stop',{extra:1}));
  assert.equal((await handle({jsonrpc:'2.0',id:5,method:'missing'})).error.code,-32601);
  // Exercise the actual newline-delimited stdio process, not just the handler.
  const child=spawn(process.execPath,['native/mcp/server.cjs'],{env:process.env,stdio:['pipe','pipe','pipe']});
  let output='',error='';child.stdout.on('data',chunk=>output+=chunk);child.stderr.on('data',chunk=>error+=chunk);
  child.stdin.end(JSON.stringify({jsonrpc:'2.0',id:9,method:'initialize',params:{protocolVersion:'2025-06-18'}})+'\n{bad}\n');
  await new Promise((resolve,reject)=>{child.on('error',reject);child.on('exit',code=>code===0?resolve():reject(Error(error)));});
  const lines=output.trim().split('\n').map(JSON.parse);
  assert(lines.some(line=>line.id===9&&line.result.serverInfo.name==='nulllight'));
  assert(lines.some(line=>line.error?.code===-32700));
  console.log('Passed: MCP lifecycle, tools, schemas, authenticated HTTP, execution errors and real stdio transport.');
 }finally{server.closeAllConnections();server.close();}
})().catch(error=>{console.error(error);process.exitCode=1;});
