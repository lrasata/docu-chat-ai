import type { ChatSource } from "../api/chatApi.ts";

export type { ChatSource };

export interface Message {
  id: string;
  sender: "user" | "bot";
  text: string;
  sources?: ChatSource[];
  error?: boolean;
  isStreaming?: boolean;
}

export interface IFile {
  filename: string;
  file_key: string;
  url: string;
  file_size: number;
  uploaded_timestamp: string;
  resource: string;
  status: "processed" | "indexed" | "failed";
}
