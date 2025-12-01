#!/usr/bin/env node

const cp = require("child_process");
const fs = require("fs");
const path = require("path");
const { packager } = require("@electron/packager");

function sh(command, options = {}) {
  cp.execSync(command, { stdio: "inherit", ...options });
}

function buildUI() {
  sh("pnpm build");
}

function buildMaria() {
  sh("moon build", { cwd: path.join(__dirname, "..") });
  fs.mkdirSync("./dist/bin", { recursive: true });
  fs.copyFileSync(
    "../../target/native/release/build/cmd/main/main.exe",
    "./dist/bin/maria",
  );
}

function dateString() {
  const now = new Date();
  const year = now.getFullYear();
  const month = String(now.getMonth() + 1).padStart(2, "0");
  const day = String(now.getDate()).padStart(2, "0");
  return `${year}-${month}-${day}`;
}

const today = dateString();

async function main() {
  // Build the native app
  buildUI();
  buildMaria();
  fs.copyFileSync("./package.dist.json", "./dist/package.json");

  fs.rmSync("./out", { recursive: true, force: true });
  await packager({
    asar: {
      unpackDir: "bin",
    },
    dir: "./dist",
    platform: "darwin",
    arch: "arm64",
    out: "./out",
    overwrite: true,
    quiet: false,
    osxSign: true,
  });
  sh("zip -r -X -y ../maria.zip Maria.app", {
    cwd: "./out/Maria-darwin-arm64",
  });
  sh(
    `rclone copyto -P ./out/maria.zip minio:maria-electron/${today}/darwin-arm64/maria.zip`,
  );

  console.log("Build and upload completed.");

  console.log(
    `Download url: http://192.168.209.231:9000/maria-electron/${today}/darwin-arm64/maria.zip`,
  );
}

main();
