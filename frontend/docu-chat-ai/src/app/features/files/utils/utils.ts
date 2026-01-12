import { API_UPLOAD_MEDIA } from "../../../shared/constants/constants.ts";

export const getPresignedUrl = async (
  id: number | string,
  file: File,
  resource: string = "users",
): Promise<{ upload_url: string; file_key: string } | undefined> => {
  try {
    const [filenameWithoutExt, extension] = file.name.split(".");

    const mimeType = file.type || "application/octet-stream";

    const queryParams = {
      id: id,
      file_key: filenameWithoutExt,
      ext: extension,
      resource,
      mimeType,
    };

    const params = new URLSearchParams();
    for (const [key, value] of Object.entries(queryParams)) {
      params.append(key, value as string);
    }

    const response = await fetch(`${API_UPLOAD_MEDIA}?${params}`, {
      method: "GET",
      // TODO keep this only for local testing, when infra done, will be injected by cloudfront
      // headers:{
      //     "x-api-gateway-img-upload-auth": "",
      // }
    });

    if (!response.ok) {
      throw new Error(`Get presigned url failed: ${response.statusText}`);
    }

    const data = await response.json();

    return {
      upload_url: data["upload_url"],
      file_key: data["file_key"],
    };
  } catch (error) {
    console.error(error);
    return undefined;
  }
};
