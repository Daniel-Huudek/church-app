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
      amount: ((json['value'] ?? json['amount']) as num).toDouble(),
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'description': description,
    'value': amount,
    'type': type,
    'status': status,
    'categoryId': categoryId,
    'categoryName': categoryName,
    'costCenterName': costCenterName,
    'paymentMethod': paymentMethod,
    'date': date.toIso8601String(),
    'dueDate': dueDate?.toIso8601String(),
    'paidAt': paidAt?.toIso8601String(),
    'createdByName': createdByName,
    'createdAt': createdAt.toIso8601String(),
  };
}

class CashFlowMonthModel {
  final String month;
  final double revenue;
  final double expenses;
  final double balance;

  const CashFlowMonthModel({
    required this.month,
    this.revenue = 0,
    this.expenses = 0,
    this.balance = 0,
  });

  factory CashFlowMonthModel.fromJson(Map<String, dynamic> json) {
    return CashFlowMonthModel(
      month: json['month'] as String,
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
      expenses: (json['expenses'] as num?)?.toDouble() ?? 0,
      balance: (json['balance'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'month': month,
    'revenue': revenue,
    'expenses': expenses,
    'balance': balance,
  };
}

class FinanceDashboardModel {
  final double balance;
  final double totalIncome;
  final double totalExpense;
  final List<Map<String, dynamic>> incomeByCategory;
  final List<Map<String, dynamic>> expenseByCategory;
  final List<Map<String, dynamic>> monthlyHistory;

  const FinanceDashboardModel({
    this.balance = 0,
    this.totalIncome = 0,
    this.totalExpense = 0,
    this.incomeByCategory = const [],
    this.expenseByCategory = const [],
    this.monthlyHistory = const [],
  });

  factory FinanceDashboardModel.fromJson(Map<String, dynamic> json) {
    return FinanceDashboardModel(
      balance: (json['balance'] as num?)?.toDouble() ?? 0,
      totalIncome: (json['totalIncome'] as num?)?.toDouble() ?? 0,
      totalExpense: (json['totalExpense'] as num?)?.toDouble() ?? 0,
      incomeByCategory: (json['incomeByCategory'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ?? [],
      expenseByCategory: (json['expenseByCategory'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ?? [],
      monthlyHistory: (json['monthlyHistory'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
    'balance': balance,
    'totalIncome': totalIncome,
    'totalExpense': totalExpense,
    'incomeByCategory': incomeByCategory,
    'expenseByCategory': expenseByCategory,
    'monthlyHistory': monthlyHistory,
  };
}
