import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:un_mart_user_app/config/api_config.dart';
import 'package:un_mart_user_app/widgets/custom_text.dart';
import '../providers/store_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';
import 'order_success_screen.dart';
import 'profile/add_address_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _paymentMethod = 'COD'; // COD, ONLINE, WALLET
  AddressModel? _selectedAddress;

  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _receiverNameController = TextEditingController();
  final _receiverPhoneController = TextEditingController();
  final String _tag = 'HOME';

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.user != null) {
      _receiverNameController.text = auth.user!.name;
      _receiverPhoneController.text = auth.user!.phone;
      if (auth.user!.addresses.isNotEmpty) {
        _selectedAddress = auth.user!.addresses.first;
      }
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _receiverNameController.dispose();
    _receiverPhoneController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final store = Provider.of<StoreProvider>(context, listen: false);
    final cart = Provider.of<CartProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    if (auth.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please login to place your order")),
      );
      return;
    }

    // Safety check: Validate wallet balance if paying via WALLET
    if (_paymentMethod == 'WALLET') {
      final currentBalance = auth.user?.walletBalance ?? 0;
      if (currentBalance < cart.grandTotal) {
        final needed = cart.grandTotal - currentBalance;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Insufficient Wallet Balance! Available: ₹${currentBalance.toStringAsFixed(0)}, Need: ₹${cart.grandTotal.toStringAsFixed(0)} (Short by ₹${needed.toStringAsFixed(0)}).",
            ),
            backgroundColor: Colors.red.shade700,
          ),
        );
        return;
      }
    }

    AddressModel addressToUse;
    if (_selectedAddress != null) {
      addressToUse = _selectedAddress!;
    } else if (auth.user!.addresses.isNotEmpty) {
      addressToUse = auth.user!.addresses.first;
    } else {
      if (_formKey.currentState != null && !_formKey.currentState!.validate()) {
        return;
      }

      final completeAddr = _addressController.text.trim();
      if (completeAddr.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter a delivery address")),
        );
        return;
      }

      addressToUse = AddressModel(
        tag: _tag,
        completeAddress: completeAddr,
        receiverName: _receiverNameController.text.trim().isNotEmpty
            ? _receiverNameController.text.trim()
            : auth.user!.name,
        receiverPhone: _receiverPhoneController.text.trim().isNotEmpty
            ? _receiverPhoneController.text.trim()
            : auth.user!.phone,
      );

      await auth.addAddress(addressToUse);
    }

    final storeId =
        (store.selectedStore?.id != null && store.selectedStore!.id.isNotEmpty)
        ? store.selectedStore!.id
        : ApiConfig.defaultStoreId;

    final createdOrder = await orderProvider.placeOrder(
      storeId: storeId,
      user: auth.user!,
      deliveryAddress: addressToUse,
      cart: cart,
      paymentMethod: _paymentMethod,
    );

    if (createdOrder != null && mounted) {
      // Refresh user to immediately reflect any wallet balance deduction
      await auth.refreshUser();

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => OrderSuccessScreen(order: createdOrder),
        ),
        (route) => false,
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            orderProvider.errorMessage ??
                "Failed to place order. Please try again.",
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final cart = Provider.of<CartProvider>(context);
    final orderProvider = Provider.of<OrderProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Checkout")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Delivery Address Section
            const CustomText(
              "Delivery Address",
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            const SizedBox(height: 12),

            if (auth.user != null && auth.user!.addresses.isNotEmpty) ...[
              for (var addr in auth.user!.addresses)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      color:
                          _selectedAddress?.id == addr.id ||
                              _selectedAddress?.completeAddress ==
                                  addr.completeAddress
                          ? AppTheme.primary
                          : Colors.grey.shade300,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    leading: Icon(
                      addr.tag == 'HOME'
                          ? Icons.home
                          : addr.tag == 'WORK'
                          ? Icons.work
                          : Icons.location_on,
                      color: AppTheme.primary,
                    ),
                    title: CustomText("${addr.tag} - ${addr.receiverName}"),
                    subtitle: CustomText(
                      "${addr.completeAddress}\nPhone: ${addr.receiverPhone}",
                    ),
                    isThreeLine: true,
                    trailing: Radio<AddressModel>(
                      value: addr,
                      groupValue: _selectedAddress,
                      onChanged: (val) {
                        setState(() {
                          _selectedAddress = val;
                        });
                      },
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AddAddressScreen()),
                      );
                      if (!context.mounted) return;
                      final updatedAuth = Provider.of<AuthProvider>(context, listen: false);
                      if (updatedAuth.user != null && updatedAuth.user!.addresses.isNotEmpty) {
                        setState(() {
                          _selectedAddress = updatedAuth.user!.addresses.first;
                        });
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      side: BorderSide(color: AppTheme.primary, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.add_location_alt_rounded, size: 18),
                    label: const Text(
                      "+ Add New Address with Google Map",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddAddressScreen()),
                    );
                    if (!context.mounted) return;
                    final updatedAuth = Provider.of<AuthProvider>(context, listen: false);
                    if (updatedAuth.user != null && updatedAuth.user!.addresses.isNotEmpty) {
                      setState(() {
                        _selectedAddress = updatedAuth.user!.addresses.first;
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.location_on_rounded, size: 20),
                  label: const Text(
                    "Pin Delivery Address on Google Map",
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text("OR ENTER MANUALLY", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 12),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _addressController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: "Complete Address *",
                        hintText: "House No, Building, Street, Area",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? "Address is required"
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _receiverNameController,
                            decoration: InputDecoration(
                              labelText: "Receiver Name *",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            validator: (val) =>
                                val == null || val.trim().isEmpty
                                ? "Name required"
                                : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _receiverPhoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: "Receiver Phone *",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            validator: (val) =>
                                val == null || val.trim().isEmpty
                                ? "Phone required"
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Payment Options
            const CustomText(
              "Payment Method",
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            const SizedBox(height: 12),

            Card(
              child: Column(
                children: [
                  RadioListTile<String>(
                    title: const Text("Cash on Delivery (COD)"),
                    subtitle: const Text("Pay cash or UPI at time of delivery"),
                    value: 'COD',
                    groupValue: _paymentMethod,
                    onChanged: (val) {
                      setState(() {
                        _paymentMethod = val!;
                      });
                    },
                  ),
                  const Divider(height: 1),
                  RadioListTile<String>(
                    title: const Text("Online Payment / UPI"),
                    subtitle: const Text("Google Pay, PhonePe, Cards"),
                    value: 'ONLINE',
                    groupValue: _paymentMethod,
                    onChanged: (val) {
                      setState(() {
                        _paymentMethod = val!;
                      });
                    },
                  ),
                  const Divider(height: 1),
                  RadioListTile<String>(
                    title: Text(
                      "UB Wallet (Balance: ₹${auth.user?.walletBalance.toStringAsFixed(0) ?? '0'})",
                    ),
                    subtitle: Text(
                      (auth.user?.walletBalance ?? 0) >= cart.grandTotal
                          ? "Deduct from internal wallet"
                          : "Insufficient balance (Short by ₹${(cart.grandTotal - (auth.user?.walletBalance ?? 0)).toStringAsFixed(0)})",
                      style: TextStyle(
                        color: (auth.user?.walletBalance ?? 0) >= cart.grandTotal
                            ? Colors.grey.shade600
                            : Colors.red.shade700,
                        fontWeight: (auth.user?.walletBalance ?? 0) >= cart.grandTotal
                            ? FontWeight.normal
                            : FontWeight.w600,
                      ),
                    ),
                    value: 'WALLET',
                    groupValue: _paymentMethod,
                    onChanged: (val) {
                      setState(() {
                        _paymentMethod = val!;
                      });
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Order Total Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Total Amount Payable:",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  Text(
                    "₹${cart.grandTotal.toStringAsFixed(0)}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: orderProvider.isLoading ? null : _placeOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: orderProvider.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "PLACE ORDER",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
