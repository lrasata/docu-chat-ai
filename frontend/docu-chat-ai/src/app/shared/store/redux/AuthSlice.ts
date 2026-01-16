import { createSlice } from "@reduxjs/toolkit";
import type { PayloadAction } from "@reduxjs/toolkit";

// Helper to decode JWT and check expiration
function isTokenValid(token: string | null): boolean {
  if (!token) return false;
  try {
    const [, payload] = token.split(".");
    if (!payload) return false;
    const decoded = JSON.parse(
      atob(payload.replace(/-/g, "+").replace(/_/g, "/")),
    );
    if (!decoded.exp) return false;
    // exp is in seconds
    return Date.now() < decoded.exp * 1000;
  } catch {
    return false;
  }
}

interface AuthState {
  token: string | null;
  refreshToken: string | null;
  isLoggedIn: boolean;
}

const persistedToken = localStorage.getItem("cognitoToken");
const preloadedAuthState =
  persistedToken && isTokenValid(persistedToken)
    ? { isLoggedIn: true, token: persistedToken }
    : { isLoggedIn: false, token: null };

const initialState: AuthState = {
  refreshToken: null,
  ...preloadedAuthState,
};

const authSlice = createSlice({
  name: "authentication",
  initialState: initialState,
  reducers: {
    setTokens(
      state,
      action: PayloadAction<{
        token: string | null;
        refreshToken: string | null;
      }>,
    ) {
      state.token = action.payload.token;
      state.refreshToken = action.payload.refreshToken;
      state.isLoggedIn = isTokenValid(action.payload.token);

      // Save token to localStorage for persistence
      if (action.payload.token) {
        localStorage.setItem("cognitoToken", action.payload.token);
      } else {
        localStorage.removeItem("cognitoToken");
      }
    },
    clearTokens(state) {
      state.token = null;
      state.refreshToken = null;
      state.isLoggedIn = false;
      // Remove from localStorage
      localStorage.removeItem("cognitoToken");
    },
    updateIsLoggedInState(
      state,
      action: PayloadAction<{ isLoggedIn: boolean }>,
    ) {
      state.isLoggedIn = action.payload.isLoggedIn;
      if (!action.payload.isLoggedIn) {
        state.token = null;
        localStorage.removeItem("cognitoToken");
      }
    },
    reset() {
      return { ...initialState };
    },
  },
});

export const authSliceActions = authSlice.actions;
export default authSlice.reducer;
