import { experimental_AstroContainer as AstroContainer } from 'astro/container';
import { describe, expect, it } from 'vitest';
import Hero from '../../src/components/Hero.astro';

describe('Hero section', () => {
  it('renders an <h1> with the headline copy', async () => {
    const container = await AstroContainer.create();
    const html = await container.renderToString(Hero);

    expect(html).toMatch(/<h1[\s>][\s\S]*ateliê[\s\S]*<\/h1>/i);
  });

  it('renders the primary CTA pointing to #planos', async () => {
    const container = await AstroContainer.create();
    const html = await container.renderToString(Hero);

    expect(html).toMatch(/href="#planos"/);
    expect(html).toContain('Quero conhecer');
  });

  it('renders a secondary CTA for students', async () => {
    const container = await AstroContainer.create();
    const html = await container.renderToString(Hero);

    expect(html).toMatch(/href="#alunas"/);
    expect(html).toContain('Para alunas');
  });

  it('shows the studio location eyebrow', async () => {
    const container = await AstroContainer.create();
    const html = await container.renderToString(Hero);

    expect(html).toMatch(/Tijuca/i);
  });

  it('speaks to prospective students, not atelier owners', async () => {
    const container = await AstroContainer.create();
    const html = await container.renderToString(Hero);

    // The page must NOT pitch the app to atelier owners ("your studio", "your students")
    expect(html).not.toMatch(/seu ateliê/i);
    expect(html).not.toMatch(/suas alunas/i);
    // And must NOT default-feminize the audience
    expect(html).not.toMatch(/celular das alunas/i);
  });

  it('shows the founding year in the hero stats', async () => {
    const container = await AstroContainer.create();
    const html = await container.renderToString(Hero);

    expect(html).toContain('2018');
  });
});
