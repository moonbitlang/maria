import type { OpenDialogReturnValue } from "electron";
export interface ElectronAPI {
  selectDirectory: () => Promise<OpenDialogReturnValue>;
  getUrl: () => Promise<string>;
  mariaReady: () => Promise<void>;
  reloadApp: () => Promise<void>;
}
