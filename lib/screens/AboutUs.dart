import 'package:eFinance/utils/Constants.dart';
import 'package:flutter/material.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Us',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primary_color,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: bg_color,
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        children: [
          // About Developer Card
          Container(
            decoration: BoxDecoration(
              color: bg_color,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person_rounded, color: primary_color, size: 26),
                      const SizedBox(width: 8),
                      const Text(
                        'About Developer',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20, thickness: 1, color: Colors.black26),
                  const SizedBox(height: 6),
                  const Text('Name: Dhyey Shah',
                      style: TextStyle(color: Colors.black, fontSize: 16)),
                  const SizedBox(height: 6),
                  const Text('Email: dhyeyshah@email.com',
                      style: TextStyle(color: Colors.black, fontSize: 16)),
                  const SizedBox(height: 6),
                  const Text('Contact: +91 9724277321',
                      style: TextStyle(color: Colors.black, fontSize: 16)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Container(
            decoration: BoxDecoration(
              color: bg_color,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: primary_color, size: 26),
                      const SizedBox(width: 8),
                      const Text(
                        'Version',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20, thickness: 1, color: Colors.black26),
                  const SizedBox(height: 6),
                  const Text(
                    'Version: 2025.06.23',
                    style: TextStyle(color: Colors.black, fontSize: 16),
                  ),
                ],
              ),
            ),
          )

        ],
      ),
    );
  }
}
