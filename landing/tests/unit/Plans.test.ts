import { experimental_AstroContainer as AstroContainer } from 'astro/container';
import { describe, expect, it } from 'vitest';
import Plans from '../../src/components/Plans.astro';

const EXPECTED_PLANS = ['Mensal', 'Trimestral', 'Semestral', 'Avulsa', 'Oficina'];

describe('Plans section', () => {
  it('renders all five plan names', async () => {
    const container = await AstroContainer.create();
    const html = await container.renderToString(Plans);

    for (const name of EXPECTED_PLANS) {
      expect(html).toContain(name);
    }
  });

  it('exposes a #planos anchor target', async () => {
    const container = await AstroContainer.create();
    const html = await container.renderToString(Plans);

    expect(html).toMatch(/id="planos"/);
  });

  it('shows "Sob consulta" placeholder pricing for every plan', async () => {
    const container = await AstroContainer.create();
    const html = await container.renderToString(Plans);

    const matches = html.match(/Sob consulta/g) ?? [];
    expect(matches.length).toBeGreaterThanOrEqual(EXPECTED_PLANS.length);
  });
});
