import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tienda_ropa/features/shop/models/cart_item_model.dart';
import 'package:tienda_ropa/utils/helpers/helper_functions.dart';

import '../../../utils/constants/enums.dart';
import '../../personalization/models/address_model.dart';

class OrderModel {
  final String id;
  final String userId;
  final OrderStatus status;
  final double totalAmount;
  final DateTime orderDate;
  final String paymentMethod;
  final AddressModel? address;
  final DateTime? deliveryDate;
  final List<CartItemModel> items;
  final double shippingCost;
  final double taxCost;
  final double discount;

  OrderModel({
    required this.id,
    this.userId = '',
    required this.status,
    required this.items,
    required this.totalAmount,
    required this.orderDate,
    this.paymentMethod = 'Paypal',
    this.address,
    this.deliveryDate,
    this.shippingCost = 0.0,
    this.taxCost = 0.0,
    this.discount = 0.0,
  });

  String get formattedOrderDate => THelperFunctions.getFormattedDate(orderDate);

  String get formattedDeliveryDate => deliveryDate != null ? THelperFunctions.getFormattedDate(deliveryDate!) : '';

  String get orderStatusText => status == OrderStatus.delivered
      ? 'Entregado'
      : status == OrderStatus.shipped
          ? 'Pedido en camino'
          : 'Procesando';

  Map<String, dynamic> toJson() {
    return {
      'id' : id,
      'userId' : userId,
      'status' : status.name,
      'totalAmount' : totalAmount,
      'orderDate' : orderDate,
      'paymentMethod' : paymentMethod,
      'address' : address?.toJson(),
      'deliveryDate' : deliveryDate,
      'items' : items.map((item) => item.toJson()).toList(),
      'shippingCost' : shippingCost,
      'taxCost' : taxCost,
      'discount' : discount,
    };
  }

  factory OrderModel.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;

    print('🔍 [OrderModel] Parseando documento: ${snapshot.id}');
    print('🔍 [OrderModel] Datos disponibles: ${data.keys.toList()}');
    print('🔍 [OrderModel] Status en Firebase: ${data['status']}');

    // Mapear status del panel de administrador a la app móvil
    OrderStatus parseStatus(String? statusString) {
      if (statusString == null) return OrderStatus.pending;

      print('🔄 [OrderModel] Mapeando status: $statusString');

      // Remover "OrderStatus." si existe
      final cleanStatus = statusString.replaceAll('OrderStatus.', '').toLowerCase();

      // Mapear estados en español a inglés
      switch (cleanStatus) {
        case 'pendiente':
        case 'pending':
          return OrderStatus.pending;

        case 'procesando':
        case 'processing':
          return OrderStatus.processing;

        case 'enviado':
        case 'shipped':
          return OrderStatus.shipped;

        case 'entregado':
        case 'delivered':
          return OrderStatus.delivered;

        case 'cancelado':
        case 'cancelled':
          return OrderStatus.cancelled;

        default:
          print('⚠️ [OrderModel] Status no reconocido: $statusString, usando pending');
          return OrderStatus.pending;
      }
    }

    return OrderModel(
      id: data['id'] ?? '',
      userId: data['userId'] ?? '',

      // Usar la función de mapeo mejorada
      status: parseStatus(data['status'] as String?),

      // Convertir números de forma segura
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0.0,

      // Convertir fechas con validación
      orderDate: data['orderDate'] != null
          ? (data['orderDate'] as Timestamp).toDate()
          : DateTime.now(),

      paymentMethod: data['paymentMethod'] ?? 'Paypal',

      // Validar dirección null
      address: data['address'] != null
          ? AddressModel.fromMap(data['address'] as Map<String, dynamic>)
          : null,

      deliveryDate: data['deliveryDate'] != null
          ? (data['deliveryDate'] as Timestamp).toDate()
          : null,

      // Validar items null
      items: data['items'] != null
          ? (data['items'] as List<dynamic>)
              .map((itemData) => CartItemModel.fromJson(itemData as Map<String, dynamic>))
              .toList()
          : [],

      // Nuevos campos de costos
      shippingCost: (data['shippingCost'] as num?)?.toDouble() ?? 0.0,
      taxCost: (data['taxCost'] as num?)?.toDouble() ?? 0.0,
      discount: (data['discount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}