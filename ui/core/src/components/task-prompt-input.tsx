import type { ChatStatus } from "ai";
import * as monaco from "monaco-editor-core";
import {
  useCallback,
  useEffect,
  useImperativeHandle,
  useRef,
  useState,
} from "react";
import { cn } from "../lib/utils";
import MonacoEditor, { type EditorDidMount } from "./monaco-editor";
import {
  PromptInput,
  PromptInputSubmit,
  PromptInputToolbar,
  PromptInputTools,
} from "./ui/shadcn-io/ai/prompt-input";

export interface TaskPromptInputHandle {
  clear: () => void;
  focus: () => void;
}

interface TaskPromptInputProps {
  onChange: (value: string) => void;
  onSubmit: () => void;
  placeholder: string;
  className?: string;
  inputTools?: React.ReactNode;
  chatStatus?: ChatStatus;
  ref?: React.Ref<TaskPromptInputHandle>;
}

function computeDisabled(chatStatus: ChatStatus, value: string): boolean {
  return chatStatus === "ready" && value.trim().length === 0;
}

function clear(editor: monaco.editor.IStandaloneCodeEditor) {
  const model = editor.getModel();
  if (model) {
    model.setValue("");
  }
}

export function TaskPromptInput({
  onChange,
  onSubmit,
  className = "",
  inputTools,
  placeholder,
  chatStatus = "ready",
  ref,
}: TaskPromptInputProps) {
  const tools = inputTools ? inputTools : <PromptInputTools></PromptInputTools>;
  const editorRef = useRef<monaco.editor.IStandaloneCodeEditor>(undefined);
  const [disabled, setDisabled] = useState(true);

  useImperativeHandle(ref, () => {
    return {
      clear: () => {
        if (editorRef.current) {
          clear(editorRef.current);
        }
      },
      focus: () => {
        if (editorRef.current) {
          editorRef.current.focus();
        }
      },
    };
  }, []);

  useEffect(() => {
    if (!editorRef.current) return;
    const d = monaco.editor.registerCommand("chat/send", () => {
      const model = editorRef.current?.getModel();
      if (!model) return;
      const value = model.getValue();
      const isDisabled = computeDisabled(chatStatus, value);
      if (isDisabled) return;
      onSubmit();
    });
    return () => {
      d.dispose();
    };
  }, [chatStatus, onSubmit]);

  useEffect(() => {
    if (!editorRef.current) return;
    const model = editorRef.current.getModel();
    if (!model) return;
    const value = model.getValue();
    setDisabled(computeDisabled(chatStatus, value));
    const d = model.onDidChangeContent(() => {
      const value = model.getValue();
      setDisabled(computeDisabled(chatStatus, value));
      onChange(value);
    });
    return () => {
      d.dispose();
    };
  }, [chatStatus, onChange]);

  useEffect(() => {
    if (!editorRef.current) return;
    editorRef.current.updateOptions({ placeholder });
  }, [placeholder]);

  const editorDidMount: EditorDidMount = useCallback((editor, monaco) => {
    editorRef.current = editor;
    const d = monaco.editor.addKeybindingRules([
      {
        keybinding: monaco.KeyCode.Enter,
        command: "chat/send",
        when: "editorTextFocus && !suggestWidgetVisible",
      },
    ]);
    return d;
  }, []);

  return (
    <PromptInput
      className={cn(
        `mx-auto max-w-4xl shadow-lg transition-shadow hover:shadow-xl`,
        className,
      )}
      onSubmit={(e) => {
        e.preventDefault();
        if (editorRef.current) {
          clear(editorRef.current);
          onSubmit();
        }
      }}
    >
      <div
        className={cn(
          "w-full resize-none rounded-none border-none p-3 shadow-none ring-0 outline-none",
          "field-sizing-content max-h-[6lh] bg-transparent dark:bg-transparent",
          "focus-visible:ring-0",
        )}
      >
        <MonacoEditor editorDidMount={editorDidMount} />
      </div>
      <PromptInputToolbar>
        {tools}
        <PromptInputSubmit
          disabled={disabled}
          status={chatStatus}
          className="cursor-pointer transition-all"
        ></PromptInputSubmit>
      </PromptInputToolbar>
    </PromptInput>
  );
}
