import * as monaco from "monaco-editor-core";
import editorWorker from "monaco-editor-core/esm/vs/editor/editor.worker.start?worker&inline";
import { memo, useLayoutEffect, useRef } from "react";
import "./chat-lang";

self.MonacoEnvironment = {
  getWorker() {
    return new editorWorker();
  },
};

export type EditorDidMount = (
  editor: monaco.editor.IStandaloneCodeEditor,
  m: typeof monaco,
) => monaco.IDisposable;

type EditorProps = {
  editorDidMount: EditorDidMount;
};

function Editor(props: EditorProps) {
  const { editorDidMount } = props;
  const containerRef = useRef<HTMLDivElement>(null);
  function getContainer() {
    if (!containerRef.current) {
      throw new Error("Container ref is not set");
    }
    return containerRef.current;
  }
  useLayoutEffect(() => {
    const container = getContainer();
    container.classList.add("hideSuggestTextIcons");
    const model = monaco.editor.createModel("", "chat");

    const editor = monaco.editor.create(container, {
      model,
      fontFamily: "inherit",
      fontSize: 16,
      theme: "vs",
      autoDetectHighContrast: false,
      minimap: { enabled: false },
      wordWrap: "on",
      selectOnLineNumbers: false,
      selectionHighlight: false,
      matchBrackets: "never",
      renderLineHighlight: "none",
      scrollBeyondLastLine: false,
      cursorStyle: "line",
      cursorBlinking: "blink",
      scrollbar: {
        vertical: "hidden",
        horizontal: "hidden",
        alwaysConsumeMouseWheel: false,
      },
      stickyScroll: { enabled: false },
      overviewRulerLanes: 0,
      glyphMargin: false,
      folding: false,
      lineNumbers: "off",
      lineDecorationsWidth: 0,
      lineNumbersMinChars: 0,
      occurrencesHighlight: "off",
      automaticLayout: true,
      contextmenu: false,
      tabSize: 2,
      placeholder: "Input your task...",
      cursorWidth: 1,
      padding: { top: 2, bottom: 2 },
      wrappingStrategy: "advanced",
      bracketPairColorization: {
        enabled: false,
      },
      guides: {
        indentation: false,
      },
      suggest: {
        showIcons: true,
        showSnippets: false,
        showWords: true,
        showStatusBar: false,
        insertMode: "insert",
      },
      defaultColorDecorators: "never",
      quickSuggestions: false,
      fixedOverflowWidgets: true,
    });

    const d = editorDidMount(editor, monaco);
    // const slashCommandDecoration = setupSlashCommandDecoration(editor);

    const updateHeight = () => {
      const height = Math.min(124, editor.getContentHeight());
      const width = container.clientWidth;
      container.style.height = `${height}px`;
      editor.layout({ width, height });
    };
    editor.onDidContentSizeChange(updateHeight);
    updateHeight();

    return () => {
      model.dispose();
      editor.dispose();
      d.dispose();
      // slashCommandDecoration.dispose();
    };
  }, [editorDidMount]);
  return <div ref={containerRef}></div>;
}

export default memo(Editor);
