import Box from "@mui/material/Box";
import Typography from "@mui/material/Typography";
import InputFileUpload from "../components/InputFileUpload.tsx";
import SelectFileCardContainer from "./SelectFileCardContainer.tsx";
import { type ChangeEvent, useState } from "react";
import { useDispatch } from "react-redux";
// import { AppDispatch } from "@/shared/store/redux";
import { getPresignedUrl } from "../utils/utils.ts";

const UploadFileContainer = () => {
  const [loading, setLoading] = useState(false);
  // const dispatch = useDispatch<AppDispatch>();

  const handleFileChange = async (event: ChangeEvent<HTMLInputElement>) => {
    setLoading(true);
    const file = event.target.files?.[0];

    // if (file && file.type.startsWith("image/") && user.id) {
    //   try {
    //     const presignedUrlData = await getPresignedUrl(user.id, file);
    //
    //     if (
    //       presignedUrlData &&
    //       presignedUrlData.upload_url &&
    //       presignedUrlData.file_key
    //     ) {
    //       const { upload_url, file_key } = presignedUrlData;
    //
    //       const response = await fetch(upload_url, {
    //         method: "PUT",
    //         body: file,
    //         headers: {
    //           "Content-Type": file.type,
    //         },
    //       });
    //
    //       if (!response.ok) {
    //         throw new Error(
    //           `Upload failed: ${response.statusText} , file_key ${file_key}`,
    //         );
    //       } else {
    //         // user.id && dispatch(fetchuser({ id: user.id }));
    //       }
    //
    //       setLoading(false);
    //     }
    //   } catch (error) {
    //     console.error("Upload error: ", error);
    //     setLoading(false);
    //   }
    // }
  };

  return (
    <Box>
      <Typography variant="body1" gutterBottom>
        Upload document
      </Typography>
      <InputFileUpload handleFileChange={handleFileChange} />
      <SelectFileCardContainer />
    </Box>
  );
};

export default UploadFileContainer;
