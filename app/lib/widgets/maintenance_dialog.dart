import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MaintenanceDialog extends StatelessWidget {
  final String featureName;
  final String message;

  const MaintenanceDialog({
    super.key,
    required this.featureName,
    this.message =
        "This feature is currently under maintenance. We'll be back soon!",
  });

  // --- ADDED STATIC METHOD ---
  static void show(
    BuildContext context,
    String featureName, {
    String? customMessage,
  }) {
    showDialog(
      context: context,
      builder: (context) => MaintenanceDialog(
        featureName: featureName,
        message:
            customMessage ??
            "This feature is currently under maintenance. We'll be back soon!",
      ),
    );
  }
  // ---------------------------

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            // Use withValues for Flutter 3.27+ compatibility
            color: Colors.orangeAccent.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orangeAccent.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.construction,
                size: 60,
                color: Colors.orangeAccent,
              ),
            ),

            const SizedBox(height: 25),

            // Title
            Text(
              "Under Maintenance",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 15),

            // Feature Name
            Text(
              featureName,
              style: GoogleFonts.poppins(
                color: Colors.orangeAccent,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 15),

            // Message
            Text(
              message,
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 30),

            // Close Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "Got It",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
