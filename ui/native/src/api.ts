import type { OpenDialogReturnValue } from "electron";
export interface ElectronAPI {
  selectDirectory: () => Promise<OpenDialogReturnValue>;
}
