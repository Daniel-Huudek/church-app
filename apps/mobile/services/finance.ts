import { api } from './api';

export const financeService = {
  getTransactions: (params?: {
    page?: number; limit?: number; type?: string; status?: string;
    categoryId?: string; startDate?: string; endDate?: string; search?: string;
  }) => api.get('/finance/transactions', { params }),

  getTransaction: (id: string) =>
    api.get(`/finance/transactions/${id}`),

  createTransaction: (data: any) =>
    api.post('/finance/transactions', data),

  updateTransaction: (id: string, data: any) =>
    api.put(`/finance/transactions/${id}`, data),

  deleteTransaction: (id: string) =>
    api.delete(`/finance/transactions/${id}`),

  confirmTransaction: (id: string) =>
    api.post(`/finance/transactions/${id}/confirm`),

  cancelTransaction: (id: string) =>
    api.post(`/finance/transactions/${id}/cancel`),

  getDashboard: () =>
    api.get('/finance/dashboard'),

  getBalance: () =>
    api.get('/finance/dashboard/balance'),

  getCashFlow: () =>
    api.get('/finance/dashboard/cash-flow'),

  getMonthlyReport: (year: number, month: number) =>
    api.get('/finance/reports/monthly', { params: { year, month } }),

  getCategories: () =>
    api.get('/finance/categories'),

  createCategory: (data: any) =>
    api.post('/finance/categories', data),

  getCostCenters: () =>
    api.get('/finance/cost-centers'),

  createCostCenter: (data: any) =>
    api.post('/finance/cost-centers', data),

  createMonthlyClose: (referenceDate: string) =>
    api.post('/finance/monthly-close', { referenceDate }),

  getMonthlyCloses: () =>
    api.get('/finance/monthly-close'),

  getAuditLogs: (page = 1, limit = 20) =>
    api.get('/finance/audit', { params: { page, limit } }),
};
