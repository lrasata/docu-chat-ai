import React, { useState } from "react";
import { Box, Alert, CircularProgress, Typography } from "@mui/material";
import ChatWindow from "../components/ChatWindow";
import MessageInput from "../components/MessageInput";
import { chatApi, ChatResponse } from "../../../shared/api/chatApi";

interface Message {
  id: number;
  sender: "user" | "bot";
  text: string;
  sources?: ChatResponse["sources"];
  error?: boolean;
}

const ChatPage: React.FC = () => {
  const [messages, setMessages] = useState<Message[]>([
    {
      id: 1,
      sender: "bot",
      text: "Hello! Upload your document and ask me anything about it.",
    },
  ]);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSend = async (text: string) => {
    // Clear any previous errors
    setError(null);

    // Add user message
    const userMessage: Message = {
      id: Date.now(),
      sender: "user",
      text
    };
    setMessages((prev) => [...prev, userMessage]);

    // Show loading indicator
    setIsLoading(true);

    try {
      // Call the chat API
      const response = await chatApi.queryAllDocuments(text);

      // Add bot response
      const botMessage: Message = {
        id: Date.now() + 1,
        sender: "bot",
        text: response.answer,
        sources: response.sources,
      };
      setMessages((prev) => [...prev, botMessage]);
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : "Failed to get response";
      setError(errorMessage);

      // Add error message to chat
      const errorMsg: Message = {
        id: Date.now() + 1,
        sender: "bot",
        text: `Sorry, I encountered an error: ${errorMessage}`,
        error: true,
      };
      setMessages((prev) => [...prev, errorMsg]);
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
