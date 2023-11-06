import { Sap, Type, SapView } from "./sap";

function storm({ state }: { state: Sap }) {
  if (state[0] === Type.Undef) {
    return (
      <p>
        <em>Loading…</em>
      </p>
    );
  }

  return (
    <>
      <table>
        <tbody>
          <tr>
            <th>State</th>
            <th>Step &amp; primitive</th>
            <th>Fault</th>
          </tr>
          <tr>
            <td>
              <SapView value={state[1] as Sap} />
            </td>
            <td>
              <SapView value={state[2] as Sap} />
              <SapView value={state[3] as Sap} />
            </td>
            <td>
              <SapView value={state[4] as Sap} />
            </td>
          </tr>
        </tbody>
      </table>
      <table>
        <tbody>
          <tr>
            <th>Contexts</th>
            <th>Data</th>
            <th>Stream</th>
          </tr>
          <tr>
            <td>
              <SapView value={state[5] as Sap} />
            </td>
            <td>
              <SapView value={state[6] as Sap} />
            </td>
            <td>
              <SapView value={state[7] as Sap} />
            </td>
          </tr>
        </tbody>
      </table>
    </>
  );
}

export default storm;
