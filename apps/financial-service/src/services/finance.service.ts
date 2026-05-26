import { PrismaClient, TransactionType, TransactionStatus } from '@prisma/client';
import { NotFoundError, BadRequestError, ForbiddenError } from '@church-app/shared';
import fs from 'fs/promises';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const UPLOADS_DIR = path.join(__dirname, '../../uploads');

interface PaginatedResult<T> {
  data: T[];
  total: number;
  page: number;
  limit: number;
  totalPages: number;
}

export class FinanceService {
  constructor(private prisma: PrismaClient) {}

  // Transactions
  async findAllTransactions({ page = 1, limit = 20, type, status, categoryId, costCenterId, startDate, endDate, search }: {
    page?: number; limit?: number; type?: string; status?: string;
    categoryId?: string; costCenterId?: string; startDate?: string; endDate?: string; search?: string;
  }) {
    const where: any = { deletedAt: null };
    if (type) where.type = type;
    if (status) where.status = status;
    if (categoryId) where.categoryId = categoryId;
    if (costCenterId) where.costCenterId = costCenterId;
    if (startDate || endDate) {
      where.date = {};
      if (startDate) where.date.gte = new Date(startDate);
      if (endDate) where.date.lte = new Date(endDate);
    }
    if (search) {
      where.OR = [
        { description: { contains: search, mode: 'insensitive' as const } },
        { notes: { contains: search, mode: 'insensitive' as const } },
      ];
    }

    const skip = (page - 1) * limit;
    const [data, total] = await Promise.all([
      this.prisma.transaction.findMany({
        skip, take: limit, where,
        include: { category: true, costCenter: true, attachments: true },
        orderBy: [{ date: 'desc' }, { createdAt: 'desc' }],
      }),
      this.prisma.transaction.count({ where }),
    ]);
    return { success: true, data: { data, total, page, limit, totalPages: Math.ceil(total / limit) } };
  }

  async findTransactionById(id: string) {
    const data = await this.prisma.transaction.findFirst({
      where: { id, deletedAt: null },
      include: { category: true, costCenter: true, attachments: true, auditLogs: { orderBy: { createdAt: 'desc' } } },
    });
    if (!data) throw new NotFoundError('Transaction not found');
    return { success: true, data };
  }

  async createTransaction(body: any, userId: string, userRole: string) {
    const data = await this.prisma.transaction.create({
      data: {
        type: body.type,
        value: body.value,
        description: body.description,
        date: new Date(body.date),
        dueDate: body.dueDate ? new Date(body.dueDate) : undefined,
        paymentDate: body.paymentDate ? new Date(body.paymentDate) : undefined,
        categoryId: body.categoryId,
        costCenterId: body.costCenterId,
        createdById: userId,
        createdByRole: userRole,
        status: body.status || 'PENDING',
        paymentMethod: body.paymentMethod,
        isRecurring: body.isRecurring || false,
        recurrenceRule: body.recurrenceRule,
        notes: body.notes,
      },
      include: { category: true, costCenter: true },
    });
    await this.createAuditLog(data.id, 'CREATED', null, data, userId, userRole);
    return { success: true, data };
  }

  async updateTransaction(id: string, body: any, userId: string, userRole: string) {
    const existing = await this.prisma.transaction.findFirst({ where: { id, deletedAt: null } });
    if (!existing) throw new NotFoundError('Transaction not found');

    const data = await this.prisma.transaction.update({
      where: { id },
      data: {
        ...body,
        date: body.date ? new Date(body.date) : undefined,
        dueDate: body.dueDate ? new Date(body.dueDate) : undefined,
        paymentDate: body.paymentDate ? new Date(body.paymentDate) : undefined,
      },
      include: { category: true, costCenter: true },
    });
    await this.createAuditLog(id, 'UPDATED', existing, data, userId, userRole);
    return { success: true, data };
  }

  async deleteTransaction(id: string, userId: string, userRole: string) {
    const existing = await this.prisma.transaction.findFirst({ where: { id, deletedAt: null } });
    if (!existing) throw new NotFoundError('Transaction not found');
    await this.prisma.transaction.update({ where: { id }, data: { deletedAt: new Date() } });
    await this.createAuditLog(id, 'DELETED', existing, null, userId, userRole);
    return { success: true };
  }

  async confirmTransaction(id: string, userId: string, userRole: string) {
    const existing = await this.prisma.transaction.findFirst({ where: { id, deletedAt: null } });
    if (!existing) throw new NotFoundError('Transaction not found');
    const data = await this.prisma.transaction.update({
      where: { id },
      data: { status: 'CONFIRMED', paymentDate: new Date() },
    });
    await this.createAuditLog(id, 'CONFIRMED', existing, data, userId, userRole);
    return { success: true, data };
  }

  async cancelTransaction(id: string, userId: string, userRole: string) {
    const existing = await this.prisma.transaction.findFirst({ where: { id, deletedAt: null } });
    if (!existing) throw new NotFoundError('Transaction not found');
    const data = await this.prisma.transaction.update({ where: { id }, data: { status: 'CANCELLED' } });
    await this.createAuditLog(id, 'CANCELLED', existing, data, userId, userRole);
    return { success: true, data };
  }

  // Attachments
  async addAttachment(transactionId: string, file: { filename: string; buffer: Buffer; mimetype: string }, userId: string) {
    const transaction = await this.prisma.transaction.findFirst({ where: { id: transactionId, deletedAt: null } });
    if (!transaction) throw new NotFoundError('Transaction not found');

    await fs.mkdir(UPLOADS_DIR, { recursive: true });
    const savedName = `finance-${transactionId}-${Date.now()}${path.extname(file.filename)}`;
    const filePath = path.join(UPLOADS_DIR, savedName);
    await fs.writeFile(filePath, file.buffer);

    const data = await this.prisma.attachment.create({
      data: {
        transactionId,
        filename: savedName,
        originalName: file.filename,
        mimeType: file.mimetype,
        size: file.buffer.length,
        url: `/uploads/${savedName}`,
        type: 'OTHER',
      },
    });
    return { success: true, data };
  }

  // Dashboard
  async getDashboard() {
    const now = new Date();
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
    const endOfMonth = new Date(now.getFullYear(), now.getMonth() + 1, 0);

    const [balanceResult, incomeResult, expenseResult, incomeByCategory, expenseByCategory, monthlyHistory] = await Promise.all([
      this.getBalance(),
      this.getTotalByType('INCOME', startOfMonth, endOfMonth),
      this.getTotalByType('EXPENSE', startOfMonth, endOfMonth),
      this.getSumByCategory('INCOME', startOfMonth, endOfMonth),
      this.getSumByCategory('EXPENSE', startOfMonth, endOfMonth),
      this.getMonthlyHistory(6),
    ]);

    return {
      success: true,
      data: {
        balance: balanceResult.balance,
        totalIncome: incomeResult,
        totalExpense: expenseResult,
        incomeByCategory,
        expenseByCategory,
        monthlyHistory,
      },
    };
  }

  async getBalance() {
    const confirmedIncome = await this.prisma.transaction.aggregate({
      where: { deletedAt: null, status: 'CONFIRMED', type: { in: ['INCOME', 'TITHE', 'OFFERING'] } },
      _sum: { value: true },
    });
    const confirmedExpense = await this.prisma.transaction.aggregate({
      where: { deletedAt: null, status: 'CONFIRMED', type: 'EXPENSE' },
      _sum: { value: true },
    });
    const income = Number(confirmedIncome._sum.value || 0);
    const expense = Number(confirmedExpense._sum.value || 0);
    return { income, expense, balance: income - expense };
  }

  async getCashFlow() {
    const transactions = await this.prisma.transaction.findMany({
      where: { deletedAt: null, status: 'CONFIRMED' },
      orderBy: { date: 'asc' },
    });
    let runningBalance = 0;
    const flow = transactions.map((t) => {
      const isIncome = ['INCOME', 'TITHE', 'OFFERING'].includes(t.type);
      const value = Number(t.value);
      runningBalance += isIncome ? value : -value;
      return {
        id: t.id,
        date: t.date,
        description: t.description,
        type: t.type,
        value: isIncome ? value : -value,
        balance: runningBalance,
      };
    });
    return { success: true, data: flow };
  }

  // Reports
  async getMonthlyReport(year: number, month: number) {
    const startDate = new Date(year, month - 1, 1);
    const endDate = new Date(year, month, 0);

    const [income, expense, tithes, offerings, byCategory, byCostCenter] = await Promise.all([
      this.getTotalByType('INCOME', startDate, endDate),
      this.getTotalByType('EXPENSE', startDate, endDate),
      this.getTotalByType('TITHE', startDate, endDate),
      this.getTotalByType('OFFERING', startDate, endDate),
      this.getSumByCategory(null, startDate, endDate),
      this.getSumByCostCenter(startDate, endDate),
    ]);

    return {
      success: true,
      data: {
        period: `${year}-${String(month).padStart(2, '0')}`,
        income,
        expense,
        tithes,
        offerings,
        balance: income - expense,
        byCategory,
        byCostCenter,
      },
    };
  }

  // Monthly Close
  async createMonthlyClose(referenceDate: string, userId: string, userRole: string, notes?: string) {
    const date = new Date(referenceDate);
    const startOfMonth = new Date(date.getFullYear(), date.getMonth(), 1);
    const endOfMonth = new Date(date.getFullYear(), date.getMonth() + 1, 0);

    const income = await this.getTotalByType('INCOME', startOfMonth, endOfMonth);
    const expense = await this.getTotalByType('EXPENSE', startOfMonth, endOfMonth);
    const balance = income - expense;

    const existing = await this.prisma.monthlyClose.findUnique({ where: { referenceDate: startOfMonth } });
    if (existing && existing.status === 'CLOSED') {
      throw new BadRequestError('This month is already closed');
    }

    const data = await this.prisma.monthlyClose.upsert({
      where: { referenceDate: startOfMonth },
      create: {
        referenceDate: startOfMonth,
        totalIncome: income,
        totalExpense: expense,
        balance,
        closedById: userId,
        closedByRole: userRole,
        status: 'CLOSED',
        notes,
      },
      update: {
        totalIncome: income,
        totalExpense: expense,
        balance,
        closedById: userId,
        closedByRole: userRole,
        status: 'CLOSED',
        closedAt: new Date(),
        notes,
      },
    });

    return { success: true, data };
  }

  async getMonthlyCloses() {
    const data = await this.prisma.monthlyClose.findMany({ orderBy: { referenceDate: 'desc' } });
    return { success: true, data };
  }

  // Categories
  async findAllCategories() {
    const data = await this.prisma.transactionCategory.findMany({
      include: { _count: { select: { transactions: true } } },
    });
    return { success: true, data };
  }

  async createCategory(body: { name: string; type: string; description?: string; color?: string }) {
    const data = await this.prisma.transactionCategory.create({ data: body as any });
    return { success: true, data };
  }

  async updateCategory(id: string, body: any) {
    const data = await this.prisma.transactionCategory.update({ where: { id }, data: body });
    return { success: true, data };
  }

  // Cost Centers
  async findAllCostCenters() {
    const data = await this.prisma.costCenter.findMany({
      include: { _count: { select: { transactions: true } } },
    });
    return { success: true, data };
  }

  async createCostCenter(body: { name: string; description?: string; budget?: number }) {
    const data = await this.prisma.costCenter.create({ data: body as any });
    return { success: true, data };
  }

  async updateCostCenter(id: string, body: any) {
    const data = await this.prisma.costCenter.update({ where: { id }, data: body });
    return { success: true, data };
  }

  // Audit
  async getAuditLogs({ page = 1, limit = 20, transactionId }: { page?: number; limit?: number; transactionId?: string }) {
    const where: any = {};
    if (transactionId) where.transactionId = transactionId;
    const skip = (page - 1) * limit;
    const [data, total] = await Promise.all([
      this.prisma.financialAuditLog.findMany({
        skip, take: limit, where,
        include: { transaction: { select: { id: true, description: true, value: true } } },
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.financialAuditLog.count({ where }),
    ]);
    return { success: true, data: { data, total, page, limit, totalPages: Math.ceil(total / limit) } };
  }

  // Private helpers
  private async createAuditLog(transactionId: string, action: string, oldValue: any, newValue: any, changedById: string, changedByRole?: string) {
    await this.prisma.financialAuditLog.create({
      data: { transactionId, action, changedById, changedByRole, oldValue, newValue },
    });
  }

  private async getTotalByType(type: string, startDate: Date, endDate: Date): Promise<number> {
    const result = await this.prisma.transaction.aggregate({
      where: {
        deletedAt: null,
        status: 'CONFIRMED',
        type: type as TransactionType,
        date: { gte: startDate, lte: endDate },
      },
      _sum: { value: true },
    });
    return Number(result._sum.value || 0);
  }

  private async getSumByCategory(type: string | null, startDate: Date, endDate: Date): Promise<{ category: string; value: number }[]> {
    const where: any = { deletedAt: null, status: 'CONFIRMED', date: { gte: startDate, lte: endDate } };
    if (type) where.type = type as TransactionType;
    const results = await this.prisma.transaction.groupBy({
      by: ['categoryId'],
      where,
      _sum: { value: true },
    });
    const categories = await this.prisma.transactionCategory.findMany();
    const categoryMap = new Map(categories.map((c) => [c.id, c.name]));
    return results.map((r) => ({
      category: categoryMap.get(r.categoryId || '') || 'Sem categoria',
      value: Number(r._sum.value || 0),
    }));
  }

  private async getSumByCostCenter(startDate: Date, endDate: Date): Promise<{ center: string; value: number }[]> {
    const results = await this.prisma.transaction.groupBy({
      by: ['costCenterId'],
      where: { deletedAt: null, status: 'CONFIRMED', date: { gte: startDate, lte: endDate } },
      _sum: { value: true },
    });
    const centers = await this.prisma.costCenter.findMany();
    const centerMap = new Map(centers.map((c) => [c.id, c.name]));
    return results.map((r) => ({
      center: centerMap.get(r.costCenterId || '') || 'Sem centro de custo',
      value: Number(r._sum.value || 0),
    }));
  }

  private async getMonthlyHistory(months: number): Promise<{ month: string; income: number; expense: number; balance: number }[]> {
    const history = [];
    for (let i = 0; i < months; i++) {
      const now = new Date();
      const startDate = new Date(now.getFullYear(), now.getMonth() - i, 1);
      const endDate = new Date(now.getFullYear(), now.getMonth() - i + 1, 0);
      const income = await this.getTotalByType('INCOME', startDate, endDate);
      const expense = await this.getTotalByType('EXPENSE', startDate, endDate);
      history.push({
        month: `${startDate.getFullYear()}-${String(startDate.getMonth() + 1).padStart(2, '0')}`,
        income,
        expense,
        balance: income - expense,
      });
    }
    return history;
  }
}
