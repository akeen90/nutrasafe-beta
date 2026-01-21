/**
 * NutraSafe Cookie Consent Manager
 * GDPR-compliant cookie consent with Firebase logging
 */

(function() {
    'use strict';

    // Configuration
    const CONSENT_KEY = 'nutrasafe_cookie_consent';
    const CONSENT_TIMESTAMP_KEY = 'nutrasafe_consent_timestamp';
    const FIREBASE_PROJECT_ID = 'nutrasafe-705c7';
    const FIRESTORE_URL = `https://firestore.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/databases/(default)/documents/cookie_consents`;

    // Check if consent already given
    const existingConsent = localStorage.getItem(CONSENT_KEY);

    if (existingConsent) {
        // User has already made a choice
        if (existingConsent === 'accepted') {
            loadAnalytics();
        }
        return; // Exit early
    }

    // Create and show consent modal
    createConsentModal();

    function createConsentModal() {
        // Create modal overlay
        const overlay = document.createElement('div');
        overlay.id = 'cookie-consent-overlay';
        overlay.innerHTML = `
            <div id="cookie-consent-modal">
                <div class="consent-header">
                    <h2><img src="/app-icon-2026.png" alt="NutraSafe" class="consent-logo">Cookie Consent</h2>
                </div>
                <div class="consent-body">
                    <p>We use cookies to improve your experience and analyze site traffic. This includes Google Analytics to understand how visitors use our site.</p>
                    <p><strong>Your choice matters:</strong></p>
                    <ul>
                        <li><strong>Accept</strong> - Enable analytics to help us improve</li>
                        <li><strong>Reject</strong> - Browse without tracking (essential cookies only)</li>
                    </ul>
                    <p class="consent-legal">We'll log your choice (anonymized) for compliance purposes. Read our <a href="/privacy-policy.html" target="_blank">Privacy Policy</a> and <a href="/terms-of-service.html" target="_blank">Terms of Service</a> for details.</p>
                </div>
                <div class="consent-actions">
                    <button id="cookie-reject" class="btn-reject">Reject</button>
                    <button id="cookie-accept" class="btn-accept">Accept</button>
                </div>
            </div>
        `;

        // Add styles
        const style = document.createElement('style');
        style.textContent = `
            @import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@500;600;700&family=Inter:wght@400;500;600&display=swap');

            #cookie-consent-overlay {
                position: fixed;
                top: 0;
                left: 0;
                width: 100%;
                height: 100%;
                background: rgba(61, 122, 122, 0.15);
                backdrop-filter: blur(8px);
                z-index: 999999;
                display: flex;
                align-items: center;
                justify-content: center;
                padding: 20px;
                animation: fadeIn 0.3s ease;
            }

            @keyframes fadeIn {
                from { opacity: 0; }
                to { opacity: 1; }
            }

            #cookie-consent-modal {
                background: rgba(255, 255, 255, 0.95);
                backdrop-filter: blur(20px);
                border: 1px solid rgba(255, 255, 255, 0.9);
                border-radius: 20px;
                box-shadow: 0 20px 60px rgba(61, 122, 122, 0.15), 0 8px 24px rgba(0, 0, 0, 0.08);
                max-width: 560px;
                width: 100%;
                padding: 32px;
                animation: slideUp 0.4s ease;
            }

            @keyframes slideUp {
                from {
                    opacity: 0;
                    transform: translateY(20px);
                }
                to {
                    opacity: 1;
                    transform: translateY(0);
                }
            }

            .consent-header h2 {
                margin: 0 0 20px 0;
                font-size: 26px;
                font-weight: 600;
                color: #3d7a7a;
                display: flex;
                align-items: center;
                gap: 12px;
                font-family: 'Playfair Display', Georgia, serif;
            }

            .consent-logo {
                width: 36px;
                height: 36px;
                border-radius: 8px;
            }

            .consent-body {
                color: #4a4a4a;
                line-height: 1.7;
                margin-bottom: 24px;
                font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
            }

            .consent-body p {
                margin: 0 0 16px 0;
            }

            .consent-body ul {
                margin: 0 0 16px 0;
                padding-left: 24px;
            }

            .consent-body li {
                margin: 8px 0;
            }

            .consent-body strong {
                color: #1a1a1a;
            }

            .consent-legal {
                font-size: 13px;
                color: #7a7a7a;
                border-top: 1px solid rgba(61, 122, 122, 0.15);
                padding-top: 16px;
                margin-top: 16px;
            }

            .consent-legal a {
                color: #3d7a7a;
                text-decoration: none;
                border-bottom: 1px solid transparent;
                transition: border-color 0.2s;
            }

            .consent-legal a:hover {
                border-bottom-color: #3d7a7a;
            }

            .consent-actions {
                display: flex;
                gap: 12px;
            }

            .consent-actions button {
                flex: 1;
                padding: 14px 24px;
                border: none;
                border-radius: 12px;
                font-size: 16px;
                font-weight: 600;
                cursor: pointer;
                transition: all 0.2s ease;
                font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
            }

            .btn-reject {
                background: rgba(61, 122, 122, 0.08);
                color: #4a4a4a;
                border: 1px solid rgba(61, 122, 122, 0.2);
            }

            .btn-reject:hover {
                background: rgba(61, 122, 122, 0.12);
                border-color: rgba(61, 122, 122, 0.3);
                transform: translateY(-1px);
            }

            .btn-accept {
                background: linear-gradient(135deg, #3d7a7a 0%, #5a9a9a 100%);
                color: white;
                box-shadow: 0 4px 14px rgba(61, 122, 122, 0.3);
            }

            .btn-accept:hover {
                transform: translateY(-2px);
                box-shadow: 0 6px 20px rgba(61, 122, 122, 0.4);
            }

            .btn-accept:active,
            .btn-reject:active {
                transform: translateY(0);
            }

            @media (max-width: 600px) {
                #cookie-consent-modal {
                    padding: 24px;
                }

                .consent-header h2 {
                    font-size: 22px;
                }

                .consent-actions {
                    flex-direction: column;
                }
            }
        `;

        document.head.appendChild(style);
        document.body.appendChild(overlay);

        // Attach event listeners
        document.getElementById('cookie-accept').addEventListener('click', () => handleConsent(true));
        document.getElementById('cookie-reject').addEventListener('click', () => handleConsent(false));

        // Prevent scrolling while modal is open
        document.body.style.overflow = 'hidden';
    }

    function handleConsent(accepted) {
        const choice = accepted ? 'accepted' : 'rejected';
        const timestamp = new Date().toISOString();

        // Store in localStorage
        localStorage.setItem(CONSENT_KEY, choice);
        localStorage.setItem(CONSENT_TIMESTAMP_KEY, timestamp);

        // Log to Firebase
        logConsentToFirebase(choice, timestamp);

        // Load analytics if accepted
        if (accepted) {
            loadAnalytics();
        }

        // Remove modal
        removeConsentModal();

        // Re-enable scrolling
        document.body.style.overflow = '';

        console.log(`✅ Cookie consent: ${choice}`);
    }

    async function logConsentToFirebase(choice, timestamp) {
        try {
            const consentData = {
                fields: {
                    choice: { stringValue: choice },
                    timestamp: { timestampValue: timestamp },
                    userAgent: { stringValue: navigator.userAgent },
                    anonymizedIp: { stringValue: await getAnonymizedIP() },
                    page: { stringValue: window.location.pathname },
                    referrer: { stringValue: document.referrer || 'direct' }
                }
            };

            const response = await fetch(FIRESTORE_URL, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(consentData)
            });

            if (response.ok) {
                console.log('✅ Consent logged to Firebase');
            } else {
                console.warn('⚠️ Failed to log consent:', response.status);
            }
        } catch (error) {
            console.error('❌ Error logging consent:', error);
            // Non-blocking - continue even if logging fails
        }
    }

    async function getAnonymizedIP() {
        try {
            // Use a public IP service with short timeout
            const controller = new AbortController();
            const timeoutId = setTimeout(() => controller.abort(), 2000);

            const response = await fetch('https://api.ipify.org?format=json', {
                signal: controller.signal
            });
            clearTimeout(timeoutId);

            const data = await response.json();
            const ip = data.ip;

            // Anonymize IP (remove last octet for IPv4, last 80 bits for IPv6)
            if (ip.includes('.')) {
                // IPv4: 192.168.1.100 → 192.168.1.0
                return ip.split('.').slice(0, 3).join('.') + '.0';
            } else if (ip.includes(':')) {
                // IPv6: anonymize by keeping first 48 bits
                const parts = ip.split(':');
                return parts.slice(0, 3).join(':') + ':0000:0000:0000:0000';
            }
            return 'unknown';
        } catch (error) {
            // If IP fetch fails, continue without it
            return 'unavailable';
        }
    }

    function loadAnalytics() {
        // Load Google Analytics
        if (typeof gtag === 'undefined') {
            // Create gtag script
            const gtagScript = document.createElement('script');
            gtagScript.async = true;
            gtagScript.src = 'https://www.googletagmanager.com/gtag/js?id=G-YZNJZ4C1MV';
            document.head.appendChild(gtagScript);

            // Initialize gtag
            window.dataLayer = window.dataLayer || [];
            function gtag(){dataLayer.push(arguments);}
            window.gtag = gtag;
            gtag('js', new Date());
            gtag('config', 'G-YZNJZ4C1MV', {
                anonymize_ip: true, // GDPR compliance
                cookie_flags: 'SameSite=None;Secure'
            });

            console.log('✅ Google Analytics loaded (with consent)');
        }
    }

    function removeConsentModal() {
        const overlay = document.getElementById('cookie-consent-overlay');
        if (overlay) {
            overlay.style.animation = 'fadeOut 0.3s ease';
            setTimeout(() => overlay.remove(), 300);
        }
    }

    // Add fadeOut animation
    const fadeOutStyle = document.createElement('style');
    fadeOutStyle.textContent = `
        @keyframes fadeOut {
            from { opacity: 1; }
            to { opacity: 0; }
        }
    `;
    document.head.appendChild(fadeOutStyle);

})();
