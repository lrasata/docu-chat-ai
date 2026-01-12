import { styled } from "@mui/material/styles";
import Button from "@mui/material/Button";
import CloudUploadIcon from "@mui/icons-material/CloudUpload";
import React, { useRef } from "react";

const VisuallyHiddenInput = styled("input")({
  clip: "rect(0 0 0 0)",
  clipPath: "inset(50%)",
  height: 1,
  overflow: "hidden",
  position: "absolute",
  bottom: 0,
  left: 0,
  whiteSpace: "nowrap",
  width: 1,
});

interface InputFileUploadProps {
  handleFileChange: (event: React.ChangeEvent<HTMLInputElement>) => void;
}

const InputFileUpload: React.FC<InputFileUploadProps> = ({
  handleFileChange,
}) => {
  const fileInputRef = useRef<HTMLInputElement>(null);

  const handleButtonClick = () => {
    fileInputRef.current?.click();
  };

  return (
    <Button
      component="label"
      role={undefined}
      variant="contained"
      tabIndex={-1}
      startIcon={<CloudUploadIcon />}
      onClick={handleButtonClick}
    >
      Upload files
      <VisuallyHiddenInput type="file" onChange={handleFileChange} multiple />
    </Button>
  );
};

export default InputFileUpload;
