import axios from "axios";
import { API_BACKEND_URL } from "../../constants/constants";
import { createAsyncThunk, createSlice } from "@reduxjs/toolkit";
import type { IFile } from "../../../../types";

interface IFileState {
  selectedFile: IFile | null;
  files: IFile[];
  status: string;
  error: string | null;
}

const initialFileState: IFileState = {
  selectedFile: null,
  files: [],
  status: "idle", // 'idle' | 'loading' | 'succeeded' | 'failed' | 'created' | 'updated' | 'deleted'
  error: null,
};

export const fetchFile = createAsyncThunk(
  "files/fetchFile",
  async (arg: { id: number }, { rejectWithValue }) => {
    try {
      const fileResponse = await axios.get(
        `${API_BACKEND_URL}/files/${arg.id}`,
        {
          withCredentials: true,
        },
      );

      const response = fileResponse.data;

      return {
        file: {
          ...response,
        },
      };
    } catch (error) {
      console.error("Error fetching file with id: ", error);
      return rejectWithValue("Oops unable to fetch file from API");
    }
  },
);

export const fetchFiles = createAsyncThunk(
  "files/fetchFiles",
  async (_, { rejectWithValue }) => {
    const url = new URL(`${API_BACKEND_URL}/files`);

    try {
      const response = await axios.get(url.toString(), {
        withCredentials: true,
      });
      const data = response.data.content;
      return {
        files: data,
      };
    } catch (error) {
      console.error("Error fetching files:", error);
      return rejectWithValue("Oops unable to fetch files from API");
    }
  },
);

export const fetchFileMetadata = createAsyncThunk(
  "files/fetchFileMetadata",
  async (arg: { id: number }, { rejectWithValue }) => {
    try {
      const fileResponse = await axios.get(
        `${API_BACKEND_URL}/documents/${arg.id}`,
        {
          withCredentials: true,
        },
      );

      const response = fileResponse.data;

      return {
        file: {
          ...response,
        },
      };
    } catch (error) {
      console.error("Error fetching file metadatawith id: ", error);
      return rejectWithValue("Oops unable to fetch file metadata from API");
    }
  },
);

const fileSlice = createSlice({
  name: "files",
  initialState: initialFileState,
  reducers: {},
  extraReducers: (builder) => {
    builder.addCase(fetchFiles.pending, (state) => {
      state.status = "loading";
    });
    builder.addCase(fetchFiles.fulfilled, (state, action) => {
      state.status = "succeeded";
      state.files = action.payload.files;
    });
    builder.addCase(fetchFiles.rejected, (state, action) => {
      state.status = "failed";
      state.error = action.error.message || "Something went wrong";
    });
    builder.addCase(fetchFile.pending, (state) => {
      state.status = "loading";
    });
    builder.addCase(fetchFile.fulfilled, (state, action) => {
      state.status = "succeeded";
      state.selectedFile = { ...action.payload.file };
    });
    builder.addCase(fetchFile.rejected, (state, action) => {
      state.status = "failed";
      state.error = action.error.message || "Something went wrong";
    });
    // TODO Similar handlers can be added for fetchFileMetadata if needed
  },
});

export const fileActions = fileSlice.actions;

export default fileSlice.reducer;
