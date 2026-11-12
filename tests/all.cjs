const fs=require('fs');let test=fs.readFileSync('tests/performance.cjs','utf8');const add=`
run('data.scenes[0].steps=[newStep(),newStep(),newStep()];editing=data.scenes[0].id;stepIndex=0;tab=3;loadSetupStep();selectedStepRefs.clear();selectProgramStep(1,true);loadSetupStep()');
assert.equal(run('selectedProgramSteps().length'),2);run('setProgramTiming("hold",4.5)');assert.equal(run('current().steps[0].hold'),4.5);assert.equal(run('current().steps[1].hold'),4.5);assert.equal(run('current().steps[2].hold'),2);
run('setProgramTiming("darkAfter",true)');assert.equal(run('current().steps[0].darkAfter'),true);assert.equal(run('current().steps[1].darkAfter'),true);assert.equal(run('current().steps[2].darkAfter'),undefined);
run('selectProgramStep(2,false);loadSetupStep();setProgramTiming("fade",1.25)');assert.equal(run('selectedProgramSteps().length'),1);assert.equal(run('current().steps[2].fade'),1.25);assert.equal(run('current().steps[0].fade'),0);
run('data.masterGroups[0].collapsed=true;data.masterGroupsCollapsed=true');assert.equal(run('validateShow(data).masterGroups[0].collapsed'),true);assert.equal(run('validateShow(data).masterGroupsCollapsed'),true);
run('tab=2;bankFilter="";render()');assert.equal((nodes.get('#screen').innerHTML.match(/class="performance-number"/g)||[]).length,48);
run('createPerformanceSlot(48)');assert.equal(run('tab'),3);assert.equal(run('current().buttonNumber'),48);assert.equal(run('performanceNumber(current())'),48);assert.equal(run('performanceNumber(data.scenes[0])'),1);assert.equal(run('current().live'),false);
run('tab=2;render()');assert(nodes.get('#screen').innerHTML.includes('Button 48 programmieren'));
console.log('Passed: multiple-step timing, selection reset, collapsed masters, 48-cell grid and draft slot creation.');
`;
test=test.replace("console.log('Passed: six recent colors;",add+"console.log('Passed: six recent colors;");new Function('require','process',test)(require,process);
