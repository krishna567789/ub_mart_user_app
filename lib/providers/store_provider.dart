import 'package:flutter/material.dart';
import '../models/store_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../config/api_config.dart';

class StoreProvider with ChangeNotifier {
  List<StoreModel> _stores = [];
  StoreModel? _selectedStore;
  bool _isLoading = false;
  String? _errorMessage;

  List<StoreModel> get stores => _stores;
  StoreModel? get selectedStore => _selectedStore;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> initStore() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Try to load saved store
      _selectedStore = await StorageService.getSelectedStore();
      if (_selectedStore != null) {
        ApiConfig.defaultStoreId = _selectedStore!.id;
        apiService.setStoreId(_selectedStore!.id);
      }

      // 2. Fetch list of stores
      await fetchStores();

      // 3. If no store was selected, pick the first active store
      if (_selectedStore == null && _stores.isNotEmpty) {
        selectStore(_stores.first);
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchStores() async {
    try {
      final data = await apiService.get('/stores');
      if (data is List) {
        _stores = data.map((s) => StoreModel.fromJson(s)).toList();
        if (_selectedStore == null && _stores.isNotEmpty) {
          selectStore(_stores.first);
        }
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
    }
  }

  Future<void> selectStore(StoreModel store) async {
    _selectedStore = store;
    ApiConfig.defaultStoreId = store.id;
    apiService.setStoreId(store.id);
    await StorageService.saveSelectedStore(store);
    notifyListeners();
  }
}
