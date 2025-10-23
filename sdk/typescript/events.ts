import {
    type ChatCompletionMessage,
    type ChatCompletionMessageToolCall,
} from "openai/resources/index.mjs";
import { type CompletionUsage } from "openai/resources/completions.mjs";

export interface RequestCompletedParams {
    usage: CompletionUsage;
    message: ChatCompletionMessage;
}

export interface RequestCompleted {
    method: "maria.agent.request_completed";
    params: RequestCompletedParams;
}

export interface PostToolCallParams {
    tool_call: ChatCompletionMessageToolCall;
    value: unknown;
    text: string;
}

export interface PostToolCall {
    method: "maria.agent.post_tool_call";
    params: PostToolCallParams;
}

export type Notification = RequestCompleted | PostToolCall;

export function parseNotification(line: string): Notification {
    const parsed = JSON.parse(line);

    // Validate that the parsed object has the expected structure
    if (!parsed.method || !parsed.params) {
        throw new Error(
            "Invalid notification format: missing method or params",
        );
    }

    if (parsed.method === "maria.agent.request_completed") {
        return parsed as RequestCompleted;
    } else if (parsed.method === "maria.agent.post_tool_call") {
        return parsed as PostToolCall;
    } else {
        throw new Error(`Unknown notification method: ${parsed.method}`);
    }
}
