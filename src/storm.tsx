import { createSignal, Show } from "solid-js";

import { Sap, Type, SapView } from "./sap";

function storm() {
  const [getState, setState] = createSignal<Sap>([Type.Undef]);
  window.$ui = setState;

  return (
    <>
      <Show when={getState()[0] === Type.Undef}>
        <p>
          <em>Loading…</em>
        </p>
      </Show>
      <Show when={getState()[0] !== Type.Undef}>
        <table>
          <thead>
            <tr>
              <th>State</th>
              <th>Fault</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td>
                <SapView value={getState()[1] as Sap} />
              </td>
              <td>
                <SapView value={getState()[2] as Sap} />
              </td>
            </tr>
          </tbody>
        </table>
        <table>
          <thead>
            <tr>
              <th>Contexts</th>
              <th>Data</th>
              <th>Stream</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td>
                <SapView value={getState()[3] as Sap} />
              </td>
              <td>
                <SapView value={getState()[4] as Sap} />
              </td>
              <td>
                <SapView value={getState()[5] as Sap} />
              </td>
            </tr>
          </tbody>
        </table>
      </Show>
    </>
  );
}

export default storm;
