import { createAppSlice } from "../../app/createAppSlice";

type HomeState = {
  input: string;
  cwd?: string;
};

const initialState: HomeState = {
  input: "",
  cwd: undefined,
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
  },
  selectors: {
    selectInput(state): string {
      return state.input;
    },
    selectCwd(state): string | undefined {
      return state.cwd;
    },
  },
});

export const { setInput, setCwd } = homeSlice.actions;
export const { selectInput, selectCwd } = homeSlice.selectors;
