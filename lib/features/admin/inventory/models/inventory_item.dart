import 'package:intl/intl.dart';

class InventoryItem {
  final int id;
  final int apiaryId;
  final String itemName;
  final int quantity;
  final String unit;
  final DateTime createdAt;
  final DateTime updatedAt;

  InventoryItem({
    required this.id,
    required this.apiaryId,
    required this.itemName,
    required this.quantity,
    required this.unit,
    required this.createdAt,
    required this.updatedAt,
  });

  static final DateFormat _httpDateFormat = DateFormat('EEE, dd MMM yyyy HH:mm:ss zzz', 'en_US');

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id'],
      apiaryId: json['apiary_id'],
      itemName: json['name'],
      quantity: json['quantity'],
      unit: json['unit'],
      createdAt: _httpDateFormat.parse(json['created_at']),
      updatedAt: _httpDateFormat.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'apiary_id': apiaryId,
      'name': itemName,
      'quantity': quantity,
      'unit': unit,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'name': itemName,
      'quantity': quantity,
      'unit': unit,
    };
  }

  InventoryItem copyWith({
    int? id,
    int? apiaryId,
    String? itemName,
    int? quantity,
    String? unit,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      apiaryId: apiaryId ?? this.apiaryId,
      itemName: itemName ?? this.itemName,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
