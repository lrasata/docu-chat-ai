import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import "./index.css";
import App from "./App.tsx";
import { AuthProvider } from "react-oidc-context";
import {
  AWS_COGNITO_CLIENT_ID,
  AWS_COGNITO_DOMAIN_URL_LOGIN,
  AWS_COGNITO_REDIRECT_URI,
  AWS_COGNITO_RESPONSE,
  AWS_COGNITO_SCOPE,
} from "./app/shared/constants/constants.ts";

const cognitoAuthConfig = {
  authority: AWS_COGNITO_DOMAIN_URL_LOGIN,
  client_id: AWS_COGNITO_CLIENT_ID,
  redirect_uri: AWS_COGNITO_REDIRECT_URI,
  response_type: AWS_COGNITO_RESPONSE,
  scope: AWS_COGNITO_SCOPE,
};

createRoot(document.getElementById("root")!).render(
  <StrictMode>
    <AuthProvider {...cognitoAuthConfig}>
      <App />
    </AuthProvider>
  </StrictMode>,
);
