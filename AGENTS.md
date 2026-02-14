# OpenCode Tooling Rules
- User asks to search the web → use `mgrep` with web + answer mode (e.g., `mgrep --web --answer "query"`).
- User asks to search files or code → use `mgrep "query"`.
- User asks about current/latest information → use `mgrep --web --answer "query"`.
- User asks "what is", "how to", or any question requiring online lookup → use `mgrep --web --answer "query"`.
- You need to find files, code, or content in the codebase → use `mgrep "query"`.
- Do not use built-in `websearch`, `grep`, or `glob` tools. Use `mgrep` instead.
