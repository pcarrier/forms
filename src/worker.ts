import Module from "./formicid.js";
import stork from "./stork.stor?raw";

(async () => {
  const module = await Module();

  const send = module.cwrap("recv", null, ["number", "number", "string"]),
    advance = module.cwrap("advance", null, ["number", "number"]),
    displayVM = module.cwrap("displayVM", null, ["number"]),
    deFault = module.cwrap("deFault", null, ["number"]);

  try {
    onmessage = (evt) => {
      const [slot, ...rest] = evt.data;
      rest.forEach((x: [number, any]) => {
        let [fmt, payload] = x;
        switch (fmt) {
          case -3:
            deFault(slot);
            break;
          case -2:
            displayVM(slot);
            break;
          case -1:
            const start = performance.now();
            advance(slot, payload);
            const elapsed = performance.now() - start;
            if (elapsed > 10) console.log(`spent ${elapsed}ms`);
            break;
          default:
            if (typeof payload !== "string") payload = JSON.stringify(x);
            send(slot, fmt, payload);
        }
      });
    };

    send(0, 0, stork);
    advance(0, -1);
    displayVM(0);
  } catch (e) {
    console.log(e);
  }
})();
