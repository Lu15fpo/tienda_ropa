import 'package:flutter/material.dart';

import '../../../../../common/widgets/texts/section_heading.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../personalization/controllers/address_controller.dart';

class TBillingAddressSection extends StatelessWidget {
  const TBillingAddressSection({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final addressController = AddressController.instance;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TSectionHeading(
            title: 'Direccion de envio', buttonTitle: 'Cambiar', onPressed: () => addressController.selectNewAddressPopup(context)
        ),
        addressController.selectedAddress.value.id.isNotEmpty
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Luis Palacios', style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: TSizes.spaceBtwItems / 2),
                  Row(
                    children: [
                      const Icon(Icons.phone, color: Colors.grey, size: 16),
                      const SizedBox(width: TSizes.spaceBtwItems),
                      Text('+593 986-613-4645', style: Theme.of(context).textTheme.bodyMedium)
                    ],
                  ),
                  const SizedBox(height: TSizes.spaceBtwItems / 2),
                  Row(
                    children: [
                      const Icon(Icons.location_history, color: Colors.grey, size: 16),
                      const SizedBox(width: TSizes.spaceBtwItems),
                      Expanded(
                          child: Text('Sanchez y Cifuentes 17-111, Teodoro Gomez, Ibarra', style: Theme.of(context).textTheme.bodyMedium, softWrap: true)),
                    ],
                  ),
                ],
              )
            : Text('Seleccionar Direccion', style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}