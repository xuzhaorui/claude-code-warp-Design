import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'
import basicSsl from '@vitejs/plugin-basic-ssl'
import { createProxyMiddleware } from 'http-proxy-middleware'

let dynamicTarget = process.env.API_TARGET || 'http://175.178.165.153:8082'

const dynamicProxyPlugin = {
  name: 'dynamic-proxy',
  configureServer(server) {
    // Control endpoint: POST to update target, GET to read current target
    server.middlewares.use('/__proxy-target', (req, res) => {
      res.setHeader('Access-Control-Allow-Origin', '*')
      if (req.method === 'POST') {
        let body = ''
        req.on('data', chunk => (body += chunk))
        req.on('end', () => {
          try {
            const { target } = JSON.parse(body)
            if (target) dynamicTarget = target
            res.writeHead(200, { 'Content-Type': 'application/json' })
            res.end(JSON.stringify({ ok: true, target: dynamicTarget }))
          } catch {
            res.writeHead(400).end()
          }
        })
      } else {
        res.writeHead(200, { 'Content-Type': 'application/json' })
        res.end(JSON.stringify({ target: dynamicTarget }))
      }
    })

    // Dynamic proxy: router() is called per-request so always uses latest target
    server.middlewares.use(
      '/store',
      createProxyMiddleware({
        changeOrigin: true,
        secure: false,
        router: () => dynamicTarget,
      })
    )
  },
}

export default defineConfig({
  // Relative base so the built index.html loads ./assets/... when bundled as a
  // Flutter WebView asset (migration spec §8). Absolute /assets/ would 404 there.
  base: './',
  plugins: [
    basicSsl(),
    react(),
    tailwindcss(),
    dynamicProxyPlugin,
  ],
  server: {
    host: '0.0.0.0',
    port: 5173,
  },
  build: {
    // Target the bundled app at the Android WebView engine. The MI 8 test device
    // runs Chrome 83; Vite's default (chrome87) keeps logical-assignment (||=,
    // ??=, &&= = ES2021/Chrome 85+) which Chrome 83 can't parse → white-screen
    // SyntaxError. es2020 transpiles those while keeping Chrome 80+ features.
    target: 'es2020',
    outDir: 'wms-app',
    emptyOutDir: true,
  },
})
