/**
 * Scraper Panel Component
 * Allows scraping nutrition data from UK supermarket websites
 */

import React, { useState, useCallback, useEffect, useRef, useMemo } from 'react';

// Types
interface UKNutrition {
  energyKj?: number;
  energyKcal?: number;
  fat?: number;
  saturates?: number;
  carbohydrate?: number;
  sugars?: number;
  fibre?: number;
  protein?: number;
  salt?: number;
}

interface ExtractedProduct {
  name?: string;
  brand?: string;
  barcode?: string;
  description?: string;
  nutrition: UKNutrition;
  ingredients?: string;
  allergens?: string[];
  servingSize?: string;
  imageUrl?: string;
}

interface DetectedField {
  field: string;
  value: string | number;
  selector?: string;
  rawText?: string;
}

interface ExtractionResult {
  success: boolean;
  data?: ExtractedProduct;
  extractionMethod: string;
  confidence: number;
  warnings: string[];
  sourceUrl: string;
  error?: string;
  detectedFields?: DetectedField[];
  debugInfo?: {
    tiersAttempted?: string[];
    htmlLength?: number;
    tablesFound?: number;
    nutritionTableFound?: boolean;
  };
}

// Available Algolia indices for saving foods
const SAVE_INDICES = [
  { value: 'verified_foods', label: 'Verified Foods (Main)', description: 'Primary curated database' },
  { value: 'manual_foods', label: 'Manual Foods', description: 'Manually added foods' },
  { value: 'ai_manually_added', label: 'AI Manually Added', description: 'AI-assisted additions' },
  { value: 'uk_foods_cleaned', label: 'UK Foods Cleaned', description: 'Cleaned UK foods' },
  { value: 'tesco_products', label: 'Tesco Products', description: 'Tesco product database' },
  { value: 'user_added', label: 'User Added', description: 'User-submitted foods' },
] as const;

type SaveIndexName = typeof SAVE_INDICES[number]['value'];

interface ScraperPanelProps {
  isOpen: boolean;
  onClose: () => void;
  foodName: string;
  barcode?: string;
  currentIndex?: string; // The index the food is currently in (if editing)
  onApplyData: (data: {
    name?: string;
    brandName?: string;
    barcode?: string;
    ingredients?: string;
    imageUrl?: string;
    calories?: string;
    protein?: string;
    carbs?: string;
    fat?: string;
    saturatedFat?: string;
    fiber?: string;
    sugar?: string;
    salt?: string;
    servingSize?: string;
    targetIndex?: string; // Index to save to
  }) => void;
}

// UK Supermarket search URLs
const UK_SUPERMARKETS = [
  {
    name: 'Tesco',
    icon: '🔵',
    searchUrl: (query: string) => `https://www.tesco.com/groceries/en-GB/search?query=${encodeURIComponent(query)}`,
    color: 'bg-blue-500',
  },
  {
    name: 'Sainsbury\'s',
    icon: '🟠',
    searchUrl: (query: string) => `https://www.sainsburys.co.uk/gol-ui/SearchResults/${encodeURIComponent(query)}`,
    color: 'bg-orange-500',
  },
  {
    name: 'ASDA',
    icon: '🟢',
    searchUrl: (query: string) => `https://groceries.asda.com/search/${encodeURIComponent(query)}`,
    color: 'bg-green-500',
  },
  {
    name: 'Morrisons',
    icon: '🟡',
    searchUrl: (query: string) => `https://groceries.morrisons.com/search?q=${encodeURIComponent(query)}`,
    color: 'bg-yellow-500',
  },
  {
    name: 'Waitrose',
    icon: '🟤',
    searchUrl: (query: string) => `https://www.waitrose.com/ecom/shop/search?searchTerm=${encodeURIComponent(query)}`,
    color: 'bg-stone-500',
  },
  {
    name: 'Ocado',
    icon: '🟣',
    searchUrl: (query: string) => `https://www.ocado.com/search?entry=${encodeURIComponent(query)}`,
    color: 'bg-purple-500',
  },
];

const API_BASE = 'https://us-central1-nutrasafe-705c7.cloudfunctions.net';

// Nutrition fields that can be selected in visual picker
const NUTRITION_FIELDS = [
  { key: 'name', label: 'Product Name', unit: '', color: 'bg-gray-700', pattern: null },
  { key: 'imageUrl', label: 'Image', unit: '', color: 'bg-cyan-500', pattern: null, isImage: true },
  { key: 'calories', label: 'Calories', unit: 'kcal', color: 'bg-red-500', pattern: /(\d+(?:\.\d+)?)\s*kcal/i },
  { key: 'protein', label: 'Protein', unit: 'g', color: 'bg-blue-500', pattern: /protein[:\s]*(\d+(?:\.\d+)?)\s*g/i },
  { key: 'carbs', label: 'Carbs', unit: 'g', color: 'bg-yellow-500', pattern: /carbohydrate[s]?[:\s]*(\d+(?:\.\d+)?)\s*g/i },
  { key: 'fat', label: 'Fat', unit: 'g', color: 'bg-orange-500', pattern: /(?<!saturated\s)fat[:\s]*(\d+(?:\.\d+)?)\s*g/i },
  { key: 'saturatedFat', label: 'Saturated Fat', unit: 'g', color: 'bg-orange-600', pattern: /saturate[ds]?[:\s]*(\d+(?:\.\d+)?)\s*g/i },
  { key: 'sugar', label: 'Sugar', unit: 'g', color: 'bg-pink-500', pattern: /sugar[s]?[:\s]*(\d+(?:\.\d+)?)\s*g/i },
  { key: 'fiber', label: 'Fiber', unit: 'g', color: 'bg-green-500', pattern: /fibre[:\s]*(\d+(?:\.\d+)?)\s*g/i },
  { key: 'salt', label: 'Salt', unit: 'g', color: 'bg-purple-500', pattern: /salt[:\s]*(\d+(?:\.\d+)?)\s*g/i },
  { key: 'servingSize', label: 'Serving Size', unit: '', color: 'bg-teal-500', pattern: /serving[:\s]*(\d+(?:\.\d+)?\s*g)/i },
  { key: 'ingredients', label: 'Ingredients', unit: '', color: 'bg-amber-600', pattern: null },
];

interface SelectedField {
  key: string;
  value: string;
  element?: string;
  autoDetected?: boolean;  // true if auto-matched, false if manually selected
}

export const ScraperPanel: React.FC<ScraperPanelProps> = ({
  isOpen,
  onClose,
  foodName,
  barcode,
  currentIndex,
  onApplyData,
}) => {
  const [url, setUrl] = useState('');
  const [targetIndex, setTargetIndex] = useState<SaveIndexName>(
    (currentIndex as SaveIndexName) || 'verified_foods'
  );
  const [isExtracting, setIsExtracting] = useState(false);
  const [extractionResult, setExtractionResult] = useState<ExtractionResult | null>(null);
  const [editedFields, setEditedFields] = useState<Record<string, string>>({});
  const [activeTab, setActiveTab] = useState<'search' | 'extract' | 'visual'>('search');
  const [usePuppeteer, setUsePuppeteer] = useState(false);
  const [forceDirectScrape, setForceDirectScrape] = useState(true); // Default ON - scrape URL directly
  const [isDownloadingImage, setIsDownloadingImage] = useState(false);

  // Visual picker state
  const [visualUrl, setVisualUrl] = useState('');
  const [isLoadingVisual, setIsLoadingVisual] = useState(false);
  const [pageHtml, setPageHtml] = useState<string | null>(null);
  const [useVisualPuppeteer, setUseVisualPuppeteer] = useState(false);
  const [scrapingService, setScrapingService] = useState<'auto' | 'scrapedo' | 'scrapingbee'>('scrapedo');
  const [scrapingCredits, setScrapingCredits] = useState<{
    scrapingbee?: { remaining?: number; limit?: number; error?: string };
    scrapedo?: { remaining?: number; limit?: number; error?: string };
  } | null>(null);
  const [isLoadingCredits, setIsLoadingCredits] = useState(false);
  const [activePickingField, setActivePickingField] = useState<string | null>(null);
  const [selectedFields, setSelectedFields] = useState<Record<string, SelectedField>>({});
  const iframeRef = useRef<HTMLIFrameElement>(null);

  // Site-specific learned selectors (stored in localStorage)
  const [learnedSelectors, setLearnedSelectors] = useState<Record<string, Record<string, string>>>(() => {
    try {
      return JSON.parse(localStorage.getItem('nutrasafe_learned_selectors') || '{}');
    } catch {
      return {};
    }
  });

  // Save learned selectors to localStorage
  const saveLearnedSelector = useCallback((url: string, fieldKey: string, selector: string) => {
    const domain = new URL(url).hostname;
    setLearnedSelectors(prev => {
      const updated = {
        ...prev,
        [domain]: {
          ...prev[domain],
          [fieldKey]: selector
        }
      };
      localStorage.setItem('nutrasafe_learned_selectors', JSON.stringify(updated));
      return updated;
    });
  }, []);

  // Get learned selectors for current domain
  const getLearnedSelectorsForUrl = useCallback((url: string): Record<string, string> => {
    try {
      const domain = new URL(url).hostname;
      return learnedSelectors[domain] || {};
    } catch {
      return {};
    }
  }, [learnedSelectors]);

  // Generate interactive iframe content with selection scripts (only called once per page load)
  const getInteractiveIframeContent = useCallback(() => {
    if (!pageHtml) return '';

    // Inject selection script - this is loaded ONCE and communicates via postMessage
    const selectionScript = `
      <style>
        .nutrasafe-highlight {
          outline: 3px solid #6366f1 !important;
          outline-offset: 2px !important;
          cursor: crosshair !important;
          background-color: rgba(99, 102, 241, 0.1) !important;
        }
        .nutrasafe-selected {
          outline: 3px solid #22c55e !important;
          outline-offset: 2px !important;
          background-color: rgba(34, 197, 94, 0.15) !important;
        }
        .nutrasafe-banner {
          position: fixed !important;
          top: 0 !important;
          left: 0 !important;
          right: 0 !important;
          background: linear-gradient(135deg, #6366f1, #8b5cf6) !important;
          color: white !important;
          padding: 12px 20px !important;
          z-index: 2147483647 !important;
          font-family: system-ui, -apple-system, sans-serif !important;
          font-size: 14px !important;
          box-shadow: 0 4px 12px rgba(0,0,0,0.2) !important;
          display: flex !important;
          align-items: center !important;
          justify-content: center !important;
        }
        .nutrasafe-banner.picking {
          background: linear-gradient(135deg, #f59e0b, #d97706) !important;
          animation: pulse 1.5s infinite !important;
        }
        @keyframes pulse {
          0%, 100% { opacity: 1; }
          50% { opacity: 0.8; }
        }
        html { margin-top: 50px !important; }
        body { margin-top: 0 !important; }
        /* Hide cookie consent and overlay elements */
        [class*="cookie"], [class*="Cookie"], [class*="consent"], [class*="Consent"],
        [class*="gdpr"], [class*="GDPR"], [class*="privacy"], [class*="Privacy"],
        [id*="cookie"], [id*="Cookie"], [id*="consent"], [id*="Consent"],
        [id*="onetrust"], [class*="onetrust"], [class*="OneTrust"],
        [class*="CookieBanner"], [class*="cookie-banner"], [class*="cookieBanner"],
        .truste_box_overlay, .truste_overlay, #truste-consent-track,
        [aria-label*="cookie"], [aria-label*="consent"] {
          display: none !important;
          visibility: hidden !important;
          opacity: 0 !important;
          pointer-events: none !important;
        }
        /* Style for expandable accordion toggle button */
        .nutrasafe-expand-btn {
          cursor: pointer !important;
          background: #6366f1 !important;
          color: white !important;
          border: none !important;
          padding: 4px 8px !important;
          border-radius: 4px !important;
          font-size: 11px !important;
          margin-left: 8px !important;
        }
        .nutrasafe-expand-btn:hover {
          background: #4f46e5 !important;
        }
        /* Force show hidden accordion content */
        .nutrasafe-force-expanded {
          display: block !important;
          visibility: visible !important;
          opacity: 1 !important;
          height: auto !important;
          max-height: none !important;
          overflow: visible !important;
        }
        /* AGGRESSIVE: Force show ALL potentially hidden content */
        [aria-hidden="true"],
        [hidden],
        [class*="collapse"]:not(.show),
        [class*="hidden"],
        [class*="closed"],
        [class*="accordion"] > div,
        [class*="accordion"] > section,
        [class*="Accordion"] > div,
        [class*="Accordion"] > section,
        [class*="panel-body"],
        [class*="panel-content"],
        [class*="accordion-body"],
        [class*="accordion-content"],
        [class*="expandable-content"],
        [class*="drawer-content"],
        [role="region"],
        [role="tabpanel"],
        details > *:not(summary) {
          display: block !important;
          visibility: visible !important;
          opacity: 1 !important;
          height: auto !important;
          max-height: none !important;
          overflow: visible !important;
          clip: auto !important;
          clip-path: none !important;
          position: relative !important;
          transform: none !important;
        }
        /* Force details to be open */
        details {
          display: block !important;
        }
        details[open] > *,
        details > *:not(summary) {
          display: block !important;
        }
      </style>
      <script>
        (function() {
          // Start with picking OFF - parent will send message to start
          let isPicking = false;
          let pickingLabel = "";
          let lastHighlighted = null;
          const selectedElements = new Set();

          // Helper: Get only direct text content (not from children)
          function getDirectText(el) {
            let text = '';
            for (const node of el.childNodes) {
              if (node.nodeType === Node.TEXT_NODE) {
                text += node.textContent;
              }
            }
            return text.trim();
          }

          // Helper: Check if element is cookie/consent related
          function isCookieElement(el) {
            const str = (el.className || '') + ' ' + (el.id || '') + ' ' + (el.innerText || '');
            return /cookie|consent|gdpr|privacy|reject|accept all|manage preferences/i.test(str);
          }

          // Helper: Generate a CSS selector for an element
          function getCssSelector(el) {
            if (!el || el === document.body || el === document.documentElement) return '';

            const parts = [];
            let current = el;

            while (current && current !== document.body && parts.length < 5) {
              let selector = current.tagName.toLowerCase();

              // Add ID if available (most specific)
              if (current.id) {
                selector = '#' + current.id;
                parts.unshift(selector);
                break; // ID is unique, no need to go further
              }

              // Add class names (first 2 meaningful ones)
              if (current.className && typeof current.className === 'string') {
                const classes = current.className.split(' ')
                  .filter(c => c && !c.startsWith('nutrasafe-') && c.length < 30)
                  .slice(0, 2);
                if (classes.length > 0) {
                  selector += '.' + classes.join('.');
                }
              }

              // Add nth-child if needed for specificity
              const parent = current.parentElement;
              if (parent) {
                const siblings = Array.from(parent.children).filter(c => c.tagName === current.tagName);
                if (siblings.length > 1) {
                  const index = siblings.indexOf(current) + 1;
                  selector += ':nth-of-type(' + index + ')';
                }
              }

              parts.unshift(selector);
              current = parent;
            }

            return parts.join(' > ');
          }

          // FORCE expand all accordions - this works even without original JS
          function expandAllAccordions() {
            console.log('NutraSafe: Expanding all accordions...');

            // Helper to force-show an element
            function forceShow(el) {
              if (!el || isCookieElement(el)) return;
              el.style.setProperty('display', 'block', 'important');
              el.style.setProperty('visibility', 'visible', 'important');
              el.style.setProperty('opacity', '1', 'important');
              el.style.setProperty('height', 'auto', 'important');
              el.style.setProperty('max-height', 'none', 'important');
              el.style.setProperty('overflow', 'visible', 'important');
              el.style.setProperty('clip', 'auto', 'important');
              el.style.setProperty('clip-path', 'none', 'important');
              el.style.setProperty('transform', 'none', 'important');
              el.style.setProperty('position', 'relative', 'important');
              el.hidden = false;
              el.removeAttribute('hidden');
              el.removeAttribute('aria-hidden');
            }

            // 1. Expand details/summary elements
            document.querySelectorAll('details').forEach(function(el) {
              el.setAttribute('open', '');
              el.open = true;
            });

            // 2. Find ALL elements with aria-expanded and show their targets
            document.querySelectorAll('[aria-expanded]').forEach(function(el) {
              el.setAttribute('aria-expanded', 'true');

              // Find the controlled element by aria-controls
              const controlsId = el.getAttribute('aria-controls');
              if (controlsId) {
                const target = document.getElementById(controlsId);
                if (target) forceShow(target);
              }

              // Check for data-target
              const dataTarget = el.getAttribute('data-target') || el.getAttribute('href');
              if (dataTarget && dataTarget.startsWith('#')) {
                const target = document.querySelector(dataTarget);
                if (target) forceShow(target);
              }

              // Show ALL siblings (accordion content is often a sibling)
              let sibling = el.nextElementSibling;
              while (sibling) {
                forceShow(sibling);
                // Also show all children of siblings
                sibling.querySelectorAll('*').forEach(forceShow);
                sibling = sibling.nextElementSibling;
              }

              // Also check parent's next sibling (another common pattern)
              const parentNext = el.parentElement?.nextElementSibling;
              if (parentNext) {
                forceShow(parentNext);
                parentNext.querySelectorAll('*').forEach(forceShow);
              }
            });

            // 3. Find elements by common accordion/collapse class names
            const accordionSelectors = [
              '[class*="accordion"]', '[class*="Accordion"]',
              '[class*="collapse"]', '[class*="Collapse"]',
              '[class*="expandable"]', '[class*="Expandable"]',
              '[class*="panel"]', '[class*="Panel"]',
              '[class*="drawer"]', '[class*="Drawer"]',
              '[class*="content"]', '[class*="Content"]',
              '[class*="body"]', '[class*="Body"]',
              '[role="region"]', '[role="tabpanel"]',
            ];

            accordionSelectors.forEach(function(selector) {
              try {
                document.querySelectorAll(selector).forEach(forceShow);
              } catch(e) {}
            });

            // 4. Scan ALL elements and force-show any that are hidden
            document.querySelectorAll('*').forEach(function(el) {
              if (isCookieElement(el)) return;

              const style = window.getComputedStyle(el);
              const isHidden = (
                style.display === 'none' ||
                style.visibility === 'hidden' ||
                style.opacity === '0' ||
                style.maxHeight === '0px' ||
                style.height === '0px' ||
                style.clipPath === 'inset(100%)' ||
                el.hidden ||
                el.getAttribute('aria-hidden') === 'true'
              );

              if (isHidden) {
                forceShow(el);
              }
            });

            // 5. Remove any inline styles that hide content
            document.querySelectorAll('[style]').forEach(function(el) {
              if (isCookieElement(el)) return;
              const style = el.getAttribute('style') || '';
              if (style.includes('display: none') || style.includes('display:none') ||
                  style.includes('visibility: hidden') || style.includes('visibility:hidden') ||
                  style.includes('height: 0') || style.includes('height:0') ||
                  style.includes('max-height: 0') || style.includes('max-height:0')) {
                forceShow(el);
              }
            });

            // 6. Special: Find buttons/links that look like accordion toggles and show their associated content
            document.querySelectorAll('button, a, [role="button"], summary').forEach(function(el) {
              const text = (el.textContent || '').toLowerCase();
              if (text.includes('ingredient') || text.includes('storage') || text.includes('preparation') ||
                  text.includes('information') || text.includes('detail') || text.includes('more') ||
                  text.includes('brand') || text.includes('nutrition')) {
                // This is likely an accordion header - show everything after it
                let sibling = el.nextElementSibling;
                while (sibling) {
                  forceShow(sibling);
                  sibling.querySelectorAll('*').forEach(forceShow);
                  sibling = sibling.nextElementSibling;
                }
                // Also check parent's siblings
                const parent = el.parentElement;
                if (parent) {
                  let parentSibling = parent.nextElementSibling;
                  while (parentSibling) {
                    forceShow(parentSibling);
                    parentSibling.querySelectorAll('*').forEach(forceShow);
                    parentSibling = parentSibling.nextElementSibling;
                  }
                }
              }
            });

            console.log('NutraSafe: Accordion expansion complete - forced all hidden elements visible');
          }

          // Update banner helper
          function updateBanner() {
            if (isPicking) {
              banner.className = 'nutrasafe-banner picking';
              banner.innerHTML = '👆 Click on the <strong style="margin: 0 4px;">' + pickingLabel + '</strong> value on this page';
            } else {
              banner.className = 'nutrasafe-banner';
              banner.innerHTML = '✅ Select a field above, then click its value here | <button class="nutrasafe-expand-btn" id="nutrasafe-expand-all">📂 Expand All</button>';

              // Re-attach expand button handler
              const btn = document.getElementById('nutrasafe-expand-all');
              if (btn) {
                btn.onclick = function(evt) {
                  evt.preventDefault();
                  evt.stopPropagation();
                  expandAllAccordions();
                  this.textContent = '✓ Expanded!';
                  setTimeout(function() { btn.textContent = '📂 Expand All'; }, 1500);
                };
              }
            }
          }

          // Create banner
          const banner = document.createElement('div');
          banner.className = 'nutrasafe-banner';
          document.body.insertBefore(banner, document.body.firstChild);
          updateBanner();

          // Auto-expand on load (multiple attempts for dynamic content)
          setTimeout(expandAllAccordions, 300);
          setTimeout(expandAllAccordions, 1000);
          setTimeout(expandAllAccordions, 2000);

          // Mouseover highlighting (only when picking)
          document.addEventListener('mouseover', function(e) {
            if (!isPicking) return;
            const target = e.target;
            if (target === banner || banner.contains(target)) return;
            if (isCookieElement(target)) return;
            if (target === lastHighlighted) return;

            if (lastHighlighted && !selectedElements.has(lastHighlighted)) {
              lastHighlighted.classList.remove('nutrasafe-highlight');
            }

            if (target && target !== document.body && target !== document.documentElement) {
              target.classList.add('nutrasafe-highlight');
              lastHighlighted = target;
            }
          }, true);

          // Mouseout
          document.addEventListener('mouseout', function(e) {
            if (!isPicking) return;
            const target = e.target;
            if (target && !selectedElements.has(target)) {
              target.classList.remove('nutrasafe-highlight');
            }
          }, true);

          // Click handler - always active, checks isPicking state
          document.addEventListener('click', function(e) {
            const target = e.target;
            if (target === banner || banner.contains(target)) return;
            if (isCookieElement(target)) return;

            // If not picking, allow all clicks (for navigation, accordions, etc.)
            if (!isPicking) return;

            e.preventDefault();
            e.stopPropagation();
            e.stopImmediatePropagation();

            // Get text - prefer direct text, fallback to full text
            let text = getDirectText(target);
            if (!text || text.length < 1) {
              text = (target.innerText || target.textContent || '').trim();
            }

            // If text is too long, it's probably a container - try to find a smaller element
            if (text.length > 500) {
              // Try to get just the first line or number
              const lines = text.split('\\n').filter(l => l.trim());
              if (lines.length > 0) {
                text = lines[0].trim();
              }
            }

            const rect = target.getBoundingClientRect();
            const selector = getCssSelector(target);

            // Check if it's an image and get the src
            let imageSrc = null;
            if (target.tagName.toLowerCase() === 'img') {
              imageSrc = target.src || target.getAttribute('src') || target.getAttribute('data-src');
            }
            // Also check if clicking on a container that has an image inside
            if (!imageSrc) {
              const imgChild = target.querySelector('img');
              if (imgChild) {
                imageSrc = imgChild.src || imgChild.getAttribute('src') || imgChild.getAttribute('data-src');
              }
            }

            // Mark as selected
            target.classList.remove('nutrasafe-highlight');
            target.classList.add('nutrasafe-selected');
            selectedElements.add(target);

            // Send to parent with CSS selector for learning
            window.parent.postMessage({
              type: 'NUTRASAFE_ELEMENT_SELECTED',
              text: imageSrc || text,
              tagName: target.tagName.toLowerCase(),
              className: target.className,
              selector: selector,
              imageSrc: imageSrc,
              rect: { top: rect.top, left: rect.left, width: rect.width, height: rect.height }
            }, '*');

            isPicking = false;
            updateBanner();
          }, true);

          // Listen for messages from parent
          window.addEventListener('message', function(e) {
            if (e.data?.type === 'NUTRASAFE_START_PICKING') {
              isPicking = true;
              pickingLabel = e.data.label || '';
              updateBanner();
            } else if (e.data?.type === 'NUTRASAFE_STOP_PICKING') {
              isPicking = false;
              if (lastHighlighted) {
                lastHighlighted.classList.remove('nutrasafe-highlight');
              }
              updateBanner();
            } else if (e.data?.type === 'NUTRASAFE_EXPAND_ALL') {
              expandAllAccordions();
            }
          });

          // Notify parent that iframe is ready
          window.parent.postMessage({ type: 'NUTRASAFE_IFRAME_READY' }, '*');
        })();
      </script>
    `;

    // Inject before </body>
    if (pageHtml.includes('</body>')) {
      return pageHtml.replace('</body>', selectionScript + '</body>');
    } else {
      return pageHtml + selectionScript;
    }
  }, [pageHtml]); // Only regenerate when pageHtml changes, NOT when activePickingField changes

  // Memoize the iframe content to prevent re-renders when picking field changes
  const iframeContent = useMemo(() => getInteractiveIframeContent(), [getInteractiveIframeContent]);

  // Handle messages from iframe
  useEffect(() => {
    const handleMessage = (event: MessageEvent) => {
      if (event.data?.type === 'NUTRASAFE_ELEMENT_SELECTED' && activePickingField) {
        const { text, selector, imageSrc, tagName } = event.data;

        // Smart value extraction
        let value = text.trim();

        // For image field, use the image src
        if (activePickingField === 'imageUrl') {
          if (imageSrc) {
            value = imageSrc;
          } else if (tagName === 'img') {
            // Text might contain the src if sent from older code
            value = text;
          }
        } else if (activePickingField !== 'name' && activePickingField !== 'ingredients') {
          if (activePickingField === 'calories') {
            // Prefer kcal over kJ
            const kcalMatch = value.match(/(\d+(?:\.\d+)?)\s*kcal/i);
            if (kcalMatch) {
              value = kcalMatch[1];
            } else {
              const match = value.match(/[\d.]+/);
              if (match) value = match[0];
            }
          } else {
            // Extract number with 'g' unit preference
            const gMatch = value.match(/(\d+(?:\.\d+)?)\s*g(?![a-z])/i);
            if (gMatch) {
              value = gMatch[1];
            } else {
              const match = value.match(/[\d.]+/);
              if (match) value = match[0];
            }
          }
        }

        setSelectedFields(prev => ({
          ...prev,
          [activePickingField]: {
            key: activePickingField,
            value,
            element: text,
          }
        }));

        // Save the selector for this field to learn for future use
        if (selector && visualUrl) {
          saveLearnedSelector(visualUrl, activePickingField, selector);
        }

        setActivePickingField(null);
      }
    };

    window.addEventListener('message', handleMessage);
    return () => window.removeEventListener('message', handleMessage);
  }, [activePickingField, visualUrl, saveLearnedSelector]);

  // Notify iframe when picking field changes
  useEffect(() => {
    if (iframeRef.current?.contentWindow) {
      if (activePickingField) {
        const fieldLabel = NUTRITION_FIELDS.find(f => f.key === activePickingField)?.label || activePickingField;
        iframeRef.current.contentWindow.postMessage({
          type: 'NUTRASAFE_START_PICKING',
          field: activePickingField,
          label: fieldLabel,
        }, '*');
      } else {
        iframeRef.current.contentWindow.postMessage({
          type: 'NUTRASAFE_STOP_PICKING',
        }, '*');
      }
    }
  }, [activePickingField]);

  // Load scraping credits when visual tab is opened
  const loadScrapingCredits = useCallback(async () => {
    setIsLoadingCredits(true);
    try {
      const response = await fetch(`${API_BASE}/getScrapingCredits`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ data: {} }),
      });
      const result = await response.json();
      setScrapingCredits(result.result || result);
    } catch (error) {
      console.error('Failed to load credits:', error);
    } finally {
      setIsLoadingCredits(false);
    }
  }, []);

  // Load credits when visual tab is opened
  useEffect(() => {
    if (activeTab === 'visual' && !scrapingCredits && !isLoadingCredits) {
      loadScrapingCredits();
    }
  }, [activeTab, scrapingCredits, isLoadingCredits, loadScrapingCredits]);

  // Build search query from food name and brand
  const searchQuery = foodName || '';

  // Download image to Firebase Storage
  const downloadImage = async (imageUrl: string): Promise<string | null> => {
    if (!imageUrl) return null;

    try {
      setIsDownloadingImage(true);

      // Call Firebase function to download and store image
      const response = await fetch(`${API_BASE}/uploadFoodImage`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          data: {
            sourceUrl: imageUrl,
            foodName: foodName || 'scraped-food',
          },
        }),
      });

      const result = await response.json();
      const uploadResult = result.result || result;

      if (uploadResult.success && uploadResult.imageUrl) {
        return uploadResult.imageUrl;
      }
      return null;
    } catch (error) {
      console.error('Error downloading image:', error);
      return null;
    } finally {
      setIsDownloadingImage(false);
    }
  };

  // Load page for visual picking
  const loadPageForVisualPicking = async () => {
    if (!visualUrl.trim()) return;

    setIsLoadingVisual(true);
    setPageHtml(null);
    setSelectedFields({});

    try {
      // Fetch page through our proxy function
      const response = await fetch(`${API_BASE}/fetchPageForVisualPicker`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          data: { url: visualUrl.trim(), usePuppeteer: useVisualPuppeteer, service: scrapingService }
        }),
      });

      const result = await response.json();
      const data = result.result || result;

      if (data.success && data.html) {
        setPageHtml(data.html);

        // Auto-detect nutrition values from HTML
        const autoDetected: Record<string, SelectedField> = {};
        const htmlText = data.html.replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ');

        // Get learned selectors for this domain
        const learned = getLearnedSelectorsForUrl(visualUrl);
        const hasLearnedSelectors = Object.keys(learned).length > 0;

        // If we have learned selectors, inject them into a temp DOM to extract values
        if (hasLearnedSelectors) {
          const parser = new DOMParser();
          const doc = parser.parseFromString(data.html, 'text/html');

          for (const [fieldKey, selector] of Object.entries(learned)) {
            try {
              const element = doc.querySelector(selector);
              if (element) {
                let extractedValue = (element.textContent || '').trim();

                // Smart value extraction based on field type
                if (fieldKey !== 'name' && fieldKey !== 'ingredients') {
                  if (fieldKey === 'calories') {
                    const kcalMatch = extractedValue.match(/(\d+(?:\.\d+)?)\s*kcal/i);
                    if (kcalMatch) extractedValue = kcalMatch[1];
                    else {
                      const numMatch = extractedValue.match(/[\d.]+/);
                      if (numMatch) extractedValue = numMatch[0];
                    }
                  } else {
                    const gMatch = extractedValue.match(/(\d+(?:\.\d+)?)\s*g(?![a-z])/i);
                    if (gMatch) extractedValue = gMatch[1];
                    else {
                      const numMatch = extractedValue.match(/[\d.]+/);
                      if (numMatch) extractedValue = numMatch[0];
                    }
                  }
                }

                if (extractedValue) {
                  autoDetected[fieldKey] = {
                    key: fieldKey,
                    value: extractedValue,
                    autoDetected: true
                  };
                }
              }
            } catch (e) {
              console.warn(`Failed to extract ${fieldKey} using learned selector:`, e);
            }
          }
        }

        // Try to find product name from title or h1 (if not already learned)
        if (!autoDetected.name) {
          const titleMatch = data.html.match(/<title[^>]*>([^<]+)<\/title>/i);
          const h1Match = data.html.match(/<h1[^>]*>([^<]+)<\/h1>/i);
          if (h1Match) {
            autoDetected.name = { key: 'name', value: h1Match[1].trim(), autoDetected: true };
          } else if (titleMatch) {
            const title = titleMatch[1].replace(/\s*[-|].*$/, '').trim();
            if (title.length < 100) {
              autoDetected.name = { key: 'name', value: title, autoDetected: true };
            }
          }
        }

        // Try to find product image (if not already learned)
        if (!autoDetected.imageUrl) {
          // Look for og:image meta tag first (most reliable)
          const ogImageMatch = data.html.match(/<meta[^>]*property=["']og:image["'][^>]*content=["']([^"']+)["']/i);
          if (ogImageMatch) {
            autoDetected.imageUrl = { key: 'imageUrl', value: ogImageMatch[1], autoDetected: true };
          } else {
            // Look for product image in common patterns
            const productImgMatch = data.html.match(/<img[^>]*class=["'][^"']*product[^"']*["'][^>]*src=["']([^"']+)["']/i) ||
                                    data.html.match(/<img[^>]*src=["']([^"']+)["'][^>]*class=["'][^"']*product[^"']*["']/i) ||
                                    data.html.match(/<img[^>]*data-src=["']([^"']+)["'][^>]*class=["'][^"']*product/i);
            if (productImgMatch && productImgMatch[1]) {
              autoDetected.imageUrl = { key: 'imageUrl', value: productImgMatch[1], autoDetected: true };
            }
          }
        }

        // Look for per 100g values specifically (fallback if no learned selectors)
        const per100gSection = htmlText.match(/per\s*100\s*g[^]*?(?=per\s*serving|per\s*portion|$)/i)?.[0] || htmlText;

        // Auto-detect each nutrition field using patterns (only if not already detected via learning)
        NUTRITION_FIELDS.forEach(field => {
          if (field.pattern && !autoDetected[field.key]) {
            // For calories, specifically look for kcal value
            if (field.key === 'calories') {
              const kcalMatch = per100gSection.match(/(\d+(?:\.\d+)?)\s*kcal/i);
              if (kcalMatch) {
                autoDetected.calories = { key: 'calories', value: kcalMatch[1], autoDetected: true };
              }
            } else {
              const match = per100gSection.match(field.pattern);
              if (match && match[1]) {
                autoDetected[field.key] = { key: field.key, value: match[1], autoDetected: true };
              }
            }
          }
        });

        // Try to find ingredients (if not already detected)
        if (!autoDetected.ingredients) {
          const ingredientsMatch = data.html.match(/ingredients[:\s]*<[^>]*>([^<]{20,500})/i);
          if (ingredientsMatch) {
            const ingredients = ingredientsMatch[1].replace(/<[^>]+>/g, '').trim();
            if (ingredients.length > 10) {
              autoDetected.ingredients = { key: 'ingredients', value: ingredients.substring(0, 500), autoDetected: true };
            }
          }
        }

        // Set auto-detected values
        if (Object.keys(autoDetected).length > 0) {
          setSelectedFields(autoDetected);
        }
      } else {
        alert('Failed to load page: ' + (data.error || 'Unknown error'));
      }
    } catch (error) {
      console.error('Error loading page:', error);
      alert('Failed to load page. Try enabling Puppeteer or check the URL.');
    } finally {
      setIsLoadingVisual(false);
    }
  };

  // Apply visual picker selections to form
  const applyVisualSelections = () => {
    const data: Record<string, string | undefined> = {};

    Object.entries(selectedFields).forEach(([key, field]) => {
      if (field.value) {
        data[key] = field.value;
      }
    });

    // Include the target index
    data.targetIndex = targetIndex;

    onApplyData(data);
    onClose();
  };

  // Extract data from URL
  const extractData = async () => {
    if (!url.trim()) return;

    setIsExtracting(true);
    setExtractionResult(null);
    setEditedFields({});

    try {
      // Choose endpoint based on Puppeteer toggle
      const endpoint = usePuppeteer ? 'extractWithPuppeteer' : 'extractUKProductData';

      // Call the Firebase function
      const response = await fetch(`${API_BASE}/${endpoint}`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          data: {
            url: url.trim(),
            barcode: barcode || undefined,
            productName: foodName || undefined,
            forceDirectScrape: forceDirectScrape, // Skip API fallbacks and scrape URL directly
            returnHtmlPreview: true, // Return info about what fields were detected
          },
        }),
      });

      const result = await response.json();

      // Firebase callable functions wrap the result
      const extractionResult: ExtractionResult = result.result || result;

      setExtractionResult(extractionResult);

      // Pre-populate edited fields with extracted values
      if (extractionResult.success && extractionResult.data) {
        const data = extractionResult.data;
        setEditedFields({
          name: data.name || '',
          brandName: data.brand || '',
          barcode: data.barcode || '',
          ingredients: data.ingredients || '',
          imageUrl: data.imageUrl || '',
          calories: data.nutrition.energyKcal?.toString() || '',
          protein: data.nutrition.protein?.toString() || '',
          carbs: data.nutrition.carbohydrate?.toString() || '',
          fat: data.nutrition.fat?.toString() || '',
          saturatedFat: data.nutrition.saturates?.toString() || '',
          fiber: data.nutrition.fibre?.toString() || '',
          sugar: data.nutrition.sugars?.toString() || '',
          salt: data.nutrition.salt?.toString() || '',
        });
      }
    } catch (error) {
      console.error('Extraction error:', error);
      setExtractionResult({
        success: false,
        extractionMethod: 'failed',
        confidence: 0,
        warnings: [],
        sourceUrl: url,
        error: error instanceof Error ? error.message : 'Failed to extract data',
      });
    } finally {
      setIsExtracting(false);
    }
  };

  // Apply extracted data to food form
  const applyToFood = () => {
    onApplyData({
      name: editedFields.name || undefined,
      brandName: editedFields.brandName || undefined,
      barcode: editedFields.barcode || undefined,
      ingredients: editedFields.ingredients || undefined,
      imageUrl: editedFields.imageUrl || undefined,
      calories: editedFields.calories || undefined,
      protein: editedFields.protein || undefined,
      carbs: editedFields.carbs || undefined,
      fat: editedFields.fat || undefined,
      saturatedFat: editedFields.saturatedFat || undefined,
      fiber: editedFields.fiber || undefined,
      sugar: editedFields.sugar || undefined,
      salt: editedFields.salt || undefined,
    });
    onClose();
  };

  // Get confidence color
  const getConfidenceColor = (confidence: number) => {
    if (confidence >= 80) return 'text-green-600 bg-green-50';
    if (confidence >= 50) return 'text-yellow-600 bg-yellow-50';
    return 'text-red-600 bg-red-50';
  };

  // Get method display name
  const getMethodName = (method: string) => {
    const names: Record<string, string> = {
      tesco8_api: 'Tesco API',
      openfoodfacts: 'OpenFoodFacts',
      embedded_json: 'Embedded JSON',
      structured_data: 'Structured Data',
      html_parsing: 'HTML Parsing',
      data_attributes: 'Data Attributes',
      puppeteer: 'Puppeteer',
      failed: 'Failed',
    };
    return names[method] || method;
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 overflow-hidden">
      {/* Backdrop */}
      <div className="absolute inset-0 bg-black/30 backdrop-blur-sm" onClick={onClose} />

      {/* Panel - Full width on left for visual picker */}
      <div className="absolute left-0 top-0 h-full w-full max-w-4xl bg-white shadow-2xl transform transition-transform">
        {/* Header */}
        <div className="flex items-center justify-between p-4 border-b bg-gradient-to-r from-indigo-500 to-purple-600 text-white">
          <div className="flex items-center gap-3">
            <div className="p-2 bg-white/20 rounded-lg">
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
              </svg>
            </div>
            <div>
              <h2 className="font-semibold">Scrape Nutrition Data</h2>
              <p className="text-xs text-white/80">Extract from UK supermarket websites</p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="p-2 hover:bg-white/20 rounded-lg transition-colors"
          >
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        {/* Tabs */}
        <div className="flex border-b">
          <button
            onClick={() => setActiveTab('search')}
            className={`flex-1 px-4 py-3 text-sm font-medium transition-colors ${
              activeTab === 'search'
                ? 'text-indigo-600 border-b-2 border-indigo-600 bg-indigo-50'
                : 'text-gray-600 hover:text-gray-900 hover:bg-gray-50'
            }`}
          >
            🔍 Search Supermarkets
          </button>
          <button
            onClick={() => setActiveTab('extract')}
            className={`flex-1 px-4 py-3 text-sm font-medium transition-colors ${
              activeTab === 'extract'
                ? 'text-indigo-600 border-b-2 border-indigo-600 bg-indigo-50'
                : 'text-gray-600 hover:text-gray-900 hover:bg-gray-50'
            }`}
          >
            📥 Auto Extract
          </button>
          <button
            onClick={() => setActiveTab('visual')}
            className={`flex-1 px-4 py-3 text-sm font-medium transition-colors ${
              activeTab === 'visual'
                ? 'text-indigo-600 border-b-2 border-indigo-600 bg-indigo-50'
                : 'text-gray-600 hover:text-gray-900 hover:bg-gray-50'
            }`}
          >
            👆 Visual Picker
          </button>
        </div>

        {/* Content */}
        <div className="overflow-y-auto h-[calc(100%-120px)] p-4">
          {activeTab === 'search' && (
            <div className="space-y-4">
              {/* Search query display */}
              <div className="p-3 bg-gray-50 rounded-xl">
                <p className="text-xs text-gray-500 mb-1">Searching for:</p>
                <p className="font-medium text-gray-900">{searchQuery || 'No food name available'}</p>
                {barcode && (
                  <p className="text-xs text-gray-500 mt-1">Barcode: {barcode}</p>
                )}
              </div>

              {/* Supermarket links */}
              <div className="grid grid-cols-2 gap-3">
                {UK_SUPERMARKETS.map((store) => (
                  <a
                    key={store.name}
                    href={store.searchUrl(searchQuery)}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="flex items-center gap-3 p-4 bg-white border border-gray-200 rounded-xl hover:border-indigo-300 hover:shadow-md transition-all group"
                  >
                    <span className="text-2xl">{store.icon}</span>
                    <div>
                      <p className="font-medium text-gray-900 group-hover:text-indigo-600">{store.name}</p>
                      <p className="text-xs text-gray-500">Search →</p>
                    </div>
                  </a>
                ))}
              </div>

              {/* Instructions */}
              <div className="p-4 bg-indigo-50 rounded-xl">
                <h3 className="font-medium text-indigo-900 mb-2">How to use:</h3>
                <ol className="text-sm text-indigo-800 space-y-2">
                  <li className="flex gap-2">
                    <span className="font-bold">1.</span>
                    Click a supermarket to search for the product
                  </li>
                  <li className="flex gap-2">
                    <span className="font-bold">2.</span>
                    Find the product and copy its URL
                  </li>
                  <li className="flex gap-2">
                    <span className="font-bold">3.</span>
                    Go to "Extract from URL" tab and paste the URL
                  </li>
                  <li className="flex gap-2">
                    <span className="font-bold">4.</span>
                    Click "Extract Data" to scrape nutrition info
                  </li>
                </ol>
              </div>
            </div>
          )}

          {activeTab === 'extract' && (
            <div className="space-y-4">
              {/* URL Input */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Product Page URL
                </label>
                <div className="flex gap-2">
                  <input
                    type="url"
                    value={url}
                    onChange={(e) => setUrl(e.target.value)}
                    placeholder="https://www.tesco.com/groceries/en-GB/products/..."
                    className="flex-1 px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
                  />
                  <button
                    onClick={extractData}
                    disabled={!url.trim() || isExtracting}
                    className="px-6 py-3 bg-indigo-600 text-white font-medium rounded-xl hover:bg-indigo-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors flex items-center gap-2"
                  >
                    {isExtracting ? (
                      <>
                        <svg className="w-4 h-4 animate-spin" fill="none" viewBox="0 0 24 24">
                          <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                          <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
                        </svg>
                        Extracting...
                      </>
                    ) : (
                      <>
                        <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
                        </svg>
                        Extract
                      </>
                    )}
                  </button>
                </div>

                {/* Extraction options */}
                <div className="mt-3 p-3 bg-gray-50 rounded-lg space-y-2">
                  <p className="text-xs font-medium text-gray-600 mb-2">Extraction Options:</p>

                  {/* Force Direct Scrape toggle - DEFAULT ON */}
                  <label className="flex items-center gap-2 cursor-pointer">
                    <input
                      type="checkbox"
                      checked={forceDirectScrape}
                      onChange={(e) => setForceDirectScrape(e.target.checked)}
                      className="w-4 h-4 text-green-600 rounded focus:ring-green-500"
                    />
                    <span className="text-sm text-gray-700">Scrape URL directly</span>
                    <span className="text-xs px-1.5 py-0.5 bg-green-100 text-green-700 rounded">Recommended</span>
                  </label>
                  <p className="text-xs text-gray-500 ml-6">Extract nutrition data from the actual page HTML. Disable to try Tesco API/OpenFoodFacts first.</p>

                  {/* Puppeteer toggle for JS-heavy sites */}
                  <label className="flex items-center gap-2 cursor-pointer mt-2">
                    <input
                      type="checkbox"
                      checked={usePuppeteer}
                      onChange={(e) => setUsePuppeteer(e.target.checked)}
                      className="w-4 h-4 text-indigo-600 rounded focus:ring-indigo-500"
                    />
                    <span className="text-sm text-gray-700">Use Puppeteer (JavaScript rendering)</span>
                  </label>
                  <p className="text-xs text-gray-500 ml-6">Enable for sites that load data with JavaScript or have bot protection.</p>
                </div>

                {/* Tip box */}
                <div className="mt-3 p-3 bg-amber-50 border border-amber-200 rounded-lg text-xs text-amber-800">
                  <p className="font-medium mb-1">💡 Tips for sites with bot protection:</p>
                  <ul className="space-y-1 text-amber-700">
                    <li>• Open the supermarket link in a new tab</li>
                    <li>• Complete any captcha/verification</li>
                    <li>• Navigate to the product page</li>
                    <li>• Copy the URL and paste it here</li>
                    <li>• Enable Puppeteer if normal extraction fails</li>
                  </ul>
                </div>
              </div>

              {/* Extraction Result */}
              {extractionResult && (
                <div className="space-y-4">
                  {/* Status */}
                  <div className={`p-4 rounded-xl ${extractionResult.success ? 'bg-green-50' : 'bg-red-50'}`}>
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-2">
                        {extractionResult.success ? (
                          <svg className="w-5 h-5 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                          </svg>
                        ) : (
                          <svg className="w-5 h-5 text-red-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z" />
                          </svg>
                        )}
                        <span className={`font-medium ${extractionResult.success ? 'text-green-800' : 'text-red-800'}`}>
                          {extractionResult.success ? 'Data Extracted Successfully' : 'Extraction Failed'}
                        </span>
                      </div>
                      {extractionResult.success && (
                        <span className={`px-2 py-1 rounded-full text-xs font-medium ${getConfidenceColor(extractionResult.confidence)}`}>
                          {extractionResult.confidence}% confidence
                        </span>
                      )}
                    </div>
                    <p className="text-sm mt-1 text-gray-600">
                      Method: {getMethodName(extractionResult.extractionMethod)}
                    </p>
                    {extractionResult.error && (
                      <p className="text-sm text-red-600 mt-2">{extractionResult.error}</p>
                    )}
                    {extractionResult.warnings && extractionResult.warnings.length > 0 && (
                      <div className="mt-2 text-xs text-yellow-700">
                        {extractionResult.warnings.map((w, i) => (
                          <p key={i}>⚠️ {w}</p>
                        ))}
                      </div>
                    )}
                  </div>

                  {/* Debug Info - What was detected */}
                  {extractionResult.debugInfo && (
                    <div className="p-3 bg-slate-50 rounded-xl border border-slate-200">
                      <h4 className="text-xs font-medium text-slate-700 mb-2 flex items-center gap-1">
                        <svg className="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z" />
                        </svg>
                        Extraction Details
                      </h4>
                      <div className="grid grid-cols-2 gap-2 text-xs">
                        {extractionResult.debugInfo.tiersAttempted && (
                          <div>
                            <span className="text-slate-500">Methods tried:</span>
                            <div className="flex flex-wrap gap-1 mt-0.5">
                              {extractionResult.debugInfo.tiersAttempted.map((tier, i) => (
                                <span key={i} className={`px-1.5 py-0.5 rounded text-[10px] ${
                                  tier === extractionResult.extractionMethod
                                    ? 'bg-green-100 text-green-700 font-medium'
                                    : 'bg-slate-100 text-slate-600'
                                }`}>
                                  {tier}
                                </span>
                              ))}
                            </div>
                          </div>
                        )}
                        {extractionResult.debugInfo.htmlLength && (
                          <div>
                            <span className="text-slate-500">Page size:</span>
                            <span className="ml-1 text-slate-700">{Math.round(extractionResult.debugInfo.htmlLength / 1024)}KB</span>
                          </div>
                        )}
                        {extractionResult.debugInfo.tablesFound !== undefined && (
                          <div>
                            <span className="text-slate-500">Tables found:</span>
                            <span className="ml-1 text-slate-700">{extractionResult.debugInfo.tablesFound}</span>
                            {extractionResult.debugInfo.nutritionTableFound && (
                              <span className="ml-1 text-green-600">✓ nutrition</span>
                            )}
                          </div>
                        )}
                      </div>
                    </div>
                  )}

                  {/* Detected Fields - Shows what the scraper found */}
                  {extractionResult.detectedFields && extractionResult.detectedFields.length > 0 && (
                    <div className="p-3 bg-emerald-50 rounded-xl border border-emerald-200">
                      <h4 className="text-xs font-medium text-emerald-800 mb-2 flex items-center gap-1">
                        <svg className="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                        </svg>
                        Fields Detected on Page ({extractionResult.detectedFields.length})
                      </h4>
                      <div className="space-y-1.5 max-h-40 overflow-y-auto">
                        {extractionResult.detectedFields.map((field, i) => (
                          <div key={i} className="flex items-start gap-2 text-xs bg-white/60 p-2 rounded-lg">
                            <span className="font-medium text-emerald-700 min-w-[80px]">{field.field}</span>
                            <span className="text-slate-600 flex-1">{String(field.value)}</span>
                            {field.selector && (
                              <span className="text-slate-400 text-[10px] bg-slate-100 px-1.5 py-0.5 rounded font-mono">
                                {field.selector}
                              </span>
                            )}
                          </div>
                        ))}
                      </div>
                    </div>
                  )}

                  {/* Extracted Fields */}
                  {extractionResult.success && extractionResult.data && (
                    <>
                      {/* Product Info */}
                      <div className="p-4 bg-gray-50 rounded-xl space-y-3">
                        <h3 className="font-medium text-gray-900 flex items-center gap-2">
                          <svg className="w-4 h-4 text-gray-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                          </svg>
                          Product Information
                        </h3>

                        {/* Image if available */}
                        {editedFields.imageUrl && (
                          <div className="flex flex-col items-center gap-2">
                            <img
                              src={editedFields.imageUrl}
                              alt="Product"
                              className="h-32 object-contain rounded-lg"
                              onError={(e) => e.currentTarget.style.display = 'none'}
                            />
                            <button
                              onClick={async () => {
                                const newUrl = await downloadImage(editedFields.imageUrl);
                                if (newUrl) {
                                  setEditedFields({ ...editedFields, imageUrl: newUrl });
                                }
                              }}
                              disabled={isDownloadingImage || editedFields.imageUrl.includes('firebasestorage')}
                              className="px-3 py-1.5 text-xs font-medium text-indigo-700 bg-indigo-100 hover:bg-indigo-200 rounded-lg disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-1.5"
                            >
                              {isDownloadingImage ? (
                                <>
                                  <svg className="w-3.5 h-3.5 animate-spin" fill="none" viewBox="0 0 24 24">
                                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
                                  </svg>
                                  Downloading...
                                </>
                              ) : editedFields.imageUrl.includes('firebasestorage') ? (
                                <>
                                  <svg className="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                                  </svg>
                                  Saved to Storage
                                </>
                              ) : (
                                <>
                                  <svg className="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
                                  </svg>
                                  Save Image to Storage
                                </>
                              )}
                            </button>
                          </div>
                        )}

                        <div className="grid grid-cols-2 gap-3">
                          <EditableField
                            label="Name"
                            value={editedFields.name || ''}
                            onChange={(v) => setEditedFields({ ...editedFields, name: v })}
                          />
                          <EditableField
                            label="Brand"
                            value={editedFields.brandName || ''}
                            onChange={(v) => setEditedFields({ ...editedFields, brandName: v })}
                          />
                          <EditableField
                            label="Barcode"
                            value={editedFields.barcode || ''}
                            onChange={(v) => setEditedFields({ ...editedFields, barcode: v })}
                          />
                          <EditableField
                            label="Image URL"
                            value={editedFields.imageUrl || ''}
                            onChange={(v) => setEditedFields({ ...editedFields, imageUrl: v })}
                          />
                        </div>
                        <EditableField
                          label="Ingredients"
                          value={editedFields.ingredients || ''}
                          onChange={(v) => setEditedFields({ ...editedFields, ingredients: v })}
                          multiline
                        />
                      </div>

                      {/* Nutrition Info */}
                      <div className="p-4 bg-indigo-50 rounded-xl space-y-3">
                        <h3 className="font-medium text-indigo-900 flex items-center gap-2">
                          <svg className="w-4 h-4 text-indigo-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
                          </svg>
                          Nutrition (per 100g)
                        </h3>
                        <div className="grid grid-cols-3 gap-3">
                          <NutritionField
                            label="Calories"
                            unit="kcal"
                            value={editedFields.calories || ''}
                            onChange={(v) => setEditedFields({ ...editedFields, calories: v })}
                            color="bg-red-100 text-red-800"
                          />
                          <NutritionField
                            label="Protein"
                            unit="g"
                            value={editedFields.protein || ''}
                            onChange={(v) => setEditedFields({ ...editedFields, protein: v })}
                            color="bg-blue-100 text-blue-800"
                          />
                          <NutritionField
                            label="Carbs"
                            unit="g"
                            value={editedFields.carbs || ''}
                            onChange={(v) => setEditedFields({ ...editedFields, carbs: v })}
                            color="bg-yellow-100 text-yellow-800"
                          />
                          <NutritionField
                            label="Fat"
                            unit="g"
                            value={editedFields.fat || ''}
                            onChange={(v) => setEditedFields({ ...editedFields, fat: v })}
                            color="bg-orange-100 text-orange-800"
                          />
                          <NutritionField
                            label="Saturated"
                            unit="g"
                            value={editedFields.saturatedFat || ''}
                            onChange={(v) => setEditedFields({ ...editedFields, saturatedFat: v })}
                            color="bg-orange-100 text-orange-800"
                          />
                          <NutritionField
                            label="Fiber"
                            unit="g"
                            value={editedFields.fiber || ''}
                            onChange={(v) => setEditedFields({ ...editedFields, fiber: v })}
                            color="bg-green-100 text-green-800"
                          />
                          <NutritionField
                            label="Sugar"
                            unit="g"
                            value={editedFields.sugar || ''}
                            onChange={(v) => setEditedFields({ ...editedFields, sugar: v })}
                            color="bg-pink-100 text-pink-800"
                          />
                          <NutritionField
                            label="Salt"
                            unit="g"
                            value={editedFields.salt || ''}
                            onChange={(v) => setEditedFields({ ...editedFields, salt: v })}
                            color="bg-purple-100 text-purple-800"
                          />
                        </div>
                      </div>

                      {/* Apply Button */}
                      <button
                        onClick={applyToFood}
                        className="w-full py-4 bg-gradient-to-r from-green-500 to-emerald-600 text-white font-medium rounded-xl hover:from-green-600 hover:to-emerald-700 transition-all flex items-center justify-center gap-2 shadow-lg"
                      >
                        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                        </svg>
                        Apply to Food Form
                      </button>
                    </>
                  )}
                </div>
              )}
            </div>
          )}

          {/* Visual Picker Tab */}
          {activeTab === 'visual' && (
            <div className="space-y-4">
              {/* URL Input */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Product Page URL
                </label>
                <div className="flex gap-2">
                  <input
                    type="url"
                    value={visualUrl}
                    onChange={(e) => setVisualUrl(e.target.value)}
                    placeholder="https://www.tesco.com/groceries/en-GB/products/..."
                    className="flex-1 px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
                  />
                  <button
                    onClick={loadPageForVisualPicking}
                    disabled={!visualUrl.trim() || isLoadingVisual}
                    className="px-6 py-3 bg-indigo-600 text-white font-medium rounded-xl hover:bg-indigo-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors flex items-center gap-2"
                  >
                    {isLoadingVisual ? (
                      <>
                        <svg className="w-4 h-4 animate-spin" fill="none" viewBox="0 0 24 24">
                          <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                          <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
                        </svg>
                        Loading...
                      </>
                    ) : (
                      <>
                        <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                        </svg>
                        Load Page
                      </>
                    )}
                  </button>
                </div>

                {/* Scraping service selection */}
                <div className="mt-3 p-3 bg-gray-50 rounded-lg space-y-3">
                  <div>
                    <label className="block text-xs font-medium text-gray-600 mb-2">Scraping Service:</label>
                    <div className="flex gap-2">
                      <select
                        value={scrapingService}
                        onChange={(e) => setScrapingService(e.target.value as 'auto' | 'scrapedo' | 'scrapingbee')}
                        className="flex-1 px-3 py-2 text-sm border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
                      >
                        <option value="scrapedo">🟢 Scrape.do (1K free/month forever)</option>
                        <option value="scrapingbee">🟡 ScrapingBee (trial - limited)</option>
                        <option value="auto">Auto (try available)</option>
                      </select>
                      <button
                        onClick={loadScrapingCredits}
                        disabled={isLoadingCredits}
                        className="px-3 py-2 text-xs bg-gray-200 hover:bg-gray-300 rounded-lg transition-colors"
                        title="Refresh credits"
                      >
                        {isLoadingCredits ? '...' : '↻'}
                      </button>
                    </div>
                  </div>

                  {/* Credits display */}
                  {scrapingCredits && (
                    <div className="flex gap-3 text-xs">
                      {scrapingCredits.scrapedo && !scrapingCredits.scrapedo.error && (
                        <div className="flex items-center gap-1 px-2 py-1 bg-green-50 text-green-700 rounded">
                          <span className="font-medium">Scrape.do:</span>
                          <span>{scrapingCredits.scrapedo.remaining?.toLocaleString() || '?'} / {scrapingCredits.scrapedo.limit?.toLocaleString() || '1,000'}</span>
                        </div>
                      )}
                      {scrapingCredits.scrapingbee && !scrapingCredits.scrapingbee.error && (
                        <div className="flex items-center gap-1 px-2 py-1 bg-yellow-50 text-yellow-700 rounded">
                          <span className="font-medium">ScrapingBee:</span>
                          <span>{scrapingCredits.scrapingbee.remaining?.toLocaleString() || '?'} / {scrapingCredits.scrapingbee.limit?.toLocaleString() || '?'}</span>
                        </div>
                      )}
                    </div>
                  )}

                  {/* Puppeteer option - now more prominent */}
                  <div className="p-2 bg-purple-50 border border-purple-200 rounded-lg">
                    <label className="flex items-center gap-2 cursor-pointer">
                      <input
                        type="checkbox"
                        checked={useVisualPuppeteer}
                        onChange={(e) => setUseVisualPuppeteer(e.target.checked)}
                        className="w-4 h-4 text-purple-600 rounded focus:ring-purple-500"
                      />
                      <span className="text-sm font-medium text-purple-800">🔧 Use Puppeteer (expands accordions)</span>
                    </label>
                    <p className="text-xs text-purple-600 mt-1 ml-6">
                      ⚡ Enable this if accordions (Ingredients, Storage) are hidden. Puppeteer clicks on them to expand before capturing.
                    </p>
                  </div>
                </div>
              </div>

              {/* Learned selectors indicator */}
              {Object.keys(learnedSelectors).length > 0 && (
                <div className="p-3 bg-emerald-50 rounded-xl border border-emerald-200">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      <span className="text-lg">🧠</span>
                      <div>
                        <p className="text-sm font-medium text-emerald-800">Learning Active</p>
                        <p className="text-xs text-emerald-600">
                          Remembering field positions for: {Object.keys(learnedSelectors).join(', ')}
                        </p>
                      </div>
                    </div>
                    <button
                      onClick={() => {
                        if (confirm('Clear all learned field positions? You\'ll need to re-select fields on each site.')) {
                          setLearnedSelectors({});
                          localStorage.removeItem('nutrasafe_learned_selectors');
                        }
                      }}
                      className="text-xs px-2 py-1 text-red-600 hover:text-red-700 hover:bg-red-50 rounded"
                    >
                      Clear All
                    </button>
                  </div>
                </div>
              )}

              {/* Instructions when no page loaded */}
              {!pageHtml && !isLoadingVisual && (
                <div className="p-4 bg-indigo-50 rounded-xl">
                  <h3 className="font-medium text-indigo-900 mb-2">👆 Visual Field Picker</h3>
                  <ol className="text-sm text-indigo-800 space-y-2">
                    <li className="flex gap-2">
                      <span className="font-bold">1.</span>
                      Paste a product page URL and click "Load Page"
                    </li>
                    <li className="flex gap-2">
                      <span className="font-bold">2.</span>
                      Click a field button below (e.g., "Calories")
                    </li>
                    <li className="flex gap-2">
                      <span className="font-bold">3.</span>
                      Click on that value in the page preview
                    </li>
                    <li className="flex gap-2">
                      <span className="font-bold">4.</span>
                      Repeat for each nutrition field you want
                    </li>
                    <li className="flex gap-2">
                      <span className="font-bold">🧠</span>
                      <span className="text-emerald-700">The system learns! Next time you load the same site, it will auto-fill fields.</span>
                    </li>
                  </ol>
                </div>
              )}

              {/* Field Selection Buttons */}
              {pageHtml && (
                <div className="space-y-3">
                  <p className="text-sm font-medium text-gray-700">
                    Click a field, then click its value on the page:
                  </p>
                  <div className="flex flex-wrap gap-2">
                    {NUTRITION_FIELDS.map((field) => {
                      const isSelected = !!selectedFields[field.key];
                      const isActive = activePickingField === field.key;

                      return (
                        <button
                          key={field.key}
                          onClick={() => setActivePickingField(isActive ? null : field.key)}
                          className={`px-3 py-2 rounded-lg text-sm font-medium transition-all ${
                            isActive
                              ? 'bg-indigo-600 text-white ring-2 ring-indigo-300 ring-offset-2'
                              : isSelected
                              ? 'bg-green-100 text-green-800 border-2 border-green-400'
                              : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                          }`}
                        >
                          {field.label}
                          {isSelected && (
                            <span className="ml-2 text-green-600">✓ {selectedFields[field.key].value}</span>
                          )}
                        </button>
                      );
                    })}
                  </div>

                  {activePickingField && (
                    <div className="p-3 bg-indigo-100 rounded-lg border-2 border-indigo-300 animate-pulse">
                      <p className="text-sm text-indigo-800 font-medium">
                        👆 Now click on the <strong>{NUTRITION_FIELDS.find(f => f.key === activePickingField)?.label}</strong> value in the page below
                      </p>
                    </div>
                  )}
                </div>
              )}

              {/* Interactive Page Viewer - Click directly on the page */}
              {pageHtml && (
                <div className="flex gap-4" style={{ height: '500px' }}>
                  {/* Left: Interactive iframe */}
                  <div className="flex-1 border-2 border-indigo-300 rounded-xl overflow-hidden bg-white flex flex-col">
                    <div className="px-3 py-2 bg-indigo-50 border-b border-indigo-200 flex items-center justify-between">
                      <div className="flex items-center gap-2">
                        <span className="text-sm font-medium text-indigo-800">
                          🌐 Click on values in the page below
                        </span>
                        <button
                          onClick={() => {
                            if (iframeRef.current?.contentWindow) {
                              iframeRef.current.contentWindow.postMessage({ type: 'NUTRASAFE_EXPAND_ALL' }, '*');
                            }
                          }}
                          className="text-xs px-2 py-1 bg-purple-100 text-purple-700 hover:bg-purple-200 rounded-full transition-colors"
                          title="Expand all collapsed sections on the page"
                        >
                          📂 Expand Sections
                        </button>
                      </div>
                      {activePickingField && (
                        <span className="text-xs px-2 py-1 bg-orange-100 text-orange-700 rounded-full animate-pulse">
                          Selecting: {NUTRITION_FIELDS.find(f => f.key === activePickingField)?.label}
                        </span>
                      )}
                    </div>
                    <iframe
                      ref={iframeRef}
                      srcDoc={iframeContent}
                      className="flex-1 w-full"
                      sandbox="allow-scripts allow-same-origin"
                      title="Interactive Page Picker"
                    />
                  </div>

                  {/* Right: Selected values summary */}
                  <div className="w-80 border-2 border-gray-300 rounded-xl overflow-hidden bg-white flex flex-col">
                    <div className="px-3 py-2 bg-green-100 border-b border-green-200 flex items-center justify-between">
                      <span className="text-sm font-medium text-green-800">
                        ✓ {Object.keys(selectedFields).length}/{NUTRITION_FIELDS.length} fields
                      </span>
                      {Object.values(selectedFields).some(f => f.autoDetected) && (
                        <span className="text-xs px-2 py-0.5 bg-blue-100 text-blue-700 rounded">
                          🤖 Auto-detected
                        </span>
                      )}
                    </div>
                    <div className="flex-1 overflow-y-auto p-2 space-y-1.5">
                      {NUTRITION_FIELDS.map((field) => {
                        const selected = selectedFields[field.key];
                        const isActive = activePickingField === field.key;
                        return (
                          <div
                            key={field.key}
                            onClick={() => setActivePickingField(isActive ? null : field.key)}
                            className={`p-2 rounded-lg border cursor-pointer transition-all ${
                              isActive
                                ? 'bg-orange-50 border-orange-400 ring-2 ring-orange-300'
                                : selected
                                ? selected.autoDetected
                                  ? 'bg-blue-50 border-blue-300 hover:border-blue-400'
                                  : 'bg-green-50 border-green-300 hover:border-green-400'
                                : 'bg-gray-50 border-gray-200 hover:border-indigo-300 hover:bg-indigo-50'
                            }`}
                          >
                            <div className="flex items-center justify-between">
                              <div className="flex items-center gap-1.5">
                                <span className={`text-xs font-medium ${isActive ? 'text-orange-700' : 'text-gray-600'}`}>
                                  {field.label}
                                </span>
                                {selected?.autoDetected && (
                                  <span className="text-[10px] px-1 py-0.5 bg-blue-100 text-blue-600 rounded">auto</span>
                                )}
                              </div>
                              {selected && (
                                <button
                                  onClick={(e) => {
                                    e.stopPropagation();
                                    const newFields = { ...selectedFields };
                                    delete newFields[field.key];
                                    setSelectedFields(newFields);
                                  }}
                                  className="text-xs text-red-500 hover:text-red-700"
                                >
                                  ✕
                                </button>
                              )}
                            </div>
                            {selected ? (
                              field.key === 'imageUrl' ? (
                                <div className="flex items-center gap-2">
                                  <img
                                    src={selected.value}
                                    alt="Product"
                                    className="w-10 h-10 object-contain rounded border"
                                    onError={(e) => { e.currentTarget.style.display = 'none'; }}
                                  />
                                  <span className="text-xs text-gray-500 truncate max-w-[120px]">
                                    {selected.value.split('/').pop()?.substring(0, 20)}...
                                  </span>
                                </div>
                              ) : (
                                <p className={`text-sm font-semibold ${selected.autoDetected ? 'text-blue-800' : 'text-green-800'}`}>
                                  {field.key === 'ingredients'
                                    ? (selected.value.length > 40 ? selected.value.substring(0, 40) + '...' : selected.value)
                                    : selected.value}
                                  {field.unit && <span className={`ml-1 ${selected.autoDetected ? 'text-blue-600' : 'text-green-600'}`}>{field.unit}</span>}
                                </p>
                              )
                            ) : isActive ? (
                              <p className="text-xs text-orange-600 font-medium">← Click on page</p>
                            ) : (
                              <p className="text-xs text-gray-400 italic">Click to select</p>
                            )}
                          </div>
                        );
                      })}
                    </div>

                    {/* Quick tip */}
                    <div className="p-2 bg-gray-50 border-t border-gray-200 text-xs text-gray-600">
                      💡 Auto-detected values shown in blue. Click to change.
                    </div>
                  </div>
                </div>
              )}

              {/* Index Selector & Apply Button */}
              {Object.keys(selectedFields).length > 0 && (
                <div className="space-y-3">
                  {/* Target Index Selector */}
                  <div className="p-3 bg-indigo-50 rounded-xl border border-indigo-200">
                    <label className="block text-sm font-medium text-indigo-800 mb-2">
                      💾 Save to Index:
                    </label>
                    <select
                      value={targetIndex}
                      onChange={(e) => setTargetIndex(e.target.value as SaveIndexName)}
                      className="w-full px-3 py-2 text-sm border border-indigo-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 bg-white"
                    >
                      {SAVE_INDICES.map((idx) => (
                        <option key={idx.value} value={idx.value}>
                          {idx.label} - {idx.description}
                        </option>
                      ))}
                    </select>
                    {currentIndex && currentIndex !== targetIndex && (
                      <p className="text-xs text-amber-600 mt-1">
                        ⚠️ Currently in "{currentIndex}" - will save to "{targetIndex}"
                      </p>
                    )}
                  </div>

                  {/* Apply Button */}
                  <button
                    onClick={applyVisualSelections}
                    className="w-full py-4 bg-gradient-to-r from-green-500 to-emerald-600 text-white font-medium rounded-xl hover:from-green-600 hover:to-emerald-700 transition-all flex items-center justify-center gap-2 shadow-lg"
                  >
                    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                    </svg>
                    Apply {Object.keys(selectedFields).length} Values to {SAVE_INDICES.find(i => i.value === targetIndex)?.label || targetIndex}
                  </button>
                </div>
              )}
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

// Editable Field Component
const EditableField: React.FC<{
  label: string;
  value: string;
  onChange: (value: string) => void;
  multiline?: boolean;
}> = ({ label, value, onChange, multiline }) => (
  <div className={multiline ? 'col-span-2' : ''}>
    <label className="block text-xs font-medium text-gray-500 mb-1">{label}</label>
    {multiline ? (
      <textarea
        value={value}
        onChange={(e) => onChange(e.target.value)}
        rows={2}
        className="w-full px-3 py-2 text-sm border border-gray-200 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
      />
    ) : (
      <input
        type="text"
        value={value}
        onChange={(e) => onChange(e.target.value)}
        className="w-full px-3 py-2 text-sm border border-gray-200 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
      />
    )}
  </div>
);

// Nutrition Field Component with color coding
const NutritionField: React.FC<{
  label: string;
  unit: string;
  value: string;
  onChange: (value: string) => void;
  color: string;
}> = ({ label, unit, value, onChange, color }) => (
  <div>
    <label className={`block text-xs font-medium mb-1 px-2 py-0.5 rounded-full inline-block ${color}`}>
      {label}
    </label>
    <div className="flex items-center gap-1">
      <input
        type="number"
        step="0.1"
        value={value}
        onChange={(e) => onChange(e.target.value)}
        className="w-full px-3 py-2 text-sm border border-gray-200 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
      />
      <span className="text-xs text-gray-500 min-w-[24px]">{unit}</span>
    </div>
  </div>
);

export default ScraperPanel;
