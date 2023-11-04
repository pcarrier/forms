import Worker from "./worker.js?worker";
import "./style.css";

declare global {
  interface Window {
    $worker: Worker;
    $target: HTMLElement;
    $refresh: boolean;
  }
}

const root = document.getElementById("root")!,
  stream = document.getElementById("stream")!,
  instructions = document.getElementById("instructions")! as HTMLInputElement,
  tuck = document.getElementById("tuck")! as HTMLInputElement,
  logs = document.getElementById("log")!,
  go = document.getElementById("go")!,
  runImmediately = document.getElementById("run")! as HTMLInputElement,
  steps = document.getElementById("steps")! as HTMLInputElement,
  ipf = document.getElementById("ipf")! as HTMLInputElement;

instructions.addEventListener("keydown", (e) => {
  if (e.key === "Enter" && e.ctrlKey) {
    e.preventDefault();
    go.click();
  }
});

function iResetSize() {
  instructions.style.height = "0";
  instructions.style.height = `${instructions.scrollHeight}px`;
}
instructions.addEventListener("input", iResetSize);
Array.from(document.querySelectorAll(".evaluable")).forEach((c) => {
  (c as HTMLLinkElement).onclick = (e) => {
    e.preventDefault();
    instructions.value = c.textContent || "";
    iResetSize();
  };
});

const worker = new Worker();
window.$worker = worker;
window.$target = document.getElementById("target")!;
window.$refresh = false;
// First message indicates the worker has started.
worker.onmessage = (evt) => {
  if (evt.data) {
    console.log(`Failed loading: ${evt.data}`);
  } else {
    const raf = () => {
      if (window.$refresh) {
        worker.postMessage([0, [-1, ipf.value], [-2]]);
      }
      requestAnimationFrame(raf);
    };
    requestAnimationFrame(raf);
    worker.onmessage = (evt) => eval(evt.data);
    root.style.display = "block";
  }
};

stream.addEventListener("submit", (e) => {
  e.preventDefault();
  let log = document.createElement("pre");
  log.textContent = instructions.value;
  logs.appendChild(log);
  logs.scrollTop = logs.scrollHeight;
  worker.postMessage([0, [Number(tuck.checked), instructions.value]]);
  if (runImmediately.checked) {
    window.$refresh = true;
  } else {
    window.$refresh = false;
  }
});

export function step() {
  window.$worker.postMessage([0, [-1, steps.value], [-2]]);
}
