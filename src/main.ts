import Worker from "./worker.js?worker";
import "./style.css";

declare global {
  interface Window {
    $worker: Worker;
    $target: HTMLElement;
    $refresh: boolean;
  }
}

const r = document.getElementById("root")!,
  s = document.getElementById("stream")!,
  i = document.getElementById("instructions")! as HTMLInputElement,
  t = document.getElementById("tuck")! as HTMLInputElement,
  l = document.getElementById("log")!,
  g = document.getElementById("go")!,
  runImmediately = document.getElementById("run")! as HTMLInputElement,
  steps = document.getElementById("steps")! as HTMLInputElement,
  ipf = document.getElementById("ipf")! as HTMLInputElement;

i.addEventListener("keydown", (e) => {
  if (e.key === "Enter" && e.ctrlKey) {
    e.preventDefault();
    g.click();
  }
});

function iResetSize() {
  i.style.height = "0";
  i.style.height = `${i.scrollHeight}px`;
}
i.addEventListener("input", iResetSize);
Array.from(document.querySelectorAll(".evaluable")).forEach((c) => {
  (c as HTMLLinkElement).onclick = (e) => {
    e.preventDefault();
    i.value = c.textContent || "";
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
    r.style.display = "block";
  }
};

s.addEventListener("submit", (e) => {
  e.preventDefault();
  let log = document.createElement("pre");
  log.textContent = i.value;
  l.appendChild(log);
  worker.postMessage([0, [Number(t.checked), i.value]]);
  if (runImmediately.checked) {
    window.$refresh = true;
  } else {
    window.$refresh = false;
  }
});

export function step() {
  window.$worker.postMessage([0, [-1, steps.value], [-2]]);
}
