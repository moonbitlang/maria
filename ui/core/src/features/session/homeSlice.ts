import { createAppSlice } from "../../app/createAppSlice";
import type { ChatDynamicVariable } from "../../lib/types";

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
    addDynamicVariables(state, action: { payload: ChatDynamicVariable }) {
      state.dynamicVariables.push(action.payload);
    },

    updateDynamicVariableRanges(
      state,
      action: { payload: { start: number; end: number }[] },
    ) {
      const newRanges = action.payload;
      if (newRanges.length !== state.dynamicVariables.length) {
        return;
      }
      for (let i = 0; i < newRanges.length; i++) {
        const range = newRanges[i];
        const variable = state.dynamicVariables[i];
        variable.start = range.start;
        variable.end = range.end;
      }
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
      return state.dynamicVariables;
    },
  },
});

export const {
  setInput,
  setCwd,
  toggleWebSearchEnabled,
  addDynamicVariables,
  updateDynamicVariableRanges,
} = homeSlice.actions;
export const {
  selectInput,
  selectCwd,
  selectWebSearchEnabled,
  selectDynamicVariables,
} = homeSlice.selectors;
