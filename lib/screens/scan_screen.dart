import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../providers/ble_provider.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';

class ScanScreen extends StatelessWidget {
  const ScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Start scanning on first load if not already
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<BleProvider>(context, listen: false);
      if (!provider.isScanning && !provider.isConnected) {
        provider.startScan();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text("Connect Device"),
        actions: [
          Consumer<BleProvider>(
            builder: (context, provider, child) {
              return IconButton(
                icon: Icon(provider.isScanning ? Icons.stop : Icons.refresh),
                onPressed: () {
                  if (provider.isScanning) {
                    provider.stopScan();
                  } else {
                    provider.startScan();
                  }
                },
              );
            },
          ),
        ],
      ),
      body: Consumer<BleProvider>(
        builder: (context, provider, child) {
          return StreamBuilder<List<ScanResult>>(
            stream: FlutterBluePlus.scanResults,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 20),
                      Text(
                        "Scanning for Aura Fit...",
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                );
              }

              final results = snapshot.data!;
              
              return ListView.builder(
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final result = results[index];
                  final deviceName = result.device.platformName.isNotEmpty
                      ? result.device.platformName
                      : "Unknown Device";
                  final isTarget = deviceName == provider.deviceNameFilter;

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isTarget 
                          ? AppTheme.neonCyan.withValues(alpha: 0.1) 
                          : AppTheme.cardSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: isTarget 
                          ? Border.all(color: AppTheme.neonCyan, width: 2) 
                          : null,
                    ),
                    child: ListTile(
                      title: Text(
                        deviceName,
                        style: TextStyle(
                          color: isTarget ? AppTheme.neonCyan : Colors.white,
                          fontWeight: isTarget ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        result.device.remoteId.toString(),
                        style: const TextStyle(color: Colors.grey),
                      ),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isTarget ? AppTheme.neonCyan : Colors.grey[800],
                          foregroundColor: isTarget ? Colors.black : Colors.white,
                        ),
                        onPressed: () async {
                          provider.stopScan();
                          try {
                            await provider.connect(result.device);
                            if (context.mounted) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => const DashboardScreen()),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Connection failed: $e")),
                            );
                          }
                        },
                        child: const Text("Connect"),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
