import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tienda_ropa/common/widgets/loaders/circular_loader.dart';
import 'package:tienda_ropa/common/widgets/texts/section_heading.dart';
import 'package:tienda_ropa/features/personalization/screens/address/widgets/single_address.dart';
import 'package:tienda_ropa/utils/helpers/cloud_helper_functions.dart';
import 'package:tienda_ropa/utils/helpers/network_manager.dart';
import 'package:tienda_ropa/utils/popups/full_screen_loader.dart';
import 'package:tienda_ropa/utils/popups/loaders.dart';

import '../../../data/repositories/address/address_repository.dart';
import '../../../utils/constants/image_strings.dart';
import '../../../utils/constants/sizes.dart';
import '../models/address_model.dart';
import '../screens/address/add_new_address.dart';

class AddressController extends GetxController {
  static AddressController get instance => Get.find();

  final name = TextEditingController();
  final phoneNumber = TextEditingController();
  final street = TextEditingController();
  final postalCode = TextEditingController();
  final city = TextEditingController();
  final state = TextEditingController();
  final country = TextEditingController();
  GlobalKey<FormState> addressFormKey = GlobalKey<FormState>();

  RxBool refreshData = true.obs;
  final Rx<AddressModel> selectedAddress = AddressModel.empty().obs;
  final addressRepository = Get.put(AddressRepository());

  /// Obtener todas las direcciones del usuario
  Future<List<AddressModel>> getAllUserAddresses() async {
    try {
      final addresses = await addressRepository.fetchUserAddresses();
      selectedAddress.value = addresses.firstWhere((element) => element.selectedAddress, orElse: () => AddressModel.empty());
      return addresses;
    } catch (e) {
      TLoaders.errorSnackBar(title: 'No se encontro una direccion', message: e.toString());
      return [];
    }
  }

  Future selectAddress(AddressModel newSelectedAddress) async {
    try {
      Get.defaultDialog(
        title: '',
        onWillPop: () async {return false;},
        barrierDismissible: false,
        backgroundColor: Colors.transparent,
        content: const TCircularLoader(),
      );

      // Limpiar el campo "seleccionado"
      if(selectedAddress.value.id.isNotEmpty) {
        await addressRepository.updateSelectedField(selectedAddress.value.id, false);
      }

      // Asignar la direccion seleccionada
      newSelectedAddress.selectedAddress = true;
      selectedAddress.value = newSelectedAddress;

      // Establecer el campo de "seleccion" a true para la nueva direccion seleccionada
      await addressRepository.updateSelectedField(selectedAddress.value.id, true);

      Get.back();
    } catch (e) {
      TLoaders.errorSnackBar(title: 'Error en la seleccion', message: e.toString());
    }
  }

  /// Agregar una nueva direccion
  Future addNewAddress() async {
    try {
      // Empezar Carga
      TFullScreenLoader.openLoadingDialog('Agregando direccion...', TImages.docerAnimation);

      // Revisar la conexion a internet
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        TFullScreenLoader.stopLoading();
        return;
      }

      // Validacion del formulario
      if (!addressFormKey.currentState!.validate()) {
        TFullScreenLoader.stopLoading();
        return;
      }

      // Guardar la direccion
      final address = AddressModel(
        id: '',
        name: name.text.trim(),
        phoneNumber: phoneNumber.text.trim(),
        street: street.text.trim(),
        city: city.text.trim(),
        state: state.text.trim(),
        postalCode: postalCode.text.trim(),
        country: country.text.trim(),
        selectedAddress: true,
      );
      final id = await addressRepository.addAddress(address);

      // Actualizar la direccion seleccionada
      address.id = id;
      await selectAddress(address);

      // Eliminar Carga
      TFullScreenLoader.stopLoading();

      // Mensaje de confirmacion
      TLoaders.successSnackBar(title: 'Felicidades', message: 'Tu direccion fue guardada de manera satisfactoria.');

      // Actualizar datos de direccion
      refreshData.toggle();

      // Reiniciar campos
      resetFormFields();

      // Redireccionar
      Navigator.of(Get.context!).pop();
    } catch (e) {
      // Eliminar Carga
      TFullScreenLoader.stopLoading();
      TLoaders.errorSnackBar(title: 'Direccion no encontrada', message: e.toString());
    }
  }

  /// Mostrar las direcciones ModalBottomSheet para Pagar
  Future<dynamic> selectNewAddressPopup(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(TSizes.cardRadiusLg)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(TSizes.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TSectionHeading(title: 'Seleccionar Direccion', showActionButton: false),
                const SizedBox(height: TSizes.spaceBtwItems),
                Obx(
                  () => FutureBuilder(
                    key: Key(refreshData.value.toString()),
                    future: getAllUserAddresses(),
                    builder: (_, snapshot) {
                      /// Funcion de ayuda: Manejo del Loader, No Record o mensaje de error
                      final response = TCloudHelperFunctions.checkMultiRecordState(snapshot: snapshot);
                      if (response != null) return response;

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: snapshot.data!.length,
                        itemBuilder: (_, index) => TSingleAddress(
                          address: snapshot.data![index],
                          onTap: () async {
                            await selectAddress(snapshot.data![index]);
                            Get.back();
                          },
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: TSizes.spaceBtwSections),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await Get.to(() => const AddNewAddressScreen());
                      // Actualizar la lista después de regresar
                      refreshData.toggle();
                    },
                    child: const Text('Agregar nueva direccion')
                  ),
                ),
                const SizedBox(height: TSizes.spaceBtwItems),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Funcion para reiniciar los campos del formulario
  void resetFormFields() {
    name.clear();
    phoneNumber.clear();
    street.clear();
    postalCode.clear();
    city.clear();
    state.clear();
    country.clear();
    addressFormKey.currentState?.reset();
  }
}