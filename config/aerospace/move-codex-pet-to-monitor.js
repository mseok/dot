// Run with: osascript -l JavaScript move-codex-pet-to-monitor.js
//
// Codex Pet is a group of native macOS popup windows. AeroSpace deliberately
// leaves popups outside its workspace tree, so moving one with an AeroSpace
// command either fails or breaks the composition. The ChatGPT accessibility
// tree exposes only three independently movable render owners: one composition
// surface, the activity stack, and the mascot effect. Moving every duplicate
// surface causes repeated repositioning, so this script changes those owners
// exactly once and leaves app-managed controls alone.

ObjC.import('AppKit');
ObjC.import('Foundation');

const CODEX_APP_BUNDLE_ID = 'com.openai.codex';
const COMPOSITION_TITLE = 'Codex Pet Composition Surface';
const ACTIVITY_TITLE = 'Codex Pet Activity Stack Backing';
const EFFECT_TITLE = 'Codex Pet Mascot Effect';
const DEFAULT_ACTIVITY_OFFSET = [212, 36];
const DEFAULT_EFFECT_OFFSET = [298, 210];

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

function windowSnapshot(window) {
  const position = window.position();
  const size = window.size();
  return {
    window,
    position: [number(position[0]), number(position[1])],
    size: [number(size[0]), number(size[1])],
  };
}

function boundedOffset(layer, composition, fallback) {
  const offset = [
    layer.position[0] - composition.position[0],
    layer.position[1] - composition.position[1],
  ];
  const isPlausible =
    Math.abs(offset[0]) <= composition.size[0] * 2 &&
    Math.abs(offset[1]) <= composition.size[1] * 2;
  return isPlausible ? offset : fallback;
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

  const appWindows = processes[0].windows();
  const compositionWindow = appWindows.find((window) => window.name() === COMPOSITION_TITLE);
  const activityWindow = appWindows.find((window) => window.name() === ACTIVITY_TITLE);
  const effectWindow = appWindows.find((window) => window.name() === EFFECT_TITLE);
  if (!compositionWindow || !activityWindow || !effectWindow) return;

  const composition = windowSnapshot(compositionWindow);
  const activity = windowSnapshot(activityWindow);
  const effect = windowSnapshot(effectWindow);
  const compositionCenterX = composition.position[0] + composition.size[0] / 2;
  const compositionCenterY = composition.position[1] + composition.size[1] / 2;
  const sourceScreen = screenContainingPoint(screens, compositionCenterX, compositionCenterY);
  if (sourceScreen && sourceScreen.name === targetScreen.name) return;

  const activityOffset = boundedOffset(activity, composition, DEFAULT_ACTIVITY_OFFSET);
  const effectOffset = boundedOffset(effect, composition, DEFAULT_EFFECT_OFFSET);
  const targetWidth = Math.max(targetScreen.width - composition.size[0], 0);
  const targetHeight = Math.max(targetScreen.height - composition.size[1], 0);
  let targetX;
  let targetY;

  if (sourceScreen) {
    const sourceWidth = Math.max(sourceScreen.width - composition.size[0], 0);
    const sourceHeight = Math.max(sourceScreen.height - composition.size[1], 0);
    const xRatio = sourceWidth === 0 ? 0.5 : clamp(
      (composition.position[0] - sourceScreen.x) / sourceWidth,
      0,
      1,
    );
    const yRatio = sourceHeight === 0 ? 0.5 : clamp(
      (composition.position[1] - sourceScreen.y) / sourceHeight,
      0,
      1,
    );
    targetX = targetScreen.x + xRatio * targetWidth;
    targetY = targetScreen.y + yRatio * targetHeight;
  } else {
    // A previous interrupted move can leave a surface off-screen. Recover it
    // to the center of the requested monitor rather than compounding offsets.
    targetX = targetScreen.x + targetWidth / 2;
    targetY = targetScreen.y + targetHeight / 2;
  }

  const compositionTarget = [Math.round(targetX), Math.round(targetY)];
  const activityTarget = [
    Math.round(targetX + activityOffset[0]),
    Math.round(targetY + activityOffset[1]),
  ];
  const effectTarget = [
    Math.round(targetX + effectOffset[0]),
    Math.round(targetY + effectOffset[1]),
  ];

  emitDebug({
    sourceMonitor: sourceScreen ? sourceScreen.name : null,
    targetMonitor: targetScreen.name,
    owners: 3,
    composition: { position: composition.position, size: composition.size, target: compositionTarget },
    activity: { position: activity.position, target: activityTarget },
    effect: { position: effect.position, target: effectTarget },
  });
  if (environmentValue('CODEX_PET_DRY_RUN') === '1') return;

  composition.window.position = compositionTarget;
  activity.window.position = activityTarget;
  effect.window.position = effectTarget;
}

main();
