class TransactionModel {
  final String id;
  final String description;
  final double amount;
  final String type;
  final String status;
  final String? categoryId;
  final String? categoryName;
  final String? costCenterName;
  final String? paymentMethod;
  final DateTime date;
  final DateTime? dueDate;
  final DateTime? paidAt;
  final String? createdByName;
  final DateTime createdAt;

  const TransactionModel({
    required this.id,
    required this.description,
    required this.amount,
    required this.type,
    this.status = 'PENDENTE',
    this.categoryId,
    this.categoryName,
    this.costCenterName,
    this.paymentMethod,
    required this.date,
    this.dueDate,
    this.paidAt,
    this.createdByName,
    required this.createdAt,
  });

  bool get isIncome => type == 'RECEITA' || type == 'INCOME';
  bool get isExpense => type == 'DESPESA' || type == 'EXPENSE';

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      description: json['description'] as String? ?? 'Sem descrição',
      amount: (json['value'] ?? json['amount'] as num).toDouble(),
      type: json['type'] as String? ?? 'EXPENSE',
      status: json['status'] as String? ?? 'PENDENTE',
      categoryId: json['categoryId'] as String?,
      categoryName: json['categoryName'] as String?,
      costCenterName: json['costCenterName'] as String?,
      paymentMethod: json['paymentMethod'] as String?,
      date: DateTime.parse(json['date'] as String),
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : null,
      paidAt: json['paidAt'] != null
          ? DateTime.parse(json['paidAt'] as String)
          : null,
      createdByName: json['createdByName'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class FinanceDashboardModel {
  final double balance;
  final double totalRevenue;
  final double totalExpenses;
  final List<TransactionModel> recentTransactions;

  const FinanceDashboardModel({
    this.balance = 0,
    this.totalRevenue = 0,
    this.totalExpenses = 0,
    this.recentTransactions = const [],
  });

  factory FinanceDashboardModel.fromJson(Map<String, dynamic> json) {
    return FinanceDashboardModel(
      balance: (json['balance'] as num?)?.toDouble() ?? 0,
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0,
      totalExpenses: (json['totalExpenses'] as num?)?.toDouble() ?? 0,
      recentTransactions: (json['recentTransactions'] as List<dynamic>?)
              ?.map((e) =>
                  TransactionModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
