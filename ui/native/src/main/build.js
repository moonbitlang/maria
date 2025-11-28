const esbuild = require("esbuild");

(async () => {
  const ctx = await esbuild.context({
    entryPoints: ["./main.ts"],
    external: ["electron"],
    outdir: "../../dist/main",
    bundle: true,
    format: "cjs",
    platform: "node",
  });

  if (process.argv.includes("--watch")) {
    await ctx.watch();
  } else {
    await ctx.rebuild();
    process.exit(0);
  }
})();
