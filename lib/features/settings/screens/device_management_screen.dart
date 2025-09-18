import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/device_service.dart';
import '../../../l10n/app_localizations.dart';

class DeviceManagementScreen extends StatefulWidget {
  const DeviceManagementScreen({super.key});

  @override
  State<DeviceManagementScreen> createState() => _DeviceManagementScreenState();
}

class _DeviceManagementScreenState extends State<DeviceManagementScreen> {
  final DeviceService _deviceService = DeviceService();
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  List<DeviceInfo> _devices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    setState(() => _isLoading = true);
    try {
      final devices = await _deviceService.getUserDevices(currentUserId);
      setState(() {
        _devices = devices;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      Get.snackbar('Error', 'Failed to load devices: ${e.toString()}');
    }
  }

  Future<void> _signOutDevice(String deviceId, String deviceName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out Device'),
        content: Text('Are you sure you want to sign out from "$deviceName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _deviceService.signOutDevice(currentUserId, deviceId);
        await _loadDevices(); // Refresh the list
        Get.snackbar('Success', 'Device signed out successfully');
      } catch (e) {
        Get.snackbar('Error', 'Failed to sign out device: ${e.toString()}');
      }
    }
  }

  Future<String> _getCurrentDeviceId() async {
    return await _deviceService.getDeviceId();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)?.settings ?? 'Device Management',
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _devices.isEmpty
          ? _buildEmptyState()
          : _buildDeviceList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.devices_other, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'No devices found',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceList() {
    return FutureBuilder<String>(
      future: _getCurrentDeviceId(),
      builder: (context, snapshot) {
        final currentDeviceId = snapshot.data ?? '';

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _devices.length,
          itemBuilder: (context, index) {
            final device = _devices[index];
            final isCurrentDevice = device.deviceId == currentDeviceId;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getDeviceIcon(device.platform),
                          color: isCurrentDevice ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                device.deviceName,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${device.platform} • ${device.appVersion}',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        if (isCurrentDevice)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green),
                            ),
                            child: const Text(
                              'Current',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          device.isActive ? Icons.check_circle : Icons.cancel,
                          color: device.isActive ? Colors.green : Colors.red,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          device.isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            color: device.isActive ? Colors.green : Colors.red,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatDateTime(device.lastLogin),
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                    if (!isCurrentDevice && device.isActive)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => _signOutDevice(
                            device.deviceId,
                            device.deviceName,
                          ),
                          icon: const Icon(Icons.logout, size: 16),
                          label: const Text('Sign Out'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  IconData _getDeviceIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'android':
        return Icons.android;
      case 'ios':
        return Icons.apple;
      default:
        return Icons.devices_other;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}
