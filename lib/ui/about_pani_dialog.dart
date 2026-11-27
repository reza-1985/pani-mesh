import 'package:flutter/material.dart';

Future<void> showAboutPaniDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Dialog(
          backgroundColor: const Color(0xFF181D34),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipOval(
                  child: Image.asset(
                    'assets/icons/pani_mesh_logo.png',
                    width: 84,
                    height: 84,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'درباره پانی • Pani Mesh',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'اگر پانی را از Pani VPN می‌شناسید، الان دیگر ترفیع گرفته و شده «مهندس ارشد شبکه»؛ البته همچنان با مدیریت از راه دور روی مبل خانه! در Pani Mesh پانی به‌جای یک مسیر، یک شبکه «مِش» (چندمسیره و پر از راه مخفی) ساخته که فیلترینگ هرچقدر سخت و بسته باشد، پانی راهش را پیدا می‌کند. از سرعتِ موشکی MASQUE و WARP گرفته تا تونل شخصی VLESS و SSH و حتی با کمک نیروهای Psiphon و Tor؛ کافی است یک بار روی صورت پشمالویش بزنید تا خودش راه باز به دنیای آزاد را بو بکشد و پیدا کند!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('بستن'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
