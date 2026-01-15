import { Container, ThemeProvider } from "@mui/material";
import { Outlet } from "react-router-dom";
import MainNavigationContainer from "../containers/MainNavigationContainer.tsx";
import WorkspaceLayout from "../layouts/WorkspaceLayout.tsx";
import FileManagementContainer from "../../features/files/containers/FileManagementContainer.tsx";
import ChatPage from "../../features/chat/page/ChatPage.tsx";
import theme from "../../../theme.ts";
import { useAuth } from "react-oidc-context";
import SignInWithGoogleContainer from "../../features/sign-in/containers/SignInWithGoogleContainer.tsx";
import Spinner from "../components/Spinner.tsx";

const MainLayout = () => {
  const auth = useAuth();

  if (auth.isLoading) {
    return <Spinner />;
  }

  if (auth.error) {
    return <div>Encountering error... {auth.error.message}</div>;
  }

  return (
    <>
      <ThemeProvider theme={theme}>
        <Container maxWidth="xl">
          <MainNavigationContainer isAuthenticated={auth.isAuthenticated} />
          {!auth.isAuthenticated && <SignInWithGoogleContainer />}

          {auth.isAuthenticated && (
            <WorkspaceLayout
              sidebar={<FileManagementContainer />}
              main={<ChatPage />}
            />
          )}
          <Outlet />
        </Container>
      </ThemeProvider>
    </>
  );
};

export default MainLayout;
