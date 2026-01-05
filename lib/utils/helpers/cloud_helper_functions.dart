import 'dart:io' as html;

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TCloudHelperFunctions {

  /// Funcion de ayuda para revisar el estado de un solo registro de la base de datos.
  ///
  /// Retorna un Widget basado en el estado del snapshot.
  /// Si los datos estan cargando, se muestra un CircularProgressIndicator.
  /// Si no hay datos, se muestra un mensaje generico "No Se encontro Datos".
  /// Si sucede un error, se muestra un mensaje generico.
  /// De lo contrario, retorna nulo.
  static Widget? checkSingleRecordState<T>(AsyncSnapshot<T> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!snapshot.hasData || snapshot.data == null) {
      return const Center(child: Text('No Se encontro Datos!'));
    }

    if (snapshot.hasError) {
      return const Center(child: Text('Algo salio mal.'));
    }

    return null;
  }

  /// Funcion de ayuda para revisar el estado de multiples (lista) registros de la base de datos.
  ///
  /// Retorna un Widget basado en el estado del snapshot.
  /// Si los datos estan cargando, retorna un CircularProgressIndicator.
  /// Si no se encontraron datos, retorna un mensaje generico "No Se encontro Datos!" o de manera predeterminado nothingFoundWidget si se provee.
  /// Si ocurre un error, retorna un mensaje generico "Algo salio mal."
  /// De lo contrario, retorna nulo.
  static Widget? checkMultiRecordState<T>({required AsyncSnapshot<List<T>> snapshot, Widget? loader, Widget? error, Widget? nothingFound}) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      if (loader != null) return loader;
      return const Center(child: CircularProgressIndicator());
    }

    if (!snapshot.hasData || snapshot.data == null || snapshot.data!.isEmpty) {
      if (nothingFound != null) return nothingFound;
      return const Center(child: Text('No Se encontro Datos!'));
    }

    if (snapshot.hasError) {
      if (error != null) return error;
      return const Center(child: Text('Algo salio mal.'));
    }

    return null;
  }

  /// Crea una referencia con archivo o carpeta inicial y nombre y recupera la URL de descarga.
  static Future<String> getURLFromFilePathAndName(String path) async {
    try {
      if (path.isEmpty) return '';
      final ref = FirebaseStorage.instance.ref().child(path);
      final url = await ref.getDownloadURL();
      return url;
    } on FirebaseException catch (e) {
      throw e.message!;
    } on PlatformException catch (e) {
      throw e.message!;
    } catch (e) {
      throw 'Algo salio mal.';
    }
  }

  /// Recupera la URL de descarga de una URI de almacenamiento determinada.
  static Future<String> getURLFromURI(String url) async {
    try {
      if (url.isEmpty) return '';
      final ref = FirebaseStorage.instance.refFromURL(url);
      final downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } on FirebaseException catch (e) {
      throw e.message!;
    } on PlatformException catch (e) {
      throw e.message!;
    } catch (e) {
      throw 'Something went wrong.';
    }
  }

  /// Sube cualquier imagen usando un archivo
  static Future<String> uploadImageFile({required html.File file, required String path, required String imageName}) async {
    try {
      final ref = FirebaseStorage.instance.ref(path).child(imageName);
      await ref.putBlob(file);

      final String downloadURL = await ref.getDownloadURL();

      // Return the download URL
      return downloadURL;
    } on FirebaseException catch (e) {
      throw e.message!;
    } on html.SocketException catch (e) {
      throw e.message;
    } on PlatformException catch (e) {
      throw e.message!;
    } catch (e) {
      throw e.toString();
    }
  }

  static Future<void> deleteFileFromStorage(String downloadUrl) async {
    try {
      Reference ref = FirebaseStorage.instance.refFromURL(downloadUrl);
      await ref.delete();

      print('Archivo eliminado exitosamente.');
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        print('El archivo no existe en Firebase Storage.');
      } else {
        throw e.message!;
      }
    } on html.SocketException catch (e) {
      throw e.message;
    } on PlatformException catch (e) {
      throw e.message!;
    } catch (e) {
      throw e.toString();
    }
  }
}