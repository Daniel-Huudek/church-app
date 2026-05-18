import type {
  Transaction,
  TransactionCategory,
  CostCenter,
  MonthlyClose,
  FinanceDashboard,
  FinanceFilter,
  AuditLog,
  PaginatedResponse,
} from '../types/finance';
import { api } from './api';

interface ApiResponse<T> {
  success: boolean;
  data: T;
}

export const financeKeys = {
  all: ['finance'] as const,
  transactions: () => [...financeKeys.all, 'transactions'] as const,
  transactionList: (filters: FinanceFilter) => [...financeKeys.transactions(), 'list', filters] as const,
  transactionDetail: (id: string) => [...financeKeys.transactions(), 'detail', id] as const,
  dashboard: () => [...financeKeys.all, 'dashboard'] as const,
  balance: () => [...financeKeys.all, 'balance'] as const,
  cashFlow: () => [...financeKeys.all, 'cashFlow'] as const,
  categories: () => [...financeKeys.all, 'categories'] as const,
  costCenters: () => [...financeKeys.all, 'costCenters'] as const,
  monthlyCloses: () => [...financeKeys.all, 'monthlyCloses'] as const,
  reports: () => [...financeKeys.all, 'reports'] as const,
  monthlyReport: (year: number, month: number) => [...financeKeys.reports(), year, month] as const,
  auditLogs: (page: number) => [...financeKeys.all, 'audit', page] as const,
};

export const financeService = {
  getTransactions: async (filters?: FinanceFilter): Promise<PaginatedResponse<Transaction>> => {
    const response = await api.get<ApiResponse<PaginatedResponse<Transaction>>>(
      '/finance/transactions',
      { params: filters }
    );
    return response.data.data;
  },

  getTransaction: async (id: string): Promise<Transaction> => {
    const response = await api.get<ApiResponse<Transaction>>(`/finance/transactions/${id}`);
    return response.data.data;
  },

  createTransaction: async (data: Partial<Transaction>): Promise<Transaction> => {
    const response = await api.post<ApiResponse<Transaction>>('/finance/transactions', data);
    return response.data.data;
  },

  updateTransaction: async (id: string, data: Partial<Transaction>): Promise<Transaction> => {
    const response = await api.put<ApiResponse<Transaction>>(`/finance/transactions/${id}`, data);
    return response.data.data;
  },

  deleteTransaction: async (id: string): Promise<void> => {
    await api.delete(`/finance/transactions/${id}`);
  },

  confirmTransaction: async (id: string): Promise<Transaction> => {
    const response = await api.post<ApiResponse<Transaction>>(`/finance/transactions/${id}/confirm`);
    return response.data.data;
  },

  cancelTransaction: async (id: string): Promise<Transaction> => {
    const response = await api.post<ApiResponse<Transaction>>(`/finance/transactions/${id}/cancel`);
    return response.data.data;
  },

  getDashboard: async (): Promise<FinanceDashboard> => {
    const response = await api.get<ApiResponse<FinanceDashboard>>('/finance/dashboard');
    return response.data.data;
  },

  getBalance: async (): Promise<{ balance: number; totalRevenue: number; totalExpenses: number }> => {
    const response = await api.get<ApiResponse<{ balance: number; totalRevenue: number; totalExpenses: number }>>(
      '/finance/dashboard/balance'
    );
    return response.data.data;
  },

  getCashFlow: async (): Promise<FinanceDashboard['monthlyComparison']> => {
    const response = await api.get<ApiResponse<FinanceDashboard['monthlyComparison']>>(
      '/finance/dashboard/cash-flow'
    );
    return response.data.data;
  },

  getMonthlyReport: async (year: number, month: number): Promise<{
    revenue: { category: string; amount: number }[];
    expenses: { category: string; amount: number }[];
    totalRevenue: number;
    totalExpenses: number;
    balance: number;
  }> => {
    const response = await api.get<
      ApiResponse<{
        revenue: { category: string; amount: number }[];
        expenses: { category: string; amount: number }[];
        totalRevenue: number;
        totalExpenses: number;
        balance: number;
      }>
    >('/finance/reports/monthly', { params: { year, month } });
    return response.data.data;
  },

  getCategories: async (): Promise<TransactionCategory[]> => {
    const response = await api.get<ApiResponse<TransactionCategory[]>>('/finance/categories');
    return response.data.data;
  },

  createCategory: async (data: Partial<TransactionCategory>): Promise<TransactionCategory> => {
    const response = await api.post<ApiResponse<TransactionCategory>>('/finance/categories', data);
    return response.data.data;
  },

  updateCategory: async (id: string, data: Partial<TransactionCategory>): Promise<TransactionCategory> => {
    const response = await api.put<ApiResponse<TransactionCategory>>(`/finance/categories/${id}`, data);
    return response.data.data;
  },

  deleteCategory: async (id: string): Promise<void> => {
    await api.delete(`/finance/categories/${id}`);
  },

  getCostCenters: async (): Promise<CostCenter[]> => {
    const response = await api.get<ApiResponse<CostCenter[]>>('/finance/cost-centers');
    return response.data.data;
  },

  createCostCenter: async (data: Partial<CostCenter>): Promise<CostCenter> => {
    const response = await api.post<ApiResponse<CostCenter>>('/finance/cost-centers', data);
    return response.data.data;
  },

  updateCostCenter: async (id: string, data: Partial<CostCenter>): Promise<CostCenter> => {
    const response = await api.put<ApiResponse<CostCenter>>(`/finance/cost-centers/${id}`, data);
    return response.data.data;
  },

  deleteCostCenter: async (id: string): Promise<void> => {
    await api.delete(`/finance/cost-centers/${id}`);
  },

  createMonthlyClose: async (referenceDate: string): Promise<MonthlyClose> => {
    const response = await api.post<ApiResponse<MonthlyClose>>('/finance/monthly-close', { referenceDate });
    return response.data.data;
  },

  getMonthlyCloses: async (): Promise<MonthlyClose[]> => {
    const response = await api.get<ApiResponse<MonthlyClose[]>>('/finance/monthly-close');
    return response.data.data;
  },

  reopenMonthlyClose: async (id: string): Promise<MonthlyClose> => {
    const response = await api.post<ApiResponse<MonthlyClose>>(`/finance/monthly-close/${id}/reopen`);
    return response.data.data;
  },

  getAuditLogs: async (page = 1, limit = 20): Promise<PaginatedResponse<AuditLog>> => {
    const response = await api.get<ApiResponse<PaginatedResponse<AuditLog>>>('/finance/audit', {
      params: { page, limit },
    });
    return response.data.data;
  },
};
