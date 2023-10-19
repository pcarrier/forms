try {
  importScripts("formicid.js");
  self.onmessage = (evt) => sendSTOR(evt.data);
  self.postMessage(undefined);
} catch (e) {
  self.postMessage(e);
}
