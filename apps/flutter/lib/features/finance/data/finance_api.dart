import '../../../core/network/api_client.dart';
import '../../../core/config/api_config.dart';
import '../domain/finance_model.dart';

class FinanceApi {
  final ApiClient _client;

  FinanceApi(this._client);

  Future<FinanceDashboardModel> getDashboard() async {
    final response = await _client.get(ApiConfig.financeDashboard);
    return FinanceDashboardModel.fromJson(_client.unwrapData(response.data));
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
    return _client.unwrapList(response.data, TransactionModel.fromJson);
  }

  Future<TransactionModel> createTransaction(Map<String, dynamic> data) async {
    final response = await _client.post(ApiConfig.transactions, data: data);
    return TransactionModel.fromJson(_client.unwrapData(response.data));
  }

  Future<void> confirmTransaction(String id) async {
    await _client.post('${ApiConfig.transactions}/$id/confirm');
  }

  Future<void> cancelTransaction(String id) async {
    await _client.post('${ApiConfig.transactions}/$id/cancel');
  }

  Future<void> deleteTransaction(String id) async {
    await _client.delete('${ApiConfig.transactions}/$id');
  }

  Future<List<CashFlowMonthModel>> getCashFlow() async {
    final response = await _client.get(ApiConfig.financeCashFlow);
    return _client.unwrapList(response.data, CashFlowMonthModel.fromJson);
  }

  Future<Map<String, dynamic>> getReportMonthly({int? year, int? month}) async {
    final params = <String, dynamic>{};
    if (year != null) params['year'] = year;
    if (month != null) params['month'] = month;
    final response = await _client.get(
      ApiConfig.financeReportsMonthly,
      queryParameters: params,
    );
    return _client.unwrapData(response.data);
  }
}
