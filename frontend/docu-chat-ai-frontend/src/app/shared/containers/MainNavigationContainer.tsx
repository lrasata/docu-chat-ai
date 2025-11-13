import DrawerAppBar from "../components/DrawerAppBar.tsx";
import {
  APP_NAME,
  AWS_COGNITO_CLIENT_ID,
  AWS_COGNITO_DOMAIN_URL_LOGOUT,
} from "../constants/constants.ts";
import { useEffect, useState } from "react";
import { useAuth } from "react-oidc-context";

interface MainNavigationContainerProps {
  isAuthenticated: boolean;
}
const MainNavigationContainer = ({
  isAuthenticated = false,
}: MainNavigationContainerProps) => {
  const auth = useAuth();
  const [menuContent, setMenuContent] = useState<{ title: string }>({
    title: "Sign in",
  });

  const signOutRedirect = () => {
    const clientId = AWS_COGNITO_CLIENT_ID;
    const logoutUri = `${window.location.origin}/`; // must exactly match App client Sign out URL
    const cognitoDomain = AWS_COGNITO_DOMAIN_URL_LOGOUT;

    auth.removeUser();

    // Redirect to Hosted UI logout
    window.location.href = `${cognitoDomain}/logout?client_id=${clientId}&logout_uri=${encodeURIComponent(logoutUri)}`;
  };

  useEffect(() => {
    const currentMenuItem = isAuthenticated
      ? { title: "Sign out" }
      : { title: "Sign in" };

    setMenuContent((prevState) =>
      prevState.title !== currentMenuItem.title ? currentMenuItem : prevState,
    );
  }, [isAuthenticated]);

  return (
    <DrawerAppBar
      appName={APP_NAME}
      logOutMenuItem={menuContent}
      handleOnClickLogout={signOutRedirect}
    />
  );
};

export default MainNavigationContainer;
