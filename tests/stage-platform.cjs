const fs=require('fs');
const harness=fs.readFileSync('tests/workspace.cjs','utf8').split('// Tests below')[0];
const checks=String.raw`
run('data={lights:[],scenes:[{id:"s",name:"Scene",live:true,steps:[newStep()]}],stage:{width:12,depth:8},savedLayouts:[],layoutVersion:1};editing="s";data.activeLayoutId=null;fixture=null;tab=1;render()');
assert.equal(run('defaultTabNames[1]'),'Lichter');assert.equal(run('defaultTabNames[3]'),'Szenen');
assert(!nodes.get('#screen').innerHTML.includes('id="light-form"'));assert(nodes.get('#screen').innerHTML.includes('aria-label="Licht hinzufügen"'));
run('fixture="new";render()');assert(nodes.get('#screen').innerHTML.includes('id="fixture-dialog"'));assert(nodes.get('#screen').innerHTML.includes('id="light-form"'));
assert(run('presetsForType("strobe").every(([mapping])=>mapping.includes("S"))'));assert(run('presetsForType("strip").every(([mapping])=>!mapping.includes("S"))'));
assert(run('presetsForType("par").some(([mapping])=>mapping==="R,G,B,W")'));assert(run('!presetsForType("par").some(([mapping])=>mapping==="D,S")'));
assert(run('mappingFields({visualType:"strobe",mapping:"D"}).includes("Gespeichertes Profil")'));
run('addPlatform()');assert.equal(run('stageSize().platform.width'),6);assert.equal(run('stageSize().platform.depth'),3);assert.equal(run('stageSize().platform.height'),.6);
run('setPlatform(platformAt(stageSize().platform,100,-100))');assert.equal(run('stageSize().platform.x'),6);assert.equal(run('stageSize().platform.y'),0);
run('setPlatform(platformAt(stageSize().platform,2.3,2.7))');assert.equal(run('stageSize().platform.x'),2.5);assert.equal(run('stageSize().platform.y'),2.5);
assert.throws(()=>run('setPlatform({...stageSize().platform,width:50})'));assert.throws(()=>run('setPlatform({...stageSize().platform,height:4})'));assert.throws(()=>run('validateStage({width:12,depth:8,platform:{x:0,y:0,width:2,depth:2,height:NaN}})'));
run('var layoutA=storeLayout("A");setPlatform({...stageSize().platform,x:1});var layoutB=storeLayout("B")');
// storeLayout updates the current record; a copy must retain independent geometry.
run('newLayout(true);var copyId=data.activeLayoutId;setPlatform({...stageSize().platform,x:0});loadLayout(layoutA)');assert.equal(run('stageSize().platform.x'),1);
run('loadLayout(copyId)');assert.equal(run('stageSize().platform.x'),0);
assert.equal(run('validateShow(data).stage.platform.height'),.6);assert.equal(run('validateShow(data).savedLayouts.find(item=>item.id===copyId).stage.platform.x'),0);
run('updateStage(2,2)');assert.equal(run('stageSize().platform.width'),2);assert.equal(run('stageSize().platform.depth'),2);assert.equal(run('stageSize().platform.x'),0);
run('tab=4;rigView.mode="2d";render()');assert(nodes.get('#screen').innerHTML.includes('class="stage-platform"'));assert(nodes.get('#screen').innerHTML.includes('id="platform-form"'));
run('rigView.mode="3d";var renderedPoints=[];drawPlatform({beginPath(){},moveTo(){},lineTo(){},closePath(){},fill(){},stroke(){},fillText(){}},p=>{renderedPoints.push(p);return p})');assert(run('renderedPoints.some(p=>p.z===.6)'));assert(run('renderedPoints.some(p=>p.z===0)'));
console.log('Passed: on-demand editor, short tabs, device-specific profiles, stage placement/snapping/bounds/resize, independent layouts, import and raised 3D geometry.');
`;
new Function('require','process',harness+checks)(require,process);
