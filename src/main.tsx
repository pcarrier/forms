import "./style.css";
import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import Worker from "./worker.ts?worker";
import App from "./app.tsx";

const worker = (window.$worker = new Worker());

worker.onmessage = (e) => {
  try {
    eval(e.data);
  } catch (err) {
    console.error(err, e.data);
  }
};

const root = createRoot(document.getElementById("app")!);

root.render(
  <StrictMode>
    <App worker={worker} />
  </StrictMode>
);
