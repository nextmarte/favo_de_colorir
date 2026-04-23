import { experimental_AstroContainer as AstroContainer } from 'astro/container';
import { describe, expect, it } from 'vitest';
import Button from '../../src/components/ui/Button.astro';

describe('Button', () => {
  it('renders the slot label inside an <a> when href is provided', async () => {
    const container = await AstroContainer.create();
    const result = await container.renderToString(Button, {
      props: { href: '#planos' },
      slots: { default: 'Quero conhecer' },
    });

    expect(result).toContain('Quero conhecer');
    expect(result).toMatch(/<a [^>]*href="#planos"/);
  });

  it('renders as <button> when no href is given', async () => {
    const container = await AstroContainer.create();
    const result = await container.renderToString(Button, {
      slots: { default: 'Enviar' },
    });

    expect(result).toMatch(/<button[\s>]/);
    expect(result).toContain('Enviar');
  });

  it('applies the secondary variant class when variant="secondary"', async () => {
    const container = await AstroContainer.create();
    const result = await container.renderToString(Button, {
      props: { variant: 'secondary', href: '/' },
      slots: { default: 'Saiba mais' },
    });

    expect(result).toMatch(/class="[^"]*\bbtn--secondary\b/);
  });

  it('defaults to primary variant', async () => {
    const container = await AstroContainer.create();
    const result = await container.renderToString(Button, {
      props: { href: '/' },
      slots: { default: 'OK' },
    });

    expect(result).toMatch(/class="[^"]*\bbtn--primary\b/);
  });
});
