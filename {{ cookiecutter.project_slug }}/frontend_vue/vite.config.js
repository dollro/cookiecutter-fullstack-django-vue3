import { fileURLToPath, URL } from 'node:url'
import { resolve } from 'node:path'
import { defineConfig, splitVendorChunkPlugin } from 'vite'
import vue from '@vitejs/plugin-vue'
import VueI18nPlugin from '@intlify/unplugin-vue-i18n/vite'
import tailwindcss from '@tailwindcss/vite'
//import svgLoader from 'vite-svg-loader'

function fixAssetName(assetInfo) {
  return assetInfo.name;
}


// https://vitejs.dev/config/
export default defineConfig({
  define: {
    __VUE_I18N_FULL_INSTALL__: true,
    __VUE_I18N_LEGACY_API__: false,
    __INTLIFY_DROP_MESSAGE_COMPILER__: false
  },
  build: {
    outDir: '../../backend_django/static/vue/',
    manifest: true,
    assetsDir: '',
    rollupOptions: {
      input: {
        main: resolve('./src/main.js'),
      },
      output: {
        assetFileNames: fixAssetName,
        chunkFileNames: undefined,
      },
    },
  },
  plugins: [
    vue(),
    VueI18nPlugin({
      include: resolve('./src/locales/**')
    }),
    splitVendorChunkPlugin(),
    //'@postcss',
    tailwindcss(),
    // svgLoader({
    //   defaultImport: 'component'
    // })
  ],
  envDir: resolve('.'),
  base: '/static/vue',
  root: resolve('./src'),
  server: {
    host: '0.0.0.0',
    port: 3000,
    strictPort: true,
    watch: {
      usePolling: true,
      disableGlobbing: false,
    },
    hmr: {
      host: 'localhost',
      port: 3000,
      protocol: 'ws',
    },
    cors: true,
    // proxy: {
    //   "/api": {
    //     target: "http://localhost:8000",
    //     changeOrigin: true,
    //     secure: false,
    //     //rewrite: (path) => path.replace(/^\/api/, ""),
    //   },
    // },
  },
  css: {
    preprocessorOptions: {
      scss: {
        api: 'modern-compiler',
        //silenceDeprecations: ['legacy-js-api', 'import', 'global-builtin', 'color-functions'],
      }
    },
  },
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url))
  }
  }
})
