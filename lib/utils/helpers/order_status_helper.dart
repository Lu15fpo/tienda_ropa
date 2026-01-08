import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:tienda_ropa/utils/constants/colors.dart';
import 'package:tienda_ropa/utils/constants/enums.dart';

/// Helper class para manejar los colores e iconos de estados de pedidos
class OrderStatusHelper {
  OrderStatusHelper._();

  /// Obtener color según el estado del pedido
  static Color getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.processing:
        return Colors.blue;
      case OrderStatus.shipped:
        return Colors.purple;
      case OrderStatus.delivered:
        return TColors.success;
      case OrderStatus.cancelled:
        return TColors.error;
    }
  }

  /// Obtener icono según el estado del pedido
  static IconData getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Iconsax.clock;
      case OrderStatus.processing:
        return Iconsax.box_time;
      case OrderStatus.shipped:
        return Iconsax.truck_fast;
      case OrderStatus.delivered:
        return Iconsax.tick_circle;
      case OrderStatus.cancelled:
        return Iconsax.close_circle;
    }
  }

  /// Obtener color de fondo según el estado (con transparencia)
  static Color getStatusBackgroundColor(OrderStatus status) {
    return getStatusColor(status).withValues(alpha: 0.1);
  }
}

