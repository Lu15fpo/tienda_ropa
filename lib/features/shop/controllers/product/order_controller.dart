import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tienda_ropa/common/widgets/success_screen/success_screen.dart';
import 'package:tienda_ropa/data/services/facturacion_service.dart';
import 'package:tienda_ropa/features/shop/controllers/product/cart_controller.dart';
import 'package:tienda_ropa/features/shop/controllers/product/checkout_controller.dart';
import 'package:tienda_ropa/features/shop/models/payment_method_model.dart';
import 'package:tienda_ropa/utils/constants/enums.dart';
import 'package:tienda_ropa/utils/constants/image_strings.dart';
import 'package:tienda_ropa/utils/popups/full_screen_loader.dart';
import 'package:tienda_ropa/utils/popups/loaders.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../data/repositories/authentication/authentication_repository.dart';
import '../../../../data/repositories/order/order_repository.dart';
import '../../../../data/repositories/product_repository.dart';
import '../../../../navigation_menu.dart';
import '../../../../utils/helpers/pricing_calculator.dart';
import '../../../personalization/controllers/address_controller.dart';
import '../../../personalization/screens/address/widgets/single_address.dart';
import '../../models/order_model.dart';

class OrderController extends GetxController {
  static OrderController get instance => Get.find();

  /// Variables
  final cartController = CartController.instance;
  final addressController = AddressController.instance;
  final checkoutController = CheckoutController.instance;
  final orderRepository = Get.put(OrderRepository());
  final facturacionService = FacturacionService.instance;

  /// Obtener historial de pedido de usuarios
  Future<List<OrderModel>> fetchUserOrders() async {
    try {
      final userOrders = await orderRepository.fetchUserOrders();
      return userOrders;
    } catch (e) {
      TLoaders.warningSnackBar(title: 'Oh Vaya!', message: e.toString());
      return [];
    }
  }

  /// Formatear método de pago para guardarlo en el pedido
  String _formatPaymentMethodForOrder(PaymentMethodModel method) {
    // Si es una tarjeta guardada (tiene cardHolderName)
    if (method.cardHolderName != null && method.cardHolderName!.isNotEmpty) {
      return '${method.cardType ?? 'Tarjeta'} **** ${method.cardNumberLast4 ?? '****'}';
    }

    // Si es un método antiguo (Paypal, Google Pay, etc.)
    if (method.name.isNotEmpty) {
      return method.name;
    }

    // Fallback
    return 'No especificado';
  }

  /// Agregar metodo para procesar el pedido
  void processOrder(double totalAmount) async {
    try {
      // Validar que haya una dirección seleccionada
      if (addressController.selectedAddress.value.id.isEmpty) {
        TLoaders.warningSnackBar(
          title: 'Dirección requerida',
          message: 'Por favor selecciona una dirección de envío antes de continuar.'
        );
        return;
      }

      // Empezar Carga
      TFullScreenLoader.openLoadingDialog('Procesando Pedido y Factura...', TImages.pencilAnimation);

      // Obtener ID de autentificacion de usuario
      final userId = AuthenticationRepository.instance.authUser.uid;
      if (userId.isEmpty) {
        TFullScreenLoader.stopLoading();
        TLoaders.errorSnackBar(title: 'Error', message: 'No se pudo obtener el usuario.');
        return;
      }

      print('📍 [OrderController] Dirección seleccionada: ${addressController.selectedAddress.value.name}');
      print('📍 [OrderController] Dirección completa: ${addressController.selectedAddress.value.toString()}');

      // Obtener subtotal del carrito
      final subTotal = cartController.totalCartPrice.value;
      final location = 'US'; // Puedes cambiarlo según la ubicación del usuario

      // Calcular costos individuales
      final shippingCost = double.parse(TPricingCalculator.calculateShippingCost(subTotal, location));
      final taxCost = double.parse(TPricingCalculator.calculateTax(subTotal, location));
      final discount = 0.0; // Aquí puedes agregar lógica de descuentos si existe

      // Agregar Detalles
      final order = OrderModel(
        // Generar un ID unico para el pedido
        id: UniqueKey().toString(),
        userId: userId,
        status: OrderStatus.pending,
        totalAmount: totalAmount,
        orderDate: DateTime.now(),
        paymentMethod: _formatPaymentMethodForOrder(checkoutController.selectedPaymentMethod.value),
        address: addressController.selectedAddress.value,
        // Calcular fecha de entrega
        deliveryDate: DateTime.now(),
        items: cartController.cartItems.toList(),
        // Agregar desglose de costos
        shippingCost: shippingCost,
        taxCost: taxCost,
        discount: discount,
      );

      // Guardar pedido en Firestore y obtener el ID real
      final realOrderId = await orderRepository.saveOrder(order, userId);
      print('✅ [OrderController] Pedido guardado con ID: $realOrderId');

      // Actualizar stock de productos en Firebase
      try {
        print('📦 Actualizando stock de productos...');
        for (var item in cartController.cartItems) {
          if (item.variationId != null && item.variationId!.isNotEmpty) {
            // Producto con variación
            await ProductRepository.instance.updateProductVariationStock(
              item.productId,
              item.variationId!,
              item.quantity
            );
          } else {
            // Producto simple
            await ProductRepository.instance.updateProductStock(
              item.productId,
              item.quantity
            );
          }
        }
        print('✅ Stock actualizado correctamente');
      } catch (e) {
        print('⚠️ Error actualizando stock: $e');
        // No detenemos el proceso, solo registramos el error
      }

      // Actualizar estado del carrito
      cartController.clearCart();

      // ✅ GENERAR FACTURA ELECTRÓNICA SRI AUTOMÁTICAMENTE
      print('📄 [OrderController] Generando factura electrónica SRI...');
      try {
        // Usar el ID REAL de Firestore, no el de UniqueKey
        await facturacionService.generarFactura(realOrderId, userId, showLoader: false);
        print('✅ [OrderController] Factura generada exitosamente');
      } catch (e) {
        print('⚠️ [OrderController] Error al generar factura (no crítico): $e');
        // No bloqueamos el flujo si falla la factura
      }

      // Cerrar loader del pedido
      TFullScreenLoader.stopLoading();

      // Mostrar pantalla de confirmacion
      Get.off(() => SuccessScreen(
        image: TImages.orderCompletedAnimation,
        title: 'Pago Satisfactorio!',
        subTitle: 'Tu pedido sera enviado pronto!',
        onPressed: () => Get.offAll(() => const NavigationMenu()),
      ));
    } catch (e) {
      TLoaders.errorSnackBar(title: 'Oh Vaya!', message: e.toString());
    }
  }

  /// Anular pedido (Cambiar estado a cancelado)
  Future<void> cancelOrder(String orderId) async {
    try {
      // Mostrar confirmación
      Get.defaultDialog(
        title: '¿Anular Pedido?',
        middleText: 'Esta acción cambiará el estado del pedido a "Cancelado". ¿Deseas continuar?',
        textConfirm: 'Sí, Anular',
        textCancel: 'No',
        confirmTextColor: Colors.white,
        buttonColor: Colors.red,
        onConfirm: () async {
          // Cerrar diálogo
          Get.back();

          // Mostrar loader
          TFullScreenLoader.openLoadingDialog(
            'Anulando pedido...',
            TImages.docerAnimation,
          );

          // Actualizar estado en Firebase
          await orderRepository.updateOrderStatus(orderId, OrderStatus.cancelled);

          // Ocultar loader
          TFullScreenLoader.stopLoading();

          // Mensaje de éxito
          TLoaders.successSnackBar(
            title: 'Pedido Anulado',
            message: 'El pedido ha sido cancelado exitosamente.',
          );

          // Regresar a la pantalla anterior
          Get.back();
        },
      );
    } catch (e) {
      TFullScreenLoader.stopLoading();
      TLoaders.errorSnackBar(
        title: 'Error',
        message: e.toString(),
      );
    }
  }

  /// Cambiar dirección de envío del pedido
  Future<void> changeOrderAddress(OrderModel order) async {
    try {
      // Obtener direcciones del usuario
      final addresses = await addressController.getAllUserAddresses();

      if (addresses.isEmpty) {
        TLoaders.warningSnackBar(
          title: 'Sin Direcciones',
          message: 'Por favor agrega una dirección de envío primero.',
        );
        return;
      }

      // Mostrar modal con lista de direcciones
      Get.bottomSheet(
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Get.isDarkMode ? Colors.grey[900] : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Seleccionar Nueva Dirección',
                style: Get.textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: addresses.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (_, index) {
                    final address = addresses[index];
                    return TSingleAddress(
                      address: address,
                      onTap: () async {
                        // Cerrar modal
                        Get.back();

                        // Confirmar cambio
                        Get.defaultDialog(
                          title: '¿Cambiar Dirección?',
                          middleText: '¿Deseas cambiar la dirección de envío a "${address.name}"?',
                          textConfirm: 'Sí, Cambiar',
                          textCancel: 'Cancelar',
                          confirmTextColor: Colors.white,
                          onConfirm: () async {
                            // Cerrar diálogo
                            Get.back();

                            // Mostrar loader
                            TFullScreenLoader.openLoadingDialog(
                              'Actualizando dirección...',
                              TImages.docerAnimation,
                            );

                            // Actualizar dirección en Firebase
                            await orderRepository.updateOrderAddress(order.id, address);

                            // Ocultar loader
                            TFullScreenLoader.stopLoading();

                            // Mensaje de éxito
                            TLoaders.successSnackBar(
                              title: 'Dirección Actualizada',
                              message: 'La dirección de envío ha sido cambiada exitosamente.',
                            );

                            // Regresar a la pantalla anterior
                            Get.back();
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        isDismissible: true,
        enableDrag: true,
      );
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: e.toString(),
      );
    }
  }

  /// Ver PDF de la factura
  Future<void> verPdfFactura(String orderId) async {
    try {
      // Mostrar loader
      TFullScreenLoader.openLoadingDialog(
        'Obteniendo factura...',
        TImages.docerAnimation,
      );

      // Obtener URL del PDF desde Firestore
      final pdfUrl = await facturacionService.obtenerUrlPdfPorPedido(orderId);

      // Ocultar loader
      TFullScreenLoader.stopLoading();

      if (pdfUrl == null || pdfUrl.isEmpty) {
        TLoaders.warningSnackBar(
          title: 'Factura no disponible',
          message: 'La factura para este pedido aún no ha sido generada.',
        );
        return;
      }

      // Abrir PDF en el navegador/visor del sistema
      final uri = Uri.parse(pdfUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        TLoaders.errorSnackBar(
          title: 'Error',
          message: 'No se pudo abrir el PDF. Por favor intenta nuevamente.',
        );
      }
    } catch (e) {
      TFullScreenLoader.stopLoading();
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Error al obtener la factura: ${e.toString()}',
      );
    }
  }
}