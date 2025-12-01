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
}

main();
