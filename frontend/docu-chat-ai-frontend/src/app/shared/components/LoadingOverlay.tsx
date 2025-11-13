import React from "react";
import { Backdrop, CircularProgress, Typography } from "@mui/material";

interface LoadingOverlayProps {
  visible: boolean;
  message?: string;
}

const LoadingOverlay: React.FC<LoadingOverlayProps> = ({
  visible,
  message,
}) => {
  return (
    <Backdrop
      open={visible}
      sx={{
        zIndex: (theme) => theme.zIndex.drawer + 1,
        color: "#fff",
        flexDirection: "column",
      }}
    >
      <CircularProgress color="inherit" />
      {message && (
        <Typography variant="h6" sx={{ mt: 2 }}>
          {message}
        </Typography>
      )}
    </Backdrop>
  );
};

export default LoadingOverlay;
