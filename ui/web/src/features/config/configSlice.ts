import { createSlice, type PayloadAction } from "@reduxjs/toolkit";

interface ConfigState {
  apiBaseUrl: string;
}

const initialState: ConfigState = {
  apiBaseUrl: import.meta.env.VITE_API_BASE_URL || "http://localhost:8090/v1",
};

export const configSlice = createSlice({
  name: "config",
  initialState,
  reducers: {
    setApiBaseUrl: (state, action: PayloadAction<string>) => {
      state.apiBaseUrl = action.payload;
    },
  },
  selectors: {
    selectApiBaseUrl: (state) => state.apiBaseUrl,
  },
});

export const { setApiBaseUrl } = configSlice.actions;
export const { selectApiBaseUrl } = configSlice.selectors;
