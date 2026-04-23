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
});
