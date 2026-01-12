import React from "react";
import { Box, Typography, Paper } from "@mui/material";

interface Message {
  id: number;
  sender: "user" | "bot";
  text: string;
}

interface ChatWindowProps {
  messages: Message[];
}

const ChatWindow: React.FC<ChatWindowProps> = ({ messages }) => {
  return (
    <Box sx={{ flexGrow: 1, overflowY: "auto", mb: 2 }}>
      {messages.map((msg) => (
        <Paper
          key={msg.id}
          sx={{
            p: 2,
            mb: 1.5,
            alignSelf: msg.sender === "user" ? "flex-end" : "flex-start",
            bgcolor: msg.sender === "user" ? "primary.main" : "grey.200",
          }}
        >
          <Typography
            variant="body1"
            color={msg.sender === "user" ? "white" : "textPrimary"}
          >
            {msg.text}
          </Typography>
        </Paper>
      ))}
    </Box>
  );
};

export default ChatWindow;
