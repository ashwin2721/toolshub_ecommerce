import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    required super.name,
    super.phone,
    super.photoUrl,
    required super.role,
    super.isEmailVerified,
    super.isPhoneVerified,
    super.isBlocked,
    super.addresses,
    super.defaultAddressId,
    super.fcmToken,
    super.languageCode,
    required super.createdAt,
    super.lastLoginAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      phone: data['phone'],
      photoUrl: data['photoUrl'],
      role: data['role'] ?? 'customer',
      isEmailVerified: data['isEmailVerified'] ?? false,
      isPhoneVerified: data['isPhoneVerified'] ?? false,
      isBlocked: data['isBlocked'] ?? false,
      addresses: (data['addresses'] as List<dynamic>?)
              ?.map((a) => AddressModel.fromMap(a as Map<String, dynamic>))
              .toList() ??
          [],
      defaultAddressId: data['defaultAddressId'],
      fcmToken: data['fcmToken'],
      languageCode: data['languageCode'] ?? 'en',
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : data['createdAt'] is String
              ? DateTime.tryParse(data['createdAt']) ?? DateTime.now()
              : DateTime.now(),
      lastLoginAt: data['lastLoginAt'] is Timestamp
          ? (data['lastLoginAt'] as Timestamp).toDate()
          : data['lastLoginAt'] is String
              ? DateTime.tryParse(data['lastLoginAt'])
              : null,
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> data, String id) {
    return UserModel(
      id: id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      phone: data['phone'],
      photoUrl: data['photoUrl'],
      role: data['role'] ?? 'customer',
      isEmailVerified: data['isEmailVerified'] ?? false,
      isPhoneVerified: data['isPhoneVerified'] ?? false,
      isBlocked: data['isBlocked'] ?? false,
      addresses: (data['addresses'] as List<dynamic>?)
              ?.map((a) => AddressModel.fromMap(a as Map<String, dynamic>))
              .toList() ??
          [],
      defaultAddressId: data['defaultAddressId'],
      fcmToken: data['fcmToken'],
      languageCode: data['languageCode'] ?? 'en',
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : data['createdAt'] is String
              ? DateTime.tryParse(data['createdAt']) ?? DateTime.now()
              : DateTime.now(),
      lastLoginAt: data['lastLoginAt'] is Timestamp
          ? (data['lastLoginAt'] as Timestamp).toDate()
          : data['lastLoginAt'] is String
              ? DateTime.tryParse(data['lastLoginAt'])
              : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'email': email,
        'name': name,
        'phone': phone,
        'photoUrl': photoUrl,
        'role': role,
        'isEmailVerified': isEmailVerified,
        'isPhoneVerified': isPhoneVerified,
        'isBlocked': isBlocked,
        'addresses': addresses
            .map((a) => AddressModel.fromEntity(a).toMap())
            .toList(),
        'defaultAddressId': defaultAddressId,
        'fcmToken': fcmToken,
        'languageCode': languageCode,
        'createdAt': Timestamp.fromDate(createdAt),
        'lastLoginAt':
            lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
      };
}

class AddressModel extends AddressEntity {
  const AddressModel({
    required super.id,
    required super.type,
    required super.fullName,
    required super.phone,
    required super.street,
    required super.city,
    required super.state,
    required super.country,
    required super.pinCode,
    super.isDefault,
  });

  factory AddressModel.fromEntity(AddressEntity e) => AddressModel(
        id: e.id,
        type: e.type,
        fullName: e.fullName,
        phone: e.phone,
        street: e.street,
        city: e.city,
        state: e.state,
        country: e.country,
        pinCode: e.pinCode,
        isDefault: e.isDefault,
      );

  factory AddressModel.fromMap(Map<String, dynamic> data) => AddressModel(
        id: data['id'] ?? '',
        type: data['type'] ?? 'home',
        fullName: data['fullName'] ?? '',
        phone: data['phone'] ?? '',
        street: data['street'] ?? '',
        city: data['city'] ?? '',
        state: data['state'] ?? '',
        country: data['country'] ?? 'India',
        pinCode: data['pinCode'] ?? '',
        isDefault: data['isDefault'] ?? false,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type,
        'fullName': fullName,
        'phone': phone,
        'street': street,
        'city': city,
        'state': state,
        'country': country,
        'pinCode': pinCode,
        'isDefault': isDefault,
      };
}
