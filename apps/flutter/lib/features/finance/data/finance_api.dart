import '../../../core/network/api_client.dart';
import '../../../core/config/api_config.dart';
import '../domain/finance_model.dart';

class FinanceApi {
  final ApiClient _client;

  FinanceApi(this._client);

  Future<FinanceDashboardModel> getDashboard() async {
    final response = await _client.get(ApiConfig.financeDashboard);
    final data = response.data as Map<String, dynamic>;
    return FinanceDashboardModel.fromJson(
        data['data'] as Map<String, dynamic>);
  }

  Future<List<TransactionModel>> getTransactions({
    int page = 1,
    String? type,
    String? status,
  }) async {
    final params = <String, dynamic>{'page': page};
    if (type != null) params['type'] = type;
    if (status != null) params['status'] = status;

    final response = await _client.get(
      ApiConfig.transactions,
      queryParameters: params,
    );
    final data = response.data as Map<String, dynamic>;
    final list = data['data'] as List<dynamic>;
    return list
        .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TransactionModel> createTransaction(Map<String, dynamic> data) async {
    final response = await _client.post(ApiConfig.transactions, data: data);
    final result = response.data as Map<String, dynamic>;
    return TransactionModel.fromJson(
        result['data'] as Map<String, dynamic>);
  }

  Future<void> confirmTransaction(String id) async {
    await _client.post('${ApiConfig.transactions}/$id/confirm');
  }

  Future<void> cancelTransaction(String id) async {
    await _client.post('${ApiConfig.transactions}/$id/cancel');
  }

  Future<List<CashFlowMonthModel>> getCashFlow() async {
    final response = await _client.get(ApiConfig.financeCashFlow);
    final data = response.data as Map<String, dynamic>;
    final list = data['data'] as List<dynamic>;
    return list
        .map((e) => CashFlowMonthModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> getReportMonthly({int? year, int? month}) async {
    final params = <String, dynamic>{};
    if (year != null) params['year'] = year;
    if (month != null) params['month'] = month;
    final response = await _client.get(
      ApiConfig.financeReportsMonthly,
      queryParameters: params,
    );
    final data = response.data as Map<String, dynamic>;
    return data['data'] as Map<String, dynamic>;
  }
}
