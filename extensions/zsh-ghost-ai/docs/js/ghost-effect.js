/* ==========================================================================
   zsh-ghost-ai — The Ghost Effect (signature animation)
   ========================================================================== */

const GHOST_COMMAND = "git che";
const GHOST_SUGGESTION = "ckout main";
const CHAR_DELAY = 100;      // ms per typed char
const GHOST_DELAY = 90;      // ms per ghost char
const PAUSE_MS = 150;        // pause between typing and ghost
const ACCEPT_MS = 2000;      // when to auto-accept

let effectContainer = null;
let geTyped = null;
let geCursor = null;
let geTypedGhost = null;
let geGhostCaret = null;
let geHint = null;
let effectTimeout = null;
let effectAborted = false;

function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

function typeChar(el, ch) {
  const span = document.createElement("span");
  span.textContent = ch;
  span.style.opacity = "0";
  span.style.transform = "translateX(-2px)";
  span.style.transition = "opacity 0.1s ease, transform 0.1s ease";
  el.appendChild(span);
  requestAnimationFrame(() => {
    span.style.opacity = "1";
    span.style.transform = "translateX(0)";
  });
  return span;
}

function ghostTypeChar(el, ch) {
  const span = document.createElement("span");
  span.textContent = ch;
  span.style.opacity = "0";
  span.style.transform = "translateX(-1px)";
  span.style.transition = "opacity 0.1s ease, transform 0.1s ease";
  el.appendChild(span);
  requestAnimationFrame(() => {
    span.style.opacity = "0.4";
    span.style.transform = "translateX(0)";
  });
  return span;
}

async function runGhostEffect() {
  if (effectAborted) return;

  geTyped.textContent = "";
  geTypedGhost.textContent = "";
  geCursor.textContent = "▋";
  geGhostCaret.textContent = "▋";
  geHint.style.opacity = "0";
  geHint.style.transition = "opacity 0.4s ease";

  // 1. Type the command char by char
  for (let i = 0; i < GHOST_COMMAND.length; i++) {
    if (effectAborted) return;
    typeChar(geTyped, GHOST_COMMAND[i]);
    await sleep(CHAR_DELAY + (Math.random() * 40 - 20));
  }

  // 2. Pause
  await sleep(PAUSE_MS);
  if (effectAborted) return;

  // 3. Materialize ghost suggestion char by char
  for (let i = 0; i < GHOST_SUGGESTION.length; i++) {
    if (effectAborted) return;
    ghostChar(geTypedGhost, GHOST_SUGGESTION[i]);
    await sleep(GHOST_DELAY + (Math.random() * 40 - 20));
  }

  // 4. Show hint
  geHint.style.opacity = "0.7";

  // 5. Auto-accept: ghost snaps into typed buffer
  await sleep(ACCEPT_MS);
  if (effectAborted) return;

  // Move ghost text into typed
  const ghostText = geTypedGhost.textContent;
  geTyped.textContent = geTyped.textContent + ghostText;
  geTypedGhost.textContent = "";
  geGhostCaret.textContent = "";
  geHint.style.opacity = "0";

  // Cursor settles at end
  geCursor.textContent = "▋";

  // Effect complete after a short settle
  await sleep(600);
  if (effectAborted) return;

  // Remove overlay so interactive demo takes over
  const overlay = document.getElementById("ghost-effect-overlay");
  if (overlay) {
    overlay.style.opacity = "0";
    overlay.style.transition = "opacity 0.6s ease";
    setTimeout(() => {
      overlay.remove();
      startInteractiveDemo();
    }, 600);
  }
}

function ghostChar(el, ch) {
  const span = document.createElement("span");
  span.textContent = ch;
  span.style.opacity = "0.4";
  el.appendChild(span);
}

export function initGhostEffect() {
  effectContainer = document.getElementById("ghost-effect-overlay");
  if (!effectContainer) return;

  geTyped = document.getElementById("ge-typed");
  geCursor = document.getElementById("ge-cursor");
  geTypedGhost = document.getElementById("ge-typed-ghost");
  geGhostCaret = document.getElementById("ge-ghost-caret");
  geHint = document.getElementById("ge-hint");

  if (!geTyped || !geCursor || !geTypedGhost || !geGhostCaret || !geHint) {
    console.warn("ghost-effect: terminal elements not found");
    return;
  }

  // Allow abort on user interaction
  const abort = () => {
    effectAborted = true;
    const overlay = document.getElementById("ghost-effect-overlay");
    if (overlay) overlay.remove();
    startInteractiveDemo();
  };
  window.addEventListener("keydown", abort, { once: true });
  window.addEventListener("mousedown", abort, { once: true });
  window.addEventListener("touchstart", abort, { once: true });

  runGhostEffect();
}
