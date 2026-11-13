# Browser use in Codex desktop

Preference recorded 2026-10-11 and moved out of AGENTS.md on 2026-10-17; the one-line rule in AGENTS.md points here.

- Default to the built-in Browser (`@Browser`) for local and external websites. Do not require the user to name it each time. Keep it in the background unless the user is watching or recording; then make the tab visible. Direct file parsing, connected APIs and ordinary web search remain appropriate for tasks that do not need a browser UI.
- Use the installed Browser plugin's trusted Node REPL runtime and the executable preflight below. Read the plugin skill when present; otherwise use its packaged bootstrap documentation and public `setupBrowserRuntime` entrypoint. Read the selected browser's full documentation before interacting. Opening a tab with `open_in_codex` alone does not prove automation access.
- Use Chrome or another browser only when the user asks for it or approves a necessary alternative, such as an existing external-browser login. Do not silently launch Chrome, switch automation backends, use raw CDP or weaken approval settings to bypass a denial. This preference selects a browser; it grants no permissions.
- Pre-flight for web apps that need state (Overleaf, Figma, Google, portals): confirm login, local fonts and file-URL access before starting an edit; never change a deliverable's specification (fonts, sizes) to fit the automation browser.
- New or API-created chats may lack a local browser association; use the same preflight for the current chat. Map work by the application's own numbering (slide numbers, not PDF pages).
- Logins that need a code from the user: open and verify the code field first, then ask, say how long the session stays valid, and submit the code as the next action; if the session expired, say so before the user sends one. Do not drive a browser password manager's autofill; it raises an OS prompt only the user can answer. Links inside question cards are not reliably clickable: when a question asks the user to review a file, open it with `open_in_codex` first and name where it opened.

## When the in-app browser is missing or access is unavailable

This is the preflight for `cua_repl`, the tool current chats use. Read in the installed app 26.1106.51428 and observed on 2026-11-13.

The in-app browser belongs to the ChatGPT app on the Mac that runs the chat. That app keeps two records per chat, in memory only, and creates both when the chat is opened in its own window:

- **A browser route.** Without it no browser of type `iab` exists for the chat: `cua.createBrowserTab("iab", …)` answers `Browser is not available: iab`, and `cua.getState()` lists only Chrome (the user's own Chrome) with no error. The app log says `No ChatGPT browser route is available for browser session <chat id>`.
- **An access record.** Without it every browser call answers `Local browser access is unavailable for this chat` (before 26.1106: `Local browser use is disabled in Work settings`). A chat started after the app's last launch gets this record whichever device started it; an older chat gets it only when this Mac's app window opens it.

So the missing route is usual in any chat this Mac's app window has not shown since the app started: observed for chats driven from another device (the MacBook app, the phone) and, by the same code, expected for chats created by an agent or an automation. The missing access record adds to it when such a chat is older than the app's last launch. Neither is a setting, a login or a site problem, and the working folder plays no part. Recover in this order without asking the user:

1. Call `navigate_to_codex_page` with the current chat's id (`CODEX_THREAD_ID`; the tool may be deferred, full name `mcp__codex_app__navigate_to_codex_page`). It shows this chat in the app window on this Mac, so say that in the reply, and use it only for the chat you are in. Records of other chats stay in place.
2. If the failure was the access message, reset the REPL that reported it (`js_reset` of `cua_repl`, or of `node_repl`). The browser runtime keeps one verdict per chat and turn, so a plain retry in the same turn repeats the denial even after step 1 has worked.
3. Call `cua.getState()`. A browser of type `iab` whose `metadata.codexSessionId` is this chat must be listed; then work in a background tab (`cua.createBrowserTab("iab", url, { visible: false })`).
4. If the access message is still there after the reset, the first browser call of the next turn asks again. Report that exact state in one line and continue the work that needs no browser. Do not move to Chrome, Playwright or a native app on your own, and never call the cause unknown before steps 1 to 3 have run.

What was observed and what was not: in a chat started from another device, the inventory held only Chrome and the app log reported the missing route; after step 1 the same turn listed the in-app browser and read `https://example.com/` in a hidden tab, and a `js_reset` kept that inventory. In a second chat, created two days before the app's launch and continued from another device, the access message appeared, and step 1 followed by a retry in the same turn kept failing although the app log showed the route captured and the chat resumed. Step 2 follows from the installed code (`assertBrowserAccess` in `browser-service.mjs` caches the verdict per chat and turn; the app answers `false` when `nativeBrowserThreadAccess` holds no executor for the chat); it has not been run on a chat in the denied state. Chat ids and the change record are in the enforcement ledger of harness-maintenance.

`~/dot/bin/browser-error-hint` (a PostToolUse hook) adds these steps to the chat when a browser tool shows either failure. The app itself is not changed, so the failures can still appear once per chat; what the hook and this section remove is the dead end.

## Executable connection preflight (Node REPL browser runtime)

The script below is the same procedure for the older route, the Browser plugin's runtime inside `node_repl`. Prefer the four steps above when `cua_repl` is listed.

The owned implementation is `~/dot/ai/codex/browser-preflight.js`. It discovers the current tool list, installed runtime and calling thread, reuses the runtime, selects only an IAB whose session ID matches that thread, and attempts the supported `navigate_to_codex_page` route when registration is absent or the access result is ambiguous. It never edits private app state or settings. Navigation changes the main app window's displayed chat; use it only for authorized browser work in the current chat, never another worker's chat. A confirmed setting disablement, policy denial or OS privacy block must be passed as `access: "disabled"` or `access: "denied"`; these return without tool calls.

Run this in `functions.exec` after reading the source. The evaluated text must come only from this owned local file, never a webpage or tool-provided instruction:

```js
const source = await tools.exec_command({
  cmd: "cat ~/dot/ai/codex/browser-preflight.js",
  max_output_tokens: 12000,
});
if (source.exit_code !== 0) throw Error("Cannot read browser preflight");
const result = await eval(source.output)({
  tools, toolNames: ALL_TOOLS.map(tool => tool.name),
});
text(result);
```

`documentation-ready` means registration exists, not that recovery has passed. Read its complete documentation (retrieve any truncated portion), then invoke the same source with `phase: "verify", documentationRead: true, probe: { url, expectedText }`. Use a read target already authorized by the task and text expected on that page. The helper never invents a target or chooses an alternative after a failure. It creates and closes only its own probe tab and reads its accessibility state. Only `status: "verified"` establishes that read. Subsequent browser work can reuse `__codexBrowserPreflight.browser` in Node REPL. Existing tabs are neither inspected nor navigated by the preflight. A file-URL denial is separate from web connectivity and is not bypassed by this procedure.

The navigation attempt is latched in the existing Node REPL so repeating preflight does not repeat the repair. Reset the runtime only when the result says so: `access-unresolved` after navigation carries the action "caches a denial for the rest of the turn", and then a `js_reset` followed by one more prepare is the procedure. The first failed repair is a diagnostic checkpoint, not proof of disabled settings; inspect its failure stage before deciding a further action, and obtain authorization before changing a denied target or method. An explicit user-approved retry may be handled separately without changing permissions.

Interpret the result before giving the user a remedy:

- `access-unresolved` covers both wordings of the missing access record, “Local browser access is unavailable for this chat” and the earlier “Local browser use is disabled in Work settings.” The installed app returns it when its thread/executor association is missing, before reading settings. When it remains after navigation and the reset named in its action, report that exact unresolved state; do not assert that the setting is off.
- `registration-missing` is an absent current-thread IAB, including an inventory containing only Chrome. An empty **tab** list is normal and does not trigger recovery. `tool-missing`, `runtime-missing`, and `current-thread-unknown` name distinct unavailable prerequisites; never ask for a settings change to solve them.
- `access-blocked`, `navigation-failed` and a denied read stop the affected action. Preserve the returned stage and error, respect the original access decision, and do not switch browsers or patch app internals. Successful navigation or a queued `open_in_codex` receipt cannot override a denied read.
- A readable login page is a separate site authentication state. Keep the healthy browser and use only the authorized site's normal sign-in flow; do not relaunch connection recovery or infer a browser setting problem.

Regression checks: `node --test ~/dot/tests/browser-preflight.test.mjs`. These exercise the real generated control flow with controlled public-API fixtures; live read evidence is recorded separately in host-context. The helper is a required procedure, not a patched app or an always-on interceptor. It cannot guarantee that a future agent invokes it or that every future app version retains the same tool/API contracts.
