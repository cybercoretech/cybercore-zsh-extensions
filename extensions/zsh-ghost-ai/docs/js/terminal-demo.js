/* ==========================================================================
   zsh-ghost-ai — Interactive terminal demo (hero sandbox)
   ========================================================================== */

const DEMO_PREDICTIONS = {
  "git che": "ckout main",
  "git com": "mit -m \"",
  "git pus": "h origin main",
  "git pul": "l origin main",
  "git sta": "tus",
  "git ad": "d .",
  "npm inst": "all ",
  "npm run": " ",
  "docker run": " -it ",
  "docker ps": " -a",
  "kubectl get": " pods",
  "kubectl del": "ete pod ",
  "cargo bu": "ild",
  "cargo te": "st",
  "cargo che": "ck",
  "ls -l": "a",
  "cd ..": "",
  "ssh ": "user@host",
};

const DEMO_MAX_BUFFER = 60;
const DEMO_DEBOUNCE_MS = 350;

let typedEl, cursorEl, ghostLineEl, ghostTypedEl, ghostCaretEl, hintEl;
let inputBuffer = "";
let ghostText = "";
let debounceTimer = null;
let effectStarted = false;

export function startInteractiveDemo() {
  effectStarted = true;

  typedEl = document.getElementById("typed");
  cursorEl = document.getElementById("cursor");
  ghostLineEl = document.getElementById("line-ghost");
  ghostTypedEl = document.getElementById("typed-ghost");
  ghostCaretEl = document.getElementById("ghost-caret");
  hintEl = document.getElementById("line-hint");

  if (!typedEl || !cursorEl) return;

  // Make the terminal body focusable and capture keystrokes
  const terminalBody = document.getElementById("terminal-body");
  terminalBody.tabIndex = 0;
  terminalBody.focus();

  terminalBody.addEventListener("keydown", onKeyDown);
  terminalBody.addEventListener("focus", () => {
    cursorEl.style.opacity = "1";
  });
  terminalBody.addEventListener("blur", () => {
    cursorEl.style.opacity = "0.6";
  });

  // Prevent default browser handling of arrow keys in the terminal body
  terminalBody.addEventListener(
    "keydown",
    (e) => {
      if (e.key === "ArrowRight" || e.key === "ArrowLeft" || e.key === "Escape") {
        e.preventDefault();
      }
    },
    true
  );
}

function onKeyDown(e) {
  const key = e.key;

  // Accept: ArrowRight or End
  if (key === "ArrowRight" || key === "End") {
    if (ghostText) {
      acceptGhost();
    }
    return;
  }

  // Dismiss: Escape
  if (key === "Escape") {
    dismissGhost();
    return;
  }

  // Backspace
  if (key === "Backspace") {
    if (inputBuffer.length > 0) {
      inputBuffer = inputBuffer.slice(0, -1);
      renderTyped();
      clearGhost();
    }
    return;
  }

  // Printable character
  if (key.length === 1 && !e.ctrlKey && !e.altKey && !e.metaKey) {
    inputBuffer += key;
    renderTyped();
    scheduleGhost();
    return;
  }
}

function renderTyped() {
  typedEl.textContent = inputBuffer;
  if (inputBuffer.length > DEMO_MAX_BUFFER) {
    inputBuffer = inputBuffer.slice(0, DEMO_MAX_BUFFER);
  }
}

function scheduleGhost() {
  clearTimeout(debounceTimer);
  debounceTimer = setTimeout(() => {
    computeGhost();
  }, DEMO_DEBOUNCE_MS);
}

function computeGhost() {
  const lower = inputBuffer.toLowerCase().trim();
  if (!lower) {
    clearGhost();
    return;
  }

  // Find the longest matching prediction prefix
  let best = "";
  let bestLen = 0;
  for (const [prefix, suffix] of Object.entries(DEMO_PREDICTIONS)) {
    if (lower.startsWith(prefix.toLowerCase()) && prefix.length > bestLen) {
      best = suffix;
      bestLen = prefix.length;
    }
  }

  if (best && inputBuffer.length > prefixLengthFor(lower)) {
    showGhost(best);
  } else {
    clearGhost();
  }
}

function prefixLengthFor(lower) {
  let best = 0;
  for (const prefix of Object.keys(DEMO_PREDICTIONS)) {
    if (lower.startsWith(prefix.toLowerCase())) best = Math.max(best, prefix.length);
  }
  return best;
}

function showGhost(text) {
  ghostText = text;
  ghostTypedEl.textContent = text;
  ghostLineEl.classList.remove("hidden");
  hintEl.classList.remove("hidden");
}

function clearGhost() {
  ghostText = "";
  ghostTypedEl.textContent = "";
  ghostLineEl.classList.add("hidden");
  hintEl.classList.add("hidden");
}

function dismissGhost() {
  clearGhost();
  typedEl.textContent = inputBuffer;
  cursorEl.style.opacity = "1";
}

function acceptGhost() {
  if (!ghostText) return;

  inputBuffer = inputBuffer + ghostText;
  typedEl.textContent = inputBuffer;
  clearGhost();
  cursorEl.style.opacity = "1";
  cursorEl.style.transition = "none";
  cursorEl.style.opacity = "0";
  requestAnimationFrame(() => {
    cursorEl.style.transition = "";
    cursorEl.style.opacity = "1";
  });
}
