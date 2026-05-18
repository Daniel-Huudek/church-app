export interface Transaction {
  id: string;
  description: string;
  amount: number;
  type: 'RECEITA' | 'DESPESA';
  status: 'PENDENTE' | 'CONFIRMADO' | 'CANCELADO';
  categoryId: string;
  categoryName: string;
  costCenterId?: string;
  costCenterName?: string;
  paymentMethod?: PaymentMethod;
  date: string;
  dueDate?: string;
  paidAt?: string;
  recurrence?: RecurrenceType;
  recurrenceId?: string;
  documentUrl?: string;
  notes?: string;
  createdById: string;
  createdByName: string;
  approvedById?: string;
  approvedByName?: string;
  approvedAt?: string;
  createdAt: string;
  updatedAt: string;
}

export type PaymentMethod =
  | 'DINHEIRO'
  | 'PIX'
  | 'CARTAO_CREDITO'
  | 'CARTAO_DEBITO'
  | 'BOLETO'
  | 'TRANSFERENCIA'
  | 'DEPOSITO'
  | 'CHEQUE'
  | 'OUTRO';

export type RecurrenceType =
  | 'DIARIO'
  | 'SEMANAL'
  | 'QUINZENAL'
  | 'MENSAL'
  | 'BIMESTRAL'
  | 'TRIMESTRAL'
  | 'SEMESTRAL'
  | 'ANUAL';

export interface TransactionCategory {
  id: string;
  name: string;
  description?: string;
  type: 'RECEITA' | 'DESPESA';
  icon?: string;
  color?: string;
  isActive: boolean;
  order: number;
  createdAt: string;
  updatedAt: string;
}

export interface CostCenter {
  id: string;
  name: string;
  description?: string;
  responsibleId?: string;
  responsibleName?: string;
  budget?: number;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface MonthlyClose {
  id: string;
  referenceDate: string;
  status: 'ABERTO' | 'FECHADO' | 'REABERTO';
  totalRevenue: number;
  totalExpenses: number;
  balance: number;
  transactionCount: number;
  closedById?: string;
  closedByName?: string;
  closedAt?: string;
  notes?: string;
  createdAt: string;
  updatedAt: string;
}

export interface FinanceDashboard {
  balance: number;
  totalRevenue: number;
  totalExpenses: number;
  revenueChange: number;
  expensesChange: number;
  balanceChange: number;
  revenueByCategory: { category: string; amount: number; percentage: number }[];
  expensesByCategory: { category: string; amount: number; percentage: number }[];
  recentTransactions: Transaction[];
  monthlyComparison: {
    month: string;
    revenue: number;
    expenses: number;
    balance: number;
  }[];
  pendingTransactions: number;
  pendingAmount: number;
}

export interface FinanceFilter {
  page?: number;
  limit?: number;
  type?: 'RECEITA' | 'DESPESA';
  status?: 'PENDENTE' | 'CONFIRMADO' | 'CANCELADO';
  categoryId?: string;
  costCenterId?: string;
  startDate?: string;
  endDate?: string;
  minAmount?: number;
  maxAmount?: number;
  paymentMethod?: PaymentMethod;
  search?: string;
  sortBy?: string;
  sortOrder?: 'asc' | 'desc';
}

export interface AuditLog {
  id: string;
  entityType: string;
  entityId: string;
  action: string;
  description: string;
  changes?: Record<string, { old: unknown; new: unknown }>;
  authorId: string;
  authorName: string;
  ipAddress?: string;
  userAgent?: string;
  createdAt: string;
}

export type { PaginatedResponse } from './member';
