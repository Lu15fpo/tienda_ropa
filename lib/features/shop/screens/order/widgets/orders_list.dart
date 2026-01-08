import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:tienda_ropa/common/widgets/custom_shapes/containers/rounded_container.dart';
import 'package:tienda_ropa/common/widgets/loaders/animation_loader.dart';
import 'package:tienda_ropa/features/shop/screens/order/order_detail.dart';
import 'package:tienda_ropa/utils/helpers/cloud_helper_functions.dart';
import 'package:tienda_ropa/utils/helpers/order_status_helper.dart';

import '../../../../../navigation_menu.dart';
import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/image_strings.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/helpers/helper_functions.dart';
import '../../../controllers/product/order_controller.dart';

class TOrderListItems extends StatelessWidget {
  const TOrderListItems({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(OrderController());
    THelperFunctions.isDarkMode(context);
    return FutureBuilder(
      future: controller.fetchUserOrders(),
      builder: (_, snapshot) {
        /// No se encontro el Widget
        final emptyWidget = TAnimationLoaderWidget(
          text: 'Ooops! No hay pedidos',
          animation: TImages.orderCompletedAnimation,
          showAction: true,
          actionText: 'Vamos a la tienda',
          onActionPressed: () => Get.off(() => const NavigationMenu()),
        );

        /// Funcion de ayuda: Manejo del Loader, No Record o mensaje de error
        final response = TCloudHelperFunctions.checkMultiRecordState(snapshot: snapshot, nothingFound: emptyWidget);
        if (response != null) return response;

        /// Felicidades historial encontrado.
        final orders = snapshot.data!;
        return ListView.separated(
          shrinkWrap: true,
          itemCount: orders.length,
          separatorBuilder: (_, index) => const SizedBox(height: TSizes.spaceBtwItems),
          itemBuilder: (_, index) {
            final order = orders[index];
            return TRoundedContainer(
              showBorder: true,
              padding: const EdgeInsets.all(TSizes.md),
              backgroundColor: THelperFunctions.isDarkMode(context) ? TColors.dark : TColors.light,
              child: Column(
                children: [
                  /// -- Row 1
                  Row(
                    children: [
                      /// 1 - Icono del estado (dinámico)
                      Icon(
                        OrderStatusHelper.getStatusIcon(order.status),
                        color: OrderStatusHelper.getStatusColor(order.status),
                      ),
                      const SizedBox(width: TSizes.spaceBtwItems / 2),

                      /// 2 - Estado y Fecha
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.orderStatusText,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyLarge!.apply(
                                color: OrderStatusHelper.getStatusColor(order.status),
                                fontWeightDelta: 1,
                              ),
                            ),
                            Text(order.formattedOrderDate, style: Theme.of(context).textTheme.headlineSmall),
                          ],
                        ),
                      ),

                      /// 3 - Icono
                      IconButton(
                        onPressed: () => Get.to(() => OrderDetailScreen(order: order)),
                        icon: const Icon(Iconsax.arrow_right_34, size: TSizes.iconSm),
                      ),
                    ],
                  ),
                  const SizedBox(height: TSizes.spaceBtwItems),

                  /// -- Row 2
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            /// 1 - Icono
                            const Icon(Iconsax.tag),
                            const SizedBox(width: TSizes.spaceBtwItems / 2),

                            /// 2 - Estado y Fecha
                            Flexible(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Orden', maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelMedium),
                                  Text(order.id, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      Expanded(
                        child: Row(
                          children: [
                            /// 1 - Icono
                            const Icon(Iconsax.calendar),
                            const SizedBox(width: TSizes.spaceBtwItems / 2),

                            /// 2 - Estado y Fecha
                            Flexible(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Fecha de Entrega', maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelMedium),
                                  Text(order.formattedDeliveryDate, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }
        );
      }
    );
  }
}