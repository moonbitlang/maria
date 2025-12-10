import * as monaco from "monaco-editor-core";

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
            insertText: "fix-all-warnings",
            kind: monaco.languages.CompletionItemKind.Text,
            range,
          },
        ],
      };
    },
  },
);
