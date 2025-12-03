import cp from "child_process";
import {
  app,
  BrowserWindow,
  dialog,
  ipcMain,
  OpenDialogReturnValue,
} from "electron";
import started from "electron-squirrel-startup";
import fs from "fs";
import os from "os";
import path from "path";
import { getResolvedShellEnv } from "./shellEnv";

// Handle creating/removing shortcuts on Windows when installing/uninstalling.
if (started) {
  app.quit();
}

let mainWindow: BrowserWindow | null;

function createWindow() {
  // Create the browser window.
  mainWindow = new BrowserWindow({
    width: 800,
    height: 600,
    webPreferences: {
      preload: path.join(__dirname, "../preload/preload.js"),
    },
  });

  // and load the index.html of the app.
  if (process.env.MARIA_DEV) {
    mainWindow.loadURL(`http://localhost:5173`);
    // Open the DevTools.
    mainWindow.webContents.openDevTools();
  } else {
    mainWindow.loadFile(path.join(__dirname, `../renderer/index.html`));
  }
}

let url = "";
let unixShellEnvPromise: Promise<void> | undefined = undefined;

async function setupMariaProcess() {
  if (unixShellEnvPromise) {
    return await unixShellEnvPromise;
  }
  unixShellEnvPromise = doSetupMariaProcess();
  return await unixShellEnvPromise;
}

async function doSetupMariaProcess() {
  try {
    const shellEnv = await getResolvedShellEnv();
    const mariaPath = process.env.MARIA_DEV
      ? path.join(
          __dirname,
          "../../../../target/native/release/build/cmd/main/main.exe",
        )
      : path.join(__dirname, "../../app.asar.unpacked/bin/maria");

    const exitCode = await new Promise<number>((resolve, reject) => {
      const maria = cp.spawn(mariaPath, ["daemon", "--port", "0", "--detach"], {
        stdio: "ignore",
        env: shellEnv,
      });

      maria.on("error", reject);
      maria.on("exit", (code) => {
        resolve(code);
      });
    });

    if (exitCode !== 0) {
      if (shellEnv["OPENAI_API_KEY"] === undefined)
        throw new Error("OPENAI_API_KEY is not set in the shell environment");
      throw new Error(`Maria daemon exited with code ${exitCode}`);
    }

    const daemonJsonPath = path.join(os.homedir(), ".moonagent", "daemon.json");
    const daemonJson: { pid: number; port: number } = JSON.parse(
      fs.readFileSync(daemonJsonPath, "utf-8"),
    );
    url = `http://localhost:${daemonJson.port}/v1`;
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : String(error);
    dialog.showErrorBox("Maria Startup Error", errorMessage);
    app.quit();
  }
}

const onReady = () => {
  // dont await the promise, we will show a loading screen in the renderer
  setupMariaProcess();
  createWindow();
};

// This method will be called when Electron has finished
// initialization and is ready to create browser windows.
// Some APIs can only be used after this event occurs.
app.on("ready", onReady);

// Quit when all windows are closed, except on macOS. There, it's common
// for applications and their menu bar to stay active until the user quits
// explicitly with Cmd + Q.
app.on("window-all-closed", () => {
  if (process.platform !== "darwin") {
    app.quit();
  }
});

app.on("activate", () => {
  // On OS X it's common to re-create a window in the app when the
  // dock icon is clicked and there are no other windows open.
  if (BrowserWindow.getAllWindows().length === 0) {
    createWindow();
  }
});

// In this file you can include the rest of your app's specific main process
// code. You can also put them in separate files and import them here.
ipcMain.handle("select-directory", async (): Promise<OpenDialogReturnValue> => {
  if (!mainWindow) return { canceled: true, filePaths: [] };
  return await dialog.showOpenDialog(mainWindow, {
    properties: ["openDirectory", "createDirectory", "promptToCreate"],
  });
});

ipcMain.handle("get-url", () => {
  return url;
});

ipcMain.handle("maria-ready", async () => {
  await setupMariaProcess();
});
