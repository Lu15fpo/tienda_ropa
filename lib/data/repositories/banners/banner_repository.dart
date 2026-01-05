import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:tienda_ropa/features/shop/models/banner_model.dart';
import 'package:tienda_ropa/utils/exceptions/firebase_exceptions.dart';
import 'package:tienda_ropa/utils/exceptions/format_exceptions.dart';

import '../../../utils/exceptions/platform_exceptions.dart';

class BannerRepository extends GetxController {
  static BannerRepository get instance => Get.find();

  /// Variables
  final _db = FirebaseFirestore.instance;


  /// Obtener toda la orden del usuario actual
  Future<List<BannerModel>> fetchBanners() async {
    try {
      final result = await _db.collection('Banners').where('Active', isEqualTo: true).get();
      return result.docs.map((documentSnapshot) => BannerModel.fromSnapshot(documentSnapshot)).toList();

    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Algo salio mal al cargar los Banners.';
    }
  }



  /// Subir los Banners a la Cloud Firebase
}