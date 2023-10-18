try {
  importScripts("formicid.js");
  const eval_stor = Module.cwrap("eval_stor", null, ["string"]);
  self.onmessage = (evt) => eval_stor(evt.data);
  self.postMessage(undefined);
} catch (e) {
  self.postMessage(e);
}
