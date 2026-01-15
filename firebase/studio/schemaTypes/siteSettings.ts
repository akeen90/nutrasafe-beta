import {defineField, defineType} from 'sanity'

export default defineType({
  name: 'siteSettings',
  title: 'Site Settings',
  type: 'document',
  fields: [
    defineField({
      name: 'siteName',
      title: 'Site Name',
      type: 'string',
      validation: (Rule) => Rule.required(),
    }),
    defineField({
      name: 'tagline',
      title: 'Tagline',
      type: 'string',
    }),
    defineField({
      name: 'logo',
      title: 'Logo',
      type: 'image',
      options: {
        hotspot: true,
      },
    }),
    defineField({
      name: 'favicon',
      title: 'Favicon',
      type: 'image',
    }),
    defineField({
      name: 'ogImage',
      title: 'Default Social Share Image',
      type: 'image',
      description: 'Default image used when sharing pages on social media',
    }),
    defineField({
      name: 'appStoreUrl',
      title: 'App Store URL',
      type: 'url',
    }),
    defineField({
      name: 'playStoreUrl',
      title: 'Play Store URL',
      type: 'url',
    }),
    defineField({
      name: 'socialLinks',
      title: 'Social Links',
      type: 'object',
      fields: [
        defineField({
          name: 'twitter',
          title: 'Twitter/X URL',
          type: 'url',
        }),
        defineField({
          name: 'instagram',
          title: 'Instagram URL',
          type: 'url',
        }),
        defineField({
          name: 'facebook',
          title: 'Facebook URL',
          type: 'url',
        }),
        defineField({
          name: 'linkedin',
          title: 'LinkedIn URL',
          type: 'url',
        }),
      ],
    }),
    defineField({
      name: 'contactEmail',
      title: 'Contact Email',
      type: 'string',
    }),
    defineField({
      name: 'footerText',
      title: 'Footer Copyright Text',
      type: 'string',
    }),
    defineField({
      name: 'announcement',
      title: 'Announcement Banner',
      type: 'object',
      fields: [
        defineField({
          name: 'enabled',
          title: 'Show Announcement',
          type: 'boolean',
        }),
        defineField({
          name: 'text',
          title: 'Announcement Text',
          type: 'string',
        }),
        defineField({
          name: 'link',
          title: 'Announcement Link',
          type: 'url',
        }),
        defineField({
          name: 'bgColor',
          title: 'Background Colour',
          type: 'string',
          description: 'Hex colour code (e.g., #4CAF50)',
        }),
      ],
    }),
  ],
  preview: {
    select: {
      title: 'siteName',
      media: 'logo',
    },
  },
})
