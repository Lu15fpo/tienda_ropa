import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:tienda_ropa/common/widgets/appbar/appbar.dart';
import 'package:tienda_ropa/common/widgets/payment/card_preview.dart';
import 'package:tienda_ropa/features/shop/controllers/payment_method_controller.dart';
import 'package:tienda_ropa/features/shop/models/payment_method_model.dart';
import 'package:tienda_ropa/utils/constants/sizes.dart';
import 'package:tienda_ropa/utils/formatters/card_input_formatters.dart';
import 'package:tienda_ropa/utils/validators/validation.dart';

/// Pantalla para editar un método de pago existente
class EditPaymentMethodScreen extends StatelessWidget {
  const EditPaymentMethodScreen({
    super.key,
    required this.paymentMethod,
  });

  final PaymentMethodModel paymentMethod;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PaymentMethodController());

    // Inicializar los campos con los datos existentes
    controller.initializeEditForm(paymentMethod);

    return Scaffold(
      appBar: const TAppBar(
        showBackArrow: true,
        title: Text('Editar Método de Pago'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          child: Column(
            children: [
              /// Vista previa de la tarjeta (se actualiza en tiempo real)
              Obx(
                () => CardPreview(
                  cardNumber: controller.cardNumberPreview.value,
                  cardHolderName: controller.cardHolderNamePreview.value,
                  expiryDate: controller.expiryDatePreview.value,
                  cardType: controller.detectedCardType.value,
                ),
              ),
              const SizedBox(height: TSizes.spaceBtwSections),

              /// Formulario
              Form(
                key: controller.paymentMethodFormKey,
                child: Column(
                  children: [
                    /// Nombre del titular
                    TextFormField(
                      controller: controller.cardHolderName,
                      validator: TValidator.validateCardHolderName,
                      inputFormatters: [CardHolderNameInputFormatter()],
                      keyboardType: TextInputType.name,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Iconsax.user),
                        labelText: 'Nombre del Titular',
                        hintText: 'JUAN PEREZ',
                      ),
                    ),
                    const SizedBox(height: TSizes.spaceBtwInputFields),

                    /// Número de tarjeta (Solo últimos 4 dígitos - no editable)
                    TextFormField(
                      initialValue: '**** **** **** ${paymentMethod.cardNumberLast4}',
                      enabled: false,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Iconsax.card),
                        labelText: 'Número de Tarjeta',
                        hintText: '**** **** **** 4242',
                      ),
                    ),
                    const SizedBox(height: TSizes.spaceBtwInputFields),

                    /// Fecha de expiración
                    Row(
                      children: [
                        /// Fecha de expiración
                        Expanded(
                          child: TextFormField(
                            controller: controller.expiryDate,
                            validator: TValidator.validateExpiryDate,
                            inputFormatters: [ExpiryDateInputFormatter()],
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Iconsax.calendar),
                              labelText: 'Expiración',
                              hintText: 'MM/YY',
                            ),
                          ),
                        ),
                        const SizedBox(width: TSizes.spaceBtwInputFields),

                        /// Tipo de tarjeta (no editable, solo informativo)
                        Expanded(
                          child: TextFormField(
                            initialValue: paymentMethod.cardType ?? 'Tarjeta',
                            enabled: false,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Iconsax.card_pos),
                              labelText: 'Tipo',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: TSizes.spaceBtwInputFields),

                    /// Toggle para establecer como predeterminado
                    Obx(
                      () => CheckboxListTile(
                        value: controller.isDefault.value,
                        onChanged: (value) => controller.isDefault.value = value ?? false,
                        title: const Text('Establecer como método predeterminado'),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),

                    /// Información de seguridad
                    Container(
                      padding: const EdgeInsets.all(TSizes.md),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Iconsax.shield_tick,
                            color: Colors.blue,
                            size: 24,
                          ),
                          const SizedBox(width: TSizes.spaceBtwItems),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Información segura',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: Colors.blue,
                                      ),
                                ),
                                Text(
                                  'No almacenamos tu número de tarjeta completo ni CVV',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: TSizes.spaceBtwSections),

                    /// Botón de actualizar
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => controller.updatePaymentMethodFromForm(paymentMethod.id),
                        child: const Text('Actualizar Método de Pago'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

