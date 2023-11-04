/// <reference types="vite/client" />

import { Sap } from "./sap";

declare global {
  interface Window {
    $ui: (src: Sap) => void;
    $worker: Worker;
  }
}
