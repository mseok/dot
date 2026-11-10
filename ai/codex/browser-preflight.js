// Run this owned source through functions.exec; see references/codex-browser.md.
// Uses only public tools. Never changes settings, accounts, or another thread.
(async function browserPreflight({ tools, toolNames, phase = "prepare", access = "unknown", documentationRead = false, probe }) {
  if (["denied", "disabled"].includes(access)) {
    return { status: "access-blocked", action: "Respect the confirmed access decision; do not navigate or retry." };
  }
  const replName = toolNames.find(name => /^mcp__node_repl__js$/.test(name));
  const navigateName = toolNames.find(name => /^mcp__codex_app__navigate_to_codex_page$/.test(name));
  if (!replName) return { status: "tool-missing", tool: "node_repl.js" };
  async function repl(code) {
    const result = await tools[replName]({ code, timeout_ms: 30000, title: "Browser connection preflight" });
    if (result.isError) throw new Error("Node REPL failed; inspect the tool result before retrying.");
    const block = result.content.find(item => item.type === "text");
    return JSON.parse(block.text);
  }
  if (phase === "prepare") {
    if (!tools.exec_command) return { status: "tool-missing", tool: "exec_command" };
    const discovery = await tools.exec_command({
      cmd: "python3 - <<'PY'\nimport json, os, re\nfrom pathlib import Path\nroot = Path.home() / '.codex/plugins/cache/openai-bundled/browser'\npaths = list(root.glob('*/scripts/browser-client.mjs'))\npaths.sort(key=lambda p: tuple(int(n) for n in re.findall(r'\\d+', p.parent.parent.name)))\nprint(json.dumps({'threadId': os.environ.get('CODEX_THREAD_ID'), 'runtime': str(paths[-1]) if paths else None}))\nPY",
      max_output_tokens: 1000,
    });
    if (discovery.exit_code !== 0) return { status: "discovery-failed" };
    const context = JSON.parse(discovery.output);
    if (!context.runtime) return { status: "runtime-missing" };
    if (!/^[0-9a-f-]{36}$/.test(context.threadId ?? "")) return { status: "current-thread-unknown" };
    // Check bindings in a separate cell: a redeclared initializer can shadow
    // its previous value in the persistent REPL and reset the attempt latch.
    const bindings = await repl("nodeRepl.write(JSON.stringify({ state: typeof __codexBrowserPreflight !== 'undefined', agent: typeof agent !== 'undefined' }));");
    if (!bindings.state) {
      await repl("var __codexBrowserPreflight = { navigated: false }; nodeRepl.write(JSON.stringify({ initialized: true }));");
    }
    const bootstrapCode = `
        var agent;
        try { agent = await (await import(${JSON.stringify(context.runtime)})).setupBrowserRuntime();
          nodeRepl.write(JSON.stringify({ status: 'bootstrapped' })); }
        catch (error) { nodeRepl.write(JSON.stringify({ status:
          String(error?.message ?? error).trim() === 'Local browser use is disabled in Work settings'
            ? 'access-unresolved'
            : /denied|permission|not authorized|prohibited|rejected|requires approval|blocked by/i.test(String(error?.message ?? error))
              ? 'access-blocked' : 'bootstrap-failed', error: String(error?.message ?? error),
              navigationAttempted: __codexBrowserPreflight.navigated })); }
      `;
    const bootstrap = bindings.agent ? { status: "bootstrapped" } : await repl(bootstrapCode);
    const inspectCode = `
      var bp = __codexBrowserPreflight;
      bp.threadId = ${JSON.stringify(context.threadId)};
      var bpResult;
      try {
        var bpInventory = await agent.browsers.list();
        var bpIab = bpInventory.find(item => item.type === 'iab' && item.metadata?.codexSessionId === bp.threadId);
        if (bpIab) {
          if (!bp.browser || bp.browser.browserId !== bpIab.id) {
            bp.browser = await agent.browsers.get(bpIab.id);
            bp.documentation = await bp.browser.documentation();
          }
          bp.ready = true;
          bpResult = { status: 'documentation-ready', recovered: bp.navigated,
            browserTypes: bpInventory.map(item => item.type), documentation: bp.documentation };
        } else {
          bp.ready = false;
          bpResult = { status: 'registration-missing', browserTypes: bpInventory.map(item => item.type) };
        }
      } catch (error) {
        bp.ready = false;
        var bpMessage = String(error?.message ?? error);
        bpResult = { status: bpMessage.trim() === 'Local browser use is disabled in Work settings'
          ? 'access-unresolved'
          : /denied|permission|not authorized|prohibited|rejected|requires approval|blocked by/i.test(bpMessage)
            ? 'access-blocked' : 'browser-error', error: bpMessage };
      }
      nodeRepl.write(JSON.stringify({ ...bpResult, navigationAttempted: bp.navigated }));
    `;
    let observation = bootstrap.status === "bootstrapped" ? await repl(inspectCode) : bootstrap;
    if (!["registration-missing", "access-unresolved"].includes(observation.status)) return observation;
    if (observation.navigationAttempted) return { ...observation, action: "Stop. Navigation already attempted; do not repeat it or infer a disabled setting." };
    if (!navigateName) return { ...observation, status: "tool-missing", tool: "navigate_to_codex_page" };
    await repl("__codexBrowserPreflight.navigated = true; nodeRepl.write(JSON.stringify({ recorded: true }));");
    const navigation = await tools[navigateName]({ threadId: context.threadId });
    // A queued tab or a navigation receipt is never proof of browser access.
    if (navigation.isError) return { status: "navigation-failed", action: "Inspect the tool result; do not retry or change settings." };
    const retryBootstrap = bootstrap.status === "bootstrapped" ? bootstrap : await repl(bootstrapCode);
    observation = retryBootstrap.status === "bootstrapped" ? await repl(inspectCode) : retryBootstrap;
    return observation.status === "documentation-ready" ? observation : {
      ...observation, action: "Stop. The supported navigation did not establish IAB access; do not bypass the access check."
    };
  }
  if (phase === "verify") {
    if (!documentationRead) return { status: "documentation-review-required" };
    if (!probe?.url || !probe?.expectedText) return { status: "authorized-read-target-required" };
    return await repl(`
      if (typeof __codexBrowserPreflight === 'undefined' || !__codexBrowserPreflight.ready) {
        nodeRepl.write(JSON.stringify({ status: 'prepare-required' }));
      } else {
        var bp = __codexBrowserPreflight;
        var bpProbe;
        var bpProof;
        var bpStage = 'create-tab';
        try {
          bpProbe = await bp.browser.tabs.new();
          bpStage = 'navigate-probe';
          await bpProbe.goto(${JSON.stringify(probe.url)});
          bpStage = 'read-probe';
          var bpState = await bpProbe.ax.get('state', { disableDiffing: true });
          bpProof = { status: bpState.includes(${JSON.stringify(probe.expectedText)}) ? 'verified' : 'read-probe-failed',
            recovered: bp.navigated, readState: bpState };
        } catch (error) {
          bpProof = { status: /denied|permission|not authorized|prohibited|rejected|requires approval|blocked by/i.test(String(error?.message ?? error))
            ? 'access-blocked' : 'read-probe-error', stage: bpStage, error: String(error?.message ?? error) };
        } finally {
          if (bpProbe) {
            try { await bpProbe.close(); }
            catch { bpProof.cleanupFailed = true; bpProof.probeTabId = bpProbe.id; }
          }
        }
        nodeRepl.write(JSON.stringify(bpProof));
      }
    `);
  }
  throw new Error("Expected phase prepare or verify");
})
