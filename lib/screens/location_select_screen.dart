import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/store_provider.dart';
import '../theme/app_theme.dart';
import 'main_navigation_screen.dart';

class LocationSelectScreen extends StatelessWidget {
  const LocationSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final storeProvider = Provider.of<StoreProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Store Location"),
        centerTitle: true,
      ),
      body: storeProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : storeProvider.stores.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.storefront, size: 60, color: Colors.grey),
                      const SizedBox(height: 12),
                      const Text(
                        "No Stores Available",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => storeProvider.fetchStores(),
                        child: const Text("Retry"),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Choose a store near you:",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          itemCount: storeProvider.stores.length,
                          itemBuilder: (context, index) {
                            final store = storeProvider.stores[index];
                            final isSelected = storeProvider.selectedStore?.id == store.id;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isSelected ? AppTheme.primary : AppTheme.primaryLight,
                                  child: Icon(
                                    Icons.store,
                                    color: isSelected ? Colors.white : AppTheme.primary,
                                  ),
                                ),
                                title: Text(
                                  store.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text("Phone: ${store.phone}"),
                                trailing: isSelected
                                    ? const Icon(Icons.check_circle, color: AppTheme.primary)
                                    : const Icon(Icons.arrow_forward_ios, size: 16),
                                onTap: () async {
                                  await storeProvider.selectStore(store);
                                  if (context.mounted) {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
                                    );
                                  }
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
