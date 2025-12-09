import { createAppSlice } from "../../app/createAppSlice";

type UrlState = {
  url: string;
};

const initialState: UrlState = {
  url: import.meta.env.VITE_API_BASE_URL || "http://localhost:8090/v1",
};

export const urlSlice = createAppSlice({
  name: "url",
  initialState,
  reducers: {
    setUrl(state, action: { payload: string }) {
      state.url = action.payload;
    },
  },
  selectors: {
    selectUrl(state): string {
      return state.url;
    },
  },
});

export const { setUrl } = urlSlice.actions;
export const { selectUrl } = urlSlice.selectors;
