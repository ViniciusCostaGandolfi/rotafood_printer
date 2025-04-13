import 'package:rotafood_printer/enums/merchant_user_role.dart';

class MerchantUserDto {
  final String id;
  final String name;
  final String email;
  final String phone;
  final MerchantUserRole role;
  final String merchantId;

  MerchantUserDto({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.merchantId,
  });

  factory MerchantUserDto.fromJson(Map<String, dynamic> json) {
    return MerchantUserDto(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      role: MerchantUserRole.values.firstWhere(
        (e) => e.toString().split('.').last == json['role'],
        orElse: () => MerchantUserRole.GARSON, // Valor default
      ),
      merchantId: json['merchantId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.toString().split('.').last,
      'merchantId': merchantId,
    };
  }
}

