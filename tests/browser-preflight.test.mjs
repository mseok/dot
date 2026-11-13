import assert from 'node:assert/strict';
import fs from 'node:fs';
import test from 'node:test';
import vm from 'node:vm';

const source = fs.readFileSync(new URL('../ai/codex/browser-preflight.js', import.meta.url), 'utf8');
const run = vm.runInNewContext(source);
const threadId = '00000000-0000-0000-0000-000000000001';
const ambiguous = 'Local browser use is disabled in Work settings';
const unavailable = 'Local browser access is unavailable for this chat';
const names = ['mcp__node_repl__js', 'mcp__codex_app__navigate_to_codex_page'];

// Execute the actual emitted REPL cells against a controlled public-API fixture.
// The tiny adapter preserves top-level bindings as the real Node REPL does.
function fixture({ state = 'missing', message = ambiguous, bootstrapError, readError, navigationError,
  fixed = true, siteLoggedOut = false, wrongThread = false, runtime = '/runtime.mjs' } = {}) {
  const events = [];
  const existing = { title: siteLoggedOut ? 'Sign in' : 'User page', touched: false };
  const probe = {
    id: 'owned-probe',
    goto: async url => { events.push(['goto', url]); },
    ax: { get: async () => {
      events.push(['read']);
      if (readError) throw Error(readError);
      return 'CODEX_BROWSER_READ_PROBE_OK';
    } },
    close: async () => { events.push(['close']); },
  };
  const browser = {
    browserId: 'iab', documentation: async () => 'Actual API documentation',
    tabs: {
      new: async () => { events.push(['new']); return probe; },
      list: async () => { throw Error('Must not inspect user tabs'); },
      get: async () => { throw Error('Must not touch user tabs'); },
    },
  };
  const agent = { browsers: {
    list: async () => {
      events.push(['inventory']);
      if (state === 'ambiguous') throw Error(message);
      if (state === 'denied') throw Error('Browser access denied by policy');
      return state === 'healthy' ? [{ type: 'iab', id: 'iab',
        metadata: { codexSessionId: wrongThread ? 'different-thread' : threadId } }] : [];
    },
    get: async id => { events.push(['get', id]); return browser; },
  } };
  const context = vm.createContext({
    nodeRepl: { write: value => { context.output = value; } },
    __import: async () => ({ setupBrowserRuntime: async () => {
      events.push(['bootstrap']);
      if (bootstrapError) throw Error(bootstrapError);
      return agent;
    } }),
  });
  const tools = {
    exec_command: async () => ({ exit_code: 0, output: JSON.stringify({ threadId, runtime }) }),
    mcp__node_repl__js: async ({ code }) => {
      const adapted = code.replace(/\bvar (\w+);/g, 'globalThis.$1 = undefined;')
        .replace(/\bvar /g, '').replace(/\bimport\(/g, '__import(');
      await vm.runInContext(`(async () => { ${adapted} })()`, context, { timeout: 1000 });
      return { content: [{ type: 'text', text: context.output }] };
    },
    mcp__codex_app__navigate_to_codex_page: async args => {
      events.push(['navigate', args.threadId]);
      assert.equal(args.threadId, threadId);
      if (navigationError) return { isError: true };
      if (fixed) { state = 'healthy'; bootstrapError = undefined; }
      return { content: [{ type: 'text', text: '{"navigated":true}' }] };
    },
  };
  return { tools, events, existing, context,
    prepare: opts => run({ tools, toolNames: names, ...opts }),
    verify: opts => run({ tools, toolNames: names, phase: 'verify', documentationRead: true,
      probe: { url: 'https://example.com/', expectedText: 'CODEX_BROWSER_READ_PROBE_OK' }, ...opts }) };
}

test('missing registration uses current-thread navigation and requires a real read', async () => {
  const f = fixture();
  assert.equal((await f.prepare()).status, 'documentation-ready');
  assert.equal(f.events.some(([event]) => event === 'read'), false);
  assert.equal((await f.verify()).status, 'verified');
  assert.deepEqual(f.events.filter(([event]) => event === 'navigate'), [['navigate', threadId]]);
  assert.deepEqual(f.events.slice(-4).map(([event]) => event), ['new', 'goto', 'read', 'close']);
});

test('the recorded misleading disabled-setting message recovers', async () => {
  const f = fixture({ state: 'ambiguous' });
  assert.equal((await f.prepare()).status, 'documentation-ready');
  assert.equal((await f.verify()).status, 'verified');
});

test('the same misleading message during bootstrap also recovers', async () => {
  const f = fixture({ bootstrapError: ambiguous });
  assert.equal((await f.prepare()).status, 'documentation-ready');
  assert.equal((await f.verify()).status, 'verified');
});

test('the access-unavailable wording of app 26.1106 is the same unresolved state and recovers', async () => {
  for (const f of [fixture({ state: 'ambiguous', message: unavailable }), fixture({ bootstrapError: unavailable })]) {
    assert.equal((await f.prepare()).status, 'documentation-ready');
    assert.deepEqual(f.events.filter(([event]) => event === 'navigate'), [['navigate', threadId]]);
    assert.equal((await f.verify()).status, 'verified');
  }
});

test('a denial that survives navigation names the REPL reset, as recorded on 2026-11-13', async () => {
  const f = fixture({ state: 'ambiguous', message: unavailable, fixed: false });
  for (const result of [await f.prepare(), await f.prepare()]) {
    assert.equal(result.status, 'access-unresolved');
    assert.match(result.action, /caches a denial for the rest of the turn.*js_reset.*next turn/);
  }
  assert.equal(f.events.filter(([event]) => event === 'navigate').length, 1);
});

test('healthy connection is not navigated, reimported or reselected on a second prepare', async () => {
  const f = fixture({ state: 'healthy' });
  await f.prepare();
  await f.prepare();
  assert.equal(f.events.filter(([event]) => event === 'bootstrap').length, 1);
  assert.equal(f.events.filter(([event]) => event === 'get').length, 1);
  assert.equal(f.events.some(([event]) => event === 'navigate'), false);
});

for (const access of ['denied', 'disabled']) {
  test(`confirmed ${access} never calls a tool`, async () => {
    const f = fixture();
    assert.equal((await f.prepare({ access })).status, 'access-blocked');
    assert.deepEqual(f.events, []);
  });
}

test('actual access rejection from the runtime is not retried by navigation', async () => {
  const f = fixture({ state: 'denied' });
  assert.equal((await f.prepare()).status, 'access-blocked');
  assert.equal(f.events.some(([event]) => event === 'navigate'), false);
});

test('an explicit bootstrap denial containing the misleading message still stops', async () => {
  const f = fixture({ bootstrapError: `Permission denied: ${ambiguous}` });
  assert.equal((await f.prepare()).status, 'access-blocked');
  assert.equal(f.events.some(([event]) => event === 'navigate'), false);
});

test('genuinely disabled but ambiguous access stays blocked after navigation, without loops', async () => {
  const f = fixture({ state: 'ambiguous', fixed: false });
  assert.equal((await f.prepare()).status, 'access-unresolved');
  assert.equal((await f.prepare()).status, 'access-unresolved');
  assert.equal(f.events.filter(([event]) => event === 'navigate').length, 1);
  assert.equal((await f.verify()).status, 'prepare-required');
});

test('tool discovery distinguishes missing navigator and missing REPL', async () => {
  const f = fixture();
  assert.equal((await f.prepare({ toolNames: [names[0]] })).tool, 'navigate_to_codex_page');
  assert.equal((await f.prepare({ toolNames: [] })).tool, 'node_repl.js');
  assert.equal(f.events.some(([event]) => event === 'navigate'), false);
});

test('missing runtime is not called a disabled setting', async () => {
  assert.equal((await fixture({ runtime: null }).prepare()).status, 'runtime-missing');
});

test('site logout never triggers connection recovery or touches a login tab', async () => {
  const f = fixture({ state: 'healthy', siteLoggedOut: true });
  await f.prepare();
  assert.equal((await f.verify()).status, 'verified');
  assert.equal(f.events.some(([event]) => event === 'navigate'), false);
  assert.deepEqual(f.existing, { title: 'Sign in', touched: false });
});

test('another thread IAB is never selected', async () => {
  const f = fixture({ state: 'healthy', wrongThread: true });
  assert.equal((await f.prepare()).status, 'registration-missing');
  assert.equal(f.events.some(([event]) => event === 'get'), false);
});

test('a navigation receipt without registration is not recovery', async () => {
  const f = fixture({ fixed: false });
  assert.equal((await f.prepare()).status, 'registration-missing');
  assert.equal((await f.verify()).status, 'prepare-required');
});

test('an actual read rejection preserves the failure stage and closes only its probe', async () => {
  const f = fixture({ state: 'healthy', readError: 'Permission denied for this page' });
  await f.prepare();
  const result = await f.verify();
  assert.equal(result.status, 'access-blocked');
  assert.equal(result.stage, 'read-probe');
  assert.equal(result.error, 'Permission denied for this page');
  assert.equal(f.events.at(-1)[0], 'close');
  assert.equal(f.events.some(([event]) => event === 'navigate'), false);
});

test('navigation denial is not retried or reported as success', async () => {
  const f = fixture({ navigationError: true });
  assert.equal((await f.prepare()).status, 'navigation-failed');
  await f.prepare();
  assert.equal(f.events.filter(([event]) => event === 'navigate').length, 1);
});

test('reading requires the agent to inspect the returned API documentation first', async () => {
  const f = fixture({ state: 'healthy' });
  await f.prepare();
  assert.equal((await f.verify({ documentationRead: false })).status, 'documentation-review-required');
  assert.equal(f.events.some(([event]) => event === 'new'), false);
});

test('verification never invents a target or silently switches to another URL', async () => {
  const f = fixture({ state: 'healthy' });
  await f.prepare();
  assert.equal((await f.verify({ probe: undefined })).status, 'authorized-read-target-required');
  assert.equal(f.events.some(([event]) => event === 'new'), false);
});
