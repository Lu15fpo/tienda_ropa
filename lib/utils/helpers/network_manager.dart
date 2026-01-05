import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../popups/loaders.dart';

/// Manejo del estatus de conectividad y proveer metodos para conectarse a Internet
class NetworkManager extends GetxController {
  static NetworkManager get instance => Get.find();

  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  final Rx<ConnectivityResult> _connectionStatus = ConnectivityResult.none.obs;

  /// Inicializar el controlador de internet e instalar el stream para revisar el estatus de conexion
  @override
  void onInit() {
    super.onInit();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  /// Actualizar el estatus de conexion basado en los cambios en conectividad y mostrar mensaje de no conexion
  Future<void> _updateConnectionStatus(List<ConnectivityResult> results) async {
    _connectionStatus.value = results.isNotEmpty ? results.first : ConnectivityResult.none;
    if (_connectionStatus.value == ConnectivityResult.none) {
      TLoaders.warningSnackBar(title: 'No hay conexion a Internet');
    }
  }

  /// Revisar si hay conexion a Internet
  /// Retornar true si hay conexion, false si no hay conexion
  Future<bool> isConnected() async {
    try {
      final results = await _connectivity.checkConnectivity();
      if (results.contains(ConnectivityResult.none) || results.isEmpty) {
        return false;
      } else {
        return true;
      }
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Disponer o cerrar la conexion activa de stream
  @override
  void onClose() {
    super.onClose();
    _connectivitySubscription.cancel();
  }
}