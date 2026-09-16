import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import 'add_address_screen.dart';

class AddressBookScreen extends StatelessWidget {
  const AddressBookScreen({super.key});

  void _confirmDelete(BuildContext context, AuthProvider authProvider, int index, AddressModel addr) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete Address?", style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text(
          "Are you sure you want to remove '${addr.tag} - ${addr.receiverName}' from your saved addresses?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              HapticFeedback.mediumImpact();
              await authProvider.deleteAddress(index);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text("Address removed successfully."),
                    backgroundColor: const Color(0xFFEF4444),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }
            },
            child: const Text("Delete", style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final addresses = user?.addresses ?? [];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0F19) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0B0F19) : Colors.white,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Text(
              "Saved Addresses",
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 20,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(width: 8),
            if (addresses.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "${addresses.length}",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primary,
                  ),
                ),
              ),
          ],
        ),
        actions: [
          if (addresses.isNotEmpty)
            IconButton(
              tooltip: "Add Address",
              icon: Icon(
                Icons.add_circle_outline_rounded,
                color: isDark ? Colors.white70 : const Color(0xFF0F172A),
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddAddressScreen()),
                );
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: addresses.isEmpty
          ? _buildEmptyState(context, isDark)
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              physics: const BouncingScrollPhysics(),
              children: [
                // ── Top Delivery Hub Banner ──
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.14),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.bolt_rounded, color: Color(0xFF10B981), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "10-15 Min Express Delivery",
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Orders dispatched instantly from your nearest dark-store hub.",
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white54 : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Address Cards ──
                for (int i = 0; i < addresses.length; i++) ...[
                  _buildAddressCard(
                    context: context,
                    authProvider: authProvider,
                    addr: addresses[i],
                    index: i,
                    isDefault: i == 0,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 14),
                ],
              ],
            ),

      // ── Sticky Bottom "Add New Address" Action ──
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0B0F19) : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                elevation: 2,
                shadowColor: AppTheme.primary.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddAddressScreen()),
                );
              },
              icon: const Icon(Icons.add_location_alt_rounded, size: 20),
              label: const Text(
                "+ Add New Address",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── INDIVIDUAL ADDRESS CARD ──
  Widget _buildAddressCard({
    required BuildContext context,
    required AuthProvider authProvider,
    required AddressModel addr,
    required int index,
    required bool isDefault,
    required bool isDark,
  }) {
    Color tagColor;
    IconData tagIcon;
    switch (addr.tag.toUpperCase()) {
      case 'HOME':
        tagColor = const Color(0xFFF59E0B); // Amber
        tagIcon = Icons.home_rounded;
        break;
      case 'WORK':
        tagColor = const Color(0xFF0284C7); // Sky Blue
        tagIcon = Icons.work_rounded;
        break;
      default:
        tagColor = const Color(0xFF8B5CF6); // Purple
        tagIcon = Icons.location_on_rounded;
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDefault
              ? const Color(0xFF10B981).withValues(alpha: 0.5)
              : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
          width: isDefault ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isDefault
                ? const Color(0xFF10B981).withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Card Header: Tag Pill + Default Pill + Overflow Menu ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: tagColor.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(tagIcon, size: 16, color: tagColor),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: tagColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        addr.tag.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: tagColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    if (isDefault) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF10B981)),
                            SizedBox(width: 4),
                            Text(
                              "DEFAULT",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF10B981),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),

                // Popup menu for quick actions
                PopupMenuButton<String>(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: isDark ? Colors.white54 : Colors.grey.shade500,
                    size: 20,
                  ),
                  onSelected: (value) {
                    if (value == 'edit') {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddAddressScreen(
                            initialAddress: addr,
                            addressIndex: index,
                          ),
                        ),
                      );
                    } else if (value == 'default') {
                      HapticFeedback.mediumImpact();
                      authProvider.setDefaultAddress(index);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Set ${addr.tag} as your default delivery address! ⚡"),
                          backgroundColor: const Color(0xFF10B981),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    } else if (value == 'delete') {
                      _confirmDelete(context, authProvider, index, addr);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18),
                          SizedBox(width: 10),
                          Text("Edit Address", style: TextStyle(fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    if (!isDefault)
                      const PopupMenuItem(
                        value: 'default',
                        child: Row(
                          children: [
                            Icon(Icons.star_outline_rounded, size: 18, color: Color(0xFF10B981)),
                            SizedBox(width: 10),
                            Text("Set as Default", style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF10B981))),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                          SizedBox(width: 10),
                          Text("Delete", style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFEF4444))),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Card Body: Name, Address, Phone ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  addr.receiverName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.place_outlined,
                        size: 15,
                        color: isDark ? Colors.white54 : Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        addr.completeAddress,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.phone_rounded,
                      size: 13,
                      color: isDark ? Colors.white54 : Colors.grey.shade500,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "+91 ${addr.receiverPhone}",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white60 : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (addr.lat != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.gps_fixed_rounded, size: 10, color: Color(0xFF0284C7)),
                            SizedBox(width: 3),
                            Text(
                              "GPS Pinned",
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0284C7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          Divider(
            height: 1,
            color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
          ),

          // ── Card Actions Footer ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (isDefault)
                  Row(
                    children: const [
                      Icon(Icons.check_rounded, size: 16, color: Color(0xFF10B981)),
                      SizedBox(width: 4),
                      Text(
                        "Selected for Delivery",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  )
                else
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      authProvider.setDefaultAddress(index);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Selected ${addr.tag} for your deliveries! ⚡"),
                          backgroundColor: const Color(0xFF10B981),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    },
                    icon: const Icon(Icons.navigation_rounded, size: 14, color: Color(0xFF0284C7)),
                    label: const Text(
                      "Deliver Here 🛵",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0284C7),
                      ),
                    ),
                  ),

                Row(
                  children: [
                    // Edit button
                    IconButton(
                      tooltip: "Edit",
                      icon: Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: isDark ? Colors.white60 : Colors.grey.shade600,
                      ),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddAddressScreen(
                              initialAddress: addr,
                              addressIndex: index,
                            ),
                          ),
                        );
                      },
                    ),

                    // Delete button
                    IconButton(
                      tooltip: "Delete",
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: Color(0xFFEF4444),
                      ),
                      onPressed: () => _confirmDelete(context, authProvider, index, addr),
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

  // ── EMPTY STATE ──
  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_off_rounded,
                size: 50,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "No Delivery Addresses Saved Yet",
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Save your home, work, or favorite locations to enjoy instant 10-15 minute doorstep grocery deliveries.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white60 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddAddressScreen()),
                  );
                },
                icon: const Icon(Icons.add_location_alt_rounded, size: 18),
                label: const Text(
                  "+ Add Your First Address",
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
