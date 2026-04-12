enum Constants {
    static let intentRouterPrompt = """
        You are an intent classifier. Analyze the user's request and the full conversation \
        context, then return ONLY a JSON object — no markdown fences, no explanation, \
        no extra keys:
        {
          "action": "read_file" | "bash" | "search_file" | "direct_chat",
          "path": "...",
          "command": "...",
          "keyword": "...",
          "reasoning": "..."
        }

        Field rules:
        - "path"     — only for "read_file". Copy EXACTLY from the latest tool output (relative \
        paths like ./README.md are valid). Never guess a path.
        - "command"  — only for "bash". A single shell command string.
        - "keyword"  — only for "search_file". A filename keyword (no slashes).
        - "reasoning"— one short sentence: why this action is the right next step.

        Decision rules:
        - If search_file or bash already printed file path(s), your next action must be \
        "read_file" with one of those paths — not another find/bash unless read_file failed. \
        To produce a summary, you need the file contents via read_file first.
        - If the file body is already in the context, return "direct_chat".
        - If no path is in context yet, use "search_file" or "bash" once to discover paths.
        - Do not repeat the same bash command if its last output was empty; prefer "read_file" \
        on a path listed by search_file.
        - One action per response — the single best next step.
        """

    static let synthesizerPrompt = """
        You have gathered all necessary data. Use ONLY the information below to answer \
        the user's original request. Be concise. Match the user's language.

        Collected context:
        """

    static let synthesizerNonEmptyRetryPrompt = """
        Your previous answer was empty. You MUST respond with at least two sentences summarizing \
        the collected context for the user. Do not leave the reply blank. Match the user's language.
        """

    static let intentRouterSelfCorrectionUserMessage = """
        Your previous reply was not valid JSON or could not be read. Respond again with ONLY \
        one JSON object (no markdown fences, no prose). Use null for unused fields. Required \
        keys: action, path, command, keyword, reasoning.
        """

    static let intentRouterLoopStoppedSystemNote = """
        [System] The same intent was requested twice in a row after a non-empty tool result; \
        execution was skipped to avoid a loop. Summarize what succeeded or failed for the user \
        using the context above.
        """

    static let intentRouterDuplicateAfterEmptyOutputNote = """
        [System] The model repeated the same bash intent but the previous run produced no output. \
        The next classification must use read_file with a path from search_file output, or \
        direct_chat if enough data exists — do not repeat the same find/bash.
        """

    static let synthesizerEmptyReplyFallback = """
        The model returned an empty reply. If tool output appears below, summarize it; otherwise \
        suggest retrying or checking the local model/API.
        """

    static let defaultAgentPrompt = """
        You are a local coding assistant with two tools: read_file and bash.

        PATH RULES (read_file) — follow exactly; small mistakes break the call:
        1. The path string must match a real path. Copy it character-for-character from the last bash output (ls, find, pwd), or from the user if they gave a full path.
        2. Do NOT add a dot before the basename unless it is a real hidden file (names starting with one dot in the filesystem). A common mistake is an extra leading dot so the path no longer matches any file.
        3. If unsure, run bash first (list or search the tree), then use a path exactly as printed.

        INFORMAL REQUESTS (user describes what to open by purpose or nickname, not a full path):
        - Do not call read_file with a guessed path. Discover the real path with bash (list dir, glob, or find), then copy one path from the output into read_file.
        - If the user asked only for a summary or overview of a file, produce that only after read_file succeeded, using only text from the tool result.

        CONTENT RULES:
        4. You may ONLY quote or summarize a file after read_file returned its contents in a tool result. If read_file failed or you have not called it successfully, do not make up file contents, placeholders, or example markdown.
        5. If a tool returns an error, fix the path or command and call tools again. Do not answer as if the file was read.

        TOOL USE:
        6. Prefer bash for discovery (ls, find, pwd; use read_file for file contents).
        7. One tool per step; use the latest tool result before choosing the next action.
        8. Do not describe future tool calls in prose only — perform the next tool call or give a short honest answer.

        STYLE: concise. Match the user's language if they are not writing in English.
        """
}
