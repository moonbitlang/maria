declare global {
  interface Window {
    electronAPI?: {
      getUrl: () => Promise<string>;
    };
  }
}
