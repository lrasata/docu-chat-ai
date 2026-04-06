
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

// SSE event shapes emitted by the Lambda streaming handler
type SseTextDelta = { type: "text_delta"; text: string };
type SseSources = { type: "sources"; sources: ChatSource[] };
type SseError = { type: "error"; message: string };
type SseEvent = SseTextDelta | SseSources | SseError;

class ChatApiService {
  /**
   * Stream a chat response from the Lambda Function URL using SSE over fetch.
   *
   * The Lambda streams three event types:
   *   {"type":"text_delta","text":"..."}  — incremental answer token
   *   {"type":"sources","sources":[...]}  — retrieved document chunks (sent after the full answer)
   *   [DONE]                              — signals end of stream
   *
   * @param request      Chat payload (question + optional documentId)
   * @param token        Cognito access token (validated by the Lambda)
   * @param onChunk      Called with each text token as it arrives
   * @param onSources    Called once with the source list after the answer is complete
   * @param signal       Optional AbortSignal to cancel mid-stream
   */
  async streamChat(
    request: ChatRequest,
    token: string,
    onChunk: (text: string) => void,
    onSources: (sources: ChatSource[]) => void,
    signal?: AbortSignal,
  ): Promise<void> {
    const response = await fetch("/api/chat", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify(request),
      signal,
    });

    if (!response.ok) {
      const text = await response.text().catch(() => "");
      throw new Error(`Stream request failed (${response.status}): ${text}`);
    }

    if (!response.body) {
      throw new Error("Response body is not readable.");
    }

    const reader = response.body.getReader();
    const decoder = new TextDecoder("utf-8");
    let buffer = "";

    while (true) {
      const { done, value } = await reader.read();
      if (done) break;

      buffer += decoder.decode(value, { stream: true });

      // SSE lines are separated by "\n\n"; split on double-newline
      const parts = buffer.split("\n\n");
      // Keep the last (potentially incomplete) part in the buffer
      buffer = parts.pop() ?? "";

      for (const part of parts) {
        for (const line of part.split("\n")) {
          if (!line.startsWith("data: ")) continue;

          const data = line.slice(6).trim();
          if (data === "[DONE]") return;

          try {
            const event = JSON.parse(data) as SseEvent;
            if (event.type === "text_delta") {
              onChunk(event.text);
            } else if (event.type === "sources") {
              onSources(event.sources);
            } else if (event.type === "error") {
              throw new Error(event.message);
            }
          } catch (e) {
            if (e instanceof SyntaxError) continue; // malformed JSON — skip
            throw e;
          }
        }
      }
    }
  }
}

export const chatApi = new ChatApiService();
