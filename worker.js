(async () => {
  try {
    importScripts("formicid.js");
    const module = await Module();
    const send = module.cwrap("recv", null, ["number", "number", "string"]),
      advance = module.cwrap("advance", null, ["number", "number"]),
      bootstrap = await (await fetch("i.stor")).text();
    onmessage = (evt) => {
      const [slot, ...rest] = evt.data;
      rest.forEach((x) => {
        let [fmt, payload] = x;
        switch (fmt) {
          case -1:
            advance(slot, payload);
            break;
          default:
            if (typeof payload !== "string") payload = JSON.stringify(x);
            send(slot, fmt, payload);
        }
      });
    };
    send(0, 0, bootstrap);
    advance(0, -1);
  } catch (e) {
    postMessage(e);
  }
})();
