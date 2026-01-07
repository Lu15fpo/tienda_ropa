import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:tienda_ropa/common/widgets/appbar/appbar.dart';
import 'package:tienda_ropa/common/widgets/payment/card_preview.dart';
import 'package:tienda_ropa/features/shop/controllers/payment_method_controller.dart';
import 'package:tienda_ropa/utils/constants/sizes.dart';
import 'package:tienda_ropa/utils/formatters/card_input_formatters.dart';
import 'package:tienda_ropa/utils/validators/validation.dart';

/// Pantalla para agregar un nuevo método de pago
class AddPaymentMethodScreen extends StatelessWidget {
  const AddPaymentMethodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PaymentMethodController());

    return Scaffold(
      appBar: const TAppBar(
        showBackArrow: true,
        title: Text('Agregar Método de Pago'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          child: Column(
            children: [
              /// Vista previa de la tarjeta (se actualiza en tiempo real)
              Obx(
                () => CardPreview(
                  cardNumber: controller.cardNumber.text,
                  cardHolderName: controller.cardHolderName.text,
                  expiryDate: controller.expiryDate.text,
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

                    /// Número de tarjeta
                    TextFormField(
                      controller: controller.cardNumber,
                      validator: TValidator.validateCardNumber,
                      inputFormatters: [CardNumberInputFormatter()],
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Iconsax.card),
                        labelText: 'Número de Tarjeta',
                        hintText: '4242 4242 4242 4242',
                      ),
                      onChanged: (value) => controller.onCardNumberChanged(value),
                    ),
                    const SizedBox(height: TSizes.spaceBtwInputFields),

                    /// Fecha de expiración y CVV (en la misma fila)
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

                        /// CVV
                        Expanded(
                          child: TextFormField(
                            controller: controller.cvv,
                            validator: TValidator.validateCVV,
                            inputFormatters: [CVVInputFormatter(maxLength: 3)],
                            keyboardType: TextInputType.number,
                            obscureText: true,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Iconsax.shield_tick),
                              labelText: 'CVV',
                              hintText: '123',
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
                    const SizedBox(height: TSizes.spaceBtwSections),

                    /// Información de seguridad
                    Container(
                      padding: const EdgeInsets.all(TSizes.md),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
                        border: Border.all(
                          color: Colors.blue.withValues(alpha: 0.3),
                        ),
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
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tu información está protegida. Solo guardamos los últimos 4 dígitos de tu tarjeta.',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: TSizes.spaceBtwSections),

                    /// Botón de guardar
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => controller.addNewPaymentMethod(),
                        child: const Text('Guardar Método de Pago'),
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

