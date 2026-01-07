import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:tienda_ropa/common/widgets/appbar/appbar.dart';

import '../../../../utils/constants/sizes.dart';
import '../../../../utils/validators/validation.dart';
import '../../controllers/address_controller.dart';

class AddNewAddressScreen extends StatelessWidget {
  const AddNewAddressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AddressController.instance;

    return Scaffold(
      appBar: const TAppBar(showBackArrow: true, title: Text('Agregar una Direccion')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          child: Form(
            key: controller.addressFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                    controller: controller.name,
                    validator: (value) => TValidator.validateEmptyText('Name', value),
                    decoration: const InputDecoration(prefixIcon: Icon(Iconsax.user), labelText: 'Nombre')
                ),
                const SizedBox(height: TSizes.spaceBtwInputFields),
                TextFormField(
                    controller: controller.phoneNumber,
                    validator: TValidator.validatePhoneNumber,
                    decoration: const InputDecoration(prefixIcon: Icon(Iconsax.mobile), labelText: 'N° de Telefono')
                ),
                const SizedBox(height: TSizes.spaceBtwInputFields),
                Row(
                  children: [
                    Expanded(
                        child: TextFormField(
                            controller: controller.street,
                            validator: (value) => TValidator.validateEmptyText('Street', value),
                            decoration: const InputDecoration(prefixIcon: Icon(Iconsax.building_31), labelText: 'Calle')
                        )
                    ),
                    const SizedBox(height: TSizes.spaceBtwInputFields),
                    Expanded(
                        child: TextFormField(
                            controller: controller.postalCode,
                            validator: (value) => TValidator.validateEmptyText('Codigo Postal', value),
                            decoration: const InputDecoration(prefixIcon: Icon(Iconsax.code), labelText: 'Codigo Postal')
                        )
                    ),
                  ],
                ),
                const SizedBox(height: TSizes.spaceBtwInputFields),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                          controller: controller.city,
                          validator: (value) => TValidator.validateEmptyText('Ciudad', value),
                          expands: false,
                          decoration: const InputDecoration(labelText: 'Ciudad', prefixIcon: Icon(Iconsax.building))
                      ),
                    ),
                    const SizedBox(height: TSizes.spaceBtwInputFields),
                    Expanded(
                        child: TextFormField(
                            controller: controller.state,
                            validator: (value) => TValidator.validateEmptyText('Provincia', value),
                            expands: false,
                            decoration: const InputDecoration(prefixIcon: Icon(Iconsax.activity), labelText: 'Provincia')
                        ),
                    ),
                  ],
                ),
                const SizedBox(height: TSizes.spaceBtwInputFields),
                TextFormField(
                    controller: controller.country,
                    validator: (value) => TValidator.validateEmptyText('País', value),
                    decoration: const InputDecoration(prefixIcon: Icon(Iconsax.global), labelText: 'País')
                ),
                const SizedBox(height: TSizes.spaceBtwSections),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => controller.addNewAddress(),
                    child: const Text('Guardar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}