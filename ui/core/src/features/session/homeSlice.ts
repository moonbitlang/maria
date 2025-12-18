import { createAppSlice } from "../../app/createAppSlice";
import type { ChatDynamicVariable } from "../../lib/types";
import * as dynamicVariables from "./dynamic-variables";

type HomeState = {
  input: string;
  cwd?: string;
  webSearchEnabled: boolean;
  dynamicVariables: ChatDynamicVariable[];
};

export const initialState: HomeState = {
  input: "",
  cwd: undefined,
  webSearchEnabled: false,
  dynamicVariables: [],
};

export const homeSlice = createAppSlice({
  name: "home",
  initialState,
  reducers: {
    setInput(state, action: { payload: string }) {
      state.input = action.payload;
    },
    setCwd(state, action: { payload: string | undefined }) {
      state.cwd = action.payload;
    },
    toggleWebSearchEnabled(state) {
      state.webSearchEnabled = !state.webSearchEnabled;
    },
    addDynamicVariable(state, action: { payload: ChatDynamicVariable }) {
      dynamicVariables.add(state, action.payload);
    },

    updateDynamicVariableRanges(
      state,
      action: { payload: { start: number; end: number }[] },
    ) {
      dynamicVariables.updateRanges(state, action.payload);
    },
  },
  selectors: {
    selectInput(state): string {
      return state.input;
    },
    selectCwd(state): string | undefined {
      return state.cwd;
    },
    selectWebSearchEnabled(state): boolean {
      return state.webSearchEnabled;
    },
    selectDynamicVariables(state): ChatDynamicVariable[] {
      return dynamicVariables.get(state);
    },
  },
});

export const {
  setInput,
  setCwd,
  toggleWebSearchEnabled,
  addDynamicVariable,
  updateDynamicVariableRanges,
} = homeSlice.actions;
export const {
  selectInput,
  selectCwd,
  selectWebSearchEnabled,
  selectDynamicVariables,
} = homeSlice.selectors;
