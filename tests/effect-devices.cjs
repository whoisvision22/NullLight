const fs=require('fs');
const harness=fs.readFileSync('tests/workspace.cjs','utf8').split('// Tests below')[0];
const checks=String.raw`
run('data={lights:[],scenes:[{id:"s",name:"Test",live:true,steps:[newStep()]}],savedLayouts:[],stage:{width:12,depth:8},layoutVersion:1};editing="s";setupDraft=null;loadSetupStep();setupSelection.clear();');
assert.equal(run('deviceTypes.laser.name'),'Laser');assert.equal(run('deviceTypes.fog.mapping'),'F');
run('addFixtureBatch({name:"Laser",visualType:"laser",mode:"Eigenes Profil",mapping:deviceTypes.laser.mapping,address:1,group:"Effekte"},1);addFixtureBatch({name:"Nebel",visualType:"fog",mode:"Eigenes Profil",mapping:"F,U",address:20,group:"Effekte"},1);addFixtureBatch({name:"PAR",visualType:"par",mode:"RGB",mapping:"R,G,B",address:30,group:"Licht"},1);var laserId=data.lights[0].id,fogId=data.lights[1].id,parId=data.lights[2].id;');
assert.equal(run('patchProblem()'),'');assert(run('encodeFrame(setupDraft).every(value=>value===0)'));
assert(run('setFixtureChannel(laserId,3,120)'));assert(run('setFixtureChannel(fogId,0,200)'));assert(run('setFixtureChannel(fogId,1,80)'));
assert.equal(run('encodeFrame(setupDraft)[3]'),120);assert.equal(run('encodeFrame(setupDraft)[19]'),200);assert.equal(run('encodeFrame(setupDraft)[20]'),80);
assert.equal(run('setFixtureChannel(laserId,8,90)'),false);assert.equal(run('setFixtureChannel(fogId,0,256)'),false);assert.equal(run('setFixtureChannel(fogId,0,-1)'),false);
run('setupSelection.add(laserId);setupSelection.add(fogId);setupSelection.add(parId);applySetupValue("color","#ff0000")');assert.equal(run('encodeFrame(setupDraft)[19]'),200);assert.equal(run('encodeFrame(setupDraft)[3]'),120);
const white=run('encodeFrame(setupDraft,"white")');assert(white.slice(0,8).every(value=>value===0));assert.equal(white[19],0);assert.equal(white[20],0);assert.equal(white[29],255);
assert(run('encodeFrame(setupDraft,"black").every(value=>value===0)'));
run('var effects=effectStep(setupDraft,{effects:[{enabled:true,type:"solid",mix:"replace",color:"#ffffff",level:100,speed:1,width:1,axis:"x",ids:[]}]},0)');assert.equal(run('encodeFrame(effects)[19]'),200);assert.equal(run('encodeFrame(effects)[3]'),120);
run('data.scenes[0].steps[0]=copy(setupDraft)');assert.equal(run('validateShow(data).lights[0].visualType'),'laser');assert.equal(run('validateShow(data).lights[1].visualType'),'fog');
assert.throws(()=>run('validateShow({...data,scenes:[{id:"bad",name:"Bad",steps:[{fade:0,hold:1,values:{[fogId]:{color:"#ffffff",level:10,channels:{0:999}}}}]}]})'));
assert.equal(run('resizeEffectMapping({mapping:"F",visualType:"fog"},3).mapping'),'F,U,U');assert.equal(run('resizeEffectMapping({mapping:"U,U,U,U",visualType:"laser"},2).mapping'),'U,U');assert.throws(()=>run('resizeEffectMapping({mapping:"U"},513)'));
assert(run('presetsForType("laser").every(([mapping])=>mapping.split(",").every(channel=>channel==="U"))'));assert(run('presetsForType("fog").every(([mapping])=>mapping.includes("F"))'));
assert(run('presetsForType("par").every(([mapping])=>!mapping.includes("F"))'));assert(run('presetsForType("strip").every(([mapping])=>!mapping.includes("F"))'));
assert(run('universalChannelControls(data.lights).includes("Nebelausstoß")'));assert.equal((run('universalChannelControls(data.lights)').match(/data-channel-offset=/g)||[]).length,10);
run('stopEffectDevices()');assert.equal(run('encodeFrame(setupDraft)[19]'),0);assert.equal(run('encodeFrame(setupDraft)[3]'),0);assert.equal(run('encodeFrame(setupDraft)[29]'),255);
run('tab=1;fixture="new";prepareFixtureDraft();fixtureDraft.visualType="laser";fixtureDraft.mapping=deviceTypes.laser.mapping;render()');assert(nodes.get('#screen').innerHTML.includes('name="visualType" value="laser"'));assert(nodes.get('#screen').innerHTML.includes('universal-channel-count'));

run('addFixtureBatch({name:"Fog mixed",visualType:"fog",mode:"Eigenes Profil",mapping:"D,F,R,G,B",address:60,group:"Effekte"},1);var mixedFog=data.lights.at(-1).id;setFixtureChannel(mixedFog,0,0);setFixtureChannel(mixedFog,1,200);setupSelection.add(mixedFog);var fogFrame=JSON.stringify(encodeFrame(setupDraft).slice(59,64));applySetupValue("color","#00ff00")');assert.equal(run('JSON.stringify(encodeFrame(setupDraft).slice(59,64))'),run('fogFrame'));
run('addFixtureBatch({name:"Strobe raw",visualType:"strobe",mode:"Eigenes Profil",mapping:"D,S",address:80,group:"Licht"},1);var rawStrobe=data.lights.at(-1).id;setFixtureChannel(rawStrobe,0,91);setFixtureChannel(rawStrobe,1,220);setupSelection.clear();setupSelection.add(rawStrobe);applySetupValue("strobe",33)');assert.equal(run('encodeFrame(setupDraft)[79]'),91);assert.equal(run('encodeFrame(setupDraft)[80]'),33);
console.log('Passed: effect fixture channels survive global color changes; strobe changes preserve raw dimmer and replace raw strobe.');
console.log('Passed: universal laser/fog profiles, raw channel output and limits, retained values, White/Blackout behaviour, effect isolation, show import and individual stop.');
`;
new Function('require','process',harness+checks)(require,process);
