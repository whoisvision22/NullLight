const fs=require('fs'),vm=require('vm'),assert=require('assert/strict');
const html=fs.readFileSync(process.argv[2],'utf8'),js=html.match(/<script>([\s\S]*?)<\/script>/)[1];
const listeners={},nodes=new Map();
function element(){return {innerHTML:'',textContent:'',style:{setProperty(){}},dataset:{},classList:{add(){},remove(){},toggle(){}},addEventListener(){},querySelector(){return null},querySelectorAll(){return []},getBoundingClientRect(){return {width:900,height:600,left:0,top:0}}};}
const document={querySelector(key){if(!nodes.has(key))nodes.set(key,element());return nodes.get(key)},querySelectorAll(){return []},addEventListener(type,cb){(listeners[type]??=[]).push(cb)},createElement(){return element()}};
const context={document,window:{addEventListener(){}},localStorage:{getItem(){return null},setItem(){}},setInterval(){},setTimeout(){},clearTimeout(){},requestAnimationFrame(){},performance:{now(){return 0}},crypto:{randomUUID(){return 'test-id'}},console,confirm(){return true},getComputedStyle(){return {}},structuredClone};
vm.createContext(context);const run=s=>vm.runInContext(s,context);run(js);
for(const tab of [1,4,3,2,6,7]){run(`tab=${tab};render()`);assert(nodes.get('#screen').innerHTML.length>100)}
run('tab=3;render()');let body=nodes.get('#screen').innerHTML;
assert.equal((body.match(/class="rig-canvas /g)||[]).length,1);assert(body.indexOf('program-sidebar')<body.indexOf('rig-canvas'));assert(body.indexOf('step-panel')>body.indexOf('rig-canvas'));
run('tab=4;render()');body=nodes.get('#screen').innerHTML;assert(body.includes('stage-size-form'));assert(body.includes('Raster 0,5 m'));assert(body.includes('fixture-inventory'));
run('updateStage(13.5,9.5)');assert.equal(run('stageSize().width'),13.5);assert.equal(run('stageSize().depth'),9.5);
for(const p of [{x:.13,y:.27},{x:0,y:0},{x:1,y:1},{x:-1,y:2}]){const q=run(`snapPosition(${JSON.stringify(p)})`);assert(q.x>=0&&q.x<=1&&q.y>=0&&q.y<=1);assert(Math.abs(q.x*13.5*2-Math.round(q.x*13.5*2))<1e-9);assert(Math.abs(q.y*9.5*2-Math.round(q.y*9.5*2))<1e-9)}
for(const dimensions of [[0,8],[8,51],[8.2,6],[NaN,8]])assert.throws(()=>run(`updateStage(${dimensions[0]},${dimensions[1]})`));
run('data.stage={width:50,depth:50};data.lights=[]');
for(let i=0;i<9;i++)run(`data.lights.push({id:'light${i}',name:'Test ${i}',mode:'RGB',mapping:'R,G,B',address:${i*3+1},height:${i%3*2.5},position:{x:${i%3/2},y:${Math.floor(i/3)/2}}})`);
// All boundary and elevated fixtures stay inside the 3D viewport at each rotation.
for(const width of [320,600,1200])for(const height of [210,420,700])for(const yaw of [-3,-1,0,1,3])for(const pitch of [.2,.92,1.45]){
 run(`Object.assign(rigView,{mode:'3d',yaw:${yaw},pitch:${pitch},zoom:1})`);
 for(let i=0;i<9;i++){const p=run(`lightScreenPosition(data.lights[${i}],${i},${width},${height})`);assert(p.x>=65&&p.x<=width-65,JSON.stringify({p,width,height}));assert(p.y>=50&&p.y<=height-50,JSON.stringify({p,width,height}));}
}
// Same normalized coordinates in both views; export/import retains stage dimensions.
run('data.stage={width:13.5,depth:9.5}');assert.equal(run('rigWorld(data.lights[0],0).x'),-6.75);assert.equal(run('validateShow(data).stage.width'),13.5);assert.equal(run('validateShow({...data,stage:undefined}).stage.depth'),8);
run(`setupDraft={values:{light0:{color:'#ff0000',level:100}}};data.scenes[0].steps[0].values.light0={color:'#ff0000',level:100};setupDrafts.set(data.scenes[0].steps[0],setupDraft);setupSelection.add('light0');fixture='light0';data.scenes[0].effects=[{ids:['light0'],enabled:true}];removeFixture('light0')`);
assert.equal(run("data.lights.some(light=>light.id==='light0')"),false);assert.equal(run("setupSelection.has('light0')"),false);assert.equal(run("data.scenes[0].steps[0].values.light0"),undefined);assert.equal(run("setupDraft.values.light0"),undefined);assert.equal(run('fixture'),null);assert.equal(run('data.scenes[0].effects[0].enabled'),false);
// New fixtures occupy the next available half-metre grid location.
const p=run('automaticLightPosition()');assert(Math.abs(p.x*13.5*2-Math.round(p.x*13.5*2))<1e-9);
run('tab=1;render()');assert(nodes.get('#screen').innerHTML.includes('delete-light:light1'));
console.log('Passed: all screens, compact workspace, 0.5 m snapping, stage validation/import, 1,215 projection checks, deletion and draft cleanup.');
