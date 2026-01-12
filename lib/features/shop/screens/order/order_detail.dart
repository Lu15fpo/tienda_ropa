import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:tienda_ropa/common/widgets/appbar/appbar.dart';
import 'package:tienda_ropa/common/widgets/custom_shapes/containers/rounded_container.dart';
import 'package:tienda_ropa/features/shop/models/order_model.dart';
import 'package:tienda_ropa/utils/constants/colors.dart';
import 'package:tienda_ropa/utils/constants/enums.dart';
import 'package:tienda_ropa/utils/constants/sizes.dart';
import 'package:tienda_ropa/utils/helpers/helper_functions.dart';
import 'package:tienda_ropa/utils/helpers/order_status_helper.dart';

import '../../controllers/product/order_controller.dart';

/// Pantalla de detalle del pedido
class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({
    super.key,
    required this.order,
  });

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(OrderController());
    final dark = THelperFunctions.isDarkMode(context);

    // Verificar si el pedido puede ser modificado (Pendiente o Procesando)
    final canModify = order.status == OrderStatus.pending ||
                      order.status == OrderStatus.processing;

    return Scaffold(
      appBar: TAppBar(
        title: Text(
          'Detalle del Pedido',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        showBackArrow: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Estado del Pedido
              TRoundedContainer(
                showBorder: true,
                padding: const EdgeInsets.all(TSizes.md),
                backgroundColor: OrderStatusHelper.getStatusBackgroundColor(order.status),
                borderColor: OrderStatusHelper.getStatusColor(order.status),
                child: Row(
                  children: [
                    Icon(
                      OrderStatusHelper.getStatusIcon(order.status),
                      color: OrderStatusHelper.getStatusColor(order.status),
                      size: 32,
                    ),
                    const SizedBox(width: TSizes.spaceBtwItems),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Estado del Pedido',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Text(
                            order.orderStatusText,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: OrderStatusHelper.getStatusColor(order.status),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: TSizes.spaceBtwSections),

              /// Información del Pedido
              _buildInfoSection(
                context: context,
                title: 'Información del Pedido',
                dark: dark,
                children: [
                  _buildInfoRow(
                    context: context,
                    icon: Iconsax.tag,
                    label: 'ID del Pedido',
                    value: order.id,
                  ),
                  _buildInfoRow(
                    context: context,
                    icon: Iconsax.calendar,
                    label: 'Fecha del Pedido',
                    value: order.formattedOrderDate,
                  ),
                  _buildInfoRow(
                    context: context,
                    icon: Iconsax.calendar_1,
                    label: 'Fecha de Entrega',
                    value: order.formattedDeliveryDate,
                  ),
                ],
              ),
              const SizedBox(height: TSizes.spaceBtwSections),

              /// Dirección de Envío
              _buildInfoSection(
                context: context,
                title: 'Dirección de Envío',
                dark: dark,
                children: [
                  if (order.address != null) ...[
                    _buildInfoRow(
                      context: context,
                      icon: Iconsax.location,
                      label: 'Nombre',
                      value: order.address!.name,
                    ),
                    _buildInfoRow(
                      context: context,
                      icon: Iconsax.call,
                      label: 'Teléfono',
                      value: order.address!.phoneNumber,
                    ),
                    _buildInfoRow(
                      context: context,
                      icon: Iconsax.house,
                      label: 'Dirección',
                      value: '${order.address!.street}, ${order.address!.city}, ${order.address!.state} ${order.address!.postalCode}',
                      maxLines: 3,
                    ),
                  ] else
                    const Text('No hay dirección registrada'),
                ],
              ),
              const SizedBox(height: TSizes.spaceBtwSections),

              /// Método de Pago
              _buildInfoSection(
                context: context,
                title: 'Método de Pago',
                dark: dark,
                children: [
                  _buildInfoRow(
                    context: context,
                    icon: Iconsax.card,
                    label: 'Método',
                    value: order.paymentMethod,
                  ),
                ],
              ),
              const SizedBox(height: TSizes.spaceBtwSections),

              /// Productos
              _buildInfoSection(
                context: context,
                title: 'Productos (${order.items.length})',
                dark: dark,
                children: [
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: order.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: TSizes.spaceBtwItems),
                    itemBuilder: (_, index) {
                      final item = order.items[index];
                      return Row(
                        children: [
                          /// Imagen del producto
                          TRoundedContainer(
                            width: 60,
                            height: 60,
                            padding: const EdgeInsets.all(TSizes.sm),
                            backgroundColor: dark ? TColors.darkerGrey : TColors.light,
                            child: item.image != null && item.image!.isNotEmpty
                                ? Image.network(
                                    item.image!,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => const Icon(Iconsax.box),
                                  )
                                : const Icon(Iconsax.box),
                          ),
                          const SizedBox(width: TSizes.spaceBtwItems),

                          /// Detalles del producto
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: Theme.of(context).textTheme.titleMedium,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Cantidad: ${item.quantity}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),

                          /// Precio
                          Text(
                            '\$${item.price}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: TColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: TSizes.spaceBtwSections),

              /// Resumen de Costos
              _buildInfoSection(
                context: context,
                title: 'Resumen',
                dark: dark,
                children: [
                  _buildCostRow(context, 'Subtotal', order.totalAmount - order.shippingCost - order.taxCost + order.discount),
                  _buildCostRow(context, 'Envío', order.shippingCost),
                  _buildCostRow(context, 'Impuestos', order.taxCost),
                  if (order.discount > 0)
                    _buildCostRow(context, 'Descuento', -order.discount, isDiscount: true),
                  const Divider(),
                  _buildCostRow(
                    context,
                    'Total',
                    order.totalAmount,
                    isTotal: true,
                  ),
                ],
              ),
              const SizedBox(height: TSizes.spaceBtwSections),

              /// Botón Ver Factura PDF (Siempre visible)
              const Divider(),
              const SizedBox(height: TSizes.spaceBtwItems),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => controller.verPdfFactura(order.id),
                  icon: const Icon(Iconsax.document),
                  label: const Text('Ver Factura PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),

              /// Botones de Acción (Solo si puede modificar)
              if (canModify) ...[
                const SizedBox(height: TSizes.spaceBtwItems),

                /// Botón Cambiar Dirección
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => controller.changeOrderAddress(order),
                    icon: const Icon(Iconsax.location),
                    label: const Text('Cambiar Dirección de Envío'),
                  ),
                ),
                const SizedBox(height: TSizes.spaceBtwItems),

                /// Botón Anular Pedido
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => controller.cancelOrder(order.id),
                    icon: const Icon(Iconsax.close_circle),
                    label: const Text('Anular Pedido'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: TColors.error,
                      side: const BorderSide(color: TColors.error),
                    ),
                  ),
                ),
              ] else ...[
                /// Mensaje informativo si no puede modificar
                TRoundedContainer(
                  showBorder: true,
                  padding: const EdgeInsets.all(TSizes.md),
                  backgroundColor: Colors.blue.withValues(alpha: 0.1),
                  borderColor: Colors.blue,
                  child: Row(
                    children: [
                      const Icon(
                        Iconsax.info_circle,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: TSizes.spaceBtwItems),
                      Expanded(
                        child: Text(
                          order.status == OrderStatus.cancelled
                              ? 'Este pedido fue cancelado'
                              : 'Este pedido ya fue ${order.status == OrderStatus.shipped ? "enviado" : "entregado"} y no puede ser modificado',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Widget para construir una sección de información
  Widget _buildInfoSection({
    required BuildContext context,
    required String title,
    required List<Widget> children,
    required bool dark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: TSizes.spaceBtwItems),
        TRoundedContainer(
          showBorder: true,
          padding: const EdgeInsets.all(TSizes.md),
          backgroundColor: dark ? TColors.darkerGrey : TColors.white,
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  /// Widget para construir una fila de información
  Widget _buildInfoRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TSizes.spaceBtwItems / 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: TColors.darkGrey),
          const SizedBox(width: TSizes.spaceBtwItems),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: TColors.darkGrey,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Widget para construir una fila de costo
  Widget _buildCostRow(
    BuildContext context,
    String label,
    double amount, {
    bool isTotal = false,
    bool isDiscount = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TSizes.spaceBtwItems / 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isTotal
                ? Theme.of(context).textTheme.titleLarge
                : Theme.of(context).textTheme.bodyLarge,
          ),
          Text(
            '${isDiscount ? "-" : ""}\$${amount.toStringAsFixed(2)}',
            style: isTotal
                ? Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: TColors.primary,
                      fontWeight: FontWeight.bold,
                    )
                : Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: isDiscount ? TColors.success : null,
                      fontWeight: FontWeight.w600,
                    ),
          ),
        ],
      ),
    );
  }
}

