import 'dart:async';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class TFirebaseStorageService extends GetxController {
  static TFirebaseStorageService get instance => Get.find();

  final _firebaseStorage = FirebaseStorage.instance;

  /// Subir los Assets locales desde el IDE
  /// Retornar Uint8List que contiene los datos de imagen
  Future<Uint8List> getImageDataFromAssets(String path) async {
    try {
      final byteData = await rootBundle.load(path);
      final imageData = byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
      return imageData;
    } catch (e) {
      // Manejo de excepciones
      throw 'Error al cargar los datos de imagen: $e';
    }
  }

  /// Subir imagen usando ImageData en Cloud Firebase Storage
  /// Retornar la URL de descarga de la imagen subida.
  Future<String> uploadImageData(String path, Uint8List image, String name) async {
    try {
      final ref = _firebaseStorage.ref(path).child(name);
      await ref.putData(image);
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      // Manejo de excepciones
      if (e is FirebaseException) {
        throw 'Firebase Exception: ${e.message}';
      } else if (e is SocketException) {
        throw 'Error de conexión: ${e.message}';
      } else if (e is PlatformException) {
        throw 'Error de plataforma: ${e.message}';
      } else {
        throw 'Algo salió mal! Por favor intentalo de nuevo.';
      }
    }
  }

  /// Subir Imagen en Cloud Firebase Storage
  /// Retornar el URL de descarga de la imagen subida.
  Future<String> uploadImageFile(String path, XFile image) async {
    try {
      final ref = _firebaseStorage.ref(path).child(image.name);
      await ref.putFile(File(image.path));
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      // Manejo de excepciones
      if (e is FirebaseException) {
        throw 'Firebase Exception: ${e.message}';
      } else if (e is SocketException) {
        throw 'Error de conexión: ${e.message}';
      } else if (e is PlatformException) {
        throw 'Error de plataforma: ${e.message}';
      } else {
        throw 'Algo salió mal! Por favor intentalo de nuevo.';
      }
    }
  }

}