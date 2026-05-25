import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../data/finance_api.dart';
import '../../domain/finance_model.dart';

final financeApiProvider = Provider<FinanceApi>((ref) {
  return FinanceApi(ref.read(apiClientProvider));
});

class FinanceDashboardState {
  final FinanceDashboardModel? dashboard;
  final bool loading;
  final String? error;

  const FinanceDashboardState({this.dashboard, this.loading = true, this.error});
}

final financeDashboardProvider = StateNotifierProvider.autoDispose<FinanceDashboardNotifier, FinanceDashboardState>((ref) {
  return FinanceDashboardNotifier(ref.read(financeApiProvider));
});

class FinanceDashboardNotifier extends StateNotifier<FinanceDashboardState> {
  final FinanceApi _api;

  FinanceDashboardNotifier(this._api) : super(const FinanceDashboardState()) {
    load();
  }

  Future<void> load() async {
    state = const FinanceDashboardState(loading: true);
    try {
      final dashboard = await _api.getDashboard();
      state = FinanceDashboardState(dashboard: dashboard, loading: false);
    } catch (e) {
      state = FinanceDashboardState(loading: false, error: e.toString());
    }
  }
}

class TransactionListState {
  final List<TransactionModel> transactions;
  final bool loading;
  final String? error;

  const TransactionListState({
    this.transactions = const [],
    this.loading = true,
    this.error,
  });
}

final transactionListProvider = StateNotifierProvider.autoDispose<TransactionListNotifier, TransactionListState>((ref) {
  return TransactionListNotifier(ref.read(financeApiProvider));
});

class TransactionListNotifier extends StateNotifier<TransactionListState> {
  final FinanceApi _api;

  TransactionListNotifier(this._api) : super(const TransactionListState()) {
    load();
  }

  Future<void> load() async {
    state = TransactionListState(transactions: state.transactions, loading: true);
    try {
      final transactions = await _api.getTransactions();
      state = TransactionListState(transactions: transactions, loading: false);
    } catch (e) {
      state = TransactionListState(transactions: state.transactions, loading: false, error: e.toString());
    }
  }
}

class CashFlowState {
  final List<CashFlowMonthModel> months;
  final bool loading;
  final String? error;

  const CashFlowState({
    this.months = const [],
    this.loading = true,
    this.error,
  });
}

final cashFlowProvider = StateNotifierProvider.autoDispose<CashFlowNotifier, CashFlowState>((ref) {
  return CashFlowNotifier(ref.read(financeApiProvider));
});

class CashFlowNotifier extends StateNotifier<CashFlowState> {
  final FinanceApi _api;

  CashFlowNotifier(this._api) : super(const CashFlowState()) {
    load();
  }

  Future<void> load() async {
    state = CashFlowState(months: state.months, loading: true);
    try {
      final months = await _api.getCashFlow();
      state = CashFlowState(months: months, loading: false);
    } catch (e) {
      state = CashFlowState(months: state.months, loading: false, error: e.toString());
    }
  }
}

class ReportMonthlyState {
  final Map<String, dynamic>? report;
  final bool loading;
  final String? error;

  const ReportMonthlyState({this.report, this.loading = true, this.error});
}

final reportMonthlyProvider = StateNotifierProvider.autoDispose<ReportMonthlyNotifier, ReportMonthlyState>((ref) {
  return ReportMonthlyNotifier(ref.read(financeApiProvider));
});

class ReportMonthlyNotifier extends StateNotifier<ReportMonthlyState> {
  final FinanceApi _api;

  ReportMonthlyNotifier(this._api) : super(const ReportMonthlyState()) {
    load();
  }

  Future<void> load({int? year, int? month}) async {
    state = const ReportMonthlyState(loading: true);
    try {
      final report = await _api.getReportMonthly(year: year, month: month);
      state = ReportMonthlyState(report: report, loading: false);
    } catch (e) {
      state = ReportMonthlyState(loading: false, error: e.toString());
    }
  }
}
