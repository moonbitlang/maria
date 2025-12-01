import {
  app,
  BrowserWindow,
  dialog,
  ipcMain,
  OpenDialogReturnValue,
} from "electron";
import path from "path";
import fs from "fs";
import os from "os";
import cp from "child_process";
import started from "electron-squirrel-startup";

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

function discoverMoonBitPath(): string {
  let moonHome;
  if (process.env.MOON_HOME) {
    moonHome = process.env.MOON_HOME;
  } else {
    moonHome = path.join(os.homedir(), ".moon");
  }
  return path.join(moonHome, "bin");
}

let url = "";
function spawnMariaProcess() {
  try {
    const newPath = process.env.PATH + path.delimiter + discoverMoonBitPath();
    const mariaPath = process.env.MARIA_DEV
      ? path.join(
          __dirname,
          "../../../../target/native/release/build/cmd/main/main.exe",
        )
      : path.join(__dirname, "../../app.asar.unpacked/bin/maria");

    const result = cp.spawnSync(
      mariaPath,
      ["daemon", "--port", "0", "--detach"],
      { stdio: "ignore", env: { ...process.env, PATH: newPath } },
    );

    if (result.error) {
      throw new Error(
        `Failed to spawn Maria daemon process:\n${result.error.message}\n\nPath: ${mariaPath}`,
      );
    }

    if (result.status !== 0) {
      const stderr = result.stderr?.toString() || "No error output";
      throw new Error(
        `Maria daemon exited with code ${result.status}:\n${stderr}`,
      );
    }

    const daemonJsonPath = path.join(os.homedir(), ".moonagent", "daemon.json");

    if (!fs.existsSync(daemonJsonPath)) {
      throw new Error(
        `Daemon configuration file not found:\n${daemonJsonPath}\n\nThe daemon may have failed to start properly.`,
      );
    }

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
  spawnMariaProcess();
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
