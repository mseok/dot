// Run with: osascript -l JavaScript move-codex-pet-to-monitor.js
//
// Codex Pet is a group of native macOS popup windows. AeroSpace deliberately
// leaves popups outside its workspace tree, so moving any individual layer with
// an AeroSpace command either fails or breaks the composition. This script uses
// the supported Accessibility position property to move every Pet layer by one
// identical offset, preserving their relative geometry.

ObjC.import('AppKit');
ObjC.import('Foundation');

const CODEX_APP_BUNDLE_ID = 'com.openai.codex';
const PET_ROOT_TITLE = 'Codex';
const PET_TITLE_PREFIX = 'Codex Pet ';

function environmentValue(name) {
  const value = $.NSProcessInfo.processInfo.environment.objectForKey($(name));
  return value ? ObjC.unwrap(value) : '';
}

function number(value) {
  return Number(value);
}

function clamp(value, lower, upper) {
  return Math.max(lower, Math.min(upper, value));
}

function isPetWindow(name, size) {
  if (name.indexOf(PET_TITLE_PREFIX) === 0) return true;

  // The root overlay is simply titled "Codex". Keep the size bound so a
  // future ordinary ChatGPT window with that title is never moved by mistake.
  return name === PET_ROOT_TITLE &&
    size[0] >= 200 && size[0] <= 600 &&
    size[1] >= 40 && size[1] <= 500;
}

function accessibilityFrame(screen, primaryTop) {
  const frame = screen.frame;
  return {
    name: ObjC.unwrap(screen.localizedName),
    x: number(frame.origin.x),
    y: primaryTop - number(frame.origin.y) - number(frame.size.height),
    width: number(frame.size.width),
    height: number(frame.size.height),
  };
}

function screenContainingPoint(screens, x, y) {
  return screens.find((screen) =>
    x >= screen.x && x < screen.x + screen.width &&
    y >= screen.y && y < screen.y + screen.height,
  );
}

function emitDebug(payload) {
  if (environmentValue('CODEX_PET_DEBUG') === '1') {
    console.log(JSON.stringify(payload));
  }
}

function main() {
  const targetMonitorName = environmentValue('AEROSPACE_TARGET_MONITOR');
  if (!targetMonitorName) return;

  const primaryFrame = $.NSScreen.mainScreen.frame;
  const primaryTop = number(primaryFrame.origin.y) + number(primaryFrame.size.height);
  const screens = [];
  const nativeScreens = $.NSScreen.screens;
  for (let index = 0; index < nativeScreens.count; index += 1) {
    screens.push(accessibilityFrame(nativeScreens.objectAtIndex(index), primaryTop));
  }

  const targetScreen = screens.find((screen) => screen.name === targetMonitorName);
  if (!targetScreen) {
    emitDebug({ reason: 'target-monitor-not-found', targetMonitorName, screens });
    return;
  }

  const systemEvents = Application('System Events');
  const processes = systemEvents.applicationProcesses.whose({
    bundleIdentifier: CODEX_APP_BUNDLE_ID,
  })();
  if (!processes || processes.length === 0) return;

  const petWindows = processes[0].windows().map((window) => {
    const position = window.position();
    const size = window.size();
    return {
      window,
      name: window.name(),
      position: [number(position[0]), number(position[1])],
      size: [number(size[0]), number(size[1])],
    };
  }).filter((window) => isPetWindow(window.name, window.size));
  if (petWindows.length === 0) return;

  const anchor = petWindows.find((window) => window.name === PET_ROOT_TITLE) || petWindows[0];
  const anchorCenterX = anchor.position[0] + anchor.size[0] / 2;
  const anchorCenterY = anchor.position[1] + anchor.size[1] / 2;
  const sourceScreen = screenContainingPoint(screens, anchorCenterX, anchorCenterY);
  if (!sourceScreen) {
    emitDebug({ reason: 'anchor-off-screen', anchor, screens });
    return;
  }
  if (sourceScreen.name === targetScreen.name) return;

  // Preserve the user's relative anchor position while adapting it to the
  // target monitor's usable dimensions. Every auxiliary layer gets exactly
  // the same delta, keeping the native Pet composition intact.
  const xSpan = Math.max(sourceScreen.width - anchor.size[0], 0);
  const ySpan = Math.max(sourceScreen.height - anchor.size[1], 0);
  const xRatio = xSpan === 0 ? 0.5 : clamp((anchor.position[0] - sourceScreen.x) / xSpan, 0, 1);
  const yRatio = ySpan === 0 ? 0.5 : clamp((anchor.position[1] - sourceScreen.y) / ySpan, 0, 1);
  const targetX = targetScreen.x + xRatio * Math.max(targetScreen.width - anchor.size[0], 0);
  const targetY = targetScreen.y + yRatio * Math.max(targetScreen.height - anchor.size[1], 0);
  const deltaX = Math.round(targetX - anchor.position[0]);
  const deltaY = Math.round(targetY - anchor.position[1]);

  emitDebug({
    sourceMonitor: sourceScreen.name,
    targetMonitor: targetScreen.name,
    layers: petWindows.length,
    anchor: { name: anchor.name, position: anchor.position, size: anchor.size },
    delta: [deltaX, deltaY],
  });
  if (environmentValue('CODEX_PET_DRY_RUN') === '1') return;

  petWindows.forEach((window) => {
    window.window.position = [
      Math.round(window.position[0] + deltaX),
      Math.round(window.position[1] + deltaY),
    ];
  });
}

main();
