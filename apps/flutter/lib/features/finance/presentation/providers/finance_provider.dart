import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../data/finance_api.dart';
import '../../domain/finance_model.dart';
import '../../../../shared/providers/async_state.dart';

final financeApiProvider = Provider<FinanceApi>((ref) {
  return FinanceApi(ref.read(apiClientProvider));
});

final financeDashboardProvider = StateNotifierProvider.autoDispose<FinanceDashboardNotifier, AsyncState<FinanceDashboardModel?>>((ref) {
  return FinanceDashboardNotifier(ref.read(financeApiProvider));
});

class FinanceDashboardNotifier extends StateNotifier<AsyncState<FinanceDashboardModel?>> {
  final FinanceApi _api;

  FinanceDashboardNotifier(this._api) : super(const AsyncState(data: null)) {
    load();
  }

  Future<void> load() async {
    state = const AsyncState(data: null, loading: true);
    try {
      final dashboard = await _api.getDashboard();
      state = AsyncState(data: dashboard, loading: false);
    } catch (e) {
      state = AsyncState(data: null, loading: false, error: e.toString());
    }
  }
}

final transactionListProvider = StateNotifierProvider.autoDispose<TransactionListNotifier, AsyncState<List<TransactionModel>>>((ref) {
  return TransactionListNotifier(ref.read(financeApiProvider));
});

class TransactionListNotifier extends StateNotifier<AsyncState<List<TransactionModel>>> {
  final FinanceApi _api;

  TransactionListNotifier(this._api) : super(const AsyncState(data: [])) {
    load();
  }

  Future<void> load() async {
    state = AsyncState(data: state.data, loading: true);
    try {
      final transactions = await _api.getTransactions();
      state = AsyncState(data: transactions, loading: false);
    } catch (e) {
      state = AsyncState(data: state.data, loading: false, error: e.toString());
    }
  }
}

final cashFlowProvider = StateNotifierProvider.autoDispose<CashFlowNotifier, AsyncState<List<CashFlowMonthModel>>>((ref) {
  return CashFlowNotifier(ref.read(financeApiProvider));
});

class CashFlowNotifier extends StateNotifier<AsyncState<List<CashFlowMonthModel>>> {
  final FinanceApi _api;

  CashFlowNotifier(this._api) : super(const AsyncState(data: [])) {
    load();
  }

  Future<void> load() async {
    state = AsyncState(data: state.data, loading: true);
    try {
      final months = await _api.getCashFlow();
      state = AsyncState(data: months, loading: false);
    } catch (e) {
      state = AsyncState(data: state.data, loading: false, error: e.toString());
    }
  }
}

final reportMonthlyProvider = StateNotifierProvider.autoDispose<ReportMonthlyNotifier, AsyncState<Map<String, dynamic>?>>((ref) {
  return ReportMonthlyNotifier(ref.read(financeApiProvider));
});

class ReportMonthlyNotifier extends StateNotifier<AsyncState<Map<String, dynamic>?>> {
  final FinanceApi _api;

  ReportMonthlyNotifier(this._api) : super(const AsyncState(data: null)) {
    load();
  }

  Future<void> load({int? year, int? month}) async {
    state = const AsyncState(data: null, loading: true);
    try {
      final report = await _api.getReportMonthly(year: year, month: month);
      state = AsyncState(data: report, loading: false);
    } catch (e) {
      state = AsyncState(data: null, loading: false, error: e.toString());
    }
  }
}
