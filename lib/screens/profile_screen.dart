import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/store_provider.dart';
import '../config/api_config.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'location_select_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  void _showApiUrlDialog(BuildContext context) {
    final controller = TextEditingController(text: ApiConfig.baseUrl);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("API Base URL Setting"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Default Emulator: http://10.0.2.2:3000/api\nPhysical Device: http://<Your_WiFi_IP>:3000/api",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: "Base API URL",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              ApiConfig.customBaseUrl = controller.text.trim();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("API Base URL set to ${ApiConfig.baseUrl}")),
              );
              Provider.of<StoreProvider>(context, listen: false).fetchStores();
            },
            child: const Text("Save & Reconnect"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final storeProvider = Provider.of<StoreProvider>(context);

    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Account"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // User Details Card
            if (authProvider.isLoggedIn && user != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppTheme.primaryLight,
                      child: Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : "U",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            user.phone,
                            style: const TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                          if (user.email != null)
                            Text(
                              user.email!,
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text(
                      "Log in to unlock saved addresses, wallet balance and quick checkout.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: AppTheme.primaryDark),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      },
                      child: const Text("LOGIN / SIGN UP"),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // Wallet Balance Card
            if (authProvider.isLoggedIn && user != null) ...[
              Card(
                color: AppTheme.primary,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.account_balance_wallet, color: Colors.white, size: 28),
                          SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "UB Wallet Balance",
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                              Text(
                                "Cashback & Refunds",
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Text(
                        "₹${user.walletBalance.toStringAsFixed(0)}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Menu Options List
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.store, color: AppTheme.primary),
                    title: const Text("Current Store Location"),
                    subtitle: Text(storeProvider.selectedStore?.name ?? "Select Store"),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LocationSelectScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.dns, color: AppTheme.primary),
                    title: const Text("Backend API Settings"),
                    subtitle: Text(ApiConfig.baseUrl),
                    trailing: const Icon(Icons.edit, size: 18),
                    onTap: () => _showApiUrlDialog(context),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.location_on_outlined, color: AppTheme.primary),
                    title: const Text("Saved Addresses"),
                    subtitle: Text("${user?.addresses.length ?? 0} Saved Addresses"),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.support_agent_outlined, color: AppTheme.primary),
                    title: const Text("Customer Support"),
                    subtitle: const Text("Help & Contact Us"),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            if (authProvider.isLoggedIn)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await authProvider.logout();
                  },
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text("LOGOUT", style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
