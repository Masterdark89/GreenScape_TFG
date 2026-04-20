import 'package:flutter/material.dart';

class InventoryItem {
  final int? id;
  final String name;
  final String description;
  final String category;
  final String stockStatus;
  final int currentUnits;
  final int totalUnits;
  final int pendingRentalUnits;

  const InventoryItem({
    this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.stockStatus,
    required this.currentUnits,
    required this.totalUnits,
    this.pendingRentalUnits = 0,
  });

  static String normalizeStatus(String status) {
    final upper = status.trim().toUpperCase();
    if (upper == 'EN ESTOCK') {
      return 'EN STOCK';
    }
    return upper;
  }

  static String deriveStockStatus({
    required int currentUnits,
    required int totalUnits,
  }) {
    if (currentUnits <= 0 || totalUnits <= 0) {
      return 'SIN STOCK';
    }

    final threshold = totalUnits / 2;
    if (currentUnits < threshold) {
      return 'BAJO STOCK';
    }
    return 'EN STOCK';
  }

  String get stockStatusDisplay {
    return normalizeStatus(stockStatus);
  }

  Color get stockStatusColor {
    switch (stockStatusDisplay.toUpperCase()) {
      case 'EN STOCK':
        return Colors.green;
      case 'BAJO STOCK':
        return Colors.orange;
      case 'SIN STOCK':
        return Colors.red;
      default:
        return Colors.green;
    }
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'stock_status': deriveStockStatus(
        currentUnits: currentUnits,
        totalUnits: totalUnits,
      ),
      'current_units': currentUnits,
      'total_units': totalUnits,
      'pending_rental_units': pendingRentalUnits,
    };
  }

  factory InventoryItem.fromMap(Map<String, Object?> map) {
    final int currentUnits = (map['current_units'] as num?)?.toInt() ?? 0;
    final int totalUnits = (map['total_units'] as num?)?.toInt() ?? 0;
    return InventoryItem(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String,
      category: map['category'] as String,
      stockStatus: deriveStockStatus(
        currentUnits: currentUnits,
        totalUnits: totalUnits,
      ),
      currentUnits: currentUnits,
      totalUnits: totalUnits,
      pendingRentalUnits: (map['pending_rental_units'] as num?)?.toInt() ?? 0,
    );
  }
}
