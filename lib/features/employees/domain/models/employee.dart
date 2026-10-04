enum EmployeeRole {
  admin,
  manager,
  cashier,
}

enum Permission {
  createSale,
  refund,
  modifyPrice,
  manageProducts,
  manageInventory,
  viewProfit,
  manageEmployees,
  viewReports,
  manageSettings,
}

extension EmployeeRoleExtension on EmployeeRole {
  String get displayName {
    switch (this) {
      case EmployeeRole.admin:
        return 'Admin';
      case EmployeeRole.manager:
        return 'Manager';
      case EmployeeRole.cashier:
        return 'Cashier';
    }
  }

  Set<Permission> get defaultPermissions {
    switch (this) {
      case EmployeeRole.admin:
        return Permission.values.toSet();
      case EmployeeRole.manager:
        return {
          Permission.createSale,
          Permission.refund,
          Permission.manageProducts,
          Permission.manageInventory,
          Permission.viewReports,
        };
      case EmployeeRole.cashier:
        return {
          Permission.createSale,
        };
    }
  }
}

class Employee {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final EmployeeRole role;
  final Set<Permission> customPermissions; // If we want to override default role permissions
  final bool isActive;
  final DateTime createdAt;

  Employee({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    Set<Permission>? customPermissions,
    this.isActive = true,
    required this.createdAt,
  }) : customPermissions = customPermissions ?? {};

  Set<Permission> get effectivePermissions => 
      customPermissions.isNotEmpty ? customPermissions : role.defaultPermissions;

  bool hasPermission(Permission permission) {
    if (!isActive) return false;
    return effectivePermissions.contains(permission);
  }

  Employee copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    EmployeeRole? role,
    Set<Permission>? customPermissions,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Employee(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      customPermissions: customPermissions ?? this.customPermissions,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
