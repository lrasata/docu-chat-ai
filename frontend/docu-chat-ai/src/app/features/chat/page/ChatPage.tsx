import React, { useRef, useState } from "react";
import { Box, Alert, CircularProgress, Typography } from "@mui/material";
import ChatWindow from "../components/ChatWindow";
import MessageInput from "../components/MessageInput";
import { chatApi } from "../../../shared/api/chatApi";
import { useAuth } from "react-oidc-context";
import type { Message } from "../../../shared/types/types.ts";

interface ChatPageProps {
  selectedDocumentId?: string;
  isSelectedDocumentPending?: boolean;
}

const ChatPage: React.FC<ChatPageProps> = ({
  selectedDocumentId,
  isSelectedDocumentPending,
}) => {
  const auth = useAuth();
  const [messages, setMessages] = useState<Message[]>([
    {
      id: crypto.randomUUID(),
      sender: "bot",
      text: "Hello! Upload your document and ask me anything about it.",
    },
  ]);
  const [isLoading, setIsLoading] = useState(false);
  const [isStreaming, setIsStreaming] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const abortControllerRef = useRef<AbortController | null>(null);

  const handleSend = async (text: string) => {
    // Cancel any in-flight stream before starting a new one
    if (abortControllerRef.current) {
      abortControllerRef.current.abort();
    }

    setError(null);
    const botMessageId = crypto.randomUUID();

    setMessages((prev) => [
      ...prev,
      { id: crypto.randomUUID(), sender: "user", text },
      { id: botMessageId, sender: "bot", text: "", isStreaming: true },
    ]);
    setIsLoading(true);
    setIsStreaming(false);

    const controller = new AbortController();
    abortControllerRef.current = controller;

    try {
      const token = auth.user?.access_token ?? "";
      const request = selectedDocumentId
        ? { question: text, documentId: selectedDocumentId }
        : { question: text };

      await chatApi.streamChat(
        request,
        token,
        (chunk) => {
          // Hide spinner as soon as the first token arrives
          setIsStreaming(true);
          setMessages((prev) =>
            prev.map((msg) =>
              msg.id === botMessageId ? { ...msg, text: msg.text + chunk } : msg,
            ),
          );
        },
        (sources) => {
          setMessages((prev) =>
            prev.map((msg) =>
              msg.id === botMessageId ? { ...msg, sources } : msg,
            ),
          );
        },
        controller.signal,
      );

      setMessages((prev) =>
        prev.map((msg) =>
          msg.id === botMessageId ? { ...msg, isStreaming: false } : msg,
        ),
      );
    } catch (err) {
      if (err instanceof Error && err.name === "AbortError") return;

      const errorMessage =
        err instanceof Error ? err.message : "Failed to get response";
      setError(errorMessage);

      setMessages((prev) =>
        prev.map((msg) =>
          msg.id === botMessageId
            ? {
                ...msg,
                text: `Sorry, I encountered an error: ${errorMessage}`,
                error: true,
                isStreaming: false,
              }
            : msg,
        ),
      );
    } finally {
      setIsLoading(false);
      setIsStreaming(false);
      abortControllerRef.current = null;
    }
  };

  return (
    <Box sx={{ display: "flex", flexDirection: "column", height: "100%" }}>
      {error && (
        <Alert severity="error" onClose={() => setError(null)} sx={{ mb: 2 }}>
          {error}
        </Alert>
      )}

      <ChatWindow messages={messages} />

      {isSelectedDocumentPending && (
        <Alert severity="warning" sx={{ mb: 1 }}>
          A document is still being indexed. Please wait before asking questions
          about it.
        </Alert>
      )}

      {isLoading && !isStreaming && (
        <Box sx={{ display: "flex", justifyContent: "center", mb: 2 }}>
          <CircularProgress size={24} />
          <Typography variant="body2" sx={{ ml: 2, color: "text.secondary" }}>
            Thinking...
          </Typography>
        </Box>
      )}

      <MessageInput
        onSend={handleSend}
        disabled={isLoading || !!isSelectedDocumentPending}
      />
    </Box>
  );
};

export default ChatPage;
