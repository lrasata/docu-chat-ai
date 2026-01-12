import React, { useState } from "react";
import ChatWindow from "../components/ChatWindow";
import MessageInput from "../components/MessageInput";

interface Message {
  id: number;
  sender: "user" | "bot";
  text: string;
}

const ChatPage: React.FC = () => {
  const [messages, setMessages] = useState<Message[]>([
    {
      id: 1,
      sender: "bot",
      text: "Hello! Upload your document or ask me anything.",
    },
  ]);

  const handleSend = (text: string) => {
    const newMessage: Message = { id: Date.now(), sender: "user", text };
    setMessages((prev) => [...prev, newMessage]);

    // Simulated bot response
    setTimeout(() => {
      setMessages((prev) => [
        ...prev,
        {
          id: Date.now() + 1,
          sender: "bot",
          text: "Processing your request...",
        },
      ]);
    }, 800);
  };

  return (
    <>
      <ChatWindow messages={messages} />
      <MessageInput onSend={handleSend} />
    </>
  );
};

export default ChatPage;
