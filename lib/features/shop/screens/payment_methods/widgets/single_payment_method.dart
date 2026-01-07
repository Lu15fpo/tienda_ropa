import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:tienda_ropa/common/widgets/custom_shapes/containers/rounded_container.dart';
import 'package:tienda_ropa/features/shop/models/payment_method_model.dart';
import 'package:tienda_ropa/utils/constants/colors.dart';
import 'package:tienda_ropa/utils/constants/sizes.dart';
import 'package:tienda_ropa/utils/helpers/helper_functions.dart';

/// Widget para mostrar un método de pago en una lista
/// Similar a TSingleAddress pero para métodos de pago
class SinglePaymentMethod extends StatelessWidget {
  const SinglePaymentMethod({
    super.key,
    required this.paymentMethod,
    required this.onTap,
    this.showEditButton = true,
    this.onEdit,
    this.onDelete,
  });

  final PaymentMethodModel paymentMethod;
  final VoidCallback onTap;
  final bool showEditButton;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);

    return GestureDetector(
      onTap: onTap,
      child: TRoundedContainer(
        padding: const EdgeInsets.all(TSizes.md),
        width: double.infinity,
        showBorder: true,
        backgroundColor: paymentMethod.isDefault
            ? TColors.primary.withValues(alpha: 0.1)
            : Colors.transparent,
        borderColor: paymentMethod.isDefault
            ? TColors.primary
            : dark
                ? TColors.darkGrey
                : TColors.grey,
        margin: const EdgeInsets.only(bottom: TSizes.spaceBtwItems),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Tipo de tarjeta y marca de predeterminado
                Row(
                  children: [
                    /// Icono de tipo de tarjeta
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: TSizes.sm,
                        vertical: TSizes.xs,
                      ),
                      decoration: BoxDecoration(
                        color: dark ? TColors.dark : TColors.light,
                        borderRadius: BorderRadius.circular(TSizes.sm),
                        border: Border.all(color: TColors.grey),
                      ),
                      child: Text(
                        paymentMethod.cardType ?? 'Card',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                    const SizedBox(width: TSizes.spaceBtwItems),

                    /// Marca de predeterminado
                    if (paymentMethod.isDefault)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: TSizes.sm,
                          vertical: TSizes.xs,
                        ),
                        decoration: BoxDecoration(
                          color: TColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(TSizes.sm),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: TColors.primary,
                              size: 16,
                            ),
                            const SizedBox(width: TSizes.xs),
                            Text(
                              'Predeterminado',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium!
                                  .apply(color: TColors.primary),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: TSizes.spaceBtwItems / 2),

                /// Número de tarjeta enmascarado
                Text(
                  paymentMethod.maskedCardNumber,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: TSizes.spaceBtwItems / 4),

                /// Nombre del titular
                Row(
                  children: [
                    const Icon(Iconsax.user, size: 16, color: Colors.grey),
                    const SizedBox(width: TSizes.spaceBtwItems / 2),
                    Expanded(
                      child: Text(
                        paymentMethod.cardHolderName ?? '',
                        style: Theme.of(context).textTheme.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: TSizes.spaceBtwItems / 4),

                /// Fecha de expiración
                Row(
                  children: [
                    const Icon(Iconsax.calendar, size: 16, color: Colors.grey),
                    const SizedBox(width: TSizes.spaceBtwItems / 2),
                    Text(
                      'Expira: ${paymentMethod.expiryDate}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),

            /// Botones de acción (editar/eliminar)
            if (showEditButton)
              Positioned(
                right: 0,
                top: 0,
                child: Row(
                  children: [
                    /// Botón editar
                    if (onEdit != null)
                      IconButton(
                        onPressed: onEdit,
                        icon: const Icon(Iconsax.edit, size: 18),
                        color: TColors.primary,
                      ),

                    /// Botón eliminar
                    if (onDelete != null)
                      IconButton(
                        onPressed: onDelete,
                        icon: const Icon(Iconsax.trash, size: 18),
                        color: Colors.red,
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

