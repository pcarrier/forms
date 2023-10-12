try {
  self.Module = {};
  importScripts('formicid.js');
  const send = Module.cwrap('recv', null, ['number', 'number', 'string']);
  onmessage = (evt) => {
    const [slot, ...rest] = evt.data;
    rest.forEach((x) => {
      let [fmt, payload] = x;
      if (typeof payload !== 'string') payload = JSON.stringify(x);
      send(slot, fmt, payload);
    });
  }
} catch (e) {
  postMessage(e);
}
