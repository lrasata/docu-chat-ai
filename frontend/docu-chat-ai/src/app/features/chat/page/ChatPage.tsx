import React, { useState } from "react";
import { Box, Alert, CircularProgress, Typography } from "@mui/material";
import ChatWindow from "../components/ChatWindow";
import MessageInput from "../components/MessageInput";
import { chatApi, type ChatResponse } from "../../../shared/api/chatApi";
import { useAuth } from "react-oidc-context";

interface Message {
  id: string;
  sender: "user" | "bot";
  text: string;
  sources?: ChatResponse["sources"];
  error?: boolean;
}

const ChatPage: React.FC = () => {
  const auth = useAuth();
  const [messages, setMessages] = useState<Message[]>([
    {
      id: crypto.randomUUID(),
      sender: "bot",
      text: "Hello! Upload your document and ask me anything about it.",
    },
  ]);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSend = async (text: string) => {
    setError(null);

    setMessages((prev) => [
      ...prev,
      {
        id: crypto.randomUUID(),
        sender: "user",
        text,
      },
    ]);
    setIsLoading(true);

    try {
      const token = auth.user?.access_token ?? "";
      const response = await chatApi.queryAllDocuments(text, token);

      setMessages((prev) => [
        ...prev,
        {
          id: crypto.randomUUID(),
          sender: "bot",
          text: response.answer,
          sources: response.sources,
        },
      ]);
    } catch (err) {
      const errorMessage =
        err instanceof Error ? err.message : "Failed to get response";
      setError(errorMessage);

      setMessages((prev) => [
        ...prev,
        {
          id: crypto.randomUUID(),
          sender: "bot",
          text: `Sorry, I encountered an error: ${errorMessage}`,
          error: true,
        },
      ]);
    } finally {
      setIsLoading(false);
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

      {isLoading && (
        <Box sx={{ display: "flex", justifyContent: "center", mb: 2 }}>
          <CircularProgress size={24} />
          <Typography variant="body2" sx={{ ml: 2, color: "text.secondary" }}>
            Thinking...
          </Typography>
        </Box>
      )}

      <MessageInput onSend={handleSend} disabled={isLoading} />
    </Box>
  );
};

export default ChatPage;
