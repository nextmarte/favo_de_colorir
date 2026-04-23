import { expect, test } from '@playwright/test';

test.describe('Home page', () => {
  test('loads the hero with H1 and CTAs', async ({ page }) => {
    await page.goto('/');

    const heading = page.getByRole('heading', { level: 1 });
    await expect(heading).toBeVisible();
    await expect(heading).toContainText('ateliê');

    await expect(page.getByRole('link', { name: /quero conhecer/i })).toBeVisible();
    await expect(page.getByRole('link', { name: /para alunas/i })).toBeVisible();
  });

  test('renders all five plan names', async ({ page }) => {
    await page.goto('/');

    const plansSection = page.locator('#planos');
    await plansSection.scrollIntoViewIfNeeded();

    for (const name of ['Mensal', 'Trimestral', 'Semestral', 'Avulsa', 'Oficina']) {
      await expect(plansSection.getByRole('heading', { level: 3, name })).toBeVisible();
    }
  });

  test('hero CTA jumps to the plans anchor', async ({ page }) => {
    await page.goto('/');

    await page.getByRole('link', { name: /quero conhecer/i }).first().click();
    await expect(page).toHaveURL(/#planos$/);
    await expect(page.locator('#planos')).toBeInViewport();
  });

  test('renders correctly at mobile viewport (375x812)', async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 812 });
    await page.goto('/');

    await expect(page.getByRole('heading', { level: 1 })).toBeVisible();

    // Footer must be reachable without horizontal overflow
    const footer = page.getByRole('contentinfo');
    await footer.scrollIntoViewIfNeeded();
    await expect(footer).toBeVisible();

    // Sanity: no horizontal scroll on the body
    const overflowX = await page.evaluate(() => document.documentElement.scrollWidth - document.documentElement.clientWidth);
    expect(overflowX).toBeLessThanOrEqual(1);
  });

  test('all major sections have anchor IDs', async ({ page }) => {
    await page.goto('/');
    for (const id of ['produto', 'planos', 'atelie', 'contato']) {
      await expect(page.locator(`#${id}`)).toBeVisible();
    }
  });
});
