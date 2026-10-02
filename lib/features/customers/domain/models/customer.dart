class Customer {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? notes;
  final double totalSpending;
  final double outstandingBalance;
  final int loyaltyPoints;
  final DateTime createdAt;

  Customer({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.notes,
    this.totalSpending = 0.0,
    this.outstandingBalance = 0.0,
    this.loyaltyPoints = 0,
    required this.createdAt,
  });

  Customer copyWith({
    String? name,
    String? phone,
    String? email,
    String? address,
    String? notes,
    double? totalSpending,
    double? outstandingBalance,
    int? loyaltyPoints,
  }) {
    return Customer(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      totalSpending: totalSpending ?? this.totalSpending,
      outstandingBalance: outstandingBalance ?? this.outstandingBalance,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      createdAt: createdAt,
    );
  }
}
