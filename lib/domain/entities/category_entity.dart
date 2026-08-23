import 'package:equatable/equatable.dart';

class CategoryEntity extends Equatable {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? imageUrl;
  final String? iconName;
  final int productCount;
  final bool isActive;
  final int sortOrder;
  final List<SubcategoryEntity> subcategories;

  const CategoryEntity({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.imageUrl,
    this.iconName,
    this.productCount = 0,
    this.isActive = true,
    this.sortOrder = 0,
    this.subcategories = const [],
  });

  @override
  List<Object?> get props => [id, name, slug];
}

class SubcategoryEntity extends Equatable {
  final String id;
  final String parentId;
  final String name;
  final String slug;
  final String? imageUrl;
  final int productCount;
  final bool isActive;
  final int sortOrder;

  const SubcategoryEntity({
    required this.id,
    required this.parentId,
    required this.name,
    required this.slug,
    this.imageUrl,
    this.productCount = 0,
    this.isActive = true,
    this.sortOrder = 0,
  });

  @override
  List<Object?> get props => [id, parentId, name];
}

class BrandEntity extends Equatable {
  final String id;
  final String name;
  final String slug;
  final String? logoUrl;
  final String? description;
  final bool isActive;
  final int productCount;

  const BrandEntity({
    required this.id,
    required this.name,
    required this.slug,
    this.logoUrl,
    this.description,
    this.isActive = true,
    this.productCount = 0,
  });

  @override
  List<Object?> get props => [id, name];
}
