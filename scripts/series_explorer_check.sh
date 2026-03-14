#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${1:-http://127.0.0.1:4012}"

if ! command -v npx >/dev/null 2>&1; then
  echo "[fail] npx is required for Series Explorer checks"
  exit 1
fi

node_script="$(mktemp)"
trap 'rm -f "${node_script}"' EXIT

playwright_bin="$(npx --yes -p playwright -c 'which playwright')"
playwright_node_modules="$(cd "$(dirname "${playwright_bin}")/.." && pwd)"

cat > "${node_script}" <<'NODE'
const { chromium } = require('playwright');

const baseUrl = process.argv[2];

function compareText(left, right) {
  return left.localeCompare(right, 'ko', { sensitivity: 'base', numeric: true });
}

function sortItems(items, sortValue) {
  return [...items].sort((leftItem, rightItem) => {
    if (sortValue === 'title') {
      return compareText(leftItem.title, rightItem.title) || rightItem.date - leftItem.date;
    }

    if (sortValue === 'series') {
      return (
        compareText(leftItem.series, rightItem.series)
        || rightItem.date - leftItem.date
        || compareText(leftItem.title, rightItem.title)
      );
    }

    return (
      rightItem.date - leftItem.date
      || compareText(leftItem.series, rightItem.series)
      || compareText(leftItem.title, rightItem.title)
    );
  });
}

function assert(condition, message) {
  if (!condition) {
    throw new Error(message);
  }
}

async function readExplorerState(page) {
  return page.evaluate(() => {
    const items = Array.from(document.querySelectorAll('[data-series-explorer-item]')).map((item) => ({
      title: item.getAttribute('data-series-entry-title') || '',
      series: item.getAttribute('data-series-entry-series') || '',
      date: Number.parseInt(item.getAttribute('data-series-entry-date') || '0', 10),
      hidden: item.hidden,
    }));

    const visibleItems = items.filter((item) => !item.hidden);
    const status = document.querySelector('[data-series-explorer-status]')?.textContent?.trim() || '';
    const emptyHidden = document.querySelector('[data-series-explorer-empty]')?.hidden ?? true;
    const activePreset = document.querySelector('[data-series-explorer-preset][aria-pressed="true"]')?.textContent?.trim() || '';

    return {
      totalCount: items.length,
      visibleItems,
      status,
      emptyHidden,
      activePreset,
    };
  });
}

async function expectSorted(page, sortValue) {
  const state = await readExplorerState(page);
  const expected = sortItems(state.visibleItems, sortValue);
  assert(
    JSON.stringify(state.visibleItems) === JSON.stringify(expected),
    `Series Explorer order does not match ${sortValue} sort`
  );
  return state;
}

(async () => {
  const browser = await chromium.launch({ headless: true });

  try {
    const context = await browser.newContext({ viewport: { width: 1366, height: 900 } });
    const page = await context.newPage();

    const response = await page.goto(`${baseUrl}/docs/`, {
      waitUntil: 'domcontentloaded',
      timeout: 30000,
    });

    if (!response || !response.ok()) {
      throw new Error(`navigation failed with status ${response ? response.status() : 'no-response'}`);
    }

    await page.waitForSelector('[data-series-explorer-list]');
    await page.waitForTimeout(150);

    let state = await readExplorerState(page);
    assert(state.totalCount >= 20, `expected at least 20 Series Explorer items but got ${state.totalCount}`);
    assert(
      state.visibleItems.length === state.totalCount,
      `expected all Series Explorer items to be visible initially but got ${state.visibleItems.length}/${state.totalCount}`
    );
    await expectSorted(page, 'latest');
    console.log(`[ok] initial explorer state -> ${state.visibleItems.length} visible items`);

    await page.click('[data-series-explorer-preset="데이터 중심 애플리케이션 설계"]');
    await page.waitForTimeout(150);
    state = await readExplorerState(page);
    assert(state.visibleItems.length === 5, `expected data preset to show 5 items but got ${state.visibleItems.length}`);
    assert(
      state.visibleItems.every((item) => item.series.includes('데이터중심 애플리케이션')),
      'expected data preset to keep only the data-intensive application design series items'
    );
    assert(state.activePreset.includes('데이터 중심 애플리케이션 설계'), 'expected data preset button to be active');
    assert(
      (await page.inputValue('[data-series-explorer-filter]')) === '데이터 중심 애플리케이션 설계',
      'expected data preset to sync the friendly filter input value'
    );
    console.log('[ok] data preset filter');

    await page.click('[data-series-explorer-preset="쿼리파이 핸즈온"]');
    await page.waitForTimeout(150);
    state = await readExplorerState(page);
    assert(state.visibleItems.length === 1, `expected QueryPie preset to show exactly 1 item but got ${state.visibleItems.length}`);
    assert(
      state.visibleItems.every((item) => item.series.includes('쿼리파이')),
      'expected QueryPie preset to keep only QueryPie series items'
    );
    assert(state.activePreset.includes('쿼리파이 핸즈온'), 'expected QueryPie preset button to be active');
    assert(
      (await page.inputValue('[data-series-explorer-filter]')) === '쿼리파이 핸즈온',
      'expected QueryPie preset to sync the filter input value'
    );
    console.log('[ok] QueryPie preset filter');

    await page.click('[data-series-explorer-preset=""]');
    await page.waitForTimeout(150);
    state = await expectSorted(page, 'latest');
    assert(state.visibleItems.length === state.totalCount, 'expected All preset to restore the full Series Explorer list');
    console.log('[ok] all preset reset');

    await page.fill('[data-series-explorer-filter]', '쿼리파이');
    await page.waitForTimeout(150);
    state = await readExplorerState(page);
    assert(state.visibleItems.length > 0, 'expected query filter to keep at least one visible item');
    assert(state.visibleItems.length < state.totalCount, 'expected query filter to narrow the explorer list');
    assert(
      state.visibleItems.every((item) => item.series.includes('쿼리파이')),
      'expected filtered explorer items to belong to the QueryPie series'
    );
    assert(state.status.includes('쿼리파이'), 'expected explorer status text to include the active filter');
    console.log(`[ok] filter query -> ${state.visibleItems.length} QueryPie items`);

    await page.selectOption('[data-series-explorer-sort]', 'title');
    await page.waitForTimeout(150);
    await expectSorted(page, 'title');
    console.log('[ok] title sort order');

    await page.fill('[data-series-explorer-filter]', '');
    await page.selectOption('[data-series-explorer-sort]', 'series');
    await page.waitForTimeout(150);
    state = await expectSorted(page, 'series');
    assert(
      state.visibleItems.length === state.totalCount,
      `expected clearing filter to restore all explorer items but got ${state.visibleItems.length}/${state.totalCount}`
    );
    console.log('[ok] series sort order');

    await page.fill('[data-series-explorer-filter]', 'zzzz-no-match-series-explorer');
    await page.waitForTimeout(150);
    state = await readExplorerState(page);
    assert(state.visibleItems.length === 0, `expected no visible items for empty-state query but got ${state.visibleItems.length}`);
    assert(state.emptyHidden === false, 'expected empty-state panel to be visible for no-match query');
    console.log('[ok] empty-state query');

    await context.close();
    console.log('[pass] series explorer interaction check');
  } finally {
    await browser.close();
  }
})().catch((error) => {
  console.error(`[fail] ${error.message}`);
  process.exit(1);
});
NODE

echo "[series-explorer] base url: ${BASE_URL}"
NODE_PATH="${playwright_node_modules}" node "${node_script}" "${BASE_URL}"
