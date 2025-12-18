import * as monaco from "monaco-editor-core";
import { RAL } from "../lib/ral";
import type {
  ChatDynamicVariable,
  ChatDynamicVariableInfo,
} from "../lib/types";
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

const slashCommands = ["fix-all-warnings"];

function createItem(
  info: ChatDynamicVariableInfo,
  // start offset of the dynamic variable, should include the trigger character
  startOffset: number,
  // the range to be replaced, should not include the trigger character
  range: monaco.IRange,
): monaco.languages.CompletionItem {
  const label = info.name;
  let insertText = label;
  let detail = undefined;
  switch (info.kind) {
    case "command": {
      insertText = `${label} `;
      break;
    }
    case "file": {
      insertText = `file:${label} `;
      detail = info.uri;
      break;
    }
    case "symbol": {
      insertText = `sym:${label} `;
      detail = info.uri;
      break;
    }
  }
  const arg: ChatDynamicVariable = {
    info,
    start: startOffset,
    end: startOffset + insertText.length,
  };
  return {
    label,
    kind: info.itemKind,
    detail,
    command: {
      id: "chat/add-dynamic-variable",
      title: "Chat: Add Dynamic Variable",
      arguments: [arg],
    },
    insertText,
    range,
  };
}

function getDynamicVariables(): ChatDynamicVariable[] {
  return executeCommand("chat/get-dynamic-variables");
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

  const ed = editor.onDidChangeModelContent((e) => {
    const model = editor.getModel();
    if (!model) return;
    const dynamicVariables = getDynamicVariables();
    const changedVariableIndexes = new Set<number>();
    const variablesToDelete: number[] = [];

    for (const change of e.changes) {
      const rangeStartOffset = change.rangeOffset;
      const rangeEndOffset = rangeStartOffset + change.rangeLength;
      for (let i = 0; i < dynamicVariables.length; i++) {
        const variable = dynamicVariables[i];
        // Check if the change's range overlaps with the variable's range
        if (
          rangeStartOffset < variable.end &&
          rangeEndOffset > variable.start
        ) {
          // Check if the variable is only partially affected
          const fullyDeleted =
            rangeStartOffset <= variable.start &&
            rangeEndOffset >= variable.end;
          if (!fullyDeleted) {
            // Variable is partially affected, delete it completely
            variablesToDelete.push(i);
          }
          changedVariableIndexes.add(i);
        }
      }
    }

    // Delete partially affected variables completely
    if (variablesToDelete.length > 0) {
      const edits = variablesToDelete.map((i) => {
        const variable = dynamicVariables[i];
        return {
          range: monaco.Range.fromPositions(
            model.getPositionAt(variable.start),
            model.getPositionAt(variable.end),
          ),
          text: "",
        };
      });
      model.pushEditOperations([], edits, () => null);
    }

    // Update ranges of changed variables
    const ranges = decorations?.getRanges();
    if (!ranges || ranges.length === 0) return;
    if (ranges.length !== dynamicVariables.length) return;
    let rangesChanged = false;
    for (let i = 0; i < ranges.length; i++) {
      const range = ranges[i];
      const variable = dynamicVariables[i];
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
      ed.dispose();
      decorations = undefined;
      editorInstance = undefined;
    },
  };
}

monaco.languages.register({ id: "chat" });

const TRIGGER_CHARACTERS = ["/", "#"];

function findTriggerCharacterInLine(
  line: string,
  col: number,
): { char: string; index: number } | undefined {
  for (let i = col; i >= 0; i--) {
    const char = line[i];
    if (TRIGGER_CHARACTERS.includes(char)) {
      return { char, index: i };
    }
  }
  return undefined;
}

function provideSlashCompletions(
  model: monaco.editor.ITextModel,
  startOffset: number,
  range: monaco.IRange,
): monaco.languages.ProviderResult<monaco.languages.CompletionList> {
  const content = model.getValue().slice(0, startOffset);
  // only provide slash commands when the content before is empty or whitespace
  if (content.match(/^\s*$/)) {
    return {
      suggestions: slashCommands.map((command) =>
        createItem(
          {
            kind: "command",
            name: command,
            itemKind: monaco.languages.CompletionItemKind.Text,
          },
          startOffset,
          range,
        ),
      ),
    };
  }
  return null;
}

async function provideDynamicVariableCompletions(
  model: monaco.editor.ITextModel,
  startOffset: number,
  range: monaco.IRange,
): Promise<monaco.languages.ProviderResult<monaco.languages.CompletionList>> {
  const ral = RAL();
  const query = model.getValueInRange(range);
  if (ral.platform === "vsc-webview") {
    const dynamicVariables = await ral.vscodeApi.getDynamicVariables(query);
    return {
      incomplete: true,
      suggestions: dynamicVariables.map((v) => {
        return createItem(v, startOffset, range);
      }),
    };
  } else {
    return null;
  }
}

monaco.languages.registerCompletionItemProvider(
  { language: "chat" },
  {
    triggerCharacters: TRIGGER_CHARACTERS,
    provideCompletionItems: async function (
      model: monaco.editor.ITextModel,
      position: monaco.Position,
      context: monaco.languages.CompletionContext,
    ): Promise<monaco.languages.CompletionList | null | undefined> {
      switch (context.triggerKind) {
        case monaco.languages.CompletionTriggerKind.TriggerCharacter: {
          const startOffset = model.getOffsetAt(position) - 1;
          const range = monaco.Range.fromPositions(position);
          switch (context.triggerCharacter) {
            case "/": {
              return provideSlashCompletions(model, startOffset, range);
            }
            case "#": {
              return provideDynamicVariableCompletions(
                model,
                startOffset,
                range,
              );
            }
            default: {
              return null;
            }
          }
        }
        case monaco.languages.CompletionTriggerKind.Invoke:
        case monaco.languages.CompletionTriggerKind
          .TriggerForIncompleteCompletions: {
          const line = model.getLineContent(position.lineNumber);
          const trigger = findTriggerCharacterInLine(line, position.column - 2);
          if (trigger === undefined) return null;
          const { char, index } = trigger;
          const triggerPos = new monaco.Position(
            position.lineNumber,
            index + 2,
          );
          const startOffset = model.getOffsetAt(triggerPos) - 1;
          const range = monaco.Range.fromPositions(triggerPos, position);
          switch (char) {
            case "/": {
              return provideSlashCompletions(model, startOffset, range);
            }
            case "#": {
              return provideDynamicVariableCompletions(
                model,
                startOffset,
                range,
              );
            }
          }
        }
      }
    },
  },
);
