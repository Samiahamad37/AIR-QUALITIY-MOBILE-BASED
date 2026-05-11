

import 'package:flutter/material.dart';

class homepage extends StatelessWidget {
  const homepage({super.key});

  @override
  Widget build(BuildContext context) {
    int aqi = 0; // simulate API failure like your screenshot

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      // 🔵 TOP NAV BAR (like your DSM dashboard)
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.blue,
              child: Icon(Icons.air, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Text(
              "AirQuality DSM",
              style: TextStyle(color: Colors.black),
            ),
            const Spacer(),
            _navItem("Home", true),
            _navItem("Map View", false),
            _navItem("API Docs", false),
            const SizedBox(width: 20),
            ElevatedButton(
              onPressed: () {},
              child: const Text("Sign in"),
            )
          ],
        ),
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [

            // 🔷 HERO SECTION (gradient like your screenshot)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF007BFF), Color(0xFF00C6FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Container(
                  width: 400,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "CITY-WIDE AIR QUALITY INDEX",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),

                      // ❌ Failed state (like your image)
                      aqi == 0
                          ? const Text(
                              "Failed to fetch",
                              style: TextStyle(color: Colors.red),
                            )
                          : Text(
                              "$aqi",
                              style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold),
                            ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 🟢 HEALTH RECOMMENDATION
            _infoCard(
              title: "Health Recommendations",
              icon: Icons.info_outline,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text("• Enjoy outdoor activities as usual."),
                  Text("• Open windows for ventilation if comfortable."),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 📊 STATS CARDS (like your 3 boxes)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _statCard(Icons.show_chart, "1", "Active Sensors"),
                  const SizedBox(width: 10),
                  _statCard(Icons.trending_up, "1", "Good Locations"),
                  const SizedBox(width: 10),
                  _mapCard(),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 📍 MONITORING LOCATIONS
            const Padding(
              padding: EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Monitoring Locations",
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Loading ...",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 NAV ITEM
  static Widget _navItem(String title, bool active) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Text(
        title,
        style: TextStyle(
          color: active ? Colors.blue : Colors.grey,
          fontWeight: active ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  // 🔹 INFO CARD
  static Widget _infoCard(
      {required String title,
      required IconData icon,
      required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon),
              const SizedBox(width: 10),
              Text(title,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  // 🔹 STATS CARD
  static Widget _statCard(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.blue),
            const SizedBox(height: 10),
            Text(value,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            Text(label),
          ],
        ),
      ),
    );
  }

  // 🔹 MAP CARD
  static Widget _mapCard() {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          children: [
            Icon(Icons.location_on, color: Colors.purple),
            SizedBox(height: 10),
            Text("View Map",
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            Text("Interactive City Map"),
          ],
        ),
      ),
    );
  }
}