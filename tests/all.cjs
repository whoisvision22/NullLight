const fs=require('fs');let test=fs.readFileSync('tests/performance.cjs','utf8');const add=`
run('data.scenes[0].steps=[newStep(),newStep(),newStep()];editing=data.scenes[0].id;stepIndex=0;tab=3;loadSetupStep();selectedStepRefs.clear();selectProgramStep(1,true);loadSetupStep()');
assert.equal(run('selectedProgramSteps().length'),2);run('setProgramTiming("hold",4.5)');assert.equal(run('current().steps[0].hold'),4.5);assert.equal(run('current().steps[1].hold'),4.5);assert.equal(run('current().steps[2].hold'),2);
run('setProgramTiming("darkAfter",true)');assert.equal(run('current().steps[0].darkAfter'),true);assert.equal(run('current().steps[1].darkAfter'),true);assert.equal(run('current().steps[2].darkAfter'),undefined);
run('selectProgramStep(2,false);loadSetupStep();setProgramTiming("fade",1.25)');assert.equal(run('selectedProgramSteps().length'),1);assert.equal(run('current().steps[2].fade'),1.25);assert.equal(run('current().steps[0].fade'),0);
run('data.masterGroups[0].collapsed=true;data.masterGroupsCollapsed=true');assert.equal(run('validateShow(data).masterGroups[0].collapsed'),true);assert.equal(run('validateShow(data).masterGroupsCollapsed'),true);
run('tab=2;bankFilter="";render()');assert.equal((nodes.get('#screen').innerHTML.match(/class="performance-number"/g)||[]).length,48);
run('createPerformanceSlot(48)');assert.equal(run('tab'),3);assert.equal(run('current().buttonNumber'),48);assert.equal(run('performanceNumber(current())'),48);assert.equal(run('performanceNumber(data.scenes[0])'),1);assert.equal(run('current().live'),false);
run('tab=2;render()');assert(nodes.get('#screen').innerHTML.includes('Button 48 programmieren'));

run('data.savedLayouts=[];data.activeLayoutId=null;data.lights[0].inLayout=true;data.lights[0].tilt={x:20,y:30,z:40};storeLayout("Bühne A")');
const firstLayout=run('data.activeLayoutId');
run('newLayout(false)');assert.equal(run('data.lights[0].inLayout'),false);
run('data.stage={width:14,depth:8};data.lights[0].inLayout=true;data.lights[0].tilt={x:0,y:0,z:90};save()');
const secondLayout=run('data.activeLayoutId');
run('loadLayout('+JSON.stringify(firstLayout)+')');assert.equal(run('data.lights[0].tilt.x'),20);assert.equal(run('data.lights[0].inLayout'),true);
run('loadLayout('+JSON.stringify(secondLayout)+')');assert.equal(run('data.stage.width'),14);assert.equal(run('data.lights[0].tilt.z'),90);
assert.equal(run('validateShow(data).savedLayouts.length'),2);assert.throws(()=>run('validateTilt({x:181})'));
assert.equal(run('Math.round(rotateFixture({x:0,y:0,z:-1},{x:90,y:0,z:0}).y)'),1);
run('tab=3;render()');assert(nodes.get('#screen').innerHTML.includes('scene-picker-list'));
run('tab=2;render()');assert(nodes.get('#screen').innerHTML.indexOf('panel master-panel')<nodes.get('#screen').innerHTML.indexOf('panel bank-list'));
console.log('Passed: independent saved layouts, stage/tilt persistence, import validation, scene chooser and bank/master order.');
console.log('Passed: multiple-step timing, selection reset, collapsed masters, 48-cell grid and draft slot creation.');
`;
test=test.replace("console.log('Passed: six recent colors;",add+"console.log('Passed: six recent colors;");new Function('require','process',test)(require,process);
