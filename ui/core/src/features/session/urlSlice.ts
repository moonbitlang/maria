import { createAppSlice } from "../../app/createAppSlice";

type UrlState = {
  url: string;
};

async function getDefaultUrl(): Promise<string> {
  if ((window as any).electronAPI) {
    const url = await (window as any).electronAPI.getUrl();
    return url;
  }
  return import.meta.env.VITE_API_BASE_URL || "http://localhost:8090/v1";
}

const initialState: UrlState = {
  url: await getDefaultUrl(),
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
