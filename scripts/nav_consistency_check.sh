#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${1:-http://127.0.0.1:4012}"

if ! command -v npx >/dev/null 2>&1; then
  echo "[fail] npx is required for nav consistency checks"
  exit 1
fi

node_script="$(mktemp)"
trap 'rm -f "${node_script}"' EXIT

playwright_bin="$(npx --yes -p playwright -c 'which playwright')"
playwright_node_modules="$(cd "$(dirname "${playwright_bin}")/.." && pwd)"

cat > "${node_script}" <<'NODE'
const { chromium } = require('playwright');

const baseUrl = process.argv[2];
const routes = ['/', '/news/', '/docs/', '/about/', '/archive/', '/tags/', '/search/', '/2023/c-for-beginner-hongongc/', '/docs/istio-in-action/'];

async function waitMobileOpen(page) {
  await page.waitForFunction(() => {
    const nav = document.querySelector('nav.gnb');
    const toggle = document.querySelector('[data-nav-toggle]');
    if (!nav || !toggle) return false;
    if (!nav.classList.contains('is-open')) return false;
    if (toggle.getAttribute('aria-expanded') !== 'true') return false;
    if (toggle.getAttribute('aria-label') !== 'Close navigation menu') return false;
    if (nav.getAttribute('aria-hidden') !== 'false') return false;
    const style = getComputedStyle(nav);
    return style.visibility === 'visible' && Number.parseFloat(style.opacity || '0') > 0.95;
  }, null, { timeout: 3000 });
}

async function waitMobileClosed(page) {
  await page.waitForFunction(() => {
    const nav = document.querySelector('nav.gnb');
    const toggle = document.querySelector('[data-nav-toggle]');
    if (!nav || !toggle) return false;
    if (nav.classList.contains('is-open')) return false;
    if (toggle.getAttribute('aria-expanded') !== 'false') return false;
    if (toggle.getAttribute('aria-label') !== 'Open navigation menu') return false;
    if (nav.getAttribute('aria-hidden') !== 'true') return false;
    const style = getComputedStyle(nav);
    return style.visibility === 'hidden' && Number.parseFloat(style.opacity || '0') < 0.05;
  }, null, { timeout: 3000 });
}

async function checkDesktop(page, route) {
  const desktop = await page.evaluate(() => {
    const px = (value) => {
      const parsed = Number.parseFloat(value || '0');
      return Number.isFinite(parsed) ? parsed : 0;
    };

    const nav = document.querySelector('nav.gnb');
    const headerInner = document.querySelector('.site-header__inner');
    const toggle = document.querySelector('[data-nav-toggle]');
    if (!nav) return { ok: false, reason: 'missing nav.gnb' };
    if (!headerInner) return { ok: false, reason: 'missing .site-header__inner' };
    if (!toggle) return { ok: false, reason: 'missing nav toggle' };

    const navStyle = getComputedStyle(nav);
    const toggleStyle = getComputedStyle(toggle);
    if (navStyle.display !== 'flex') return { ok: false, reason: `desktop nav display=${navStyle.display}` };
    if (navStyle.alignItems !== 'center') return { ok: false, reason: `desktop nav align-items=${navStyle.alignItems}` };
    if (toggleStyle.display !== 'none') return { ok: false, reason: `desktop toggle display=${toggleStyle.display}` };

    const headerHeight = px(getComputedStyle(headerInner).height);
    if (headerHeight < 74 || headerHeight > 78) {
      return { ok: false, reason: `desktop header height=${headerHeight}` };
    }

    const links = Array.from(nav.querySelectorAll('.gnb__link'));
    if (!links.length) return { ok: false, reason: 'missing .gnb__link' };

    const details = links.map((link) => {
      const style = getComputedStyle(link);
      return {
        display: style.display,
        alignItems: style.alignItems,
        height: px(style.height),
      };
    });

    const invalidLink = details.find((detail) => !['flex', 'inline-flex'].includes(detail.display) || detail.alignItems !== 'center');
    if (invalidLink) return { ok: false, reason: 'desktop link flex alignment mismatch' };

    const heights = details.map((detail) => detail.height);
    const minHeight = Math.min(...heights);
    const maxHeight = Math.max(...heights);
    if (maxHeight - minHeight > 1.1) {
      return { ok: false, reason: `desktop link height mismatch ${minHeight}-${maxHeight}` };
    }
    if (minHeight < 40 || maxHeight > 44) {
      return { ok: false, reason: `desktop link height out-of-range ${minHeight}-${maxHeight}` };
    }

    const activeCount = links.filter((link) => link.classList.contains('is-active')).length;
    const ariaCurrentCount = links.filter((link) => link.getAttribute('aria-current') === 'page').length;
    if (activeCount !== 1 || ariaCurrentCount !== 1) {
      return { ok: false, reason: `desktop active=${activeCount} aria-current=${ariaCurrentCount}` };
    }

    return {
      ok: true,
      linkCount: links.length,
      linkHeight: minHeight,
      headerHeight,
    };
  });

  if (!desktop.ok) {
    throw new Error(`${route} desktop ${desktop.reason}`);
  }

  const hoverTarget = await page.$('nav.gnb .gnb__link:not(.is-active)');
  if (!hoverTarget) {
    throw new Error(`${route} desktop missing non-active nav link for hover check`);
  }

  const before = await hoverTarget.evaluate((el) => {
    const style = getComputedStyle(el);
    return {
      color: style.color,
      backgroundColor: style.backgroundColor,
      transform: style.transform,
    };
  });

  await hoverTarget.hover();
  await page.waitForTimeout(120);

  const after = await hoverTarget.evaluate((el) => {
    const style = getComputedStyle(el);
    return {
      color: style.color,
      backgroundColor: style.backgroundColor,
      transform: style.transform,
    };
  });

  const changed = before.color !== after.color
    || before.backgroundColor !== after.backgroundColor
    || before.transform !== after.transform;
  if (!changed) {
    throw new Error(`${route} desktop hover style did not change`);
  }

  return desktop;
}

async function checkMobile(page, route) {
  const toggle = await page.$('[data-nav-toggle]');
  if (!toggle) {
    throw new Error(`${route} mobile missing nav toggle`);
  }

  // Open with toggle and validate open-state metrics.
  await toggle.click();
  await waitMobileOpen(page);

  const mobile = await page.evaluate(() => {
    const px = (value) => {
      const parsed = Number.parseFloat(value || '0');
      return Number.isFinite(parsed) ? parsed : 0;
    };

    const nav = document.querySelector('nav.gnb');
    const headerInner = document.querySelector('.site-header__inner');
    const toggle = document.querySelector('[data-nav-toggle]');

    if (!nav) return { ok: false, reason: 'missing nav.gnb' };
    if (!headerInner) return { ok: false, reason: 'missing .site-header__inner' };
    if (!toggle) return { ok: false, reason: 'missing nav toggle' };

    const toggleExpanded = toggle.getAttribute('aria-expanded');
    if (toggleExpanded !== 'true') return { ok: false, reason: `toggle aria-expanded=${toggleExpanded}` };

    if (!nav.classList.contains('is-open')) return { ok: false, reason: 'nav is-open class missing' };

    const navStyle = getComputedStyle(nav);
    const toggleStyle = getComputedStyle(toggle);
    if (navStyle.visibility !== 'visible') return { ok: false, reason: `mobile nav visibility=${navStyle.visibility}` };
    if (px(navStyle.opacity) < 0.95) return { ok: false, reason: `mobile nav opacity=${navStyle.opacity}` };
    if (nav.getAttribute('aria-hidden') !== 'false') return { ok: false, reason: `mobile nav aria-hidden=${nav.getAttribute('aria-hidden')}` };
    if (toggle.getAttribute('aria-label') !== 'Close navigation menu') return { ok: false, reason: `mobile toggle aria-label=${toggle.getAttribute('aria-label')}` };
    if (toggleStyle.display === 'none') return { ok: false, reason: 'mobile toggle hidden' };

    const headerHeight = px(getComputedStyle(headerInner).height);
    if (headerHeight < 68 || headerHeight > 72) {
      return { ok: false, reason: `mobile header height=${headerHeight}` };
    }

    const links = Array.from(nav.querySelectorAll('.gnb__link'));
    if (!links.length) return { ok: false, reason: 'missing .gnb__link' };

    const details = links.map((link) => {
      const style = getComputedStyle(link);
      return {
        height: px(style.height),
        width: px(style.width),
      };
    });
    const heights = details.map((detail) => detail.height);
    const minHeight = Math.min(...heights);
    const maxHeight = Math.max(...heights);
    if (maxHeight - minHeight > 1.1) {
      return { ok: false, reason: `mobile link height mismatch ${minHeight}-${maxHeight}` };
    }
    if (minHeight < 43 || maxHeight > 46) {
      return { ok: false, reason: `mobile link height out-of-range ${minHeight}-${maxHeight}` };
    }
    if (details.some((detail) => detail.width < 200)) {
      return { ok: false, reason: 'mobile link width too small' };
    }

    const activeCount = links.filter((link) => link.classList.contains('is-active')).length;
    const ariaCurrentCount = links.filter((link) => link.getAttribute('aria-current') === 'page').length;
    if (activeCount !== 1 || ariaCurrentCount !== 1) {
      return { ok: false, reason: `mobile active=${activeCount} aria-current=${ariaCurrentCount}` };
    }

    return {
      ok: true,
      linkCount: links.length,
      linkHeight: minHeight,
      headerHeight,
    };
  });

  if (!mobile.ok) {
    throw new Error(`${route} mobile ${mobile.reason}`);
  }

  // Close by toggle click.
  await toggle.click();
  await waitMobileClosed(page);

  // Open and close with Escape.
  await toggle.click();
  await waitMobileOpen(page);
  await page.keyboard.press('Escape');
  await waitMobileClosed(page);

  // Open and close by clicking outside nav/toggle.
  await toggle.click();
  await waitMobileOpen(page);
  await page.evaluate(() => {
    const event = new MouseEvent('click', {
      bubbles: true,
      cancelable: true,
      view: window,
    });
    document.body.dispatchEvent(event);
  });
  await waitMobileClosed(page);

  // Open and navigate via internal nav link; destination should load with closed menu state.
  const targetPath = route.startsWith('/docs/') || route === '/docs/' ? '/news/' : '/docs/';
  await toggle.click();
  await waitMobileOpen(page);
  const targetSelector = `nav.gnb .gnb__link[href="${targetPath}"]`;
  const targetLink = await page.$(targetSelector);
  if (!targetLink) {
    throw new Error(`${route} mobile missing navigation target link ${targetPath}`);
  }

  await Promise.all([
    page.waitForURL((url) => {
      var normalized = url.pathname.endsWith('/') ? url.pathname : `${url.pathname}/`;
      return normalized === targetPath;
    }, { timeout: 30000 }),
    targetLink.click(),
  ]);
  await page.waitForLoadState('domcontentloaded');

  const postNavigate = await page.evaluate(() => {
    const nav = document.querySelector('nav.gnb');
    const toggle = document.querySelector('[data-nav-toggle]');
    if (!nav || !toggle) return { ok: false, reason: 'missing nav/toggle after link navigation' };
    if (nav.classList.contains('is-open')) return { ok: false, reason: 'menu remained open after nav link click' };
    if (toggle.getAttribute('aria-expanded') !== 'false') return { ok: false, reason: `aria-expanded=${toggle.getAttribute('aria-expanded')}` };
    if (toggle.getAttribute('aria-label') !== 'Open navigation menu') return { ok: false, reason: `aria-label=${toggle.getAttribute('aria-label')}` };
    if (nav.getAttribute('aria-hidden') !== 'true') return { ok: false, reason: `aria-hidden=${nav.getAttribute('aria-hidden')}` };

    const links = Array.from(nav.querySelectorAll('.gnb__link'));
    const activeCount = links.filter((link) => link.classList.contains('is-active')).length;
    const ariaCurrentCount = links.filter((link) => link.getAttribute('aria-current') === 'page').length;
    if (activeCount !== 1 || ariaCurrentCount !== 1) {
      return { ok: false, reason: `post-nav active=${activeCount} aria-current=${ariaCurrentCount}` };
    }
    return { ok: true };
  });
  if (!postNavigate.ok) {
    throw new Error(`${route} mobile ${postNavigate.reason}`);
  }

  return mobile;
}

(async () => {
  const browser = await chromium.launch({ headless: true });
  let checks = 0;

  try {
    for (const route of routes) {
      const desktopContext = await browser.newContext({ viewport: { width: 1366, height: 900 } });
      const desktopPage = await desktopContext.newPage();
      await desktopPage.goto(`${baseUrl}${route}`, { waitUntil: 'domcontentloaded', timeout: 30000 });
      await desktopPage.waitForTimeout(120);
      const desktop = await checkDesktop(desktopPage, route);
      checks += 1;
      console.log(`[ok] ${route} desktop nav consistency (links=${desktop.linkCount}, link-h=${desktop.linkHeight.toFixed(1)}, header-h=${desktop.headerHeight.toFixed(1)})`);
      await desktopContext.close();

      const mobileContext = await browser.newContext({ viewport: { width: 390, height: 844 } });
      const mobilePage = await mobileContext.newPage();
      await mobilePage.goto(`${baseUrl}${route}`, { waitUntil: 'domcontentloaded', timeout: 30000 });
      await mobilePage.waitForTimeout(120);
      const mobile = await checkMobile(mobilePage, route);
      checks += 1;
      console.log(`[ok] ${route} mobile nav consistency (links=${mobile.linkCount}, link-h=${mobile.linkHeight.toFixed(1)}, header-h=${mobile.headerHeight.toFixed(1)})`);
      await mobileContext.close();
    }
  } catch (error) {
    console.error(`[fail] nav consistency: ${error.message}`);
    process.exitCode = 1;
    return;
  } finally {
    await browser.close();
  }

  console.log(`[pass] nav consistency check: ${checks} assertions`);
})();
NODE

echo "[nav] base url: ${BASE_URL}"
NODE_PATH="${playwright_node_modules}" node "${node_script}" "${BASE_URL}"
