// @ts-check
import { defineConfig } from 'astro/config';

export default defineConfig({
  output: 'static',
  site: 'https://favodecolorir.com.br',
  trailingSlash: 'never',
  build: {
    inlineStylesheets: 'auto',
  },
});
