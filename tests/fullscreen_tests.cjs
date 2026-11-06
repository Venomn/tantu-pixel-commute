const {test}=require('node:test');const assert=require('node:assert/strict');const vm=require('node:vm');const fs=require('node:fs');
const code=fs.readFileSync('tools/mobile_shell.html','utf8').match(/<script id="tantu-fullscreen">([\s\S]*?)<\/script>/)[1];
function setup(mode){
 const events={};const nodes={};for(const id of ['fullscreen-toggle','fullscreen-help','fullscreen-message','fullscreen-dismiss'])nodes[id]={hidden:true,setAttribute(){},addEventListener(name,cb){this[name]=cb;}};
 const document={getElementById:id=>nodes[id],addEventListener:(name,cb)=>events[name]=cb,documentElement:{}};
 let calls=0;let pauses=0;
 if(mode!=='unsupported')document.documentElement.requestFullscreen=async()=>{calls++;if(mode==='reject')throw Error('denied');document.fullscreenElement=document.documentElement;events.fullscreenchange();};
 document.exitFullscreen=async()=>{document.fullscreenElement=null;events.fullscreenchange();};
 vm.runInNewContext(code,{document,window:{tantuPause:()=>pauses++,addEventListener:(name,cb)=>events[name]=cb,navigator:{standalone:mode==='standalone'},matchMedia:()=>({matches:false})}});
 return{nodes,document,events,calls:()=>calls,pauses:()=>pauses,click:()=>nodes['fullscreen-toggle'].click()};
}
test('does not enter full screen without a click',()=>assert.equal(setup('supported').calls(),0));
test('supported browser enters and exits actual fullscreen state',async()=>{const e=setup('supported');await e.click();assert.ok(e.document.fullscreenElement);assert.equal(e.nodes['fullscreen-toggle'].textContent,'退出全屏');await e.click();assert.equal(e.document.fullscreenElement,null);});
test('unsupported browser explains home-screen fallback',async()=>{const e=setup('unsupported');await e.click();assert.equal(e.nodes['fullscreen-help'].hidden,false);assert.match(e.nodes['fullscreen-message'].textContent,/添加到主屏幕/);assert.equal(e.nodes['fullscreen-toggle'].textContent,'⛶ 全屏');});
test('rejected request is not presented as successful',async()=>{const e=setup('reject');await e.click();assert.equal(e.nodes['fullscreen-help'].hidden,false);assert.equal(e.nodes['fullscreen-toggle'].textContent,'⛶ 全屏');});
test('standalone launch indicates app display mode',()=>{const e=setup('standalone');assert.equal(e.nodes['fullscreen-toggle'].disabled,true);});
test('escape or browser exit updates the button',async()=>{const e=setup('supported');await e.click();e.document.fullscreenElement=null;e.events.fullscreenchange();assert.equal(e.nodes['fullscreen-toggle'].textContent,'⛶ 全屏');});

test('fullscreen and help pause gameplay before covering controls',async()=>{const e=setup('unsupported');await e.click();assert.equal(e.pauses(),1);});
test('backgrounding and focus loss request pause',()=>{const e=setup('supported');e.document.hidden=true;e.events.visibilitychange();e.events.blur();assert.equal(e.pauses(),2);});
