import * as monaco from "monaco-editor-core";
import { RAL } from "../lib/ral";
import type { ChatDynamicVariable } from "../lib/types";
import { executeCommand, registerCommand } from "./commands";

// Define custom theme with matching background color
monaco.editor.defineTheme("custom-dark", {
  base: "vs-dark",
  inherit: true,
  rules: [],
  colors: {
    "editor.background": "#0a0a0a",
  },
});

const styleId = "chat-dynamic-variable-style";
if (!document.getElementById(styleId)) {
  const style = document.createElement("style");
  style.id = styleId;
  style.textContent = `
        .chat-dynamic-variable {
          color: #26569e !important;
          background-color: #adceff7a !important;
          border-radius: 3px;
          padding: 0 2px;
        }
        .dark .chat-dynamic-variable {
          color: #85b6ff !important;
          background-color: #26477866 !important;
        }
      `;
  document.head.appendChild(style);
}

function createAddDynamicVariableCommand(
  variable: ChatDynamicVariable,
): monaco.languages.Command {
  return {
    id: "chat/add-dynamic-variable",
    title: "Chat: Add Dynamic Variable",
    arguments: [variable],
  };
}

function getDynamicVariables(): ChatDynamicVariable[] {
  return executeCommand("chat/get-dynamic-variables");
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

const chatDynamicVariableClass = "chat-dynamic-variable";

let decorations: monaco.editor.IEditorDecorationsCollection | undefined;
let editorInstance: monaco.editor.IStandaloneCodeEditor | undefined;

registerCommand("chat/did-change-dynamic-variables", () => {
  const dynamicVariables = getDynamicVariables();
  if (!decorations) return;
  const model = editorInstance?.getModel();
  if (!model) return;
  decorations.set(
    dynamicVariables.map((variable) => {
      const range = monaco.Range.fromPositions(
        model.getPositionAt(variable.start),
        model.getPositionAt(variable.end),
      );
      return {
        options: {
          inlineClassName: chatDynamicVariableClass,
          stickiness:
            monaco.editor.TrackedRangeStickiness.NeverGrowsWhenTypingAtEdges,
        },
        range,
      };
    }),
  );
});

export function setupDynamicVariableDecoration(
  editor: monaco.editor.IStandaloneCodeEditor,
): monaco.IDisposable {
  editorInstance = editor;
  decorations = editor.createDecorationsCollection();

  const dd = decorations.onDidChange(() => {
    const ranges = decorations?.getRanges();
    if (!ranges || ranges.length === 0) return;
    const model = editor.getModel();
    if (!model) return;
    // Update the dynamic variable positions based on the current decorations
    const dynamicVariables = getDynamicVariables();
    if (ranges.length !== dynamicVariables.length) return;
    let rangesChanged = false;
    for (let i = 0; i < ranges.length; i++) {
      const range = ranges[i];
      const variable = dynamicVariables[i];
      if (!variable) break;
      const startOffset = model.getOffsetAt(range.getStartPosition());
      if (startOffset !== variable.start) {
        rangesChanged = true;
        break;
      }
      const endOffset = model.getOffsetAt(range.getEndPosition());
      if (endOffset !== variable.end) {
        rangesChanged = true;
        break;
      }
    }

    if (rangesChanged) {
      executeCommand("chat/update-dynamic-variable-ranges", {
        ranges: ranges.map((range) => {
          return {
            start: model.getOffsetAt(range.getStartPosition()),
            end: model.getOffsetAt(range.getEndPosition()),
          };
        }),
      });
    }
  });

  return {
    dispose() {
      dd.dispose();
      decorations = undefined;
      editorInstance = undefined;
    },
  };
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
      const ral = RAL();
      const startOffset = model.getOffsetAt(position) - 1;
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
        if (ral.platform) {
          return {
            suggestions: [
              {
                label: "fib",
                insertText: "sym:fib",
                command: createAddDynamicVariableCommand({
                  start: startOffset,
                  end: startOffset + "sym:fib".length + 1,
                }),
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
        } else {
          return null;
        }
      }
    },
  },
);
