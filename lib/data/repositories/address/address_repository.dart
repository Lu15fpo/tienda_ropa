import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tienda_ropa/data/repositories/authentication/authentication_repository.dart';

import '../../../features/personalization/models/address_model.dart';

class AddressRepository extends GetxController {
  static AddressRepository get instance => Get.find();

  final _db = FirebaseFirestore.instance;

  Future<List<AddressModel>> fetchUserAddresses() async {
    try {
      final userId = AuthenticationRepository.instance.authUser.uid;
      if (userId.isEmpty) throw 'No es posible encontrar la informacion del usuario. Intente de nuevo en unos minutos';

      final result = await _db.collection('Users').doc(userId).collection('Addresses').get();
      return result.docs.map((documentSnapshot) => AddressModel.fromDocumentSnapshot(documentSnapshot)).toList();

    } catch (e) {
      throw 'Algo salio mal al intentar obtener las direcciones del usuario. Intente de nuevo en unos minutos.';
    }
  }

  /// Limpiar todas las direcciones "seleccionadas"
  Future <void> updateSelectedField(String addressId, bool selected) async {
    try {
      final userId = AuthenticationRepository.instance.authUser.uid;
      await _db.collection('Users').doc(userId).collection('Addresses').doc(addressId).update({'SelectedAddress': selected});
    } catch (e) {
      throw 'No se puede actualizar la direccion seleccionada. Intente de nuevo en unos minutos.';
    }
  }

  /// Almacenar nueva direccion de usuario
  Future<String> addAddress(AddressModel address) async {
    try {
      final userId = AuthenticationRepository.instance.authUser.uid;
      final currentAddress = await _db.collection('Users').doc(userId).collection('Addresses').add(address.toJson());
      return currentAddress.id;
    } catch (e) {
      throw 'No se pudo guardar la direccion. Intente de nuevo en unos minutos.';
    }
  }
}