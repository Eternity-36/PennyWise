import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'category.g.dart';

@HiveType(typeId: 2)
class Category extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final int iconCode;

  @HiveField(3)
  final int colorValue;

  @HiveField(4)
  final bool isCustom;

  Category({
    required this.id,
    required this.name,
    required this.iconCode,
    required this.colorValue,
    this.isCustom = true,
  });

  IconData get icon => IconData(iconCode, fontFamily: 'MaterialIcons');
  Color get color => Color(colorValue);
}
