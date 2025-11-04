import React from "react";
import { Box } from "@mui/material";

interface WorkspaceLayoutProps {
  sidebar: React.ReactNode;
  main: React.ReactNode;
}

const WorkspaceLayout: React.FC<WorkspaceLayoutProps> = ({ sidebar, main }) => {
  return (
    <Box sx={{ display: "flex", height: "100vh" }}>
      <Box
        sx={{
          flex: "0 0 25%",
          bgcolor: "grey.100",
          p: "6rem 1rem 4rem 1rem",
          overflowY: "auto",
        }}
      >
        {sidebar}
      </Box>
      <Box
        sx={{
          flex: "0 0 75%",
          p: "6rem 1rem 4rem 1rem",
          overflowY: "auto",
        }}
      >
        {main}
      </Box>
    </Box>
  );
};

export default WorkspaceLayout;
