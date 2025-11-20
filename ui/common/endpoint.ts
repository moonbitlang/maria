export interface Endpoint {
  addEventListener: (type: string, listener: (event: unknown) => void) => void;
  removeEventListener: (
    type: string,
    listener: (event: unknown) => void,
  ) => void;
  postMessage: (message: unknown) => void;
}

export interface EndpointProvider {
  addEventListener: (type: string, listener: (event: any) => void) => void;
}

export function newEndpoint(
  provider: EndpointProvider,
  postMessage: (message: unknown) => void,
  tag: string,
): Endpoint {
  const listeners: Array<(event: unknown) => void> = [];

  provider.addEventListener("message", (event) => {
    const wrapMessage = event.data;

    if (wrapMessage.__tag === tag) {
      for (const listener of listeners) {
        listener({ data: wrapMessage.message });
      }
    }
  });

  return {
    addEventListener(_type, listener): void {
      listeners.push(listener);
    },
    removeEventListener(_type, listener): void {
      const index = listeners.indexOf(listener);
      if (index !== -1) {
        listeners.splice(index, 1);
      }
    },
    postMessage(message): void {
      postMessage({ __tag: tag, message });
    },
  };
}
