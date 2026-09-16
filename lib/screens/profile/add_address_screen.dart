import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class AddAddressScreen extends StatefulWidget {
  final AddressModel? initialAddress;
  final int? addressIndex;

  const AddAddressScreen({super.key, this.initialAddress, this.addressIndex});

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _houseController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  GoogleMapController? _mapController;
  late LatLng _currentLocation;
  bool _isDraggingMap = false;
  bool _isResolvingAddress = false;
  Timer? _debounceTimer;

  String _selectedAreaName = "Locating...";
  String _resolvedStreetAddress = "Moving map to select delivery location...";
  String _selectedTag = 'HOME';
  bool _isSaving = false;
  MapType _mapType = MapType.normal;

  // Animation for pin bounce when dragging
  late AnimationController _pinAnimController;
  late Animation<double> _pinLiftAnimation;

  static const String _googleMapsApiKey = "AIzaSyC43Ca-4rS__IkqlxooPqU9qedVZDnFqQ8";

  @override
  void initState() {
    super.initState();

    // Default to Lucknow center or existing coordinates
    final double initialLat = widget.initialAddress?.lat ?? 26.8467;
    final double initialLng = widget.initialAddress?.lng ?? 80.9462;
    _currentLocation = LatLng(initialLat, initialLng);

    _pinAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _pinLiftAnimation = Tween<double>(begin: 0, end: -14).animate(
      CurvedAnimation(parent: _pinAnimController, curve: Curves.easeOutCubic),
    );

    if (widget.initialAddress != null) {
      _selectedTag = widget.initialAddress!.tag;
      _houseController.text = widget.initialAddress!.completeAddress;
      _landmarkController.text = widget.initialAddress!.landmark ?? '';
      _nameController.text = widget.initialAddress!.receiverName;
      _phoneController.text = widget.initialAddress!.receiverPhone;
      _selectedAreaName = "${widget.initialAddress!.tag} Location";
      _resolvedStreetAddress = widget.initialAddress!.completeAddress;
    } else {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user != null) {
        _nameController.text = user.name;
        _phoneController.text = user.phone;
      }
      _reverseGeocode(_currentLocation);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _pinAnimController.dispose();
    _houseController.dispose();
    _landmarkController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _onCameraMoveStarted() {
    if (!_isDraggingMap) {
      setState(() => _isDraggingMap = true);
      _pinAnimController.forward();
      HapticFeedback.selectionClick();
    }
  }

  void _onCameraMove(CameraPosition position) {
    _currentLocation = position.target;
  }

  void _onCameraIdle() {
    if (_isDraggingMap) {
      setState(() => _isDraggingMap = false);
      _pinAnimController.reverse();
      HapticFeedback.lightImpact();
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      _reverseGeocode(_currentLocation);
    });
  }

  Future<void> _reverseGeocode(LatLng target) async {
    if (!mounted) return;
    setState(() => _isResolvingAddress = true);

    // 1. Google Geocoding API
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=${target.latitude},${target.longitude}&key=$_googleMapsApiKey',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK' && (data['results'] as List).isNotEmpty) {
          final result = data['results'][0];
          final formatted = result['formatted_address'] as String;

          String area = '';
          for (final comp in result['address_components']) {
            final types = List<String>.from(comp['types']);
            if (types.contains('sublocality') || types.contains('neighborhood') || types.contains('locality')) {
              area = comp['long_name'];
              break;
            }
          }

          if (mounted) {
            setState(() {
              _selectedAreaName = area.isNotEmpty ? area : "Delivery Location";
              _resolvedStreetAddress = formatted;
              _isResolvingAddress = false;
            });
          }
          return;
        }
      }
    } catch (_) {}

    // 2. OpenStreetMap Reverse Geocoding Fallback
    try {
      final osmUrl = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${target.latitude}&lon=${target.longitude}',
      );
      final osmRes = await http.get(osmUrl, headers: {'User-Agent': 'UBMartUserApp/1.0'}).timeout(const Duration(seconds: 4));
      if (osmRes.statusCode == 200) {
        final osmData = jsonDecode(osmRes.body);
        final displayName = osmData['display_name'] as String? ?? '';
        final addressMap = osmData['address'] as Map<String, dynamic>?;
        final area = addressMap?['suburb'] ??
            addressMap?['neighbourhood'] ??
            addressMap?['city_district'] ??
            addressMap?['city'] ??
            'Delivery Hub';

        if (mounted) {
          setState(() {
            _selectedAreaName = area.toString();
            _resolvedStreetAddress = displayName.isNotEmpty ? displayName : "Near $area";
            _isResolvingAddress = false;
          });
        }
        return;
      }
    } catch (_) {}

    // 3. Clean default fallback
    if (mounted) {
      setState(() {
        _selectedAreaName = "Selected Delivery Point";
        _resolvedStreetAddress = "Lat: ${target.latitude.toStringAsFixed(4)}, Lng: ${target.longitude.toStringAsFixed(4)}";
        _isResolvingAddress = false;
      });
    }
  }

  void _recenterToLocation(LatLng target) {
    HapticFeedback.lightImpact();
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: 16.5),
      ),
    );
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final houseDetails = _houseController.text.trim();
    final landmark = _landmarkController.text.trim();
    final completeAddressText = landmark.isNotEmpty
        ? "$houseDetails, Near $landmark, $_resolvedStreetAddress"
        : "$houseDetails, $_resolvedStreetAddress";

    final newAddress = AddressModel(
      id: widget.initialAddress?.id,
      tag: _selectedTag,
      completeAddress: completeAddressText,
      receiverName: _nameController.text.trim(),
      receiverPhone: _phoneController.text.trim(),
      lat: _currentLocation.latitude,
      lng: _currentLocation.longitude,
      landmark: landmark.isNotEmpty ? landmark : null,
    );

    if (widget.addressIndex != null) {
      await authProvider.updateAddress(widget.addressIndex!, newAddress);
    } else {
      await authProvider.addAddress(newAddress);
    }

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.addressIndex != null ? "Address updated successfully! 🎉" : "Address saved with Google Map pin! 📍"),
          backgroundColor: AppTheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.pop(context);
    }
  }

  Widget _buildTagButton(String tag, IconData icon, Color activeColor) {
    final isSelected = _selectedTag == tag;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedTag = tag);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? activeColor.withValues(alpha: 0.12) : Colors.transparent,
            border: Border.all(
              color: isSelected ? activeColor : Colors.grey.shade300,
              width: isSelected ? 1.8 : 1.0,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? activeColor : Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                tag,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                  color: isSelected ? activeColor : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0F19) : const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // ── 1. Interactive Google Map ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.46,
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _currentLocation,
                    zoom: 16.5,
                  ),
                  mapType: _mapType,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  compassEnabled: false,
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  onCameraMoveStarted: _onCameraMoveStarted,
                  onCameraMove: _onCameraMove,
                  onCameraIdle: _onCameraIdle,
                ),

                // Map Gradient Shadow at the top
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 100,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.5),
                          Colors.transparent,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),

                // Floating App Bar / Back Button & Area Name Pill
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        // Back Button
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            height: 40,
                            width: 40,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.18),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.black87),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Selected Area Name Header Pill
                        Expanded(
                          child: Container(
                            height: 40,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.location_on_rounded, size: 16, color: AppTheme.primary),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    _selectedAreaName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                      color: Color(0xFF0F172A),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (_isResolvingAddress)
                                  const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Floating Map Type Switcher & Recenter Buttons (Bottom Right of Map)
                Positioned(
                  bottom: 24,
                  right: 16,
                  child: Column(
                    children: [
                      // Satellite Toggle
                      FloatingActionButton.small(
                        heroTag: 'mapTypeToggle',
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF0F172A),
                        elevation: 3,
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _mapType = _mapType == MapType.normal ? MapType.hybrid : MapType.normal;
                          });
                        },
                        child: Icon(
                          _mapType == MapType.normal ? Icons.satellite_alt_rounded : Icons.map_rounded,
                          size: 18,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Recenter GPS
                      FloatingActionButton.small(
                        heroTag: 'recenterGps',
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 3,
                        onPressed: () => _recenterToLocation(_currentLocation),
                        child: const Icon(Icons.my_location_rounded, size: 18),
                      ),
                    ],
                  ),
                ),

                // ── Centered Floating Interactive Delivery Pin ──
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Floating "Order will be delivered here" pill badge
                      AnimatedOpacity(
                        opacity: _isDraggingMap ? 0.0 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text("⚡", style: TextStyle(fontSize: 12)),
                              SizedBox(width: 4),
                              Text(
                                "Order delivers here",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Animated Pin Icon with Drop Shadow
                      AnimatedBuilder(
                        animation: _pinAnimController,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, _pinLiftAnimation.value),
                            child: child,
                          );
                        },
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              size: 48,
                              color: AppTheme.primary,
                            ),
                            const Positioned(
                              top: 10,
                              child: Icon(
                                Icons.circle,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Pin Drop Dot Shadow on Map Surface
                      Container(
                        width: 8,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: _isDraggingMap ? 0.15 : 0.35),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── 2. Bottom Details Sheet (Slide-Up Form) ──
          Positioned(
            top: MediaQuery.of(context).size.height * 0.42,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                    blurRadius: 18,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Drag Handle Bar
                  Container(
                    width: 44,
                    height: 4,
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Form Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      physics: const BouncingScrollPhysics(),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Location Banner Card
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary.withValues(alpha: 0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.place_rounded, color: AppTheme.primary, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _selectedAreaName,
                                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _resolvedStreetAddress,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark ? Colors.white54 : Colors.grey.shade600,
                                            height: 1.3,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      "PINNED 📍",
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF10B981),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // House / Flat / Floor Details
                            const Text(
                              "HOUSE / FLAT / FLOOR / BUILDING *",
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _houseController,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                              decoration: InputDecoration(
                                hintText: "e.g. Flat 402, Tower B, Eldeco Greens",
                                hintStyle: TextStyle(fontSize: 13, color: isDark ? Colors.white30 : Colors.grey.shade400),
                                prefixIcon: const Icon(Icons.home_outlined, size: 20),
                                filled: true,
                                fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: AppTheme.primary, width: 2),
                                ),
                              ),
                              validator: (val) => val == null || val.trim().isEmpty ? "Please enter flat / house number" : null,
                            ),
                            const SizedBox(height: 14),

                            // Landmark / Nearby Place
                            const Text(
                              "NEARBY LANDMARK (OPTIONAL)",
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _landmarkController,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                              decoration: InputDecoration(
                                hintText: "e.g. Opposite City Hospital / Near Main Gate",
                                hintStyle: TextStyle(fontSize: 13, color: isDark ? Colors.white30 : Colors.grey.shade400),
                                prefixIcon: const Icon(Icons.near_me_outlined, size: 20),
                                filled: true,
                                fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: AppTheme.primary, width: 2),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Save As Tag Chips (HOME, WORK, OTHER)
                            const Text(
                              "SAVE ADDRESS AS *",
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _buildTagButton('HOME', Icons.home_rounded, const Color(0xFFF59E0B)),
                                const SizedBox(width: 8),
                                _buildTagButton('WORK', Icons.work_rounded, const Color(0xFF0284C7)),
                                const SizedBox(width: 8),
                                _buildTagButton('OTHER', Icons.location_on_rounded, const Color(0xFF8B5CF6)),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Receiver's Details
                            const Text(
                              "RECEIVER'S CONTACT DETAILS",
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _nameController,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                    decoration: InputDecoration(
                                      labelText: "Name *",
                                      prefixIcon: const Icon(Icons.person_outline, size: 18),
                                      filled: true,
                                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade300),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: AppTheme.primary, width: 2),
                                      ),
                                    ),
                                    validator: (val) => val == null || val.trim().isEmpty ? "Enter name" : null,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextFormField(
                                    controller: _phoneController,
                                    keyboardType: TextInputType.phone,
                                    maxLength: 10,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                    decoration: InputDecoration(
                                      counterText: "",
                                      labelText: "Phone *",
                                      prefixIcon: const Icon(Icons.phone_android, size: 18),
                                      filled: true,
                                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade300),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: AppTheme.primary, width: 2),
                                      ),
                                    ),
                                    validator: (val) => val == null || val.trim().length < 10 ? "10-digit phone" : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 22),

                            // Save & Deliver Here CTA Button
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primary,
                                  foregroundColor: Colors.white,
                                  elevation: 3,
                                  shadowColor: AppTheme.primary.withValues(alpha: 0.4),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                onPressed: _isSaving ? null : _saveAddress,
                                icon: _isSaving
                                    ? const SizedBox.shrink()
                                    : const Icon(Icons.check_circle_rounded, size: 18),
                                label: _isSaving
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      )
                                    : Text(
                                        widget.addressIndex != null
                                            ? "Update & Save Address"
                                            : "Save Address & Deliver Here 🛵",
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
