import Box from "@mui/material/Box";
import Typography from "@mui/material/Typography";
import InputFileUpload from "../components/InputFileUpload.tsx";
import SelectFileCardContainer from "./SelectFileCardContainer.tsx";

const UploadFileContainer = () => {
  return (
    <Box>
      <Typography variant="body1" gutterBottom>
        Upload document
      </Typography>
      <InputFileUpload />
      <SelectFileCardContainer />
    </Box>
  );
};

export default UploadFileContainer;
