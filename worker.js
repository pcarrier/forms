try {
  importScripts("formicid.js");
  //const eval_stor = Module.cwrap("eval_stor", null, ["string"]);
  const loop = Module.cwrap("loop", null, ["number"]);
  self.onmessage = (evt) => loop(evt.data);
  self.postMessage(undefined);
} catch (e) {
  self.postMessage(e);
}
