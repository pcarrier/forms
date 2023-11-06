import { useEffect, useRef, useState } from "react";

import STORM from "./storm";
import header from "./header";
import examples from "./examples";
import { Sap, Type } from "./sap";

function App({ worker }: { worker: Worker }) {
  const [rafRef, setRafRef] = useState<number>(0);

  const [tuck, setTuck] = useState(true);
  const [runImmediately, setRunImmediately] = useState(true);
  const refresh = useRef(false);
  const ipf = useRef(50000);
  const [steps, setSteps] = useState(1);
  const [logs, setLogs] = useState<string[]>([]);
  const [storm, setStorm] = useState<Sap>([Type.Undef]);
  const streamEl = useRef<HTMLPreElement>(null);
  const goEl = useRef<HTMLInputElement>(null);
  const formEl = useRef<HTMLFormElement>(null);
  const logsEl = useRef<HTMLDivElement>(null);

  window.$ui = setStorm;

  const animate = () => {
    if (refresh.current) {
      worker.postMessage([0, [-1, ipf.current], [-2]]);
    }
    setRafRef(requestAnimationFrame(animate));
  };

  useEffect(() => {
    animate();
    return () => cancelAnimationFrame(rafRef);
  }, [refresh]);

  return (
    <>
      {header}
      <form
        ref={formEl}
        onSubmit={(e) => {
          e.preventDefault();
          const streamIn = streamEl.current!.innerText;
          setLogs([...logs, streamIn]);
          logsEl.current!.scrollTop = logsEl.current!.scrollHeight;
          refresh.current = runImmediately;
          worker.postMessage([0, [tuck, streamIn], [-2]]);
        }}
      >
        <div id="logs" ref={logsEl}>
          {logs.map((e, i) => (
            <pre key={i}>{e}</pre>
          ))}
        </div>
        examples:{" "}
        {Object.entries(examples).map(([name, code], i) => (
          <span key={i}>
            <a
              href="#"
              onClick={(e) => {
                e.preventDefault();
                streamEl.current!.innerText = code;
              }}
            >
              {name}
            </a>{" "}
          </span>
        ))}
        <pre
          contentEditable="plaintext-only"
          id="instructions"
          onKeyDown={(e) => {
            if (e.key === "Enter" && (e.ctrlKey || e.metaKey)) {
              e.preventDefault();
              goEl.current!.click();
            }
          }}
          ref={streamEl}
        />
        <p>
          <input
            type="checkbox"
            id="tuck"
            checked={tuck}
            onChange={() => setTuck(!tuck)}
          />
          <label htmlFor="tuck">tuck front of stream</label>
          <input
            type="checkbox"
            id="runImmediately"
            checked={runImmediately}
            onChange={() => setRunImmediately(!runImmediately)}
          />
          <label htmlFor="runImmediately">run immediately</label>{" "}
          <input type="submit" value="submit" ref={goEl} />
        </p>
      </form>
      <p>
        <button
          onClick={() => {
            refresh.current = false;
            worker.postMessage([0, [-1, steps], [-2]]);
          }}
        >
          step
        </button>{" "}
        through{" "}
        <input
          id="steps"
          type="number"
          value={steps}
          min="1"
          onChange={(e) =>
            setSteps(Number((e.target as HTMLInputElement).value))
          }
        />{" "}
        instructions
      </p>
      <p>
        <button onClick={() => (refresh.current = true)}>run</button> at{" "}
        <input
          id="ipf"
          type="number"
          min="0"
          value={ipf.current}
          onChange={(e) =>
            (ipf.current = Number((e.target as HTMLInputElement).value))
          }
        />{" "}
        forms/frame
      </p>
      <p>
        <button onClick={() => worker.postMessage([0, [-3], [-2]])}>de-fault</button>{" "}
        <button onClick={() => worker.postMessage([0, [1, "clear-data"], [-2]])}>
          clear-data
        </button>{" "}
        <button onClick={() => worker.postMessage([0, [1, "clear-stream"], [-2]])}>
          clear-stream
        </button>
      </p>
      <STORM state={storm} />
    </>
  );
}

export default App;
