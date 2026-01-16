import Typography from "@mui/material/Typography";
import InputFileUpload from "../components/InputFileUpload.tsx";
import FileCardContainer from "./FileCardContainer.tsx";
import { type ChangeEvent, useEffect, useState } from "react";
import { getPresignedUrl } from "../utils/utils.ts";
import { useAuth } from "react-oidc-context";
import LoadingOverlay from "../../../shared/components/LoadingOverlay.tsx";
import { fetchFiles } from "../../../shared/store/redux/FileSlice.ts";
import { useDispatch, useSelector } from "react-redux";
import type {
  AppDispatch,
  RootState,
} from "../../../shared/store/redux/index.ts";
import type { IFile } from "../../../../types.ts";

const FileManagementContainer = () => {
  const [loading, setLoading] = useState(false);
  const auth = useAuth();
  const dispatch = useDispatch<AppDispatch>();
  const files: IFile[] = useSelector((state: RootState) => state.files.files);

  useEffect(() => {
    dispatch(fetchFiles());
  }, []);

  const handleFileChange = async (event: ChangeEvent<HTMLInputElement>) => {
    setLoading(true);
    const file = event.target.files?.[0];

    if (file && auth.isAuthenticated) {
      try {
        // Email from ID token
        const email = auth.user?.profile.email;

        if (email) {
          const presignedUrlData = await getPresignedUrl(email, file);

          if (
            presignedUrlData &&
            presignedUrlData.upload_url &&
            presignedUrlData.file_key
          ) {
            const { upload_url, file_key } = presignedUrlData;

            const response = await fetch(upload_url, {
              method: "PUT",
              body: file,
              headers: {
                "Content-Type": file.type,
              },
            });

            if (!response.ok) {
              throw new Error(
                `Upload failed: ${response.statusText} , file_key ${file_key}`,
              );
            }

            setLoading(false);
          }
        }
      } catch (error) {
        console.error("Upload error: ", error);
        setLoading(false);
      }
    }
  };

  return (
    <>
      <Typography variant="body1" gutterBottom>
        Upload document
      </Typography>
      <InputFileUpload handleFileChange={handleFileChange} />
      <FileCardContainer files={files} />
      <LoadingOverlay visible={loading} message="Uploading image..." />
    </>
  );
};

export default FileManagementContainer;
