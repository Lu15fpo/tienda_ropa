import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../../../features/personalization/models/address_model.dart';
import '../../../features/shop/models/order_model.dart';
import '../../../utils/constants/enums.dart';
import '../authentication/authentication_repository.dart';

class OrderRepository extends GetxController {
  static OrderRepository get instance => Get.find();

  /// Variables
  final _db = FirebaseFirestore.instance;

  /* ---------------------- FUNCIONES ---------------------- */

  /// Obtener todos los pedidos del usuario actual
  Future<List<OrderModel>> fetchUserOrders() async {
    try {
      print('📦 [OrderRepository] fetchUserOrders() INICIADO');

      final userId = AuthenticationRepository.instance.authUser.uid;
      print('👤 [OrderRepository] UserId: $userId');

      if (userId.isEmpty) {
        print('❌ [OrderRepository] UserId está vacío');
        throw 'No se pudo encontrar informacion del usuario. Intente de nuevo en unos minutos.';
      }

      print('📥 [OrderRepository] Consultando: Users/$userId/Orders');
      final result = await _db.collection('Users').doc(userId).collection('Orders').get();

      print('📊 [OrderRepository] Documentos encontrados: ${result.docs.length}');

      // Mostrar cada documento
      for (var i = 0; i < result.docs.length; i++) {
        final doc = result.docs[i];
        final data = doc.data();
        print('📄 [OrderRepository] Pedido ${i + 1}:');
        print('  - ID: ${doc.id}');
        print('  - Keys: ${data.keys.toList()}');
        print('  - Status: ${data['status']}');
        print('  - Total: ${data['totalAmount']}');
      }

      final orders = result.docs.map((documentSnapshot) {
        try {
          final order = OrderModel.fromSnapshot(documentSnapshot);
          print('  ✅ Pedido mapeado: ${order.id}');
          return order;
        } catch (e) {
          print('  ❌ Error mapeando pedido ${documentSnapshot.id}: $e');
          rethrow;
        }
      }).toList();

      print('🏁 [OrderRepository] fetchUserOrders() COMPLETADO - ${orders.length} pedidos');
      return orders;

    } catch (e) {
      print('❌ [OrderRepository] ERROR: $e');
      print('❌ [OrderRepository] Stack trace: ${StackTrace.current}');
      throw 'Algo salio mal obteniendo la informacion del pedido. Intentelo de nuevo en unos minutos.';
    }
  }

  /// Almacenar nuevo pedido de usuario
  Future<String> saveOrder(OrderModel order, String userId) async {
    try {
      final docRef = await _db.collection('Users').doc(userId).collection('Orders').add(order.toJson());
      return docRef.id; // Retornar el ID generado por Firestore
    } catch (e) {
      throw 'Algo salio mal guardando el pedido. Intentelo de nuevo en unos minutos.';
    }
  }

  /// Actualizar estado del pedido
  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    try {
      final userId = AuthenticationRepository.instance.authUser.uid;
      if (userId.isEmpty) {
        throw 'No se pudo encontrar información del usuario.';
      }

      await _db
          .collection('Users')
          .doc(userId)
          .collection('Orders')
          .doc(orderId)
          .update({'status': newStatus.name});
    } catch (e) {
      throw 'Algo salió mal al actualizar el estado del pedido. Intente de nuevo.';
    }
  }

  /// Actualizar dirección de envío del pedido
  Future<void> updateOrderAddress(String orderId, AddressModel newAddress) async {
    try {
      final userId = AuthenticationRepository.instance.authUser.uid;
      if (userId.isEmpty) {
        throw 'No se pudo encontrar información del usuario.';
      }

      await _db
          .collection('Users')
          .doc(userId)
          .collection('Orders')
          .doc(orderId)
          .update({'address': newAddress.toJson()});
    } catch (e) {
      throw 'Algo salió mal al actualizar la dirección. Intente de nuevo.';
    }
  }
}