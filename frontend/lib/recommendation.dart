import "package:flutter/material.dart";

class Recommendation extends StatelessWidget {
  const Recommendation({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Recommendations",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text("1. Avoid outdoor activities during high pollution hours."),
                Text("2. Use air purifiers indoors."),
                Text("3. Wear masks if you need to go outside."),
                Text("4. Keep windows closed during peak pollution times."),
              ],
            ),
          )
        ],
      ),
    );
  }
}