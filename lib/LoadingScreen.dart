import 'package:burtonaletrail_app/AppColors.dart';
import 'package:flutter/material.dart';

extension HexColor on Color {
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}

class LoadingScreen extends StatelessWidget {
  final String loadingText;
  const LoadingScreen({super.key, required this.loadingText});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20), // Reduced spacing
            Stack(
              alignment: Alignment.center,
              children: [
                // Replace 'assets/logo.png' with the path to your logo
                Image.asset(
                  'assets/images/marvin.png',
                  width: 40, // Smaller size
                  height: 40,
                ),
                SizedBox(
                  width: 50, // Smaller CircularProgressIndicator
                  height: 50,
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                    strokeWidth: 4.0, // Thinner stroke
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10), // Reduced spacing
            Text(
              loadingText,
              style: const TextStyle(
                fontSize: 12, // Smaller font size
                color: AppColors.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
