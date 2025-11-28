#!/usr/bin/env node

const cp = require("child_process");
const fs = require("fs");
const { packager } = require("@electron/packager");

function sh(command) {
  cp.execSync(command, { stdio: "inherit" });
}

async function main() {
  // Build the native app
  sh("pnpm build");
}

main();
