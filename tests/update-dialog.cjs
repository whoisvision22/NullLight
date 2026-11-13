const fs=require('fs');let source=fs.readFileSync('tests/workspace.cjs','utf8').replace('run(js);',`run(js.replace('const nativeAvailable=Boolean(window.lichtpultSession);','let nativeAvailable=false;'));`);
source+=String.raw`
return (async()=>{
 const dialog=document.querySelector('#update-dialog');dialog.showModal=function(){this.open=true};dialog.close=function(){this.open=false};
 run('nativeAvailable=true;tab=3;updateInfo=null;openUpdatesDialog()');assert.equal(run('tab'),3);assert.equal(dialog.open,true);assert(dialog.innerHTML.includes('Herunterladen und neu starten'));assert(dialog.innerHTML.includes('Schließen / Abbrechen'));
 run('nativeRequest=async()=>({state:"available",version:26,runningVersion:25,displayVersion:"0.2.5",message:"Version 0.2.5 ist verfügbar."})');await run('checkUpdates()');assert.equal(run('updateInfo.state'),'available');assert(dialog.innerHTML.includes('0.2.5'));
 context.setTimeout=callback=>{callback();return 1};
 run('var restartCount=0,polls=0;restartForUpdate=()=>restartCount++;nativeRequest=async path=>path==="/api/update/start"?{state:"downloading",progress:0}:++polls===1?{state:"verifying",progress:85}:{state:"ready",version:26,stagedVersion:26,runningVersion:25}');await run('downloadAndRestart()');assert.equal(run('restartCount'),1);assert.equal(run('polls'),2);
 run('updateBusy=false;openUpdatesDialog();nativeRequest=async()=>({state:"error",message:"checksum mismatch"})');await run('downloadAndRestart()');assert.equal(run('restartCount'),1);assert(dialog.innerHTML.includes('checksum mismatch'));
 let resolveStart;context.startGate=()=>new Promise(resolve=>resolveStart=resolve);run('openUpdatesDialog();var cancelCalls=0;nativeRequest=async path=>path==="/api/update/start"?await startGate():(cancelCalls++,{state:"cancelled"})');const pending=run('downloadAndRestart()');await run('closeUpdatesDialog()');resolveStart({state:'ready',version:26});await pending;assert.equal(run('restartCount'),1);assert.equal(dialog.open,false);assert(run('cancelCalls')>=1);
 run('nativeAvailable=false;data.scenes[0].steps=[newStep(),newStep(),newStep()];editing=data.scenes[0].id;stepIndex=1;loadSetupStep();selectedStepRefs.clear();selectAllProgramSteps()');assert.equal(run('selectedProgramSteps().length'),3);assert.equal(run('stepIndex'),1);run('setProgramTiming("hold",4)');assert.equal(run('current().steps.every(step=>step.hold===4)'),true);assert(html.includes('user-select:none'));
 console.log('Passed: update dialog retains current screen, check/download/verify/restart, error handling, cancel-before-response prevents restart; select all steps updates all timings.');
})();`;
Promise.resolve(new Function('require','process',source)(require,process)).catch(error=>{console.error(error);process.exitCode=1});
