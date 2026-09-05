import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/store_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';
import 'order_success_screen.dart';

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

    if (auth.user == null) return;

    AddressModel addressToUse;
    if (_selectedAddress != null) {
      addressToUse = _selectedAddress!;
    } else {
      if (!_formKey.currentState!.validate()) return;

      addressToUse = AddressModel(
        tag: _tag,
        completeAddress: _addressController.text.trim(),
        receiverName: _receiverNameController.text.trim(),
        receiverPhone: _receiverPhoneController.text.trim(),
      );

      await auth.addAddress(addressToUse);
    }

    final storeId = store.selectedStore?.id ?? '';

    final createdOrder = await orderProvider.placeOrder(
      storeId: storeId,
      user: auth.user!,
      deliveryAddress: addressToUse,
      cart: cart,
      paymentMethod: _paymentMethod,
    );

    if (createdOrder != null && mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => OrderSuccessScreen(order: createdOrder),
        ),
        (route) => false,
      );
    } else if (mounted && orderProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(orderProvider.errorMessage!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final cart = Provider.of<CartProvider>(context);
    final orderProvider = Provider.of<OrderProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Checkout"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Delivery Address Section
            const Text(
              "Delivery Address",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            if (auth.user != null && auth.user!.addresses.isNotEmpty) ...[
              for (var addr in auth.user!.addresses)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      color: _selectedAddress?.id == addr.id || _selectedAddress?.completeAddress == addr.completeAddress
                          ? AppTheme.primary
                          : Colors.grey.shade300,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    leading: Icon(
                      addr.tag == 'HOME' ? Icons.home : addr.tag == 'WORK' ? Icons.work : Icons.location_on,
                      color: AppTheme.primary,
                    ),
                    title: Text("${addr.tag} - ${addr.receiverName}"),
                    subtitle: Text("${addr.completeAddress}\nPhone: ${addr.receiverPhone}"),
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
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedAddress = null;
                  });
                },
                icon: const Icon(Icons.add),
                label: const Text("Add New Address"),
              ),
            ] else
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
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? "Address is required" : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _receiverNameController,
                            decoration: InputDecoration(
                              labelText: "Receiver Name *",
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            validator: (val) => val == null || val.trim().isEmpty ? "Name required" : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _receiverPhoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: "Receiver Phone *",
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            validator: (val) => val == null || val.trim().isEmpty ? "Phone required" : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Payment Options
            const Text(
              "Payment Method",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                    title: Text("UB Wallet (Balance: ₹${auth.user?.walletBalance.toStringAsFixed(0) ?? '0'})"),
                    subtitle: const Text("Deduct from internal wallet"),
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
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppTheme.primaryDark),
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
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text("PLACE ORDER", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
