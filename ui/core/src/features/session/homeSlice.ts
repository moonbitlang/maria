import { createAppSlice } from "../../app/createAppSlice";

type HomeState = {
  input: string;
  cwd?: string;
  webSearchEnabled: boolean;
};

export const initialState: HomeState = {
  input: "",
  cwd: undefined,
  webSearchEnabled: false,
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
  },
});

export const { setInput, setCwd, toggleWebSearchEnabled } = homeSlice.actions;
export const { selectInput, selectCwd, selectWebSearchEnabled } =
  homeSlice.selectors;
