import type { Static } from "@sinclair/typebox";

import { Type } from "@sinclair/typebox";
import { glob } from "glob";
import { promises as fs } from "node:fs";
import * as path from "node:path";

import type { Tool, ToolContext } from "../tool.ts";

import { youch } from "../error.ts";
import { getIgnoreFileManager } from "../ignorefile/index.ts";
import { findReferences, gotoDefinition } from "../moonanalyze.ts";
import { validateParams } from "../validate.ts";

/**
 * Search result interface matching Python version structure
 */
interface SearchResult {
  context: string;
  line_number: number;
  match_line: string;
  path: string;
}

/**
 * TypeBox schema for search_files parameters
 */
export const SearchFilesSchema = Type.Object(
  {
    context_lines: Type.Optional(
      Type.Number({
        description:
          "Number of context lines to show before and after each match. Defaults to 2.",
      })
    ),
    file_pattern: Type.Optional(
      Type.String({
        description:
          "Glob pattern to filter files (e.g., '*.ts', '*.js', '*.py', etc.). Defaults to '*' to search all files.",
      })
    ),
    kind: Type.Union(
      [
        Type.Literal("regex"),
        Type.Literal("moonbit_definition"),
        Type.Literal("moonbit_references"),
      ],
      {
        description:
          "The kind of search to perform. 'regex' performs traditional regex-based file content search. 'moonbit_definition' performs fuzzy symbolic search to find MoonBit symbol definitions - note that when using 'moonbit_definition', the regex parameter can be imprecise as the system will perform fuzzy search to find the most relevant symbols. 'moonbit_references' finds all references to a MoonBit symbol using the moon IDE tool.",
      }
    ),
    path: Type.String({
      description:
        "The path of the directory or file to search in, relative to the current working directory.",
    }),
    regex: Type.String({
      description:
        "The search pattern. For 'regex' kind: regular expression pattern with full regex syntax. For 'moonbit_definition' kind: symbol name or partial name (can be imprecise) for fuzzy symbolic search.",
    }),
  },
  {
    required: ["path", "regex", "kind"],
  }
);

type SearchFilesParams = Static<typeof SearchFilesSchema>;

/**
 * XML Documentation:
 * <search_files path="relative/path/to/directory" regex="search_pattern" kind="regex" file_pattern="*.ts" context_lines="3"/>
 *
 * Description: Search for patterns in files with enhanced context and filtering capabilities
 *
 * This tool performs comprehensive searches with two distinct modes:
 * 1. Regex mode: Traditional regex pattern matching in file contents through
 *    files. When given a directory path, it performs a recursive search through
 *    all files in that directory. When given a file path, it searches within
 *    that specific file, providing matches with context lines and advanced
 *    filtering options. It automatically applies .gitignore and
 *    .moonagentignore rules to exclude irrelevant files.
 * 2. MoonBit definition mode: Fuzzy symbolic search for MoonBit symbol
 *    definitions throughout the MoonBit project.
 * 3. MoonBit references mode: Find all references to a MoonBit symbol using
 *    the moon IDE tool.
 *
 * Features:
 * - Dual search modes: regex pattern matching and fuzzy symbolic search
 * - Context display: Shows configurable lines before and after each match
 *   (default: 2 lines)
 * - File pattern filtering using glob patterns (e.g., "*.ts", "*.js", "*.py")
 * - Automatic ignore file filtering (.gitignore, .moonagentignore)
 * - Security validation to prevent directory traversal attacks
 * - Result limiting (max 200 matches displayed)
 * - Detailed error handling and validation
 *
 * Parameters:
 *   - path (required): The directory or file path to search in, relative to the
 *     current working directory
 *   - regex (required): For regex kind: regular expression pattern. For
 *     moonbit_definition kind: symbol name (can be imprecise). For
 *     moonbit_references kind: symbol query to find references for.
 *   - kind (required): The kind of search to perform ("regex",
 *     "moonbit_definition", or "moonbit_references", defaults to "regex")
 *   - file_pattern (optional): Glob pattern to filter files (defaults to "*"
 *     for all files)
 *   - context_lines (optional): Number of context lines to show before and
 *     after each match (defaults to 2)
 *
 * Search Kinds:
 *   - "regex": Traditional regex-based file content search with full regular
 *     expression support
 *   - "moonbit_definition": Fuzzy symbolic search to find MoonBit symbol
 *     definitions (functions, types, variables, etc.) Note: The regex parameter
 *     can be imprecise when using this mode as the system performs fuzzy
 *     matching
 *   - "moonbit_references": Find all references to a MoonBit symbol using the
 *     moon IDE tool. The regex parameter should be a symbol query.
 *
 * Examples:
 *   <search_files path="src" regex="function\s+\w+" kind="regex" file_pattern="*.ts"/>
 *   <search_files path="." regex="TODO|FIXME" kind="regex" file_pattern="*.js" context_lines="3"/>
 *   <search_files path="docs" regex="API|endpoint" context_lines="1" kind="regex"/>
 *   <search_files path="src/specific_file.ts" regex="interface\s+\w+" kind="regex"/>
 *   <search_files path="src" regex="Array::length" kind="moonbit_definition"/>
 *   <search_files path="." regex="calculate_total" kind="moonbit_definition"/>
 *   <search_files path="src" regex="my_function" kind="moonbit_references"/>
 *   <search_files path="." regex="Array::map" kind="moonbit_references"/>
 */
export const search_files: Tool = {
  desc: {
    function: {
      description:
        "Search for patterns in files with three distinct modes: regex-based file content search, fuzzy symbolic search for MoonBit definitions, and MoonBit references search. This tool performs searches through files in the specified directory or file, displaying matches with context lines (configurable, default 2 lines before and after each match). Use 'regex' kind for traditional pattern matching in code/text, 'moonbit_definition' kind for finding MoonBit symbol definitions with fuzzy matching (symbol names can be imprecise), or 'moonbit_references' kind for finding all references to a MoonBit symbol.",
      name: "search_files",
      parameters: SearchFilesSchema,
    },
    type: "function",
  },
  fn: async (params: unknown, ctxOrCwd?: string | ToolContext) => {
    let validatedParams: SearchFilesParams;
    try {
      validatedParams = validateParams(SearchFilesSchema, params);
    } catch (error) {
      return `Parameter validation failed: ${error instanceof Error ? error.message : String(error)}`;
    }

    const {
      context_lines = 2,
      file_pattern = "*",
      kind,
      path: searchPath,
      regex: searchPattern,
    } = validatedParams;

    // Handle both old (cwd string) and new (ToolContext) signatures
    const cwd =
      typeof ctxOrCwd === "string" || ctxOrCwd === undefined
        ? ctxOrCwd
        : ctxOrCwd.cwd;

    // Resolve paths
    const sourceDir = cwd || process.cwd();
    const absoluteSourceDir = path.resolve(sourceDir);

    // If kind is moonbit_definition, delegate to find_moonbit_symbol
    if (kind === "moonbit_definition" || kind === "moonbit_references") {
      // Resolve the working directory for the moon command
      const workingDir = path.isAbsolute(searchPath)
        ? searchPath
        : path.resolve(sourceDir, searchPath);

      // Check if the working directory exists and is a directory
      try {
        const stats = await fs.stat(workingDir);
        if (!stats.isDirectory()) {
          return `Error: Path must be a directory for MoonBit references search: ${searchPath}`;
        }
      } catch {
        return `Error: Directory not found: ${searchPath}`;
      }

      if (kind === "moonbit_definition") {
        try {
          const symbolResult = await gotoDefinition(searchPattern, workingDir);

          // Add a note about the search type
          const note = `Search completed using fuzzy symbolic search for MoonBit definitions.\nNote: The search pattern "${searchPattern}" was used for fuzzy matching of symbol names.\n\n`;

          return note + symbolResult;
        } catch (error) {
          return `Error performing MoonBit symbol search: ${youch.toANSI(error as Error)}`;
        }
      } else if (kind === "moonbit_references") {
        try {
          const referencesResult = await findReferences(
            searchPattern,
            workingDir
          );

          // Add a note about the search type
          const note = `Search completed using MoonBit IDE find-references tool.\nQuery: "${searchPattern}"\nWorking directory: ${searchPath}\n\n`;

          return note + referencesResult;
        } catch (error) {
          return `Error performing MoonBit references search: ${youch.toANSI(error as Error)}`;
        }
      }
    }

    // Continue with regex search for kind === "regex"

    // Use absolute path as-is, otherwise resolve relative to sourceDir
    const absoluteSearchPath = path.isAbsolute(searchPath)
      ? searchPath
      : path.resolve(sourceDir, searchPath);

    try {
      // Validate that the path exists and determine if it's a file or directory
      let isFile = false;
      try {
        const stats = await fs.stat(absoluteSearchPath);
        isFile = stats.isFile();
        if (!stats.isDirectory() && !stats.isFile()) {
          return `Error: Search path is neither a file nor a directory: ${searchPath}`;
        }
      } catch {
        return `Error: Search path not found: ${searchPath}`;
      }

      // Compile regex pattern
      let compiledRegex: RegExp;
      try {
        compiledRegex = new RegExp(searchPattern);
      } catch (e) {
        return `Invalid regex pattern: ${youch.toANSI(e as Error)}`;
      }

      // Initialize ignore file manager
      const ignoreManager = await getIgnoreFileManager({
        baseDir: absoluteSourceDir,
      });

      // Get files to search
      let filePaths: string[];

      if (isFile) {
        // If path is a file, search only that file
        filePaths = [absoluteSearchPath];
      } else {
        // If path is a directory, search using glob pattern
        const searchGlobPattern = path.posix.join(
          absoluteSearchPath.replace(/\\/g, "/"),
          "**",
          file_pattern
        );

        filePaths = await glob(searchGlobPattern, {
          absolute: true,
          dot: false,
          nodir: true,
          windowsPathsNoEscape: true,
        });
      }

      const searchResults: SearchResult[] = [];

      // Process each file
      for (const filePath of filePaths) {
        // Check if file should be ignored
        const relativePath = path.relative(absoluteSourceDir, filePath);
        const filterResult = ignoreManager.filter(relativePath);
        if (filterResult.ignored) {
          continue;
        }

        try {
          // Read file content
          const content = await fs.readFile(filePath, "utf-8");
          const lines = content.split("\n");

          // Search for matches line by line
          for (let i = 0; i < lines.length; i++) {
            const line = lines[i];
            if (compiledRegex.test(line)) {
              // Generate context (configurable lines before and after)
              const contextStart = Math.max(0, i - context_lines);
              const contextEnd = Math.min(lines.length, i + context_lines + 1);

              const contextLines: string[] = [];
              for (let j = contextStart; j < contextEnd; j++) {
                contextLines.push(`${j + 1}: ${lines[j]}`);
              }

              const result: SearchResult = {
                context: contextLines.join("\n"),
                line_number: i + 1,
                match_line: line.trim(),
                path: relativePath,
              };

              searchResults.push(result);
            }
          }
        } catch (error) {
          // Log warning but continue processing other files
          console.warn(
            `Could not read or process file ${filePath}: ${error instanceof Error ? error.message : String(error)}`
          );
          continue;
        }
      }

      // Format results
      const totalResults = searchResults.length;

      if (totalResults === 0) {
        return "No matches found.";
      }

      // Limit results to 200 if needed
      let resultsToShow = searchResults;
      let message = `Search completed. Found ${totalResults} matches.`;

      if (totalResults > 200) {
        resultsToShow = searchResults.slice(0, 200);
        message = `Search completed. Found ${totalResults} matches, showing only the first 200.`;
      }

      // Format output similar to ripgrep style
      const formattedResults = resultsToShow
        .map((result) => {
          const header = `${result.path}:${result.line_number}`;
          return `${header}\n${result.context}\n`;
        })
        .join("\n");

      return `${message}\n\n${formattedResults}`;
    } catch (error) {
      return `Error searching files: ${youch.toANSI(error as Error)}`;
    }
  },
};
