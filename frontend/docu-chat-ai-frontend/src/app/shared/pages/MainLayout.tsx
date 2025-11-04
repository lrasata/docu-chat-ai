import { Container, ThemeProvider } from "@mui/material";
import { Outlet } from "react-router-dom";
import MainNavigationContainer from "../containers/MainNavigationContainer.tsx";
import WorkspaceLayout from "../layouts/WorkspaceLayout.tsx";
import UploadFileContainer from "../../features/files/containers/UploadFileContainer.tsx";
import ChatPage from "../../features/chat/page/ChatPage.tsx";
import theme from "../../../theme.ts";

const MainLayout = () => {
  return (
    <>
      <ThemeProvider theme={theme}>
        <Container maxWidth="xl">
          <MainNavigationContainer />
          <WorkspaceLayout
            sidebar={<UploadFileContainer />}
            main={<ChatPage />}
          />
          <Outlet />
        </Container>
      </ThemeProvider>
    </>
  );
};

export default MainLayout;
