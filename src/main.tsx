/* @refresh reload */

import "solid-devtools";

import { render } from "solid-js/web";
import { createSignal, onMount } from "solid-js";

import "./style.css";
import Worker from "./worker.ts?worker";
import STORM from "./storm";
import header from "./header";
import examples from "./examples";

const worker = (window.$worker = new Worker());

function App() {
  const [tuck, setTuck] = createSignal(true);
  const [runImmediately, setRunImmediately] = createSignal(true);
  const [refresh, setRefresh] = createSignal(false);
  const [streamIn, setStreamIn] = createSignal("");
  const [ipf, setIpf] = createSignal(10000);
  const [steps, setSteps] = createSignal(1);
  const [logs, setLogs] = createSignal<string[]>([]);

  function step() {
    setRefresh(false);
    worker.postMessage([0, [-1, Number(steps())], [-2]]);
  }

  let streamEl: HTMLTextAreaElement,
    goEl: HTMLInputElement,
    formEl: HTMLFormElement, logsEl: HTMLDivElement;

  function streamElResize() {
    streamEl.style.height = "0";
    streamEl.style.height = `${streamEl.scrollHeight}px`;
  }

  onMount(() => {
    formEl.addEventListener("submit", (e) => {
      e.preventDefault();
      setLogs([...logs(), streamIn()]);
      logsEl.scrollTop = logsEl.scrollHeight;
      setRefresh(runImmediately());
      worker.postMessage([0, [tuck(), streamIn()]]);
    });
    streamEl.addEventListener("keydown", (e) => {
      if (e.key === "Enter" && e.ctrlKey) {
        e.preventDefault();
        goEl.click();
      }
    });
    streamEl.addEventListener("input", streamElResize);
    streamElResize();

    worker.onmessage = (evt) => {
      if (evt.data) {
        console.log(`Failed loading: ${evt.data}`);
      } else {
        const raf = () => {
          if (refresh()) {
            worker.postMessage([0, [-1, ipf()], [-2]]);
          }
          requestAnimationFrame(raf);
        };
        requestAnimationFrame(raf);
        worker.onmessage = (e) => {
          eval(e.data);
        };
      }
    };
  });

  return (
    <>
      {header}
      <form ref={(el) => (formEl = el)}>
        <h2>Playground</h2>
        <div id="logs" ref={(el) => logsEl = el}>
          {logs().map((e) => (
            <pre>{e}</pre>
          ))}
        </div>
        <p>
          <textarea
            id="instructions"
            placeholder="Enter instructions, then press ⌃ + ⏎ or hit submit"
            ref={(el) => (streamEl = el)}
            value={streamIn()}
            onChange={(e) => setStreamIn(e.target.value)}
          />
          <br />
          examples: {Object.entries(examples).map(([name, code]) => (
            <span>
              <a
                href="#"
                onClick={(e) => {
                  e.preventDefault();
                  setStreamIn(code);
                  streamElResize();
                }}
              >
                {name}
              </a>{" "}
            </span>
          ))}
          <br />
          <input
            type="checkbox"
            id="tuck"
            checked={tuck()}
            onChange={() => setTuck(!tuck())}
          />
          <label for="tuck">tuck front of stream</label>
          <input
            type="checkbox"
            id="runImmediately"
            checked={runImmediately()}
            onChange={() => setRunImmediately(!runImmediately())}
          />
          <label for="runImmediately">run immediately</label>{" "}
          <input type="submit" value="submit" ref={(el) => (goEl = el)} />
        </p>
      </form>
      <p>
        <button onclick={step}>step</button> through{" "}
        <input
          id="steps"
          type="number"
          value={steps()}
          onChange={(e) => setSteps(Number(e.target.value))}
        />{" "}
        instructions
      </p>
      <p>
        <button onclick={() => setRefresh(true)}>run</button> at{" "}
        <input
          id="ipf"
          type="number"
          value={ipf()}
          step="1000"
          onChange={(e) => setIpf(Number(e.target.value))}
        />{" "}
        forms/frame
      </p>
      <p>
        <button onClick={() => worker.postMessage([0, [-3]])}>de-fault</button>{" "}
        <button onClick={() => worker.postMessage([0, [1, "clear-data"]])}>
          clear-data
        </button>{" "}
        <button onClick={() => worker.postMessage([0, [1, "clear-stream"]])}>
          clear-stream
        </button>
      </p>
      <STORM />
    </>
  );
}

render(App, document.getElementById("app")!);

// Array.from(document.querySelectorAll(".evaluable")).forEach((c) => {
//   (c as HTMLLinkElement).onclick = (e) => {
//     e.preventDefault();
//     instructions.value = c.textContent || "";
//     iResetSize();
//   };
// });
