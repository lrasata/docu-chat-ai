import { Box, CircularProgress } from "@mui/material";

const Spinner = () => (
  <Box
    display="flex"
    alignItems="center"
    justifyContent="center"
    height="100vh"
  >
    <CircularProgress />
  </Box>
);

export default Spinner;
