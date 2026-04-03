import type { ChatResponse } from "../api/chatApi.ts";

export interface ChatSource {
  documentId: string;
  chunkId: string;
  relevanceScore: number;
  preview: string;
}

export interface Message {
  id: string;
  sender: "user" | "bot";
  text: string;
  sources?: ChatSource[] | ChatResponse["sources"];
  error?: boolean;
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
