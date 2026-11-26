(() => {
  const APP_NAME = "FUL454";
  const ACCENT = "#d9f56b";
  const BG = "#102b25";
  const boot = () => {
    if ('serviceWorker' in navigator && location.protocol === 'https:') {
      const UPDATE_API = "https://pzgnnjwmwylkmikcxwmf.supabase.co/functions/v1/feedback-center";
      const UPDATE_KEY = "sb_publishable_1jZy2d-qVJOiCZvHoB6-ow_AytoxBA2";
      let registration = null;
      let approvedUpdate = false;
      let deferredVersion = null;
      const showUpdatePrompt = async () => {
        if (!registration || !registration.waiting || !navigator.serviceWorker.controller ||
            document.getElementById('eam-app-update-prompt')) return;
        let release = null;
        try {
          const response = await fetch(UPDATE_API, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json', 'apikey': UPDATE_KEY },
            body: JSON.stringify({ action: 'release_list', app_name: 'PROJECT FUL454' })
          });
          if (!response.ok) return;
          const data = await response.json();
          release = data && data.release;
        } catch (_) { return; }
        if (!release || deferredVersion === release.version) return;
        const box = document.createElement('aside');
        box.id = 'eam-app-update-prompt';
        box.style.cssText = 'position:fixed;right:16px;bottom:16px;z-index:2147483002;width:min(92vw,350px);box-sizing:border-box;background:#f0f8e8;color:#17372b;border:1px solid #b5d68a;border-radius:14px;padding:15px;box-shadow:0 12px 34px #0004;font:14px/1.45 system-ui';
        const heading = document.createElement('strong');
        heading.textContent = 'Update mpya inapatikana' + (release.version ? ' · ' + release.version : '');
        heading.style.cssText = 'display:block;font-size:15px;margin-bottom:5px';
        const title = document.createElement('div');
        title.textContent = release.title || 'Toleo jipya la mfumo limeandaliwa.';
        const notes = document.createElement('small');
        notes.textContent = release.release_notes || '';
        notes.style.cssText = 'display:block;margin-top:6px;white-space:pre-wrap';
        const actions = document.createElement('div');
        actions.style.cssText = 'display:flex;gap:8px;margin-top:12px';
        const update = document.createElement('button');
        update.type = 'button'; update.textContent = 'Update';
        update.style.cssText = 'border:0;border-radius:9px;padding:10px 14px;background:#176b50;color:white;font-weight:700';
        const later = document.createElement('button');
        later.type = 'button'; later.textContent = 'Baadaye';
        later.style.cssText = 'border:0;border-radius:9px;padding:10px 14px;background:#e4efdc;color:#17372b';
        actions.append(update, later);
        box.append(heading, title);
        if (notes.textContent) box.append(notes);
        box.append(actions);
        document.body.appendChild(box);
        later.addEventListener('click', () => {
          deferredVersion = release.version || 'current';
          box.remove();
        });
        update.addEventListener('click', () => {
          if (!registration || !registration.waiting) {
            box.remove();
            return;
          }
          if (!window.confirm('Unataka kusasisha FUL454 sasa? Hifadhi kwanza taarifa zozote ulizokuwa unaingiza.')) return;
          approvedUpdate = true;
          navigator.serviceWorker.addEventListener('controllerchange', () => {
            if (approvedUpdate) window.location.reload();
          }, { once: true });
          update.disabled = true;
          update.textContent = 'Inasasisha...';
          registration.waiting.postMessage({ type: 'SKIP_WAITING' });
        });
      };
      navigator.serviceWorker.register('/sw.js', { updateViaCache: 'none' }).then(async reg => {
        registration = reg;
        const checkForUpdates = () => registration.update().catch(() => {});
        checkForUpdates();
        await showUpdatePrompt();
        registration.addEventListener('updatefound', () => {
          const worker = registration.installing;
          if (!worker) return;
          worker.addEventListener('statechange', () => {
            if (worker.state === 'installed' && navigator.serviceWorker.controller) showUpdatePrompt();
          });
        });
        window.addEventListener('online', checkForUpdates);
        document.addEventListener('visibilitychange', () => {
          if (!document.hidden) {
            checkForUpdates();
            showUpdatePrompt();
          }
        });
      }).catch(error => console.warn(APP_NAME + ' service worker:', error));
    }
    if (window.matchMedia('(display-mode: standalone)').matches || navigator.standalone === true) return;
    document.querySelectorAll('.brand, .admin-brand').forEach(node => {
      if (node.querySelector('.pwa-brand-icon')) return;
      const img = document.createElement('img');
      img.className = 'pwa-brand-icon';
      img.src = '/icons/icon.svg';
      img.alt = '';
      img.setAttribute('aria-hidden', 'true');
      node.prepend(img);
    });
    if (document.getElementById('pwa-install-panel')) return;
    const style = document.createElement('style');
    style.textContent = `
      .pwa-brand-icon{width:30px;height:30px;object-fit:contain;vertical-align:middle;flex:0 0 auto;margin-right:8px}
      .pwa-install-panel{position:fixed;right:14px;bottom:14px;z-index:99999;width:min(310px,calc(100vw - 28px));padding:13px 14px;border:1px solid #dbe3ec;border-radius:16px;background:#fff;color:#172033;box-shadow:0 12px 40px #0002;font:14px/1.45 system-ui,-apple-system,Segoe UI,sans-serif}
      .pwa-install-logo{display:block;width:100%;height:44px;object-fit:contain;object-position:left center;margin:0 0 8px}\n      .pwa-install-head{display:flex;align-items:center;gap:10px;margin-bottom:9px}
      .pwa-install-head img{width:38px;height:38px;border-radius:10px;background:${BG};padding:3px}
      .pwa-install-title{font-weight:800;font-size:14px}
      .pwa-install-sub{font-size:12px;color:#64748b}
      .pwa-install-btn{width:100%;border:0;border-radius:10px;padding:11px 13px;background:${ACCENT};color:${BG};font:750 14px system-ui;cursor:pointer;min-height:44px}
      .pwa-install-help{display:none;margin:10px 2px 0;color:#475569;font-size:12px}
      .pwa-install-help.open{display:block}
      .pwa-install-close{position:absolute;right:9px;top:7px;border:0;background:transparent;color:#64748b;font-size:20px;cursor:pointer;padding:2px 6px}
      @media(max-width:480px){.pwa-install-panel{right:10px;bottom:10px}}
    `;
    document.head.appendChild(style);
    const panel = document.createElement('aside');
    panel.id = 'pwa-install-panel';
    panel.className = 'pwa-install-panel';
    panel.innerHTML = `
      <button type="button" class="pwa-install-close" aria-label="Close install panel">×</button>
      <img class="pwa-install-logo" src="/icons/logo.svg" alt="App logo"><div class="pwa-install-head"><img src="/icons/icon.svg" alt=""><div><div class="pwa-install-title">Install ${APP_NAME}</div><div class="pwa-install-sub">Sakinisha kwenye simu au kompyuta</div></div></div>
      <button type="button" class="pwa-install-btn" id="pwa-install-action">Install App · Sakinisha</button>
      <div class="pwa-install-help" id="pwa-install-help"></div>`;
    document.body.appendChild(panel);
    let installPrompt = null;
    const action = panel.querySelector('#pwa-install-action');
    const help = panel.querySelector('#pwa-install-help');
    window.addEventListener('beforeinstallprompt', event => {
      event.preventDefault();
      installPrompt = event;
      action.textContent = 'Install App · Sakinisha';
    });
    window.addEventListener('appinstalled', () => {
      panel.innerHTML = '<strong>' + APP_NAME + ' imewekwa kwenye kifaa chako.</strong>';
      setTimeout(() => panel.remove(), 3500);
    });
    action.addEventListener('click', async () => {
      if (installPrompt) {
        installPrompt.prompt();
        const result = await installPrompt.userChoice;
        installPrompt = null;
        if (result && result.outcome === 'accepted') action.textContent = 'Inasakinishwa…';
        return;
      }
      help.classList.toggle('open');
      help.textContent = /iPhone|iPad|iPod/i.test(navigator.userAgent)
        ? 'iPhone/iPad: fungua Share, kisha chagua Add to Home Screen.'
        : 'Chrome: gusa menyu ya nukta tatu (⋮), kisha chagua Install app au Add to Home screen. Kama chaguo halionekani, fungua tovuti kwa Chrome na uhakikishe mtandao upo.';
    });
    panel.querySelector('.pwa-install-close').addEventListener('click', () => panel.remove());
  };
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', boot, { once: true });
  else boot();
})();