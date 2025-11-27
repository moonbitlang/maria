import tailwindcss from "@tailwindcss/vite";
import react from "@vitejs/plugin-react";
import { defineConfig } from "vite";

export default defineConfig(({ mode }) => {
  const isVSCode = mode === "vscode";

  return {
    plugins: [react(), tailwindcss()],
    build: {
      emptyOutDir: true,
      outDir: isVSCode ? "../vsc-ext/webview" : "dist",
      minify: isVSCode ? false : true,
      rollupOptions: isVSCode
        ? {
            output: {
              entryFileNames: `[name].js`,
              chunkFileNames: `[name].js`,
              assetFileNames: `[name].[ext]`,
            },
          }
        : undefined,
    },
  };
});
