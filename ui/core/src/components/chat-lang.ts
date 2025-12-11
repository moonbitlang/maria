import * as monaco from "monaco-editor-core";

// Define custom theme with matching background color
monaco.editor.defineTheme("custom-dark", {
  base: "vs-dark",
  inherit: true,
  rules: [],
  colors: {
    "editor.background": "#0a0a0a",
  },
});

// Add CSS for slash command decorations
const styleId = "chat-slash-command-style";
if (!document.getElementById(styleId)) {
  const style = document.createElement("style");
  style.id = styleId;
  style.textContent = `
        .chat-slash-command {
          color: #26569e !important;
          background-color: #adceff7a !important;
          border-radius: 3px;
          padding: 0 2px;
        }
      `;
  document.head.appendChild(style);
}

function isEmptyBeforePosition(
  model: monaco.editor.ITextModel,
  position: monaco.Position,
): boolean {
  const startToCompletionWordStart = new monaco.Range(
    1,
    1,
    position.lineNumber,
    position.column - 1,
  );
  return !!model.getValueInRange(startToCompletionWordStart).match(/^\s*$/);
}

// Decoration types for slash commands
const slashCommandDecorationType = "chat-slash-command";

type SlashCommandToken = {
  start: number;
  end: number;
  command: string;
};

// Parse slash commands from the text, there can only be one slash command
function parseSlashCommand(text: string): SlashCommandToken | undefined {
  let state: "start" | "in-slash" = "start";
  let start = 0;
  for (let i = 0; i < text.length; i++) {
    const char = text[i];
    switch (state) {
      case "start": {
        if (char === "/") {
          state = "in-slash";
          start = i;
        } else if (char.match(/\s/)) {
          // stay in start state
        } else {
          // invalid character before slash command
          return;
        }
        break;
      }
      case "in-slash": {
        if (char.match(/\s/)) {
          // end of slash command
          return {
            start,
            end: i,
            command: text.slice(start + 1, i),
          };
        } else {
          // stay in in-slash state
        }
        break;
      }
    }
  }
  if (state === "in-slash") {
    return {
      start,
      end: text.length,
      command: text.slice(start + 1),
    };
  }
}

export function setupSlashCommandDecoration(
  editor: monaco.editor.IStandaloneCodeEditor,
): monaco.IDisposable {
  const decorations = editor.createDecorationsCollection();

  return editor.onDidChangeModelContent((e) => {
    const model = editor.getModel();
    if (!model) {
      return;
    }
    const text = model.getValue();
    const token = parseSlashCommand(text);
    if (token === undefined) {
      decorations.clear();
      return;
    }

    const startPos = model.getPositionAt(token.start);
    const endPos = model.getPositionAt(token.end);
    const range = new monaco.Range(
      startPos.lineNumber,
      startPos.column,
      endPos.lineNumber,
      endPos.column,
    );
    decorations.set([
      {
        range,
        options: {
          inlineClassName: slashCommandDecorationType,
        },
      },
    ]);

    const change = e.changes[0];
    if (!change) return;
    const changeStart = model.getOffsetAt(
      new monaco.Position(
        change.range.startLineNumber,
        change.range.startColumn,
      ),
    );
    if (change.text === "") {
      // Deletion
      if (token.start <= changeStart && token.end >= changeStart) {
        const tokenStartPos = model.getPositionAt(token.start);
        const tokenEndPos = model.getPositionAt(token.end);
        const tokenRange = new monaco.Range(
          tokenStartPos.lineNumber,
          tokenStartPos.column,
          tokenEndPos.lineNumber,
          tokenEndPos.column,
        );
        editor.executeEdits("chat-token-deleter", [
          {
            range: tokenRange,
            text: "",
            forceMoveMarkers: true,
          },
        ]);
      }
    }
  });
}

monaco.languages.register({ id: "chat" });

monaco.languages.registerCompletionItemProvider(
  { language: "chat" },
  {
    triggerCharacters: ["/"],
    provideCompletionItems: function (
      model: monaco.editor.ITextModel,
      position: monaco.Position,
      // context: monaco.languages.CompletionContext,
    ): monaco.languages.ProviderResult<monaco.languages.CompletionList> {
      if (!isEmptyBeforePosition(model, position)) {
        // No text allowed before the completion
        return;
      }
      const wordInfo = model.getWordUntilPosition(position);
      const range = new monaco.Range(
        position.lineNumber,
        wordInfo.startColumn,
        position.lineNumber,
        wordInfo.endColumn,
      );
      return {
        suggestions: [
          {
            label: "fix-all-warnings",
            insertText: "fix-all-warnings ",
            kind: monaco.languages.CompletionItemKind.Text,
            range,
          },
        ],
      };
    },
  },
);
