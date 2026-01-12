import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:get/get.dart';
import 'package:tienda_ropa/utils/popups/full_screen_loader.dart';
import 'package:tienda_ropa/utils/popups/loaders.dart';


/// Servicio de Facturación Electrónica SRI
class FacturacionService extends GetxService {
  static FacturacionService get instance => Get.find();

  late final FirebaseFunctions _functions;

  FacturacionService() {
    _functions = FirebaseFunctions.instanceFor(region: 'us-central1');

    // La configuración del emulador se hace en main.dart
    print('✅ [FacturacionService] Inicializado correctamente');
  }

  /// Genera una factura electrónica para un pedido
  ///
  /// [orderId] - ID del pedido en Firestore
  /// [userId] - ID del usuario dueño del pedido
  /// [showLoader] - Si mostrar el loader o no (por defecto true)
  /// Retorna la clave de acceso de la factura generada o null si falla
  Future<String?> generarFactura(String orderId, String userId, {bool showLoader = true}) async {
    try {
      if (showLoader) {
        TFullScreenLoader.openLoadingDialog(
          'Generando factura electrónica SRI...',
          'assets/animations/141594-animation-of-docer.json',
        );
      }

      // Llamar a la Cloud Function
      final HttpsCallable callable = _functions.httpsCallable('generarFactura');

      final result = await callable.call(<String, dynamic>{
        'orderId': orderId,
        'userId': userId,
      });

      // Cerrar loader solo si lo abrimos
      if (showLoader) {
        TFullScreenLoader.stopLoading();
      }

      if (result.data['success'] == true) {
        final claveAcceso = result.data['claveAcceso'] as String?;
        final mensaje = result.data['mensaje'] as String? ?? 'Factura generada exitosamente';

        TLoaders.successSnackBar(
          title: '¡Éxito!',
          message: mensaje,
        );

        return claveAcceso;
      } else {
        TLoaders.errorSnackBar(
          title: 'Error',
          message: result.data['mensaje'] ?? 'No se pudo generar la factura',
        );
        return null;
      }
    } on FirebaseFunctionsException catch (e) {
      if (showLoader) {
        TFullScreenLoader.stopLoading();
      }

      String errorMessage = 'Error al generar factura';

      switch (e.code) {
        case 'not-found':
          errorMessage = 'Pedido no encontrado';
          break;
        case 'unauthenticated':
          errorMessage = 'Debes iniciar sesión';
          break;
        case 'permission-denied':
          errorMessage = 'No tienes permisos para generar facturas';
          break;
        case 'internal':
          errorMessage = 'Error interno del servidor. Intenta nuevamente';
          break;
        case 'unavailable':
          errorMessage = 'Servicio no disponible. Verifica tu conexión';
          break;
        default:
          errorMessage = e.message ?? 'Error desconocido';
      }

      TLoaders.errorSnackBar(
        title: 'Error de Facturación',
        message: errorMessage,
      );

      return null;
    } catch (e) {
      if (showLoader) {
        TFullScreenLoader.stopLoading();
      }

      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Error inesperado: ${e.toString()}',
      );

      return null;
    }
  }

  /// Consulta el estado de autorización de una factura en el SRI
  ///
  /// [claveAcceso] - Clave de acceso de 49 dígitos de la factura
  Future<Map<String, dynamic>?> consultarAutorizacion(String claveAcceso) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('consultarAutorizacion');

      final result = await callable.call(<String, dynamic>{
        'claveAcceso': claveAcceso,
      });

      if (result.data['success'] == true) {
        return result.data['respuesta'] as Map<String, dynamic>?;
      } else {
        TLoaders.errorSnackBar(
          title: 'Error',
          message: 'No se pudo consultar el estado de la factura',
        );
        return null;
      }
    } on FirebaseFunctionsException catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error de Consulta',
        message: e.message ?? 'Error al consultar autorización',
      );
      return null;
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Error inesperado: ${e.toString()}',
      );
      return null;
    }
  }

  /// Genera factura automáticamente después de confirmar un pedido
  ///
  /// [orderId] - ID del pedido
  /// [userId] - ID del usuario
  /// [autoGenerate] - Si es true, genera automáticamente. Si es false, pregunta al usuario
  Future<void> generarFacturaAutomatica(String orderId, String userId, {bool autoGenerate = true}) async {
    if (autoGenerate) {
      await generarFactura(orderId, userId);
    } else {
      // Mostrar diálogo para preguntar si desea generar factura
      Get.defaultDialog(
        title: 'Factura Electrónica',
        middleText: '¿Deseas generar una factura electrónica para este pedido?',
        textConfirm: 'Sí, generar',
        textCancel: 'Más tarde',
        onConfirm: () async {
          Get.back();
          await generarFactura(orderId, userId);
        },
      );
    }
  }

  /// Obtiene la URL del PDF de la factura desde Firestore
  ///
  /// [facturaId] - ID de la factura (clave de acceso)
  /// Retorna la URL del PDF o null si no existe
  Future<String?> obtenerUrlPdfFactura(String facturaId) async {
    try {
      final facturaDoc = await FirebaseFirestore.instance
          .collection('Facturas')
          .doc(facturaId)
          .get();

      if (!facturaDoc.exists) {
        return null;
      }

      final data = facturaDoc.data();
      return data?['pdfUrl'] as String?;
    } catch (e) {
      print('❌ [FacturacionService] Error al obtener URL del PDF: $e');
      return null;
    }
  }

  /// Obtiene la URL del PDF de una factura a partir del ID del pedido
  ///
  /// [orderId] - ID del pedido
  /// Retorna la URL del PDF o null si no existe
  Future<String?> obtenerUrlPdfPorPedido(String orderId) async {
    try {
      print('🔍 [FacturacionService] Buscando factura para orderId: $orderId');

      // Buscar la factura por orderId
      final facturas = await FirebaseFirestore.instance
          .collection('Facturas')
          .where('orderId', isEqualTo: orderId)
          .limit(1)
          .get();

      print('📊 [FacturacionService] Facturas encontradas: ${facturas.docs.length}');

      if (facturas.docs.isEmpty) {
        print('⚠️ [FacturacionService] No se encontró factura para orderId: $orderId');
        return null;
      }

      final data = facturas.docs.first.data();
      final pdfUrl = data['pdfUrl'] as String?;

      print('📄 [FacturacionService] pdfUrl encontrada: $pdfUrl');

      return pdfUrl;
    } catch (e) {
      print('❌ [FacturacionService] Error al obtener URL del PDF por pedido: $e');
      return null;
    }
  }
}


