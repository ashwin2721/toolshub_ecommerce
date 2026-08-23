import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String email;
  final String name;
  final String? phone;
  final String? photoUrl;
  final String role;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final bool isBlocked;
  final List<AddressEntity> addresses;
  final String? defaultAddressId;
  final String? fcmToken;
  final String languageCode;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  const UserEntity({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    this.photoUrl,
    required this.role,
    this.isEmailVerified = false,
    this.isPhoneVerified = false,
    this.isBlocked = false,
    this.addresses = const [],
    this.defaultAddressId,
    this.fcmToken,
    this.languageCode = 'en',
    required this.createdAt,
    this.lastLoginAt,
  });

  bool get isAdmin => role == 'admin';
  bool get isStaff => role == 'staff_manager' || role == 'inventory_manager';
  AddressEntity? get defaultAddress => addresses.isEmpty
      ? null
      : defaultAddressId != null
          ? addresses.firstWhere((a) => a.id == defaultAddressId,
              orElse: () => addresses.first)
          : addresses.first;

  UserEntity copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    String? photoUrl,
    String? role,
    bool? isEmailVerified,
    bool? isPhoneVerified,
    bool? isBlocked,
    List<AddressEntity>? addresses,
    String? defaultAddressId,
    String? fcmToken,
    String? languageCode,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) =>
      UserEntity(
        id: id ?? this.id,
        email: email ?? this.email,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        photoUrl: photoUrl ?? this.photoUrl,
        role: role ?? this.role,
        isEmailVerified: isEmailVerified ?? this.isEmailVerified,
        isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
        isBlocked: isBlocked ?? this.isBlocked,
        addresses: addresses ?? this.addresses,
        defaultAddressId: defaultAddressId ?? this.defaultAddressId,
        fcmToken: fcmToken ?? this.fcmToken,
        languageCode: languageCode ?? this.languageCode,
        createdAt: createdAt ?? this.createdAt,
        lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      );

  @override
  List<Object?> get props => [id, email, name, role, isBlocked];
}

class AddressEntity extends Equatable {
  final String id;
  final String type; // home, work, other
  final String fullName;
  final String phone;
  final String street;
  final String city;
  final String state;
  final String country;
  final String pinCode;
  final bool isDefault;

  const AddressEntity({
    required this.id,
    required this.type,
    required this.fullName,
    required this.phone,
    required this.street,
    required this.city,
    required this.state,
    required this.country,
    required this.pinCode,
    this.isDefault = false,
  });

  String get formatted =>
      '$street, $city, $state - $pinCode, $country';

  @override
  List<Object?> get props => [id, street, city, pinCode];
}
