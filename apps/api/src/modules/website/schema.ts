import { z } from 'zod';

const navChildSchema = z.object({
  label: z.string().min(1),
  href: z.string().min(1),
});

const navItemSchema = z.object({
  label: z.string().min(1),
  href: z.string().min(1),
  children: z.array(navChildSchema).optional(),
});

const socialSchema = z.object({
  label: z.string().min(1),
  href: z.string().min(1),
  icon: z.enum(['facebook', 'instagram', 'youtube']),
});

const eventSchema = z.object({
  title: z.string().min(1),
  date: z.string().min(1),
  time: z.string().min(1),
  image: z.string().optional().default(''),
});

const mediaItemSchema = z.object({
  id: z.string().min(1),
  title: z.string().min(1),
  image: z.string().optional().default(''),
});

const linkSchema = z.object({
  label: z.string().min(1),
  href: z.string().min(1),
});

export const websiteContentSchema = z.object({
  brand: z.string().min(1),
  logoLabel: z.string().min(1),
  logoUrl: z.string().optional().default('/logo.png'),
  fullName: z.string().min(1),
  about: z.string().min(1),
  nav: z.array(navItemSchema).min(1),
  social: z.array(socialSchema),
  series: z.object({
    title: z.string().min(1),
    subtitle: z.string().min(1),
    caption: z.string().min(1),
    image: z.string().optional().default(''),
  }),
  events: z.array(eventSchema),
  weeklyWord: z.object({
    text: z.string().min(1),
    reference: z.string().min(1),
  }),
  news: z.array(mediaItemSchema),
  streams: z.array(mediaItemSchema),
  faith: z.object({
    titlePrefix: z.string().min(1),
    titleAccent: z.string().min(1),
    paragraphs: z.array(z.string().min(1)).min(1),
  }),
  leadership: z.object({
    titlePrefix: z.string().min(1),
    titleAccent: z.string().min(1),
    name: z.string().min(1),
    role: z.string().min(1),
    image: z.string().min(1),
    bio: z.string().min(1),
  }),
  usefulLinks: z.array(linkSchema),
  address: z.object({
    line: z.string().min(1),
    email: z.string().email(),
    emailHref: z.string().min(1),
    mapUrl: z.string().min(1),
    mapEmbed: z.string().min(1),
  }),
});

export type WebsiteContentPayload = z.infer<typeof websiteContentSchema>;
