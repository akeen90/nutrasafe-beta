/**
 * Sanity Client for NutraSafe Website
 * Fetches content from Sanity CMS
 */

const SANITY_PROJECT_ID = 'fyezlg0y';
const SANITY_DATASET = 'production';
const SANITY_API_VERSION = '2024-01-01';

// Sanity CDN URL for queries
const SANITY_CDN_URL = `https://${SANITY_PROJECT_ID}.api.sanity.io/v${SANITY_API_VERSION}/data/query/${SANITY_DATASET}`;

// Sanity image URL builder
function sanityImageUrl(imageRef, options = {}) {
    if (!imageRef || !imageRef.asset) return '';

    // Extract image ID from reference
    const ref = imageRef.asset._ref || imageRef.asset._id;
    if (!ref) return '';

    // Parse the reference: image-{id}-{width}x{height}-{format}
    const [, id, dimensions, format] = ref.split('-');
    if (!id) return '';

    let url = `https://cdn.sanity.io/images/${SANITY_PROJECT_ID}/${SANITY_DATASET}/${id}-${dimensions}.${format}`;

    // Add image transformations
    const params = [];
    if (options.width) params.push(`w=${options.width}`);
    if (options.height) params.push(`h=${options.height}`);
    if (options.quality) params.push(`q=${options.quality}`);
    if (options.fit) params.push(`fit=${options.fit}`);
    if (options.format) params.push(`fm=${options.format}`);
    if (options.blur) params.push(`blur=${options.blur}`);

    // Auto format for best compression
    if (!options.format) params.push('auto=format');

    if (params.length > 0) {
        url += '?' + params.join('&');
    }

    return url;
}

// Fetch data from Sanity
async function sanityFetch(query, params = {}) {
    try {
        // Encode the query
        let url = `${SANITY_CDN_URL}?query=${encodeURIComponent(query)}`;

        // Add parameters
        Object.keys(params).forEach(key => {
            url += `&$${key}="${encodeURIComponent(params[key])}"`;
        });

        const response = await fetch(url);
        if (!response.ok) {
            throw new Error(`Sanity fetch failed: ${response.status}`);
        }

        const data = await response.json();
        return data.result;
    } catch (error) {
        console.error('Sanity fetch error:', error);
        return null;
    }
}

// Get site settings
async function getSiteSettings() {
    const query = `*[_type == "siteSettings"][0]`;
    return await sanityFetch(query);
}

// Get all FAQs grouped by category
async function getFAQs() {
    const query = `*[_type == "faq"] | order(category asc, order asc) {
        _id,
        question,
        answer,
        category,
        order,
        isPopular
    }`;
    return await sanityFetch(query);
}

// Get FAQs by category
async function getFAQsByCategory(category) {
    const query = `*[_type == "faq" && category == $category] | order(order asc) {
        _id,
        question,
        answer,
        order,
        isPopular
    }`;
    return await sanityFetch(query, { category });
}

// Get a page by slug
async function getPage(slug) {
    const query = `*[_type == "page" && slug.current == $slug][0] {
        _id,
        title,
        slug,
        metaTitle,
        metaDescription,
        heroSection,
        features,
        contentSections,
        screenshots
    }`;
    return await sanityFetch(query, { slug });
}

// Get all pages (for navigation/sitemap)
async function getAllPages() {
    const query = `*[_type == "page"] | order(title asc) {
        _id,
        title,
        slug,
        metaTitle
    }`;
    return await sanityFetch(query);
}

// Get media images by category
async function getMediaByCategory(category) {
    const query = `*[_type == "mediaImage" && category == $category] | order(title asc) {
        _id,
        title,
        image,
        alt,
        caption,
        tags
    }`;
    return await sanityFetch(query, { category });
}

// Get all app screenshots
async function getAppScreenshots() {
    return await getMediaByCategory('screenshots');
}

// Get blog posts
async function getBlogPosts(limit = 10) {
    const query = `*[_type == "blogPost" && isPublished == true] | order(publishedAt desc)[0...${limit}] {
        _id,
        title,
        slug,
        author,
        publishedAt,
        featuredImage,
        excerpt,
        categories
    }`;
    return await sanityFetch(query);
}

// Get a single blog post by slug
async function getBlogPost(slug) {
    const query = `*[_type == "blogPost" && slug.current == $slug][0] {
        _id,
        title,
        slug,
        author,
        publishedAt,
        featuredImage,
        excerpt,
        body,
        categories,
        metaDescription
    }`;
    return await sanityFetch(query, { slug });
}

// Convert Sanity block content to HTML
function blocksToHtml(blocks) {
    if (!blocks || !Array.isArray(blocks)) return '';

    return blocks.map(block => {
        if (block._type !== 'block') {
            // Handle images or other types
            if (block._type === 'image') {
                const url = sanityImageUrl(block, { width: 800 });
                const alt = block.alt || '';
                const caption = block.caption || '';
                return `<figure><img src="${url}" alt="${alt}" loading="lazy"><figcaption>${caption}</figcaption></figure>`;
            }
            return '';
        }

        const style = block.style || 'normal';
        const children = block.children || [];

        let text = children.map(child => {
            let content = child.text || '';

            // Apply marks (bold, italic, etc.)
            if (child.marks && child.marks.length > 0) {
                child.marks.forEach(mark => {
                    if (mark === 'strong') content = `<strong>${content}</strong>`;
                    if (mark === 'em') content = `<em>${content}</em>`;
                    if (mark === 'code') content = `<code>${content}</code>`;
                    if (mark === 'underline') content = `<u>${content}</u>`;
                });
            }

            return content;
        }).join('');

        // Wrap in appropriate HTML tag
        switch (style) {
            case 'h1': return `<h1>${text}</h1>`;
            case 'h2': return `<h2>${text}</h2>`;
            case 'h3': return `<h3>${text}</h3>`;
            case 'h4': return `<h4>${text}</h4>`;
            case 'blockquote': return `<blockquote>${text}</blockquote>`;
            default: return `<p>${text}</p>`;
        }
    }).join('\n');
}

// Export for use in pages
window.SanityClient = {
    fetch: sanityFetch,
    imageUrl: sanityImageUrl,
    getSiteSettings,
    getFAQs,
    getFAQsByCategory,
    getPage,
    getAllPages,
    getMediaByCategory,
    getAppScreenshots,
    getBlogPosts,
    getBlogPost,
    blocksToHtml
};
