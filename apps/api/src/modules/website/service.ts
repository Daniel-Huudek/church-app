import { Prisma, PrismaClient } from '@prisma/client';
import { websiteContentSchema, type WebsiteContentPayload } from './schema.js';
import { DEFAULT_WEBSITE_CONTENT } from './defaults.js';

const SINGLETON_ID = 'default';

export class WebsiteService {
  constructor(private prisma: PrismaClient) {}

  async getPublic(): Promise<{ content: WebsiteContentPayload; updatedAt: string | null }> {
    const row = await this.prisma.websiteContent.findUnique({ where: { id: SINGLETON_ID } });
    if (!row) {
      return { content: DEFAULT_WEBSITE_CONTENT, updatedAt: null };
    }

    const parsed = websiteContentSchema.safeParse(row.content);
    return {
      content: parsed.success ? parsed.data : DEFAULT_WEBSITE_CONTENT,
      updatedAt: row.updatedAt.toISOString(),
    };
  }

  async upsert(content: WebsiteContentPayload, updatedBy?: string) {
    const validated = websiteContentSchema.parse(content);
    const row = await this.prisma.websiteContent.upsert({
      where: { id: SINGLETON_ID },
      create: {
        id: SINGLETON_ID,
        content: validated as Prisma.InputJsonValue,
        updatedBy: updatedBy ?? null,
      },
      update: {
        content: validated as Prisma.InputJsonValue,
        updatedBy: updatedBy ?? null,
      },
    });

    return {
      content: validated,
      updatedAt: row.updatedAt.toISOString(),
      updatedBy: row.updatedBy,
    };
  }
}
