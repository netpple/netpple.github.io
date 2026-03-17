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
const routes = [
  { path: '/', expectedActive: '/' },
  { path: '/news/', expectedActive: '/news/' },
  { path: '/docs/', expectedActive: '/docs/' },
  { path: '/about/', expectedActive: '/about/' },
  { path: '/archive/', expectedActive: '/news/' },
  { path: '/tags/', expectedActive: '/news/' },
  { path: '/search/', expectedActive: '/news/' },
  { path: '/2023/c-for-beginner-hongongc/', expectedActive: '/news/' },
  { path: '/2021/how-uid-gid-work-in-container/', expectedActive: '/news/' },
  { path: '/docs/istio-in-action/', expectedActive: '/docs/' },
  { path: '/docs/istio-in-action/Istio-ch11-performance', expectedActive: '/docs/' },
  { path: '/docs/querypie-handson/multiple-kubernetes-with-querypie-kac', expectedActive: '/docs/' },
];

const desktopViewports = [
  { name: 'desktop-min', width: 961, height: 800 },
  { name: 'desktop', width: 1366, height: 900 },
  { name: 'tablet', width: 1024, height: 768 },
];
const mobileViewports = [
  { name: 'mobile-break', width: 960, height: 800 },
  { name: 'tablet-min', width: 761, height: 900 },
  { name: 'mobile-max', width: 760, height: 900 },
  { name: 'mobile', width: 390, height: 844 },
];

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

async function checkDesktop(page, route, expectedActive, viewportName) {
  const desktop = await page.evaluate((expected) => {
    const normalizePath = (value) => {
      const pathname = value.endsWith('/') ? value : `${value}/`;
      return pathname;
    };

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
    if (toggle.getAttribute('aria-controls') !== 'site-navigation') return { ok: false, reason: `desktop toggle aria-controls=${toggle.getAttribute('aria-controls')}` };
    if (nav.getAttribute('id') !== 'site-navigation') return { ok: false, reason: `desktop nav id=${nav.getAttribute('id')}` };

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
    const activeLink = links.find((link) => link.classList.contains('is-active'));
    if (!activeLink) return { ok: false, reason: 'desktop active link missing' };
    const activeHref = new URL(activeLink.getAttribute('href'), window.location.origin).pathname;
    const normalizedActive = normalizePath(activeHref);
    if (normalizedActive !== expected) {
      return { ok: false, reason: `desktop active href=${normalizedActive} expected=${expected}` };
    }

    const blankTargetLinks = Array.from(document.querySelectorAll('a[target="_blank"]'));
    const invalidBlankTargetLinks = blankTargetLinks
      .filter((link) => {
        const relTokens = (link.getAttribute('rel') || '').toLowerCase().split(/\s+/).filter(Boolean);
        return !relTokens.includes('noreferrer') || !relTokens.includes('noopener');
      })
      .slice(0, 5)
      .map((link) => link.getAttribute('href') || '(missing href)');

    return {
      ok: true,
      linkCount: links.length,
      linkHeight: minHeight,
      headerHeight,
      blankTargetCount: blankTargetLinks.length,
      invalidBlankTargetLinks,
    };
  }, expectedActive);

  if (!desktop.ok) {
    throw new Error(`${route} ${viewportName} ${desktop.reason}`);
  }
  if (desktop.invalidBlankTargetLinks.length) {
    throw new Error(
      `${route} ${viewportName} target=_blank links missing rel safety: ${desktop.invalidBlankTargetLinks.join(', ')}`
    );
  }

  const hoverTarget = await page.$('nav.gnb .gnb__link:not(.is-active)');
  if (!hoverTarget) {
    throw new Error(`${route} ${viewportName} missing non-active nav link for hover check`);
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
    throw new Error(`${route} ${viewportName} hover style did not change`);
  }

  return desktop;
}

async function checkMobile(page, route, expectedActive, mobileViewport) {
  const mobileLabel = mobileViewport.name;
  const mobileWidth = mobileViewport.width;
  const mobileHeight = mobileViewport.height;
  const toggle = await page.$('[data-nav-toggle]');
  if (!toggle) {
    throw new Error(`${route} ${mobileLabel} missing nav toggle`);
  }
  await waitMobileClosed(page);

  // Open/close by keyboard (Enter/Space) for toggle accessibility.
  await toggle.focus();
  await page.keyboard.press('Enter');
  await waitMobileOpen(page);
  await page.keyboard.press('Space');
  await waitMobileClosed(page);

  // Open with toggle and validate open-state metrics.
  await toggle.click();
  await waitMobileOpen(page);

  const mobile = await page.evaluate((expected) => {
    const normalizePath = (value) => {
      const pathname = value.endsWith('/') ? value : `${value}/`;
      return pathname;
    };

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
    if (toggle.getAttribute('aria-controls') !== 'site-navigation') return { ok: false, reason: `mobile toggle aria-controls=${toggle.getAttribute('aria-controls')}` };
    if (nav.getAttribute('id') !== 'site-navigation') return { ok: false, reason: `mobile nav id=${nav.getAttribute('id')}` };

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
    const activeLink = links.find((link) => link.classList.contains('is-active'));
    if (!activeLink) return { ok: false, reason: 'mobile active link missing' };
    const activeHref = new URL(activeLink.getAttribute('href'), window.location.origin).pathname;
    const normalizedActive = normalizePath(activeHref);
    if (normalizedActive !== expected) {
      return { ok: false, reason: `mobile active href=${normalizedActive} expected=${expected}` };
    }

    return {
      ok: true,
      linkCount: links.length,
      linkHeight: minHeight,
      headerHeight,
    };
  }, expectedActive);

  if (!mobile.ok) {
    throw new Error(`${route} ${mobileLabel} ${mobile.reason}`);
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

  // Open in mobile, then resize to desktop should force-close and reset desktop a11y state.
  await toggle.click();
  await waitMobileOpen(page);
  const desktopViewport = desktopViewports[0];
  await page.setViewportSize({ width: desktopViewport.width, height: desktopViewport.height });
  await page.waitForFunction(() => {
    const nav = document.querySelector('nav.gnb');
    const toggle = document.querySelector('[data-nav-toggle]');
    if (!nav || !toggle) return false;
    if (nav.classList.contains('is-open')) return false;
    if (toggle.getAttribute('aria-expanded') !== 'false') return false;
    if (toggle.getAttribute('aria-label') !== 'Open navigation menu') return false;
    if (nav.getAttribute('aria-hidden') !== 'false') return false;
    if (getComputedStyle(toggle).display !== 'none') return false;
    return getComputedStyle(nav).display === 'flex';
  }, null, { timeout: 3000 });

  // Resize back to mobile should keep menu closed and hidden.
  await page.setViewportSize({ width: mobileWidth, height: mobileHeight });
  await waitMobileClosed(page);

  // Open and navigate via internal nav link; destination should load with closed menu state.
  const targetPath = route.startsWith('/docs/') || route === '/docs/' ? '/news/' : '/docs/';
  await toggle.click();
  await waitMobileOpen(page);
  const targetSelector = `nav.gnb .gnb__link[href="${targetPath}"]`;
  const targetLink = await page.$(targetSelector);
  if (!targetLink) {
    throw new Error(`${route} ${mobileLabel} missing navigation target link ${targetPath}`);
  }

  await Promise.all([
    page.waitForURL((url) => {
      var normalized = url.pathname.endsWith('/') ? url.pathname : `${url.pathname}/`;
      return normalized === targetPath;
    }, { timeout: 30000 }),
    targetLink.click(),
  ]);
  await page.waitForLoadState('domcontentloaded');

  const postNavigate = await page.evaluate((expectedPath) => {
    const normalizePath = (value) => {
      const pathname = value.endsWith('/') ? value : `${value}/`;
      return pathname;
    };

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
    const activeLink = links.find((link) => link.classList.contains('is-active'));
    if (!activeLink) return { ok: false, reason: 'post-nav active link missing' };
    const activeHref = new URL(activeLink.getAttribute('href'), window.location.origin).pathname;
    const normalizedActive = normalizePath(activeHref);
    if (normalizedActive !== expectedPath) {
      return { ok: false, reason: `post-nav active href=${normalizedActive} expected=${expectedPath}` };
    }
    return { ok: true };
  }, targetPath);
  if (!postNavigate.ok) {
    throw new Error(`${route} ${mobileLabel} ${postNavigate.reason}`);
  }

  return mobile;
}

(async () => {
  const browser = await chromium.launch({ headless: true });
  let checks = 0;

  try {
    for (const routeConfig of routes) {
      const route = routeConfig.path;
      const expectedActive = routeConfig.expectedActive;
      for (const desktopViewport of desktopViewports) {
        const desktopContext = await browser.newContext({
          viewport: { width: desktopViewport.width, height: desktopViewport.height },
        });
        const desktopPage = await desktopContext.newPage();
        await desktopPage.goto(`${baseUrl}${route}`, { waitUntil: 'domcontentloaded', timeout: 30000 });
        await desktopPage.waitForTimeout(120);
        const desktop = await checkDesktop(desktopPage, route, expectedActive, desktopViewport.name);
        checks += 1;
        console.log(`[ok] ${route} ${desktopViewport.name} nav consistency (active=${expectedActive}, links=${desktop.linkCount}, link-h=${desktop.linkHeight.toFixed(1)}, header-h=${desktop.headerHeight.toFixed(1)}, blank-target=${desktop.blankTargetCount})`);
        await desktopContext.close();
      }

      for (const mobileViewport of mobileViewports) {
        const mobileContext = await browser.newContext({
          viewport: { width: mobileViewport.width, height: mobileViewport.height },
        });
        const mobilePage = await mobileContext.newPage();
        await mobilePage.goto(`${baseUrl}${route}`, { waitUntil: 'domcontentloaded', timeout: 30000 });
        await mobilePage.waitForTimeout(120);
        const mobile = await checkMobile(mobilePage, route, expectedActive, mobileViewport);
        checks += 1;
        console.log(`[ok] ${route} ${mobileViewport.name} nav consistency (active=${expectedActive}, links=${mobile.linkCount}, link-h=${mobile.linkHeight.toFixed(1)}, header-h=${mobile.headerHeight.toFixed(1)})`);
        await mobileContext.close();
      }
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
