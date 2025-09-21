// NutraSafe Service Worker - Meta-level Performance & Offline Support
const CACHE_NAME = 'nutrasafe-admin-v1';
const STATIC_CACHE = 'nutrasafe-static-v1';
const API_CACHE = 'nutrasafe-api-v1';

// Critical resources to cache immediately
const CRITICAL_RESOURCES = [
    '/admin-fast.html',
    '/favicon.ico'
];

// API endpoints to cache
const API_ENDPOINTS = [
    '/api/foods',
    '/api/users',
    '/api/analytics'
];

// Install - Cache critical resources immediately
self.addEventListener('install', (event) => {
    console.log('SW: Installing...');
    
    event.waitUntil(
        Promise.all([
            // Cache critical static resources
            caches.open(STATIC_CACHE).then((cache) => {
                return cache.addAll(CRITICAL_RESOURCES);
            }),
            
            // Skip waiting to activate immediately
            self.skipWaiting()
        ])
    );
});

// Activate - Clean up old caches
self.addEventListener('activate', (event) => {
    console.log('SW: Activating...');
    
    event.waitUntil(
        Promise.all([
            // Clean up old caches
            caches.keys().then((cacheNames) => {
                return Promise.all(
                    cacheNames
                        .filter((cacheName) => {
                            return cacheName.startsWith('nutrasafe-') && 
                                   cacheName !== CACHE_NAME && 
                                   cacheName !== STATIC_CACHE && 
                                   cacheName !== API_CACHE;
                        })
                        .map((cacheName) => caches.delete(cacheName))
                );
            }),
            
            // Take control of all clients immediately
            self.clients.claim()
        ])
    );
});

// Fetch - Smart caching strategy like Meta
self.addEventListener('fetch', (event) => {
    const { request } = event;
    const url = new URL(request.url);
    
    // Different strategies for different resource types
    if (url.pathname.startsWith('/api/')) {
        event.respondWith(handleApiRequest(request));
    } else if (url.pathname.endsWith('.html') || url.pathname === '/') {
        event.respondWith(handlePageRequest(request));
    } else if (isStaticResource(request)) {
        event.respondWith(handleStaticResource(request));
    } else {
        event.respondWith(fetch(request));
    }
});

// API Strategy: Network First with Fallback
async function handleApiRequest(request) {
    const cache = await caches.open(API_CACHE);
    
    try {
        // Try network first for fresh data
        const response = await fetch(request);
        
        if (response.ok) {
            // Cache successful responses
            cache.put(request, response.clone());
        }
        
        return response;
    } catch (error) {
        console.log('SW: Network failed, trying cache:', request.url);
        
        // Network failed, try cache
        const cachedResponse = await cache.match(request);
        if (cachedResponse) {
            return cachedResponse;
        }
        
        // No cache available, return offline response
        return new Response(
            JSON.stringify({ 
                error: 'Offline', 
                message: 'This data is not available offline',
                cached: false 
            }),
            { 
                status: 503,
                headers: { 'Content-Type': 'application/json' }
            }
        );
    }
}

// Page Strategy: Network First with Cache Fallback
async function handlePageRequest(request) {
    try {
        const response = await fetch(request);
        return response;
    } catch (error) {
        // Network failed, serve cached page
        const cache = await caches.open(STATIC_CACHE);
        const cachedResponse = await cache.match('/admin-fast.html');
        
        if (cachedResponse) {
            return cachedResponse;
        }
        
        // No cached page, return offline page
        return new Response(`
            <!DOCTYPE html>
            <html>
            <head>
                <title>NutraSafe Admin - Offline</title>
                <meta charset="UTF-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <style>
                    body {
                        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', system-ui, sans-serif;
                        background: #000;
                        color: #fff;
                        display: flex;
                        align-items: center;
                        justify-content: center;
                        height: 100vh;
                        margin: 0;
                        text-align: center;
                    }
                    .offline-container {
                        max-width: 400px;
                        padding: 40px;
                    }
                    .offline-icon {
                        font-size: 64px;
                        margin-bottom: 20px;
                    }
                    h1 {
                        color: #00ff88;
                        margin-bottom: 10px;
                    }
                    p {
                        color: #a0a6b8;
                        line-height: 1.5;
                    }
                    .retry-btn {
                        background: #00ff88;
                        color: black;
                        border: none;
                        padding: 12px 24px;
                        border-radius: 6px;
                        font-weight: 600;
                        cursor: pointer;
                        margin-top: 20px;
                    }
                </style>
            </head>
            <body>
                <div class="offline-container">
                    <div class="offline-icon">📡</div>
                    <h1>You're Offline</h1>
                    <p>NutraSafe Admin needs an internet connection to load. Please check your connection and try again.</p>
                    <button class="retry-btn" onclick="location.reload()">Retry</button>
                </div>
            </body>
            </html>
        `, {
            headers: { 'Content-Type': 'text/html' }
        });
    }
}

// Static Resources: Cache First Strategy
async function handleStaticResource(request) {
    const cache = await caches.open(STATIC_CACHE);
    const cachedResponse = await cache.match(request);
    
    if (cachedResponse) {
        return cachedResponse;
    }
    
    try {
        const response = await fetch(request);
        if (response.ok) {
            cache.put(request, response.clone());
        }
        return response;
    } catch (error) {
        return new Response('Resource not available offline', { status: 503 });
    }
}

// Helper: Check if request is for static resource
function isStaticResource(request) {
    const url = new URL(request.url);
    const pathname = url.pathname;
    
    return pathname.endsWith('.css') ||
           pathname.endsWith('.js') ||
           pathname.endsWith('.png') ||
           pathname.endsWith('.jpg') ||
           pathname.endsWith('.jpeg') ||
           pathname.endsWith('.gif') ||
           pathname.endsWith('.svg') ||
           pathname.endsWith('.ico') ||
           pathname.endsWith('.woff') ||
           pathname.endsWith('.woff2');
}

// Background Sync for offline actions
self.addEventListener('sync', (event) => {
    if (event.tag === 'background-sync') {
        event.waitUntil(doBackgroundSync());
    }
});

async function doBackgroundSync() {
    console.log('SW: Background sync triggered');
    
    // Get queued offline actions from IndexedDB
    const offlineActions = await getOfflineActions();
    
    for (const action of offlineActions) {
        try {
            await fetch(action.url, action.options);
            await removeOfflineAction(action.id);
            console.log('SW: Synced offline action:', action.type);
        } catch (error) {
            console.log('SW: Failed to sync action:', action.type, error);
        }
    }
}

// IndexedDB helpers for offline queue
async function getOfflineActions() {
    // Implementation would connect to IndexedDB
    // For now, return empty array
    return [];
}

async function removeOfflineAction(id) {
    // Implementation would remove from IndexedDB
    console.log('SW: Remove offline action:', id);
}

// Message handling for client communication
self.addEventListener('message', (event) => {
    const { type, payload } = event.data;
    
    switch (type) {
        case 'SKIP_WAITING':
            self.skipWaiting();
            break;
            
        case 'GET_VERSION':
            event.ports[0].postMessage({
                version: CACHE_NAME,
                timestamp: new Date().toISOString()
            });
            break;
            
        case 'CLEAR_CACHE':
            clearAllCaches().then(() => {
                event.ports[0].postMessage({ success: true });
            });
            break;
            
        default:
            console.log('SW: Unknown message type:', type);
    }
});

async function clearAllCaches() {
    const cacheNames = await caches.keys();
    return Promise.all(
        cacheNames.map(cacheName => caches.delete(cacheName))
    );
}

// Performance monitoring
self.addEventListener('fetch', (event) => {
    const start = performance.now();
    
    event.respondWith(
        handleRequest(event.request).then((response) => {
            const end = performance.now();
            const duration = end - start;
            
            // Log slow requests
            if (duration > 1000) {
                console.log(`SW: Slow request (${duration}ms):`, event.request.url);
            }
            
            return response;
        })
    );
});

async function handleRequest(request) {
    // Route to appropriate handler based on request type
    const url = new URL(request.url);
    
    if (url.pathname.startsWith('/api/')) {
        return handleApiRequest(request);
    } else if (url.pathname.endsWith('.html') || url.pathname === '/') {
        return handlePageRequest(request);
    } else if (isStaticResource(request)) {
        return handleStaticResource(request);
    }
    
    return fetch(request);
}