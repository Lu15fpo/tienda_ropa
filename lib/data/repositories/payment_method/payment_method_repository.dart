import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../../../data/repositories/authentication/authentication_repository.dart';
import '../../../features/shop/models/payment_method_model.dart';

/// Repositorio para manejar operaciones de métodos de pago en Firebase
class PaymentMethodRepository extends GetxController {
  static PaymentMethodRepository get instance => Get.find();

  final _db = FirebaseFirestore.instance;

  /// Obtener todos los métodos de pago del usuario
  Future<List<PaymentMethodModel>> fetchUserPaymentMethods() async {
    try {
      final userId = AuthenticationRepository.instance.authUser.uid;
      if (userId.isEmpty) {
        throw 'No es posible encontrar la información del usuario. Intente de nuevo más tarde.';
      }

      final result = await _db
          .collection('Users')
          .doc(userId)
          .collection('PaymentMethods')
          .orderBy('CreatedAt', descending: true)
          .get();

      return result.docs
          .map((documentSnapshot) =>
              PaymentMethodModel.fromDocumentSnapshot(documentSnapshot))
          .toList();
    } catch (e) {
      throw 'Algo salió mal al obtener los métodos de pago. Por favor intente de nuevo.';
    }
  }

  /// Obtener el método de pago predeterminado
  Future<PaymentMethodModel?> fetchDefaultPaymentMethod() async {
    try {
      final userId = AuthenticationRepository.instance.authUser.uid;
      if (userId.isEmpty) return null;

      final result = await _db
          .collection('Users')
          .doc(userId)
          .collection('PaymentMethods')
          .where('IsDefault', isEqualTo: true)
          .limit(1)
          .get();

      if (result.docs.isEmpty) return null;

      return PaymentMethodModel.fromDocumentSnapshot(result.docs.first);
    } catch (e) {
      throw 'No se pudo obtener el método de pago predeterminado. Intente de nuevo.';
    }
  }

  /// Actualizar el campo IsDefault de un método de pago
  Future<void> updateDefaultField(String paymentMethodId, bool isDefault) async {
    try {
      final userId = AuthenticationRepository.instance.authUser.uid;
      await _db
          .collection('Users')
          .doc(userId)
          .collection('PaymentMethods')
          .doc(paymentMethodId)
          .update({'IsDefault': isDefault});
    } catch (e) {
      throw 'No se puede actualizar el método de pago predeterminado. Intente de nuevo.';
    }
  }

  /// Limpiar todos los métodos de pago marcados como predeterminados
  Future<void> clearAllDefaultFields() async {
    try {
      final userId = AuthenticationRepository.instance.authUser.uid;
      final defaultMethods = await _db
          .collection('Users')
          .doc(userId)
          .collection('PaymentMethods')
          .where('IsDefault', isEqualTo: true)
          .get();

      for (var doc in defaultMethods.docs) {
        await doc.reference.update({'IsDefault': false});
      }
    } catch (e) {
      throw 'No se pudo limpiar los métodos predeterminados. Intente de nuevo.';
    }
  }

  /// Agregar un nuevo método de pago
  Future<String> addPaymentMethod(PaymentMethodModel paymentMethod) async {
    try {
      final userId = AuthenticationRepository.instance.authUser.uid;

      // Si el nuevo método es predeterminado, limpiar otros predeterminados
      if (paymentMethod.isDefault) {
        await clearAllDefaultFields();
      }

      final currentPaymentMethod = await _db
          .collection('Users')
          .doc(userId)
          .collection('PaymentMethods')
          .add(paymentMethod.toJson());

      return currentPaymentMethod.id;
    } catch (e) {
      throw 'No se pudo guardar el método de pago. Intente de nuevo.';
    }
  }

  /// Actualizar un método de pago existente
  Future<void> updatePaymentMethod(PaymentMethodModel paymentMethod) async {
    try {
      final userId = AuthenticationRepository.instance.authUser.uid;

      // Si este método se marca como predeterminado, limpiar otros
      if (paymentMethod.isDefault) {
        await clearAllDefaultFields();
      }

      await _db
          .collection('Users')
          .doc(userId)
          .collection('PaymentMethods')
          .doc(paymentMethod.id)
          .update(paymentMethod.toJson());
    } catch (e) {
      throw 'No se pudo actualizar el método de pago. Intente de nuevo.';
    }
  }

  /// Eliminar un método de pago
  Future<void> removePaymentMethod(String paymentMethodId) async {
    try {
      final userId = AuthenticationRepository.instance.authUser.uid;
      await _db
          .collection('Users')
          .doc(userId)
          .collection('PaymentMethods')
          .doc(paymentMethodId)
          .delete();
    } catch (e) {
      throw 'No se pudo eliminar el método de pago. Intente de nuevo.';
    }
  }

  /// Obtener un método de pago específico por ID
  Future<PaymentMethodModel?> getPaymentMethodById(String paymentMethodId) async {
    try {
      final userId = AuthenticationRepository.instance.authUser.uid;
      final doc = await _db
          .collection('Users')
          .doc(userId)
          .collection('PaymentMethods')
          .doc(paymentMethodId)
          .get();

      if (!doc.exists) return null;

      return PaymentMethodModel.fromDocumentSnapshot(doc);
    } catch (e) {
      throw 'No se pudo obtener el método de pago. Intente de nuevo.';
    }
  }

  /// Verificar si el usuario tiene métodos de pago guardados
  Future<bool> hasPaymentMethods() async {
    try {
      final userId = AuthenticationRepository.instance.authUser.uid;
      final result = await _db
          .collection('Users')
          .doc(userId)
          .collection('PaymentMethods')
          .limit(1)
          .get();

      return result.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Contar métodos de pago del usuario
  Future<int> countPaymentMethods() async {
    try {
      final userId = AuthenticationRepository.instance.authUser.uid;
      final result = await _db
          .collection('Users')
          .doc(userId)
          .collection('PaymentMethods')
          .get();

      return result.docs.length;
    } catch (e) {
      return 0;
    }
  }
}

