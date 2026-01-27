import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import path from 'path'

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react()],
  base: '/admin-v2/',
  build: {
    outDir: 'dist',
    sourcemap: true,
  },
  server: {
    port: 5173,
    open: false,
    watch: {
      // Ignore the built production files to prevent reload loops
      ignored: [
        '**/dist/**',
        '**/assets/**'
      ]
    }
  },
  // Use index.src.html as the entry point
  root: process.cwd(),
  publicDir: 'public',
})
