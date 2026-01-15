import { configureStore } from "@reduxjs/toolkit";
import authReducer from "./AuthSlice.ts";
import fileReducer from "./FileSlice.ts";

const store = configureStore({
  reducer: {
    files: fileReducer,
    auth: authReducer,
  },
});

export type RootState = ReturnType<typeof store.getState>;
export type AppDispatch = typeof store.dispatch;

export default store;
