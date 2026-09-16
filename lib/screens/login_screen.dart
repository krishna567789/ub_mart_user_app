import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:un_mart_user_app/widgets/custom_text.dart';
import '../providers/auth_provider.dart';
import '../providers/store_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/favorites_provider.dart';
import '../theme/app_theme.dart';
import '../config/api_config.dart';
import 'package:pinput/pinput.dart';
import 'package:smart_auth/smart_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneFormKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();

  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _nameController =
      TextEditingController(); // Optional name for new users

  bool _otpSent = false;
  final smartAuth = SmartAuth.instance;

  @override
  void dispose() {
    smartAuth.removeUserConsentApiListener();
    _phoneController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_phoneFormKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // In a real app, you might ensure the phone has country code.
    final phone = _phoneController.text.trim();

    final success = await authProvider.sendOtp(phone);
    if (success && mounted) {
      setState(() {
        _otpSent = true;
      });
      final otpVal = authProvider.debugOtp;
      if (otpVal != null && otpVal.isNotEmpty) {
        _otpController.text = otpVal;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("OTP auto-filled: $otpVal"),
            backgroundColor: AppTheme.primary,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("OTP sent successfully to $phone"),
            backgroundColor: AppTheme.primary,
          ),
        );
      }

      // Start listening for SMS (using User Consent API)
      final res = await smartAuth.getSmsWithUserConsentApi();
      if (res.hasData && res.data?.code != null) {
        _otpController.text = res.data!.code!;
        if (mounted) {
          _verifyOtp();
        }
      }
    } else if (mounted && authProvider.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(authProvider.errorMessage!)));
    }
  }

  Future<void> _verifyOtp() async {
    if (!_otpFormKey.currentState!.validate()) return;

    final storeProvider = Provider.of<StoreProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final storeId = (storeProvider.selectedStore?.id.isNotEmpty ?? false)
        ? storeProvider.selectedStore!.id
        : ApiConfig.defaultStoreId;

    final success = await authProvider.verifyOtp(
      phone: _phoneController.text.trim(),
      otp: _otpController.text.trim(),
      name: _nameController.text.trim(),
      storeId: storeId,
    );

    if (success && mounted) {
      Provider.of<CartProvider>(context, listen: false).loadCartFromBackend();
      Provider.of<FavoritesProvider>(
        context,
        listen: false,
      ).loadFavoritesFromBackend();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Welcome to UB Mart, ${authProvider.user?.name ?? 'User'}!",
          ),
        ),
      );
      Navigator.pop(context);
    } else if (mounted && authProvider.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(authProvider.errorMessage!)));
    }
  }

  Widget _buildPhoneStep() {
    return Form(
      key: _phoneFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "India's last minute app",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppTheme.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Log in or sign up",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
            decoration: InputDecoration(
              counterText: "",
              prefixIcon: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                child: const Text(
                  "+91",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              hintText: "Enter Mobile Number",
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
                fontWeight: FontWeight.normal,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.primary, width: 2),
              ),
            ),
            validator: (val) {
              if (val == null || val.trim().length < 10) {
                return "Enter valid 10-digit number";
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              return SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: auth.isLoading ? null : _sendOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: auth.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const CustomText(
                          "Continue",
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Center(
            child: CustomText(
              "By continuing, you agree to our Terms of Service & Privacy Policy",
              textAlign: TextAlign.center,
              fontSize: 11,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpStep() {
    return Form(
      key: _otpFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  setState(() => _otpSent = false);
                },
              ),
              const SizedBox(width: 8),
              CustomText(
                "Verify OTP",
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ],
          ),
          const SizedBox(height: 8),
          CustomText(
            "We have sent a verification code to",
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(height: 4),
          CustomText(
            "+91 ${_phoneController.text}",
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
          const SizedBox(height: 32),
          Center(
            child: Pinput(
              controller: _otpController,
              length: 6,
              autofocus: true,
              defaultPinTheme: PinTheme(
                width: 48,
                height: 56,
                textStyle: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
              ),
              focusedPinTheme: PinTheme(
                width: 48,
                height: 56,
                textStyle: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primary, width: 2),
                ),
              ),
              validator: (val) {
                if (val == null || val.trim().length < 6) {
                  return "Enter 6-digit OTP";
                }
                return null;
              },
              onCompleted: (pin) => _verifyOtp(),
            ),
          ),
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              if (auth.debugOtp != null && auth.debugOtp!.isNotEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Center(
                    child: ActionChip(
                      avatar: const Icon(Icons.auto_awesome, size: 16, color: Colors.white),
                      label: Text(
                        "Auto-fill OTP: ${auth.debugOtp}",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      backgroundColor: AppTheme.primary,
                      onPressed: () {
                        _otpController.text = auth.debugOtp!;
                        _verifyOtp();
                      },
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          const SizedBox(height: 16),
          // Optional Name field if the user wants to set it during registration
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: "Your Name (Optional)",
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              return SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: auth.isLoading ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: auth.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const CustomText(
                          "Verify & Login",
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _otpSent ? _buildOtpStep() : _buildPhoneStep(),
        ),
      ),
    );
  }
}
