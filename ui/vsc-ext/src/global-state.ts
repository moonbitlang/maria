import type * as comlink from "comlink";
import type * as api from "../../common/api";

type GlobalState = {
  webviewApi?: comlink.Remote<api.WebviewApi>;
};

const state: GlobalState = {};

export function get<K extends keyof GlobalState>(key: K): GlobalState[K] {
  const value = state[key];
  return value;
}

export function set<K extends keyof GlobalState>(
  key: K,
  value: GlobalState[K],
): void {
  state[key] = value;
}
