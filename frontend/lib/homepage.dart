

// import 'package:flutter/material.dart';
// import 'recommendation.dart';
// import 'Apidocs.dart';

// class HomePage extends StatelessWidget {
//   const HomePage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     int aqi = 0; // simulate API failure like your screenshot

//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F7FB),

//       // 🔵 TOP NAV BAR (like your DSM dashboard)
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 1,
//         title: Row(
//           children: [
//             const CircleAvatar(
//               backgroundColor: Colors.blue,
//               child: Icon(Icons.air, color: Colors.white),
//             ),
//             const SizedBox(width: 10),
//             const Text(
//               "AirQuality",
//               style: TextStyle(color: Colors.black),
//             ),
//             actions: [
//             Flexible(child: _navItem(context, "Home", true, HomePage())),
//             Flexible(child: _navItem(context, "Health Guidance", false, Recommendation())),
//             Expanded(child: _navItem(context, "API Docs", false, ApiDocsPage())),
//             const SizedBox(width: 20),
//             ElevatedButton(
//               onPressed: () {},
//               child: const Text("Sign in"),
//             )
//             ],
//           ],
//         ),
      
//       ),
      
      

//       body: SingleChildScrollView(
//         child: Column(
//           children: [

//             // 🔷 HERO SECTION (gradient like your screenshot)
//             Container(
//               width: double.infinity,
//               padding: const EdgeInsets.all(20),
//               decoration: const BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [Color(0xFF007BFF), Color(0xFF00C6FF)],
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                 ),
//               ),
//               child: Center(
//                 child: Container(
//                   width: 400,
//                   padding: const EdgeInsets.all(20),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Column(
//                     children: [
//                       const Text(
//                         "CITY-WIDE AIR QUALITY INDEX",
//                         style: TextStyle(fontWeight: FontWeight.bold),
//                       ),
//                       const SizedBox(height: 20),

//                       // ❌ Failed state (like your image)
//                       aqi == 0
//                           ? const Text(
//                               "loading...",
//                               style: TextStyle(color: Colors.red),
//                             )
//                           : Text(
//                               "$aqi",
//                               style: const TextStyle(
//                                   fontSize: 40,
//                                   fontWeight: FontWeight.bold),
//                             ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),

//             const SizedBox(height: 20),

//             // 🟢 HEALTH RECOMMENDATION
//             _infoCard(
//               title: "Health Recommendations",
//               icon: Icons.info_outline,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: const [
//                   Text("• Enjoy outdoor activities as usual."),
//                   Text("• Open windows for ventilation if comfortable."),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 20),

//             // 📊 STATS CARDS (like your 3 boxes)
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               child: Row(
//                 children: [
//                   _statCard(Icons.show_chart, "1", "Active Sensors"),
//                   const SizedBox(width: 10),
//                   _statCard(Icons.trending_up, "1", "Good Locations"),
//                   const SizedBox(width: 10),
//                   _mapCard(),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 20),

//             // 📍 MONITORING LOCATIONS
//             const Padding(
//               padding: EdgeInsets.all(16),
//               child: Align(
//                 alignment: Alignment.centerLeft,
//                 child: Text(
//                   "Monitoring Locations",
//                   style: TextStyle(
//                       fontSize: 18, fontWeight: FontWeight.bold),
//                 ),
//               ),
//             ),

//             const Padding(
//               padding: EdgeInsets.symmetric(horizontal: 16),
//               child: Text(
//                 "Loading ...",
//                 style: TextStyle(color: Colors.red),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // 🔹 NAV ITEM
//   static Widget _navItem(BuildContext context, String title, bool active, Widget page) {
//     return GestureDetector(
//     onTap: () {
//       Navigator.push(
//         context,
//         MaterialPageRoute(builder: (context) => page),
//       );
//     },
//     child: Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 5),
//       child: Text(
//         title,
//         style: TextStyle(
//           color: active ? Colors.blue : Colors.grey,
//           fontWeight: active ? FontWeight.bold : FontWeight.normal,
//         ),
//       ),
//     ),
//     );

//   }

//   // 🔹 INFO CARD
//   static Widget _infoCard(
//       {required String title,
//       required IconData icon,
//       required Widget child}) {
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 16),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(icon),
//               const SizedBox(width: 10),
//               Text(title,
//                   style: const TextStyle(fontWeight: FontWeight.bold)),
//             ],
//           ),
//           const SizedBox(height: 10),
//           child,
//         ],
//       ),
//     );
//   }

//   // 🔹 STATS CARD
//   static Widget _statCard(IconData icon, String value, String label) {
//     return Expanded(
//       child: Container(
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: Column(
//           children: [
//             Icon(icon, color: Colors.blue),
//             const SizedBox(height: 10),
//             Text(value,
//                 style: const TextStyle(
//                     fontSize: 20, fontWeight: FontWeight.bold)),
//             Text(label),
//           ],
//         ),
//       ),
//     );
//   }

//   // 🔹 MAP CARD
//   static Widget _mapCard() {
//     return Expanded(
//       child: Container(
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: const Column(
//           children: [
//             Icon(Icons.location_on, color: Colors.purple),
//             SizedBox(height: 10),
//             Text("View Map",
//                 style: TextStyle(
//                     fontSize: 16, fontWeight: FontWeight.bold)),
//             Text("Interactive City Map"),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'recommendation.dart';
import 'Apidocs.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    int aqi = 0; // simulate API failure

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      // ── TOP NAV BAR ──────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        // Logo + App name on the left
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircleAvatar(
              backgroundColor: Colors.blue,
              child: Icon(Icons.air, color: Colors.white),
            ),
            SizedBox(width: 10),
            Text(
              "AirQuality",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        // Nav links + Sign-in button on the right
        actions: [
          _navItem(context, "Home", true, const HomePage()),
          _navItem(context, "Health Guidance", false, const Recommendation()),
          _navItem(context, "API Docs", false, const ApiDocsPage()),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text("Sign in"),
          ),
          const SizedBox(width: 16),
        ],
      ),

      // ── BODY ─────────────────────────────────────────────────────
      body: SingleChildScrollView(
        child: Column(
          children: [

            // ── HERO SECTION ────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF007BFF), Color(0xFF00C6FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Container(
                  width: 420,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "CITY-WIDE AIR QUALITY INDEX",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 1.2,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 24),
                      aqi == 0
                          ? Column(
                              children: const [
                                CircularProgressIndicator(),
                                SizedBox(height: 12),
                                Text(
                                  "Loading AQI data...",
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                Text(
                                  "$aqi",
                                  style: const TextStyle(
                                    fontSize: 56,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                                const Text(
                                  "Good",
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.green,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── HEALTH RECOMMENDATIONS ───────────────────────────────
            _infoCard(
              title: "Health Recommendations",
              icon: Icons.info_outline,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _RecommendationItem(
                    icon: Icons.directions_walk,
                    text: "Enjoy outdoor activities as usual.",
                  ),
                  SizedBox(height: 8),
                  _RecommendationItem(
                    icon: Icons.window,
                    text: "Open windows for ventilation if comfortable.",
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── STATS CARDS ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _statCard(Icons.sensors, "1", "Active Sensors", Colors.blue),
                  const SizedBox(width: 12),
                  _statCard(Icons.trending_up, "1", "Good Locations", Colors.green),
                  const SizedBox(width: 12),
                  _mapCard(context),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── MONITORING LOCATIONS ─────────────────────────────────
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Monitoring Locations",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: const [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text(
                    "Loading locations...",
                    style: TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── NAV ITEM ────────────────────────────────────────────────────
  static Widget _navItem(
      BuildContext context, String title, bool active, Widget page) {
    return GestureDetector(
      onTap: () {
        if (!active) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => page),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Text(
          title,
          style: TextStyle(
            color: active ? Colors.blue : Colors.grey[700],
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // ── INFO CARD ───────────────────────────────────────────────────
  static Widget _infoCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              Icon(icon, color: Colors.blue),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  // ── STAT CARD ───────────────────────────────────────────────────
  static Widget _statCard(
      IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // ── MAP CARD ────────────────────────────────────────────────────
  static Widget _mapCard(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          // Navigate to map page
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Column(
            children: [
              Icon(Icons.map_outlined, color: Colors.purple, size: 28),
              SizedBox(height: 10),
              Text(
                "View Map",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
              SizedBox(height: 4),
              Text(
                "Interactive City Map",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── RECOMMENDATION ITEM WIDGET ───────────────────────────────────
class _RecommendationItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _RecommendationItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.blue),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ),
      ],
    );
  }
}