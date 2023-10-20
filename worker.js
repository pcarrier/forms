try {
  importScripts("formicid.js");
  const sendMsg = Module.cwrap("sendMsg", null, ["number", "string"]);
  self.onmessage = (evt) => sendMsg(...evt.data);
} catch (e) {
  self.postMessage(e);
}
