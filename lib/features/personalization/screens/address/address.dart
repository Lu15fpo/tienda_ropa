import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tienda_ropa/common/widgets/appbar/appbar.dart';
import 'package:tienda_ropa/features/personalization/screens/address/add_new_address.dart';
import 'package:tienda_ropa/features/personalization/screens/address/widgets/single_address.dart';
import 'package:tienda_ropa/utils/helpers/cloud_helper_functions.dart';

import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../controllers/address_controller.dart';

class UserAddressScreen extends StatelessWidget {
  const UserAddressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AddressController());
    return Scaffold(
      appBar: TAppBar(showBackArrow: true, title: Text('Direcciones', style: Theme.of(context).textTheme.headlineSmall)),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          child: Obx(
              () => FutureBuilder(
              // Usar key para actualizar
              key: Key(controller.refreshData.value.toString()),
              future: controller.getAllUserAddresses(),
              builder: (context, snapshot) {
            
                /// Funcion de Ayuda: Manejo del Loader, No Record o mensaje de error
                final response = TCloudHelperFunctions.checkMultiRecordState(snapshot: snapshot);
                if (response != null) return response;
            
                final addresses = snapshot.data!;
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: addresses.length,
                  itemBuilder: (_, index) => TSingleAddress(
                      address: addresses[index],
                      onTap: () => controller.selectAddress(addresses[index])
                  ),
                );
              }
            ),
          )
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.to(AddNewAddressScreen()),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: TColors.primary,
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(
            Icons.add,
            color: TColors.white,
          ),
        ),
        tooltip: 'Agregar Direccion',
        elevation: 0,
      ),
    );
  }
}
