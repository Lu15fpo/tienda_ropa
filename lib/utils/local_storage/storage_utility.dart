import 'package:get_storage/get_storage.dart';

class TLocalStorage {

  late final GetStorage _storage;

  // Instancia unica
  static TLocalStorage? _instance;

  TLocalStorage._internal();

  factory TLocalStorage.instance() {
    _instance ??= TLocalStorage._internal();
    return _instance!;
  }

  static Future<void> init(String bucketName) async {
    await GetStorage.init(bucketName);
    _instance = TLocalStorage._internal();
    _instance!._storage = GetStorage(bucketName);
  }


  // Metodo generico para guardar los datos
  Future<void> writeData<T>(String key, T value) async {
    await _storage.write(key, value);
  }

  // Metodo generico para leer los datos
  T? readData<T>(String key) {
    return _storage.read<T>(key);
  }

  // Metodo generico para eliminar los datos
  Future<void> removeData(String key) async {
    await _storage.remove(key);
  }

  // Eliminar todos los datos
  Future<void> clearAll() async {
    await _storage.erase();
  }
}