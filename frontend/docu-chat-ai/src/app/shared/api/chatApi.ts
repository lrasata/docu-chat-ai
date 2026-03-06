import axios, { AxiosInstance } from "axios";

export interface ChatRequest {
  question: string;
  documentId?: string;
}

export interface ChatSource {
  documentId: string;
  chunkId: string;
  relevanceScore: number;
  preview: string;
}

export interface ChatResponse {
  answer: string;
  sources: ChatSource[];
  question: string;
}

export interface ChatError {
  error: string;
  message?: string;
}

class ChatApiService {
  private api: AxiosInstance;

  constructor() {
    const baseURL = import.meta.env.VITE_API_BASE_URL || "";

    this.api = axios.create({
      baseURL,
      headers: {
        "Content-Type": "application/json",
      },
    });

    // Add authorization interceptor
    this.api.interceptors.request.use(
      (config) => {
        const token = localStorage.getItem("access_token");
        if (token) {
          config.headers.Authorization = `Bearer ${token}`;
        }
        return config;
      },
      (error) => {
        return Promise.reject(error);
      }
    );
  }

  async sendMessage(request: ChatRequest): Promise<ChatResponse> {
    try {
      const response = await this.api.post<ChatResponse>("/chat", request);
      return response.data;
    } catch (error) {
      if (axios.isAxiosError(error) && error.response) {
        const errorData = error.response.data as ChatError;
        throw new Error(errorData.message || errorData.error || "Failed to send message");
      }
      throw new Error("Network error. Please check your connection.");
    }
  }

  async queryDocument(documentId: string, question: string): Promise<ChatResponse> {
    return this.sendMessage({ question, documentId });
  }

  async queryAllDocuments(question: string): Promise<ChatResponse> {
    return this.sendMessage({ question });
  }
}

export const chatApi = new ChatApiService();
