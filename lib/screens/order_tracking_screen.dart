import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';
import 'package:un_mart_user_app/widgets/custom_text.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/order_model.dart';
import '../providers/order_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/product_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/smart_image.dart';
import 'cart_screen.dart';

class OrderTrackingScreen extends StatefulWidget {
  final OrderModel order;

  const OrderTrackingScreen({super.key, required this.order});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen>
    with TickerProviderStateMixin {
  late OrderModel _order;
  Timer? _pollingTimer;
  Timer? _countdownTimer;
  int _secondsRemaining = 15 * 60;
  bool _isRefreshing = false;
  bool _itemsExpanded = true;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  late AnimationController _bikeMovementController;
  late Animation<double> _bikeMovementAnimation;

  late AnimationController _radarScanController;

  GoogleMapController? _mapController;
  bool _useGoogleMap = true;

  static const double _defaultStoreLat = 28.5706;
  static const double _defaultStoreLng = 77.3260;

  BitmapDescriptor? _storePinIcon;
  BitmapDescriptor? _destPinIcon;
  BitmapDescriptor? _riderPinIcon;

  LatLng get _storeLatLng => const LatLng(_defaultStoreLat, _defaultStoreLng);

  LatLng get _destLatLng {
    final lat = _order.deliveryAddress.lat ?? (_defaultStoreLat + 0.0078);
    final lng = _order.deliveryAddress.lng ?? (_defaultStoreLng + 0.0092);
    return LatLng(lat, lng);
  }

  // Generate smooth cubic bezier curve points matching the realistic road arc
  List<LatLng> _getCurvedRoutePoints(LatLng start, LatLng end, {int samples = 50}) {
    final dLat = end.latitude - start.latitude;
    final dLng = end.longitude - start.longitude;

    final p0 = start;
    final p1 = LatLng(
      start.latitude + dLat * 0.25 - dLng * 0.22,
      start.longitude + dLng * 0.35 + dLat * 0.22,
    );
    final p2 = LatLng(
      start.latitude + dLat * 0.70 + dLng * 0.22,
      start.longitude + dLng * 0.65 - dLat * 0.22,
    );
    final p3 = end;

    final points = <LatLng>[];
    for (int i = 0; i <= samples; i++) {
      final t = i / samples;
      final u = 1.0 - t;
      final tt = t * t;
      final uu = u * u;
      final uuu = uu * u;
      final ttt = tt * t;

      final lat = uuu * p0.latitude +
          3 * uu * t * p1.latitude +
          3 * u * tt * p2.latitude +
          ttt * p3.latitude;

      final lng = uuu * p0.longitude +
          3 * uu * t * p1.longitude +
          3 * u * tt * p2.longitude +
          ttt * p3.longitude;

      points.add(LatLng(lat, lng));
    }
    return points;
  }

  // Get animated point on curve at progress t (0.0 to 1.0)
  LatLng _getPointOnCurve(LatLng start, LatLng end, double t) {
    final dLat = end.latitude - start.latitude;
    final dLng = end.longitude - start.longitude;

    final p0 = start;
    final p1 = LatLng(
      start.latitude + dLat * 0.25 - dLng * 0.22,
      start.longitude + dLng * 0.35 + dLat * 0.22,
    );
    final p2 = LatLng(
      start.latitude + dLat * 0.70 + dLng * 0.22,
      start.longitude + dLng * 0.65 - dLat * 0.22,
    );
    final p3 = end;

    final clampedT = t.clamp(0.0, 1.0);
    final u = 1.0 - clampedT;
    final tt = clampedT * clampedT;
    final uu = u * u;
    final uuu = uu * u;
    final ttt = tt * clampedT;

    final lat = uuu * p0.latitude +
        3 * uu * clampedT * p1.latitude +
        3 * u * tt * p2.latitude +
        ttt * p3.latitude;

    final lng = uuu * p0.longitude +
        3 * uu * clampedT * p1.longitude +
        3 * u * tt * p2.longitude +
        ttt * p3.longitude;

    return LatLng(lat, lng);
  }

  // Generates animated dual polylines (traveled solid cyan-teal path + remaining dashed path)
  Set<Polyline> _getPolylines(bool isDelivered, double bikeProgress) {
    final fullRoute = _getCurvedRoutePoints(_storeLatLng, _destLatLng);

    if (isDelivered) {
      return {
        // Delivered: Emerald green route with glow
        Polyline(
          polylineId: const PolylineId('route_delivered_halo'),
          points: fullRoute,
          color: const Color(0xFF10B981).withValues(alpha: 0.35),
          width: 9,
          jointType: JointType.round,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ),
        Polyline(
          polylineId: const PolylineId('route_delivered_core'),
          points: fullRoute,
          color: const Color(0xFF10B981),
          width: 5,
          jointType: JointType.round,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ),
      };
    }

    // Split route dynamically at current animated rider progress
    final riderLatLng = _getPointOnCurve(_storeLatLng, _destLatLng, bikeProgress);
    final splitIndex = (bikeProgress * (fullRoute.length - 1)).floor();

    final traveledPoints = <LatLng>[];
    for (int i = 0; i <= splitIndex && i < fullRoute.length; i++) {
      traveledPoints.add(fullRoute[i]);
    }
    traveledPoints.add(riderLatLng);

    final remainingPoints = <LatLng>[riderLatLng];
    for (int i = splitIndex + 1; i < fullRoute.length; i++) {
      remainingPoints.add(fullRoute[i]);
    }

    return {
      // 1. Traveled Path (Solid glowing Cyan/Teal corridor)
      Polyline(
        polylineId: const PolylineId('route_traveled_halo'),
        points: traveledPoints,
        color: const Color(0xFF38BDF8).withValues(alpha: 0.35),
        width: 9,
        jointType: JointType.round,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      ),
      Polyline(
        polylineId: const PolylineId('route_traveled_core'),
        points: traveledPoints,
        color: const Color(0xFF0284C7),
        width: 5,
        jointType: JointType.round,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      ),

      // 2. Remaining Path (Dashed Amber/Orange route to destination)
      Polyline(
        polylineId: const PolylineId('route_remaining_halo'),
        points: remainingPoints,
        color: const Color(0xFFF59E0B).withValues(alpha: 0.20),
        width: 7,
        jointType: JointType.round,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      ),
      Polyline(
        polylineId: const PolylineId('route_remaining_core'),
        points: remainingPoints,
        color: const Color(0xFFF59E0B),
        width: 4,
        patterns: [PatternItem.dash(12), PatternItem.gap(6)],
        jointType: JointType.round,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      ),
    };
  }

  // Generates custom styled pins matching the in-app vector map design
  Set<Marker> _getMarkers(
    bool isDelivered,
    bool isCancelled,
    int currentStep,
    double bikeProgress,
  ) {
    final markers = <Marker>{};

    // 1. Store Hub Marker (🏪 UB Store Hub)
    markers.add(
      Marker(
        markerId: const MarkerId('store_hub'),
        position: _storeLatLng,
        icon: _storePinIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        anchor: const Offset(0.5, 0.40),
        infoWindow: const InfoWindow(
          title: "🏢 UB Store Hub",
          snippet: "Central Express Distribution Center",
        ),
      ),
    );

    // 2. Customer Destination Marker (🏠 My Location)
    markers.add(
      Marker(
        markerId: const MarkerId('customer_dest'),
        position: _destLatLng,
        icon: _destPinIcon ??
            BitmapDescriptor.defaultMarkerWithHue(
              isDelivered
                  ? BitmapDescriptor.hueGreen
                  : BitmapDescriptor.hueRed,
            ),
        anchor: const Offset(0.5, 0.40),
        infoWindow: InfoWindow(
          title: "🏠 ${_order.deliveryAddress.tag.toUpperCase()} (My Location)",
          snippet: _order.deliveryAddress.completeAddress,
        ),
      ),
    );

    // 3. Smooth Riding Delivery Partner Marker (🛵 UB Express Rider)
    if (!isCancelled && currentStep >= 1) {
      LatLng riderPos;
      final rawLoc = _order.assignedRider?['currentLocation'];
      if (rawLoc != null && rawLoc['lat'] != null && rawLoc['lng'] != null) {
        final rLat = (rawLoc['lat'] as num).toDouble();
        final rLng = (rawLoc['lng'] as num).toDouble();
        riderPos = LatLng(rLat, rLng);
      } else {
        riderPos = _getPointOnCurve(_storeLatLng, _destLatLng, bikeProgress);
      }
      markers.add(
        Marker(
          markerId: const MarkerId('delivery_rider'),
          position: riderPos,
          icon: _riderPinIcon ??
              BitmapDescriptor.defaultMarkerWithHue(
                isDelivered
                    ? BitmapDescriptor.hueGreen
                    : BitmapDescriptor.hueOrange,
              ),
          anchor: const Offset(0.5, 0.40),
          zIndexInt: 10,
          infoWindow: InfoWindow(
            title: "🛵 ${_order.assignedRider?['name'] ?? 'UB Express Partner'}",
            snippet: isDelivered ? "Delivered Successfully!" : "En-route with your order",
          ),
        ),
      );
    }

    return markers;
  }

  // Pre-renders custom bitmap icons with emojis and rounded pill badges
  Future<void> _loadCustomMapIcons() async {
    try {
      final storeIcon = await _createCustomPinBitmap(
        iconText: "🏪",
        label: "UB Store Hub",
        color: const Color(0xFF3B82F6),
      );
      final destIcon = await _createCustomPinBitmap(
        iconText: "🏠",
        label: "My Location",
        color: const Color(0xFF10B981),
      );
      final riderIcon = await _createCustomPinBitmap(
        iconText: "🛵",
        label: "UB Express",
        color: const Color(0xFFF59E0B),
      );

      if (mounted) {
        setState(() {
          _storePinIcon = storeIcon;
          _destPinIcon = destIcon;
          _riderPinIcon = riderIcon;
        });
      }
    } catch (e) {
      debugPrint("Error generating custom map icons: $e");
    }
  }

  static Future<BitmapDescriptor> _createCustomPinBitmap({
    required String iconText,
    required String label,
    required Color color,
  }) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    const double canvasWidth = 140.0;
    const double canvasHeight = 90.0;
    const double centerX = canvasWidth / 2;
    const double circleRadius = 22.0;
    const double circleCenterY = 28.0;

    // Drop shadow for circular pin
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawCircle(
      const Offset(centerX, circleCenterY + 2),
      circleRadius + 2,
      shadowPaint,
    );

    // Circular Pin Background
    final pinPaint = Paint()..color = color;
    canvas.drawCircle(
      const Offset(centerX, circleCenterY),
      circleRadius,
      pinPaint,
    );

    // White Pin Border
    final borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(
      const Offset(centerX, circleCenterY),
      circleRadius,
      borderPaint,
    );

    // Centered Emoji Icon
    final iconPainter = TextPainter(
      text: TextSpan(
        text: iconText,
        style: const TextStyle(fontSize: 20),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    iconPainter.paint(
      canvas,
      Offset(
        centerX - iconPainter.width / 2,
        circleCenterY - iconPainter.height / 2,
      ),
    );

    // Label Text Pill below Pin
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Color(0xFF0F172A),
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();

    final double pillWidth = textPainter.width + 16;
    const double pillHeight = 22.0;
    final double pillTop = circleCenterY + circleRadius + 6;
    final pillRect = Rect.fromCenter(
      center: Offset(centerX, pillTop + pillHeight / 2),
      width: pillWidth,
      height: pillHeight,
    );

    // Pill Shadow
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        pillRect.translate(0, 1.5),
        const Radius.circular(6),
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.20)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // Pill Background (Clean White)
    canvas.drawRRect(
      RRect.fromRectAndRadius(pillRect, const Radius.circular(6)),
      Paint()..color = Colors.white,
    );

    // Pill Border
    canvas.drawRRect(
      RRect.fromRectAndRadius(pillRect, const Radius.circular(6)),
      Paint()
        ..color = Colors.black12
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke,
    );

    // Paint label text
    textPainter.paint(
      canvas,
      Offset(
        centerX - textPainter.width / 2,
        pillTop + (pillHeight - textPainter.height) / 2,
      ),
    );

    final ui.Image image = await pictureRecorder.endRecording().toImage(
      canvasWidth.toInt(),
      canvasHeight.toInt(),
    );
    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    final Uint8List uint8List = byteData!.buffer.asUint8List();

    return BitmapDescriptor.bytes(uint8List);
  }

  void _fitMapBounds() {
    if (_mapController == null) return;
    final s = _storeLatLng;
    final d = _destLatLng;

    final minLat = math.min(s.latitude, d.latitude);
    final maxLat = math.max(s.latitude, d.latitude);
    final minLng = math.min(s.longitude, d.longitude);
    final maxLng = math.max(s.longitude, d.longitude);

    final southWest = LatLng(minLat - 0.003, minLng - 0.003);
    final northEast = LatLng(maxLat + 0.003, maxLng + 0.003);

    final bounds = LatLngBounds(southwest: southWest, northeast: northEast);
    _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  }

  static const String _darkMapStyle = '''[
    {"elementType": "geometry", "stylers": [{"color": "#1e293b"}]},
    {"elementType": "labels.text.fill", "stylers": [{"color": "#94a3b8"}]},
    {"elementType": "labels.text.stroke", "stylers": [{"color": "#0f172a"}]},
    {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#334155"}]},
    {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#0f172a"}]}
  ]''';

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    _loadCustomMapIcons();

    // Pulse animation for pins and live radar
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _pulseAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeOut));

    // Bike movement along route curve
    _bikeMovementController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _bikeMovementAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _bikeMovementController, curve: Curves.easeInOut),
    );

    // Radar scanning animation for rider assignment
    _radarScanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    // Start 15-min delivery countdown
    _initCountdownTimer();

    // Auto-polling every 12 seconds for live status updates
    _startPolling();
  }

  void _initCountdownTimer() {
    _countdownTimer?.cancel();
    if (_order.status == 'DELIVERED' || _order.status == 'CANCELLED') {
      _secondsRemaining = 0;
      return;
    }

    final createdAt = _order.createdAt ?? DateTime.now();
    final targetTime = createdAt.add(const Duration(minutes: 15));
    final diff = targetTime.difference(DateTime.now()).inSeconds;
    _secondsRemaining = diff > 0 ? diff : 180; // at least 3 mins left if running late

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  String _formattedCountdown() {
    if (_secondsRemaining <= 0) return "Arriving Now!";
    final mins = _secondsRemaining ~/ 60;
    final secs = _secondsRemaining % 60;
    return "${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')} min";
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      if (!mounted) return;
      if (_order.status != 'DELIVERED' && _order.status != 'CANCELLED') {
        _refreshOrderDetails(silent: true);
      }
    });
  }

  Future<void> _refreshOrderDetails({bool silent = false}) async {
    if (!silent) setState(() => _isRefreshing = true);
    final orderProv = context.read<OrderProvider>();
    final targetId = _order.id.isNotEmpty ? _order.id : _order.orderId;
    final updated = await orderProv.fetchOrderDetails(targetId);
    if (mounted) {
      if (updated != null) {
        setState(() {
          _order = updated;
          if (!silent) _isRefreshing = false;
        });
        if (_order.status == 'DELIVERED' || _order.status == 'CANCELLED') {
          _countdownTimer?.cancel();
          setState(() {
            _secondsRemaining = 0;
          });
        }
      } else {
        if (!silent) setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _countdownTimer?.cancel();
    _pulseController.dispose();
    _bikeMovementController.dispose();
    _radarScanController.dispose();
    _mapController = null;
    super.dispose();
  }

  void _callPhone(String phone) async {
    if (phone.isEmpty) return;
    HapticFeedback.lightImpact();
    final Uri url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _launchSms(String phone, String message) async {
    final uri = Uri(
      scheme: 'sms',
      path: phone,
      queryParameters: {'body': message},
    );
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      debugPrint("Error launching SMS: $e");
    }
  }

  int _getStatusStep(String status) {
    switch (status) {
      case 'PENDING':
        return 0;
      case 'ACCEPTED':
        return 1;
      case 'PACKING':
        return 2;
      case 'OUT_FOR_DELIVERY':
        return 3;
      case 'DELIVERED':
        return 4;
      default:
        return 0;
    }
  }

  String _getStatusHeadline(String status) {
    switch (status) {
      case 'PENDING':
        return "Order Confirmed!";
      case 'ACCEPTED':
        return "Order Accepted by Store";
      case 'PACKING':
        return "Packing Fresh Groceries";
      case 'OUT_FOR_DELIVERY':
        return "Rider is Speeding to You!";
      case 'DELIVERED':
        return "Order Delivered Safely!";
      case 'CANCELLED':
        return "Order Cancelled";
      default:
        return "Processing Order";
    }
  }

  String _getStatusDescription(String status) {
    switch (status) {
      case 'PENDING':
        return "We've received your order and sent it directly to the nearest store hub.";
      case 'ACCEPTED':
        return "Store has accepted your order and is verifying item inventory.";
      case 'PACKING':
        return "Your items are being hand-picked, quality-checked, and safely packed.";
      case 'OUT_FOR_DELIVERY':
        return "Your delivery partner has picked up the package and is on the way.";
      case 'DELIVERED':
        return "Items were handed over. We hope you enjoy your shopping experience!";
      case 'CANCELLED':
        return "This order was cancelled. If amount was debited, refund will be processed.";
      default:
        return "UB Mart Quick Delivery";
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING':
        return const Color(0xFF3B82F6); // Blue
      case 'ACCEPTED':
        return const Color(0xFF8B5CF6); // Purple
      case 'PACKING':
        return const Color(0xFFF59E0B); // Amber
      case 'OUT_FOR_DELIVERY':
        return const Color(0xFF10B981); // Emerald
      case 'DELIVERED':
        return const Color(0xFF059669); // Green
      case 'CANCELLED':
        return const Color(0xFFEF4444); // Red
      default:
        return AppTheme.primary;
    }
  }

  void _confirmCancelOrder() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text("Cancel Order?"),
          ],
        ),
        content: const Text(
          "Are you sure you want to cancel this order? This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("NO, KEEP IT"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await context.read<OrderProvider>().cancelOrder(
                orderId: _order.id,
                storeId: '',
              );
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Order has been cancelled"),
                    backgroundColor: Colors.red,
                  ),
                );
                _refreshOrderDetails();
              }
            },
            child: const Text("YES, CANCEL"),
          ),
        ],
      ),
    );
  }

  void _handleReorder() {
    final cartProv = Provider.of<CartProvider>(context, listen: false);
    final prodProv = Provider.of<ProductProvider>(context, listen: false);
    final orderProv = Provider.of<OrderProvider>(context, listen: false);

    final readded = orderProv.reorder(
      pastOrder: _order,
      cart: cartProv,
      catalogProducts: prodProv.allProducts,
    );

    if (readded > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("$readded item(s) added to your cart!"),
          backgroundColor: AppTheme.primary,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: "VIEW CART",
            textColor: Colors.white,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartScreen()),
              );
            },
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Items from this order are currently out of stock."),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _showRatingModal() {
    double currentRating = _order.rating ?? 5.0;
    final textController = TextEditingController(text: _order.review ?? '');
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              top: 20,
              left: 20,
              right: 20,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Rate Your Delivery",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Order #${_order.orderId}",
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starVal = (index + 1).toDouble();
                      return IconButton(
                        iconSize: 36,
                        icon: Icon(
                          starVal <= currentRating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                        ),
                        onPressed: () {
                          setModalState(() {
                            currentRating = starVal;
                          });
                        },
                      );
                    }),
                  ),
                  Text(
                    currentRating == 5
                        ? "Excellent! ⭐⭐⭐⭐⭐"
                        : currentRating == 4
                            ? "Very Good! ⭐⭐⭐⭐"
                            : currentRating == 3
                                ? "Good ⭐⭐⭐"
                                : currentRating == 2
                                    ? "Could be better ⭐⭐"
                                    : "Poor experience ⭐",
                    style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: textController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: "Write a short review or feedback (optional)...",
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              setModalState(() => isSubmitting = true);
                              final orderProv = Provider.of<OrderProvider>(context, listen: false);
                              final success = await orderProv.rateOrder(
                                orderId: _order.id,
                                rating: currentRating,
                                review: textController.text.trim(),
                              );
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      success
                                          ? "Thank you for your rating and feedback!"
                                          : (orderProv.errorMessage ?? "Failed to submit rating"),
                                    ),
                                    backgroundColor: success ? Colors.green : Colors.red,
                                  ),
                                );
                                _refreshOrderDetails();
                              }
                            },
                      child: isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text(
                              "Submit Rating",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showSupportBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text(
              "Need Help with this Order?",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              "Order ID: ${_order.orderId}",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.call, color: Colors.green),
              ),
              title: const Text(
                "Call Customer Care",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text("24/7 dedicated customer assistance"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(ctx);
                _callPhone("+919876543210");
              },
            ),
            const Divider(),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chat_bubble_outline,
                  color: Colors.blue,
                ),
              ),
              title: const Text(
                "Chat with Support",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text("Instant resolution on WhatsApp"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                Navigator.pop(ctx);
                final Uri url = Uri.parse("https://wa.me/919876543210");
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                }
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isCancelled = _order.status == 'CANCELLED';
    final bool isDelivered = _order.status == 'DELIVERED';
    final int currentStep = _getStatusStep(_order.status);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ETA calculation
    String estimatedTime = "10–15 Mins";
    if (_order.createdAt != null && !isCancelled && !isDelivered) {
      final eta = _order.createdAt!.add(const Duration(minutes: 15));
      estimatedTime = DateFormat('hh:mm a').format(eta);
    } else if (isDelivered) {
      estimatedTime = "Delivered";
    } else if (isCancelled) {
      estimatedTime = "Cancelled";
    }

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF090D16)
          : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText(
              "Live Order Tracking",
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
            CustomText(
              "ID: ${_order.orderId}",
              color: isDark ? Colors.white60 : Colors.black54,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            tooltip: "Refresh Status",
            icon: _isRefreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
            onPressed: () => _refreshOrderDetails(),
          ),
          IconButton(
            tooltip: "Support",
            icon: const Icon(Icons.help_outline_rounded),
            onPressed: _showSupportBottomSheet,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _refreshOrderDetails(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Hero Simulated Interactive Vector Map Section
              _buildInteractiveMapHero(
                isCancelled: isCancelled,
                isDelivered: isDelivered,
                currentStep: currentStep,
                estimatedTime: estimatedTime,
                isDark: isDark,
              ),

              // 2. Live Countdown Delivery ETA Card (Zepto / Blinkit style)
              _buildLiveCountdownCard(
                isDark,
                isDelivered,
                isCancelled,
                currentStep,
              ),

              // 3. Status Headline Hero Card
              _buildStatusHeadlineCard(
                currentStep: currentStep,
                estimatedTime: estimatedTime,
                isDark: isDark,
              ),

              // 4. Delivery Handover PIN / OTP Card
              if (!isDelivered && !isCancelled)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: _buildDeliveryPinCard(isDark),
                ),

              // 5. Delivery Partner / Assigning Rider Section with Call & Chat
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                child: _buildRiderSection(isDark),
              ),

              // 6. Delivery Instructions & Landmark Card (Option B integration)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                child: _buildDeliveryInstructionsCard(isDark),
              ),

              // 7. Step-by-step Detailed Journey Timeline
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                child: _buildAdvancedTimeline(currentStep, isCancelled, isDark),
              ),

              // 8. Delivery Address Card
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                child: _buildAddressCard(isDark),
              ),

              // 9. Order Items & Bill Breakdown Card
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                child: _buildItemsAndBillCard(isDark),
              ),

              // Action buttons: Cancel order if pending
              if (_order.status == 'PENDING')
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _confirmCancelOrder,
                      icon: const Icon(
                        Icons.cancel_outlined,
                        color: Colors.red,
                      ),
                      label: const Text(
                        "CANCEL ORDER",
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Colors.redAccent,
                          width: 1.2,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ),

              // Delivered: Rate Order & Re-order Card
              if (isDelivered)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: _buildDeliveredActionsCard(isDark),
                ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeliveredActionsCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF10B981),
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Delivered Successfully!",
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                    Text(
                      _order.rating != null
                          ? "You rated this order ${_order.rating!.toStringAsFixed(1)} ★"
                          : "How was your delivery experience?",
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _handleReorder,
                  icon: const Icon(Icons.replay_rounded, size: 16),
                  label: const Text("Order Again"),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showRatingModal,
                  icon: const Icon(Icons.star_rounded, size: 18),
                  label: Text(_order.rating == null ? "Rate Order" : "Edit Rating"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 1. SIMULATED VECTOR MAP HERO
  Widget _buildInteractiveMapHero({
    required bool isCancelled,
    required bool isDelivered,
    required int currentStep,
    required String estimatedTime,
    required bool isDark,
  }) {
    final double bikeProgress = isDelivered
        ? 1.0
        : (currentStep == 3
              ? 0.75 + (0.2 * _bikeMovementAnimation.value)
              : currentStep == 2
              ? 0.45 + (0.15 * _bikeMovementAnimation.value)
              : currentStep == 1
              ? 0.25
              : 0.08);

    return Container(
      height: 310,
      width: double.infinity,
      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
      child: Stack(
        children: [
          // 1. Map Layer: Real Interactive Google Map with Polyline or 3D Vector Graphic
          if (_useGoogleMap)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _bikeMovementAnimation,
                builder: (context, _) {
                  final progress = isDelivered
                      ? 1.0
                      : (currentStep == 3
                            ? 0.55 + (0.35 * _bikeMovementAnimation.value)
                            : currentStep == 2
                            ? 0.30 + (0.18 * _bikeMovementAnimation.value)
                            : currentStep == 1
                            ? 0.12 + (0.08 * _bikeMovementAnimation.value)
                            : 0.05);

                  return GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(
                        (_storeLatLng.latitude + _destLatLng.latitude) / 2,
                        (_storeLatLng.longitude + _destLatLng.longitude) / 2,
                      ),
                      zoom: 14.2,
                    ),
                    markers: _getMarkers(
                      isDelivered,
                      isCancelled,
                      currentStep,
                      progress,
                    ),
                    polylines: _getPolylines(isDelivered, progress),
                    myLocationEnabled: false,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                    compassEnabled: false,
                    rotateGesturesEnabled: true,
                    scrollGesturesEnabled: true,
                    zoomGesturesEnabled: true,
                    gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                      Factory<OneSequenceGestureRecognizer>(
                        () => EagerGestureRecognizer(),
                      ),
                    },
                    style: isDark ? _darkMapStyle : null,
                    onMapCreated: (controller) {
                      _mapController = controller;
                      _fitMapBounds();
                    },
                  );
                },
              ),
            )
          else
            // Custom Painted Realistic Map Graphic
            Positioned.fill(
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  _pulseAnimation,
                  _bikeMovementAnimation,
                ]),
                builder: (context, _) {
                  return CustomPaint(
                    painter: _DeliveryMapPainter(
                      pulseValue: _pulseAnimation.value,
                      bikeProgress: bikeProgress,
                      isDark: isDark,
                      isDelivered: isDelivered,
                      isCancelled: isCancelled,
                      primaryColor: AppTheme.primary,
                    ),
                  );
                },
              ),
            ),

          // 2. Top-right Floating Action Controls (Recenter & Map/Radar View Switcher)
          Positioned(
            top: 12,
            right: 12,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_useGoogleMap)
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _fitMapBounds();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (isDark ? const Color(0xFF0F172A) : Colors.white)
                            .withValues(alpha: 0.92),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.my_location_rounded,
                        size: 18,
                        color: Color(0xFF0284C7),
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _useGoogleMap = !_useGoogleMap;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: (isDark ? const Color(0xFF0F172A) : Colors.white)
                          .withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? Colors.white12 : Colors.black12,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _useGoogleMap
                              ? Icons.map_rounded
                              : Icons.radar_rounded,
                          size: 14,
                          color: AppTheme.primary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _useGoogleMap ? "Google Map" : "3D Radar",
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Floating Glassmorphic ETA Card on Map
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: (isDark ? const Color(0xFF0F172A) : Colors.white)
                    .withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: (isDark ? Colors.white12 : Colors.black12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Animated Scooter Icon / Delivery Tag
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDelivered
                            ? [const Color(0xFF10B981), const Color(0xFF059669)]
                            : isCancelled
                            ? [Colors.red, Colors.redAccent]
                            : [AppTheme.primary, const Color(0xFFEA580C)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color:
                              (isDelivered
                                      ? const Color(0xFF10B981)
                                      : AppTheme.primary)
                                  .withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      isDelivered
                          ? Icons.check_circle_rounded
                          : isCancelled
                          ? Icons.cancel_rounded
                          : Icons.delivery_dining_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: isDelivered
                                    ? Colors.green
                                    : isCancelled
                                    ? Colors.red
                                    : const Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isDelivered
                                  ? "DELIVERED"
                                  : isCancelled
                                  ? "CANCELLED"
                                  : "GUARANTEED 10-15 MINS",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.6,
                                color: isDelivered
                                    ? Colors.green
                                    : isCancelled
                                    ? Colors.red
                                    : const Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isDelivered
                              ? "Delivered Successfully"
                              : isCancelled
                              ? "Order was cancelled"
                              : "Arriving by $estimatedTime",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Live distance tag
                  if (!isDelivered && !isCancelled)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "1.2 km away",
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
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

  // 1B. LIVE 10-15 MIN COUNTDOWN CARD (Zepto/Blinkit Live Countdown Timer)
  Widget _buildLiveCountdownCard(
    bool isDark,
    bool isDelivered,
    bool isCancelled,
    int currentStep,
  ) {
    if (isDelivered || isCancelled) return const SizedBox.shrink();

    final countdownStr = _formattedCountdown();
    final double fraction = (_secondsRemaining / (15 * 60)).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [Colors.white, const Color(0xFFF8FAFC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Circular Countdown Progress Ring
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 52,
                height: 52,
                child: CircularProgressIndicator(
                  value: fraction,
                  strokeWidth: 4.5,
                  backgroundColor: isDark
                      ? Colors.white12
                      : const Color(0xFFE2E8F0),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _secondsRemaining < 180
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFF10B981),
                  ),
                ),
              ),
              Icon(
                Icons.bolt_rounded,
                color: _secondsRemaining < 180
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFF10B981),
                size: 26,
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF10B981),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF10B981),
                            blurRadius: 6,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    const CustomText(
                      "LIVE 10-15 MINS DELIVERY",
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                      color: Color(0xFF10B981),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    CustomText(
                      countdownStr,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    const SizedBox(width: 6),
                    const CustomText(
                      "remaining",
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                CustomText(
                  currentStep >= 3
                      ? "Rider is speeding to your address 🛵"
                      : "Fresh items are being hand-picked at store 🛒",
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 2. STATUS HEADLINE CARD WITH STEP PROGRESS BAR
  Widget _buildStatusHeadlineCard({
    required int currentStep,
    required String estimatedTime,
    required bool isDark,
  }) {
    final color = _getStatusColor(_order.status);
    final double progressFraction = (_getStatusStep(_order.status) + 1) / 5;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: CustomText(
                  _order.status.replaceAll('_', ' '),
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              CustomText(
                "Step ${currentStep + 1} of 5",
                color: isDark ? Colors.white60 : Colors.black54,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ],
          ),
          const SizedBox(height: 10),
          CustomText(
            _getStatusHeadline(_order.status),
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          const SizedBox(height: 4),
          CustomText(
            _getStatusDescription(_order.status),
            fontSize: 13,
            color: isDark ? Colors.white70 : Colors.black87,
            height: 1.35,
          ),
          const SizedBox(height: 14),

          // Linear animated Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 6,
              child: Stack(
                children: [
                  Container(
                    color: isDark ? Colors.white10 : Colors.grey.shade200,
                  ),
                  FractionallySizedBox(
                    widthFactor: progressFraction.clamp(0.05, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color.withValues(alpha: 0.7), color],
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

  // 3. DELIVERY PARTNER OR RADAR SCANNING SECTION
  Widget _buildRiderSection(bool isDark) {
    final rider = _order.assignedRider;
    final bool isCancelled = _order.status == 'CANCELLED';
    final bool isDelivered = _order.status == 'DELIVERED';

    if (isCancelled || isDelivered) return const SizedBox.shrink();

    if (rider != null) {
      final String riderName = rider['name'] ?? "UB Mart Delivery Partner";
      final String vehicleNumber = rider['vehicleNumber'] ?? "UB Express Bike";
      final String riderPhone = rider['phone'] ?? "";

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFF10B981).withValues(alpha: 0.3),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Rider Avatar with Verified badge
            Stack(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppTheme.primaryLight.withValues(alpha: 0.3),
                  child: Icon(Icons.person, size: 30, color: AppTheme.primary),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.verified_rounded,
                      color: Color(0xFF10B981),
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    riderName,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  const SizedBox(height: 2),
                  CustomText(
                    vehicleNumber,
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 2),
                      CustomText(
                        (rider['rating'] != null)
                            ? (rider['rating'] as num).toDouble().toStringAsFixed(1)
                            : "4.9",
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: CustomText(
                          "Sanitized & Vaccinated",
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Action Buttons: Quick Message & Phone Call
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Quick Message / Chat Button
                IconButton.filled(
                  tooltip: "Message Rider",
                  onPressed: () => _showRiderChatModal(riderName, riderPhone),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                    foregroundColor: AppTheme.primary,
                    padding: const EdgeInsets.all(10),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
                ),
                if (riderPhone.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  // Call Button
                  IconButton.filled(
                    tooltip: "Call Rider",
                    onPressed: () => _callPhone(riderPhone),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(10),
                    ),
                    icon: const Icon(Icons.call_rounded, size: 20),
                  ),
                ],
              ],
            ),
          ],
        ),
      );
    } else {
      // Animated Radar scanning card for rider assignment
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.amber.withValues(alpha: 0.3),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withValues(alpha: 0.05),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          children: [
            // Animated Radar Icon
            RotationTransition(
              turns: _radarScanController,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.amber.shade300, width: 1.5),
                ),
                child: const Icon(
                  Icons.radar_rounded,
                  color: Color(0xFFD97706),
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    "Assigning Delivery Partner",
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  const SizedBox(height: 2),
                  CustomText(
                    "Locating the nearest rider in your sector. Partner will be assigned before packing finishes.",
                    color: isDark ? Colors.white60 : Colors.black54,
                    fontSize: 11,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  // QUICK MESSAGE MODAL FOR RIDER
  void _showRiderChatModal(String riderName, String riderPhone) {
    HapticFeedback.lightImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                    child: Icon(
                      Icons.two_wheeler_rounded,
                      color: AppTheme.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        "Quick Message to Rider",
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      CustomText(
                        riderName,
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const CustomText(
                "TAP A QUICK MESSAGE",
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
                color: Color(0xFF94A3B8),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  "🚪 Leave at doorstep",
                  "🔕 Please don't ring bell",
                  "🛡️ Leave with security guard",
                  "📞 Call when you reach gate",
                  "🏢 Lift is on the right",
                ].map((msg) {
                  return GestureDetector(
                    onTap: () {
                      controller.text = msg;
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark
                              ? Colors.white10
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: CustomText(
                        msg,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  hintText: "Type custom message for rider...",
                  hintStyle: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                  ),
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final text = controller.text.trim();
                    if (text.isEmpty) return;
                    Navigator.pop(ctx);
                    HapticFeedback.mediumImpact();
                    if (riderPhone.isNotEmpty) {
                      _launchSms(riderPhone, text);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: CustomText(
                            "Message sent to $riderName: '$text'",
                          ),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: const Color(0xFF10B981),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: const CustomText(
                    "Send to Rider",
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 3A. SAFE HANDOVER PIN / DELIVERY OTP CARD
  Widget _buildDeliveryPinCard(bool isDark) {
    final pin = _order.deliveryPin;
    final digits = pin.padLeft(4, '0').split('');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.primary.withValues(alpha: 0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.verified_user_rounded,
                      size: 16,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  CustomText(
                    "Delivery Handover PIN",
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const CustomText(
                  "OTP FOR RIDER",
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  color: Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ...digits.map((digit) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: 46,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.3 : 0.05,
                        ),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: CustomText(
                    digit,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                );
              }),
              const SizedBox(width: 8),
              IconButton(
                tooltip: "Copy PIN",
                icon: Icon(
                  Icons.copy_rounded,
                  size: 20,
                  color: AppTheme.primary,
                ),
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  Clipboard.setData(ClipboardData(text: pin));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: CustomText(
                        "Delivery PIN $pin copied to clipboard!",
                      ),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: const Color(0xFF0F172A),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Center(
            child: CustomText(
              "Share this 4-digit code with your delivery partner upon package arrival.",
              textAlign: TextAlign.center,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  // 3B. CUSTOMER DELIVERY INSTRUCTIONS & LANDMARK NOTE CARD
  Widget _buildDeliveryInstructionsCard(bool isDark) {
    final instructions = _order.deliveryInstructions;
    final note = _order.deliveryNote;

    if (instructions.isEmpty && (note == null || note.isEmpty)) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_active_outlined,
                  size: 16,
                  color: Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 8),
              CustomText(
                "Rider Instructions",
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (instructions.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: instructions
                  .where((i) => !i.startsWith('Note: '))
                  .map((instr) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: CustomText(
                        instr,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    );
                  })
                  .toList(),
            ),
            const SizedBox(height: 8),
          ],
          if (note != null && note.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0F172A)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.navigation_rounded,
                    size: 14,
                    color: Color(0xFF64748B),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: CustomText(
                      'Landmark note: "$note"',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : const Color(0xFF334155),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 4. STEP-BY-STEP DETAILED JOURNEY TIMELINE
  Widget _buildAdvancedTimeline(
    int currentStep,
    bool isCancelled,
    bool isDark,
  ) {
    final stages = [
      {
        'title': 'Order Placed & Confirmed',
        'subtitle': 'We have received your order details',
        'icon': Icons.receipt_long_rounded,
      },
      {
        'title': 'Accepted by Store',
        'subtitle': 'Store acknowledged and assigned queue',
        'icon': Icons.storefront_rounded,
      },
      {
        'title': 'Packing & Quality Check',
        'subtitle': 'Items hygienically bagged & sealed',
        'icon': Icons.inventory_2_rounded,
      },
      {
        'title': 'Out for Delivery',
        'subtitle': 'Delivery partner is heading to your address',
        'icon': Icons.moped_rounded,
      },
      {
        'title': 'Delivered',
        'subtitle': 'Package handed over safely',
        'icon': Icons.home_rounded,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.timeline_rounded,
                size: 20,
                color: Color(0xFF10B981),
              ),
              const SizedBox(width: 8),
              CustomText(
                "Order Journey",
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: stages.length,
            itemBuilder: (context, index) {
              final isCompleted = !isCancelled && index <= currentStep;
              final isCurrent = !isCancelled && index == currentStep;
              final isLast = index == stages.length - 1;
              final stage = stages[index];

              // Timestamp display (mocked from order createdAt)
              String? timeText;
              if (index == 0 && _order.createdAt != null) {
                timeText = DateFormat('hh:mm a').format(_order.createdAt!);
              } else if (isCompleted && _order.createdAt != null) {
                final stepTime = _order.createdAt!.add(
                  Duration(minutes: index * 3),
                );
                timeText = DateFormat('hh:mm a').format(stepTime);
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon node + connecting vertical line
                  Column(
                    children: [
                      // Node circle
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isCompleted
                                  ? const Color(0xFF10B981)
                                  : (isDark
                                        ? Colors.white12
                                        : Colors.grey.shade200),
                              border: Border.all(
                                color: isCurrent
                                    ? const Color(0xFF6EE7B7)
                                    : (isCompleted
                                          ? const Color(0xFF10B981)
                                          : Colors.transparent),
                                width: isCurrent ? 2.5 : 1,
                              ),
                              boxShadow: isCurrent
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF10B981)
                                            .withValues(
                                              alpha:
                                                  0.5 * _pulseAnimation.value,
                                            ),
                                        blurRadius: 8 * _pulseAnimation.value,
                                        spreadRadius: 2 * _pulseAnimation.value,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Icon(
                              isCompleted
                                  ? Icons.check_rounded
                                  : stage['icon'] as IconData,
                              size: 16,
                              color: isCompleted
                                  ? Colors.white
                                  : (isDark
                                        ? Colors.white38
                                        : Colors.grey.shade500),
                            ),
                          );
                        },
                      ),
                      // Connector line
                      if (!isLast)
                        Container(
                          width: 2.5,
                          height: 36,
                          margin: const EdgeInsets.symmetric(vertical: 2),
                          decoration: BoxDecoration(
                            color: isCompleted && index < currentStep
                                ? const Color(0xFF10B981)
                                : (isDark
                                      ? Colors.white12
                                      : Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  // Stage Title, Subtitle, and Time
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CustomText(
                                stage['title'] as String,
                                fontSize: 14,
                                fontWeight: isCompleted
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: isCompleted
                                    ? (isDark ? Colors.white : Colors.black87)
                                    : (isDark ? Colors.white38 : Colors.grey),
                              ),
                              const Spacer(),
                              if (timeText != null)
                                CustomText(
                                  timeText,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isCompleted
                                      ? const Color(0xFF10B981)
                                      : Colors.grey,
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          CustomText(
                            stage['subtitle'] as String,
                            fontSize: 12,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // 5. DELIVERY ADDRESS DETAILS
  Widget _buildAddressCard(bool isDark) {
    final addr = _order.deliveryAddress;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.location_on_rounded,
                  color: AppTheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CustomText(
                          addr.tag.toUpperCase(),
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: CustomText(
                            "Delivery Destination",
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    CustomText(
                      addr.receiverName.isNotEmpty
                          ? "${addr.receiverName} • ${addr.receiverPhone}"
                          : _order.customerName,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          CustomText(
            addr.completeAddress.isNotEmpty
                ? addr.completeAddress
                : "Deliver to door",
            fontSize: 13,
            color: isDark ? Colors.white60 : Colors.black54,
            height: 1.3,
          ),
        ],
      ),
    );
  }

  // 6. ITEMS AND ITEMIZED BILL BREAKDOWN
  Widget _buildItemsAndBillCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Expand/Collapse button
          InkWell(
            onTap: () => setState(() => _itemsExpanded = !_itemsExpanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  const Icon(
                    Icons.shopping_bag_outlined,
                    color: Color(0xFF10B981),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Order Items (${_order.items.length})",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _itemsExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),

          // Items list
          if (_itemsExpanded) ...[
            const Divider(height: 1),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _order.items.length,
              separatorBuilder: (_, index) => const Divider(height: 1, indent: 64),
              itemBuilder: (context, index) {
                final item = _order.items[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      // Item Image
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child:
                              (item.imageUrl != null &&
                                  item.imageUrl!.isNotEmpty)
                              ? SmartImage(
                                  imageUrl: item.imageUrl!,
                                  fit: BoxFit.cover,
                                )
                              : const Icon(
                                  Icons.inventory_2_outlined,
                                  size: 20,
                                  color: Colors.grey,
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Name and variant
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              item.variantSize,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? Colors.white54
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Quantity x Price
                      Text(
                        "${item.quantity} × ₹${item.priceAtPurchase.toStringAsFixed(0)}",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],

          const Divider(height: 1),

          // Bill Summary
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildBillRow(
                  "Item Total",
                  "₹${_order.itemTotal.toStringAsFixed(0)}",
                  isDark,
                ),
                const SizedBox(height: 6),
                _buildBillRow(
                  "Delivery Fee",
                  _order.deliveryFee == 0
                      ? "FREE"
                      : "₹${_order.deliveryFee.toStringAsFixed(0)}",
                  isDark,
                  isFree: _order.deliveryFee == 0,
                ),
                if (_order.discountAmount > 0) ...[
                  const SizedBox(height: 6),
                  _buildBillRow(
                    "Discount",
                    "-₹${_order.discountAmount.toStringAsFixed(0)}",
                    isDark,
                    isDiscount: true,
                  ),
                ],
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(height: 1),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Grand Total",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        CustomText(
                          "Payment: ${_order.paymentMethod} (${_order.paymentStatus})",
                          fontSize: 11,
                          color: Color(0xFF10B981),
                          fontWeight: FontWeight.w700,
                        ),
                      ],
                    ),
                    CustomText(
                      "₹${_order.totalAmount.toStringAsFixed(0)}",
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillRow(
    String label,
    String value,
    bool isDark, {
    bool isFree = false,
    bool isDiscount = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white60 : Colors.black54,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isFree
                ? Colors.green
                : isDiscount
                ? Colors.green
                : (isDark ? Colors.white : Colors.black87),
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// CUSTOM VECTOR MAP PAINTER
// -----------------------------------------------------------------------------
class _DeliveryMapPainter extends CustomPainter {
  final double pulseValue;
  final double bikeProgress;
  final bool isDark;
  final bool isDelivered;
  final bool isCancelled;
  final Color primaryColor;

  _DeliveryMapPainter({
    required this.pulseValue,
    required this.bikeProgress,
    required this.isDark,
    required this.isDelivered,
    required this.isCancelled,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Background Grid & City Blocks
    final bgPaint = Paint()
      ..color = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Green parks / soft zones
    final parkPaint = Paint()
      ..color = isDark
          ? const Color(0xFF064E3B).withValues(alpha: 0.25)
          : const Color(0xFFDCFCE7).withValues(alpha: 0.6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(10, 20, 80, 70),
        const Radius.circular(12),
      ),
      parkPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width - 110, size.height - 110, 95, 60),
        const Radius.circular(12),
      ),
      parkPaint,
    );

    // City street grid lines
    final streetPaint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.white.withValues(alpha: 0.9)
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke;

    // Horizontal roads
    canvas.drawLine(Offset(0, 50), Offset(size.width, 50), streetPaint);
    canvas.drawLine(Offset(0, 140), Offset(size.width, 140), streetPaint);
    canvas.drawLine(Offset(0, 210), Offset(size.width, 210), streetPaint);

    // Vertical roads
    canvas.drawLine(Offset(60, 0), Offset(60, size.height), streetPaint);
    canvas.drawLine(
      Offset(size.width * 0.45, 0),
      Offset(size.width * 0.45, size.height),
      streetPaint,
    );
    canvas.drawLine(
      Offset(size.width - 60, 0),
      Offset(size.width - 60, size.height),
      streetPaint,
    );

    // 2. Route Path: Store Pin (Start) to Destination Pin (End)
    final startPoint = Offset(size.width * 0.16, size.height * 0.32);
    final controlPoint1 = Offset(size.width * 0.40, size.height * 0.15);
    final controlPoint2 = Offset(size.width * 0.55, size.height * 0.68);
    final endPoint = Offset(size.width * 0.84, size.height * 0.48);

    final routePath = Path()
      ..moveTo(startPoint.dx, startPoint.dy)
      ..cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        endPoint.dx,
        endPoint.dy,
      );

    // Route shadow / halo
    final routeGlowPaint = Paint()
      ..color =
          (isDelivered ? const Color(0xFF10B981) : const Color(0xFFF59E0B))
              .withValues(alpha: 0.25)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(routePath, routeGlowPaint);

    // Route base line
    final routeBasePaint = Paint()
      ..color = isDark ? Colors.white24 : Colors.grey.shade400
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(routePath, routeBasePaint);

    // Glowing active traveled line (animated gradient)
    final pathMetrics = routePath.computeMetrics().toList();
    if (pathMetrics.isNotEmpty) {
      final metric = pathMetrics.first;
      final traveledLength = metric.length * bikeProgress;
      final traveledPath = metric.extractPath(0, traveledLength);

      final traveledPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            const Color(0xFF38BDF8),
            isDelivered ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
          ],
        ).createShader(Rect.fromPoints(startPoint, endPoint))
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(traveledPath, traveledPaint);

      // Current Scooter Position and Heading
      final tangent = metric.getTangentForOffset(traveledLength);
      if (tangent != null && !isCancelled) {
        final bikePos = tangent.position;

        // Scooter Radar Pulse
        if (!isDelivered) {
          final radarPaint = Paint()
            ..color = const Color(
              0xFFF59E0B,
            ).withValues(alpha: (1.0 - pulseValue) * 0.5)
            ..style = PaintingStyle.fill;
          canvas.drawCircle(bikePos, 14 + (16 * pulseValue), radarPaint);
        }

        // Scooter Marker Background
        final bikeBgPaint = Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFFF59E0B), Color(0xFFEA580C)],
          ).createShader(Rect.fromCircle(center: bikePos, radius: 14))
          ..style = PaintingStyle.fill;
        canvas.drawCircle(bikePos, 14, bikeBgPaint);

        final bikeBorderPaint = Paint()
          ..color = Colors.white
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;
        canvas.drawCircle(bikePos, 14, bikeBorderPaint);

        // Draw Scooter symbol
        final textPainter = TextPainter(
          text: const TextSpan(text: "🛵", style: TextStyle(fontSize: 14)),
          textDirection: ui.TextDirection.ltr,
        )..layout();
        textPainter.paint(
          canvas,
          Offset(
            bikePos.dx - textPainter.width / 2,
            bikePos.dy - textPainter.height / 2,
          ),
        );
      }
    }

    // 3. Store Hub Pin (Start)
    _drawPin(
      canvas: canvas,
      center: startPoint,
      iconText: "🏪",
      label: "UB Store Hub",
      color: const Color(0xFF3B82F6),
      isDark: isDark,
    );

    // 4. Customer Home Pin (Destination)
    _drawPin(
      canvas: canvas,
      center: endPoint,
      iconText: "🏠",
      label: "My Location",
      color: const Color(0xFF10B981),
      isDark: isDark,
    );
  }

  void _drawPin({
    required Canvas canvas,
    required Offset center,
    required String iconText,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    // Pulse ring
    final pulsePaint = Paint()
      ..color = color.withValues(alpha: (1.0 - pulseValue) * 0.4)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 12 + (10 * pulseValue), pulsePaint);

    // Solid pin circle
    final pinPaint = Paint()..color = color;
    canvas.drawCircle(center, 13, pinPaint);

    final borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, 13, borderPaint);

    // Emoji icon
    final textPainter = TextPainter(
      text: TextSpan(text: iconText, style: const TextStyle(fontSize: 12)),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );

    // Label pill under pin
    final labelPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();

    final labelBgPaint = Paint()
      ..color = (isDark ? const Color(0xFF0F172A) : Colors.white).withValues(
        alpha: 0.85,
      );
    final labelRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy + 20),
      width: labelPainter.width + 10,
      height: 14,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(labelRect, const Radius.circular(4)),
      labelBgPaint,
    );
    labelPainter.paint(canvas, Offset(labelRect.left + 5, labelRect.top + 1));
  }

  @override
  bool shouldRepaint(covariant _DeliveryMapPainter oldDelegate) {
    return oldDelegate.pulseValue != pulseValue ||
        oldDelegate.bikeProgress != bikeProgress ||
        oldDelegate.isDelivered != isDelivered ||
        oldDelegate.isCancelled != isCancelled;
  }
}
