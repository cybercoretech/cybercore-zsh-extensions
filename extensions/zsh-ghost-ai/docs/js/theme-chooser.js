/* ==========================================================================
   zsh-ghost-ai — CyberCore shared theme chooser (mounted in top navbar)
   Mounts into legacy #themeButton / #themeMenu markup (CyberCore pattern).
   ========================================================================== */

(() => {
  'use strict';
  if (window.CybercoreThemeChooser?.boot) return;

  const SITE = window.SITE || {};
  const DATA = String(SITE.dataRoot || 'https://raw.githubusercontent.com/cybercoretech/cybercore/main').replace(/\/$/, '');
  const STORE = 'cybercore-theme';
  const FALLBACK = { bg:'09080f', white:'f0f0f2', panel:'16151f', line:'32303e', muted:'807f8b', acid_green:'39ff33', hot_pink:'ff147f', purple:'8a22e2', cyan:'00e5ff', orange:'ff9000', red:'f1142d' };
  const SURFACE = ['bg','white','panel','line','muted'];
  const VARS = { bg:'--bg', white:'--white', panel:'--panel', line:'--line', muted:'--muted', acid_green:'--acid', hot_pink:'--pink', purple:'--purple', cyan:'--cyan', orange:'--orange', red:'--red' };
  const MASHUPS = Array.isArray(SITE.mashups) ? SITE.mashups : [];
  const root = document.documentElement;
  const $ = (s, el=document) => el.querySelector(s);
  const $$ = (s, el=document) => [...el.querySelectorAll(s)];
  const display = s => String(s || '').replaceAll('-', ' ').replaceAll('_', ' ').toUpperCase();
  const familyColors = { mashup:'#ff2bd6', alien:'#9b7cff', 'cybercore-tech':'#39ff33', cyberdark:'#00e5ff', cyberdyne:'#ff1f3d', cyberpunk:'#ff0055', default:'#7dcfff', dystopian:'#d4e157', neosynth:'#00ff8c', synthwave:'#4cc9f0' };

  let families = {}, current = null, currentPalette = FALLBACK, bootPromise = null;
  const paletteCache = new Map();
  const palettePending = new Map();
  const instances = new Set();

  const familyOf = name => name && Object.keys(families).find(f => (families[f] || []).includes(name));
  const allNames = () => Object.values(families).flat();
  const mashOf = id => MASHUPS.find(m => m.id === id);
  const parseMix = id => {
    if (!id || !id.startsWith('mix:')) return null;
    const [, base, accent] = id.split(':');
    return familyOf(base) && familyOf(accent) ? { id, base, accent, label:`${display(base)} × ${display(accent)}` } : null;
  };
  const blendOf = id => mashOf(id) || parseMix(id);
  const known = id => Boolean(id && (blendOf(id) || familyOf(id)));
  const labelOf = id => blendOf(id)?.label || display(id);

  function normalizePalette(raw) {
    if (!raw || typeof raw !== 'object' || Array.isArray(raw)) {
      throw new Error('Invalid theme palette: expected an object');
    }
    const value = { ...raw };
    value.border = raw.border || raw.line || FALLBACK.line;
    value.line = raw.line || raw.border || FALLBACK.line;
    value.bg = raw.bg || FALLBACK.bg;
    value.white = raw.white || raw.text_primary || FALLBACK.white;
    value.panel = raw.panel || raw.surface || FALLBACK.panel;
    value.muted = raw.muted || FALLBACK.muted;
    value.acid_green = raw.acid_green || raw.success || FALLBACK.acid_green;
    value.hot_pink = raw.hot_pink || raw.accent_hot || FALLBACK.hot_pink;
    value.purple = raw.purple || raw.accent_alt || FALLBACK.purple;
    value.cyan = raw.cyan || FALLBACK.cyan;
    value.orange = raw.orange || raw.warning || FALLBACK.orange;
    value.red = raw.red || raw.error || FALLBACK.red;
    value.surface = raw.surface || value.panel;
    value.selection = raw.selection || value.cyan;
    value.hover = raw.hover || value.panel;
    value.text_primary = raw.text_primary || value.white;
    value.accent_hot = raw.accent_hot || value.hot_pink;
    value.accent_alt = raw.accent_alt || value.purple;
    value.success = raw.success || value.acid_green;
    value.warning = raw.warning || value.orange;
    value.error = raw.error || value.red;
    return value;
  }

  async function palette(name) {
    if (paletteCache.has(name)) return paletteCache.get(name);
    if (palettePending.has(name)) return palettePending.get(name);
    const pending = (async () => {
      const family = familyOf(name);
      if (!family) throw new Error(`Unknown theme: ${name}`);
      const response = await fetch(`${DATA}/themes/${encodeURIComponent(family)}/${encodeURIComponent(name)}.json`);
      if (!response.ok) throw new Error(`${name}: HTTP ${response.status}`);
      const value = normalizePalette(await response.json());
      paletteCache.set(name, value);
      return value;
    })();
    palettePending.set(name, pending);
    try { return await pending; }
    finally { palettePending.delete(name); }
  }

  const CANONICAL_SURFACE = [
    'bg', 'surface', 'panel', 'border', 'selection',
    'hover', 'white', 'muted', 'text_primary'
  ];

  const blend = (base, accent) => {
    const result = { ...accent };
    CANONICAL_SURFACE.forEach(key => { result[key] = base[key]; });
    result.line = result.border;
    return normalizePalette(result);
  };
  async function resolve(id) {
    const mashup = blendOf(id);
    return mashup ? blend(...await Promise.all([palette(mashup.base), palette(mashup.accent)])) : palette(id);
  }

  function syncSelection(id) {
    instances.forEach(instance => {
      $$('.cc-theme-option', instance.list).forEach(option => {
        option.setAttribute('aria-selected', String(option.dataset.value === id));
      });
      const label = $('.cc-theme-label', instance.host);
      if (label) label.textContent = labelOf(id);
    });
    $$('[data-active-theme]').forEach(el => { el.textContent = labelOf(id); });
    $$('[data-active-theme-raw]').forEach(el => { el.textContent = id; });
  }

  const CANONICAL_VARS = {
    bg:'--bg', surface:'--surface', panel:'--panel', border:'--border',
    selection:'--selection', hover:'--hover', white:'--white',
    muted:'--muted', text_primary:'--text-primary',
    accent_hot:'--accent-hot', accent_alt:'--accent-alt',
    acid_green:'--acid', hot_pink:'--pink', purple:'--purple', cyan:'--cyan',
    orange:'--orange', red:'--red', success:'--success', warning:'--warning', error:'--error'
  };

  function paint(id, value) {
    value = normalizePalette(value);
    const managedVariables = new Set([
      ...Object.values(CANONICAL_VARS),
      ...Object.values(VARS),
      '--fg'
    ]);
    managedVariables.forEach(variable => root.style.removeProperty(variable));
    Object.entries(CANONICAL_VARS).forEach(([key, variable]) => {
      root.style.setProperty(variable, `#${value[key]}`);
    });
    Object.entries(VARS).forEach(([key, variable]) => {
      const color = key === 'line' ? value.border : value[key];
      root.style.setProperty(variable, `#${color}`);
    });
    root.style.setProperty('--fg', `#${value.white}`);
    root.dataset.theme = id;
    current = id;
    currentPalette = value;
    const meta = $('meta[name="theme-color"]');
    if (meta) meta.content = `#${value.bg}`;
    syncSelection(id);
    document.dispatchEvent(new CustomEvent('cc:theme', {
      detail: { id, palette: value }
    }));
  }
  async function apply(id, { persist = true, origin = null } = {}) {
    if (!known(id)) throw new Error(`Unknown theme selection: ${id}`);
    const value = await resolve(id);
    const transition = origin && !window.matchMedia('(prefers-reduced-motion: reduce)').matches && document.startViewTransition;
    if (transition) {
      root.style.setProperty('--vx', `${origin.x}px`);
      root.style.setProperty('--vy', `${origin.y}px`);
      document.startViewTransition(() => paint(id, value));
    } else paint(id, value);
    if (persist) {
      try { localStorage.setItem(STORE, id); } catch {}
      try {
        const url = new URL(location.href);
        url.searchParams.set('theme', id);
        history.replaceState(null, '', url);
      } catch (error) { console.warn('[Cybercore chooser] Could not update URL', error); }
    }
    return value;
  }

  const groups = () => [['mashup', MASHUPS.map(item => item.id)], ...Object.entries(families)];
  function makeSwatch(option, name) {
    const load = () => {
      if (option.dataset.swatchLoaded === 'true') return;
      option.dataset.swatchLoaded = 'true';
      const dots = $('.cc-theme-dots', option);
      resolve(name).then(value => {
        if (!option.isConnected) return;
        dots.replaceChildren(...['acid_green', 'hot_pink', 'cyan'].map(key => {
          const dot = document.createElement('i');
          dot.style.background = `#${value[key] || '000000'}`;
          return dot;
        }));
      }).catch(() => { option.dataset.swatchLoaded = 'false'; });
    };
    if ('IntersectionObserver' in window) {
      const observer = new IntersectionObserver(entries => {
        if (entries.some(entry => entry.isIntersecting)) {
          observer.disconnect();
          load();
        }
      }, { root: option.closest('.cc-theme-list'), rootMargin: '120px' });
      observer.observe(option);
    }
  }

  function filterList(list, query) {
    const normalized = query.trim().toLowerCase().replaceAll(' ', '-');
    let heading = null;
    let visible = false;
    [...list.children].forEach(element => {
      if (element.classList.contains('cc-theme-group-label')) {
        if (heading) heading.hidden = !visible;
        heading = element;
        visible = false;
        return;
      }
      const hit = !normalized || element.dataset.value.toLowerCase().includes(normalized) ||
        element.dataset.family.toLowerCase().includes(normalized) ||
        element.textContent.toLowerCase().replaceAll(' ', '-').includes(normalized);
      element.hidden = !hit;
      visible ||= hit;
    });
    if (heading) heading.hidden = !visible;
  }

  function buildList(instance) {
    const { list } = instance;
    list.replaceChildren();
    groups().forEach(([family, names]) => {
      if (!names.length) return;
      const heading = document.createElement('div');
      heading.className = 'cc-theme-group-label';
      heading.dataset.family = family;
      heading.style.setProperty('--cc-family', familyColors[family] || '#00e5ff');
      heading.textContent = `${family === 'mashup' ? 'SIGNATURE MASHUPS' : display(family)} · ${names.length}`;
      list.append(heading);
      names.forEach(name => {
        const option = document.createElement('button');
        option.type = 'button';
        option.className = 'cc-theme-option';
        option.setAttribute('role', 'option');
        option.dataset.value = name;
        option.dataset.family = family;
        option.setAttribute('aria-selected', 'false');
        const title = document.createElement('span');
        title.className = 'cc-theme-option-label';
        title.textContent = labelOf(name);
        const dots = document.createElement('span');
        dots.className = 'cc-theme-dots';
        option.append(title, dots);
        option.addEventListener('click', async event => {
          try {
            await apply(name, { origin: { x: event.clientX, y: event.clientY } });
            instance.close();
            instance.button.focus({ preventScroll: true });
          } catch (error) { console.error('[Cybercore chooser]', error); }
        });
        list.append(option);
        makeSwatch(option, name);
      });
    });
    if (current) syncSelection(current);
  }

  function mount(host, legacy = false) {
    if (host.dataset.ccChooserMounted === 'true') return;
    if (!legacy) {
      host.innerHTML = '<button class="cc-theme-button" type="button" aria-haspopup="listbox" aria-expanded="false"><i class="cc-theme-swatch" aria-hidden="true"></i><span class="cc-theme-label">LOADING…</span><span aria-hidden="true">⌄</span></button><div class="cc-theme-menu" hidden><div class="cc-theme-search"><input type="search" placeholder="FILTER THEMES…" aria-label="Filter themes" autocomplete="off" spellcheck="false"></div><div class="cc-theme-list" role="listbox" aria-label="Theme"></div></div>';
    }
    const button = legacy ? $('.theme-button, #themeButton', host) : $('.cc-theme-button', host);
    const menu = legacy ? $('.theme-menu, #themeMenu', host) : $('.cc-theme-menu', host);
    let filter = legacy ? $('.theme-search input, #themeFilter', host) : $('.cc-theme-search input', host);
    let list = legacy ? $('.theme-list, #themeList', host) : $('.cc-theme-list', host);

    // In legacy mode with minimal markup (#themeButton + #themeMenu only),
    // create filter + list elements if they don't exist.
    if (legacy && !filter) {
      filter = document.createElement('input');
      filter.type = 'search';
      filter.id = 'themeFilter';
      filter.placeholder = 'FILTER THEMES…';
      filter.autocomplete = 'off';
      filter.spellcheck = false;
      menu.insertBefore(filter, menu.firstChild);
    }
    if (legacy && !list) {
      list = document.createElement('div');
      list.id = 'themeList';
      list.className = 'theme-list';
      list.setAttribute('role', 'listbox');
      list.setAttribute('aria-label', 'Theme');
      menu.appendChild(list);
    }

    if (!button || !menu || !filter || !list) {
      if (legacy) console.warn('[Cybercore chooser] Legacy #picker markup is incomplete; expected button, menu, filter, and list elements.');
      else host.innerHTML = '<p class="cc-theme-error" role="alert">Theme chooser markup is incomplete.</p>';
      return;
    }
    host.dataset.ccChooserMounted = 'true';
    host.classList.add('cc-theme-picker');
    button.setAttribute('aria-haspopup', 'listbox');
    button.setAttribute('aria-expanded', 'false');
    if (!list.id) list.id = `cc-theme-list-${instances.size + 1}`;
    button.setAttribute('aria-controls', list.id);
    const label = $('span', button);
    if (label) label.classList.add('cc-theme-label');

    const instance = { host, button, menu, filter, list, close: null, open: null };
    const close = () => {
      menu.hidden = true;
      button.setAttribute('aria-expanded', 'false');
      filter.value = '';
      filterList(list, '');
    };
    const open = () => {
      menu.hidden = false;
      button.setAttribute('aria-expanded', 'true');
      if (window.matchMedia('(pointer:fine)').matches) filter.focus({ preventScroll: true });
    };
    instance.close = close;
    instance.open = open;
    instances.add(instance);

    button.addEventListener('click', () => menu.hidden ? open() : close());
    document.addEventListener('pointerdown', event => {
      if (!menu.hidden && !host.contains(event.target)) close();
    });
    menu.addEventListener('keydown', event => {
      const options = $$('.cc-theme-option:not([hidden])', list);
      const index = options.indexOf(document.activeElement);
      if (event.key === 'Escape') {
        event.preventDefault();
        close();
        button.focus({ preventScroll: true });
      } else if (event.key === 'ArrowDown') {
        event.preventDefault();
        (options[index + 1] || options[0])?.focus();
      } else if (event.key === 'ArrowUp') {
        event.preventDefault();
        (index <= 0 ? filter : options[index - 1])?.focus();
      } else if (event.key === 'Home' && options.length) {
        event.preventDefault(); options[0].focus();
      } else if (event.key === 'End' && options.length) {
        event.preventDefault(); options[options.length - 1].focus();
      } else if (event.key === 'Enter' && document.activeElement === filter && options.length) {
        event.preventDefault(); options[0].click();
      }
    });
    filter.addEventListener('input', () => filterList(list, filter.value));
    buildList(instance);
  }

  async function boot() {
    if (bootPromise) return bootPromise;
    bootPromise = (async () => {
      const response = await fetch(`${DATA}/cybergrid.json`);
      if (!response.ok) throw new Error(`Registry HTTP ${response.status}`);
      const schema = await response.json();
      families = schema.families || {};
      $$('[data-cc-theme-chooser]').forEach(host => mount(host));
      const legacy = $('#themeButton');
      if (legacy && !legacy.dataset.ccChooserMounted) mount($('#nav'), true);

      const sourceCount = allNames().length;
      const totalCount = sourceCount + MASHUPS.length;

      const params = new URLSearchParams(location.search);
      let saved = null;
      try { saved = localStorage.getItem(STORE); } catch {}
      const start = [params.get('theme'), saved, SITE.defaultTheme, 'cybercore-tech'].find(known);
      try { await apply(start, { persist: Boolean(params.get('theme')) }); }
      catch (error) {
        console.warn('[Cybercore chooser] Initial theme failed', error);
        paint('cybercore-tech', FALLBACK);
      }
      window.dispatchEvent(new CustomEvent('cc:theme-chooser-ready', {
        detail: { sourceCount, mashupCount: MASHUPS.length, totalCount, familyCount: Object.keys(families).length }
      }));
      return window.CybercoreThemeChooser;
    })();
    try { return await bootPromise; }
    catch (error) { bootPromise = null; throw error; }
  }

  window.CybercoreThemeChooser = {
    boot, apply, resolve, palette,
    get id() { return current; },
    get paletteData() { return currentPalette; },
    get registry() {
      return {
        families: Object.fromEntries(Object.entries(families).map(([key, value]) => [key, [...value]])),
        mashups: MASHUPS.map(item => ({ ...item }))
      };
    }
  };
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', () => boot().catch(error => console.error('[Cybercore chooser]', error)), { once: true });
  else boot().catch(error => console.error('[Cybercore chooser]', error));
})();
