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
const styleId = "chat-token-style";
if (!document.getElementById(styleId)) {
  const style = document.createElement("style");
  style.id = styleId;
  style.textContent = `
        .chat-token {
          color: #26569e !important;
          background-color: #adceff7a !important;
          border-radius: 3px;
          padding: 0 2px;
        }
        .dark .chat-token {
          color: #85b6ff !important;
          background-color: #26477866 !important;
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
const chatTokenDecorationType = "chat-token";

type TokenBase = {
  start: number;
  end: number;
};

type SlashCommandToken = TokenBase & {
  command: string;
};

type UserMentionToken = TokenBase & {
  kind: "sym" | "file";
  identifier: string;
};

type Token = SlashCommandToken | UserMentionToken;

// Parse slash commands from the text, there can only be one slash command
function parseTokens(text: string): Token[] {
  const tokens: Token[] = [];
  let state: "initial" | "text" | "in-slash" | "in-hash" = "initial";
  let start = 0;

  const addSlashToken = (end: number) => {
    tokens.push({
      start,
      end,
      command: text.slice(start + 1, end),
    });
  };

  const addHashToken = (end: number) => {
    const content = text.slice(start + 1, end);
    const [kind, identifier] = content.split(":", 2);
    if (kind === "sym" || kind === "file") {
      tokens.push({
        start,
        end,
        kind: kind as "sym" | "file",
        identifier: identifier || "",
      });
    }
  };

  for (let i = 0; i < text.length; i++) {
    const char = text[i];
    switch (state) {
      case "initial": {
        if (char === "/") {
          state = "in-slash";
          start = i;
        } else if (char === "#") {
          state = "in-hash";
          start = i;
        } else if (char.match(/\s/)) {
          // stay in initial state
        } else {
          // non-whitespace character, transition to normal text
          state = "text";
        }
        break;
      }
      case "text": {
        if (char === "#") {
          state = "in-hash";
          start = i;
        }
        break;
      }
      case "in-slash": {
        if (char.match(/\s/)) {
          addSlashToken(i);
          state = "text";
        }
        break;
      }
      case "in-hash": {
        if (char.match(/\s/)) {
          addHashToken(i);
          state = "text";
        }
        break;
      }
    }
  }

  // Handle tokens that extend to end of string
  if (state === "in-slash") {
    addSlashToken(text.length);
  } else if (state === "in-hash") {
    addHashToken(text.length);
  }

  return tokens;
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
    const tokens = parseTokens(text);
    if (tokens.length === 0) {
      decorations.clear();
      return;
    }

    decorations.set(
      tokens.map((token) => {
        const startPos = model.getPositionAt(token.start);
        const endPos = model.getPositionAt(token.end);
        const range = new monaco.Range(
          startPos.lineNumber,
          startPos.column,
          endPos.lineNumber,
          endPos.column,
        );
        return {
          range,
          options: {
            inlineClassName: chatTokenDecorationType,
          },
        };
      }),
    );

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
      for (const token of tokens) {
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
          break;
        }
      }
    }
  });
}

const slashCommands = ["fix-all-warnings"];

monaco.languages.register({ id: "chat" });

monaco.languages.registerCompletionItemProvider(
  { language: "chat" },
  {
    triggerCharacters: ["/", "#"],
    provideCompletionItems: function (
      model: monaco.editor.ITextModel,
      position: monaco.Position,
      context: monaco.languages.CompletionContext,
    ): monaco.languages.ProviderResult<monaco.languages.CompletionList> {
      const wordInfo = model.getWordUntilPosition(position);
      const range = new monaco.Range(
        position.lineNumber,
        wordInfo.startColumn,
        position.lineNumber,
        wordInfo.endColumn,
      );
      if (context.triggerCharacter === "/") {
        if (!isEmptyBeforePosition(model, position)) {
          // No text allowed before the completion
          return;
        }
        return {
          suggestions: slashCommands.map((command) => ({
            label: command,
            insertText: command,
            kind: monaco.languages.CompletionItemKind.Text,
            range,
          })),
        };
      } else if (context.triggerCharacter === "#") {
        // Future: mention user completion
        return {
          suggestions: [
            {
              label: "fib",
              insertText: "sym:fib",
              kind: monaco.languages.CompletionItemKind.Function,
              range,
            },
            {
              label: "lib.mbt",
              insertText: "file:lib.mbt",
              kind: monaco.languages.CompletionItemKind.File,
              range,
            },
          ],
        };
      }
    },
  },
);
