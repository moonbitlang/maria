import path from "path";
import tailwindcss from "@tailwindcss/vite";
import react from "@vitejs/plugin-react";
import { defineConfig } from "vite";

export default defineConfig(({ mode }) => {
  const isVSCode = mode === "vscode";

  return {
    plugins: [react(), tailwindcss()],
    resolve: {
      alias: {
        "@/components/ai": path.resolve(
          __dirname,
          "./src/components/ui/shadcn-io/ai",
        ),
        "@repo/shadcn-ui": path.resolve(__dirname, "./src"),
        "@": path.resolve(__dirname, "./src"),
      },
    },
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
