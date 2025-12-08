import * as monaco from "monaco-editor-core";

monaco.languages.register({ id: "chat" });

monaco.languages.registerCompletionItemProvider(
  { language: "chat" },
  {
    provideCompletionItems: function (
      model: monaco.editor.ITextModel,
      position: monaco.Position,
      // context: monaco.languages.CompletionContext,
    ): monaco.languages.ProviderResult<monaco.languages.CompletionList> {
      const wordInfo = model.getWordUntilPosition(position);
      const wordRange = new monaco.Range(
        position.lineNumber,
        wordInfo.startColumn,
        position.lineNumber,
        wordInfo.endColumn,
      );
      return {
        suggestions: [
          {
            label: "",
            insertText: "",
            kind: monaco.languages.CompletionItemKind.Text,
            range: wordRange,
          },
        ],
      };
    },
  },
);
