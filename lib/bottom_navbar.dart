import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth/login_page.dart';
import 'providers/user_provider.dart';
import 'pages/delivery.dart';
import 'pages/history_payment.dart';
import 'pages/profile.dart';

class BottomNavbar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final int? deliveryCount;
  final bool isLoggedIn;

  const BottomNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.deliveryCount = 0,
    required this.isLoggedIn,
  });

  void _handleNavigation(BuildContext context, int index) {
    if (index == 4 && !isLoggedIn) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
      return;
    }

    onTap(index);
  }

  @override
  Widget build(BuildContext context) {
    final List<IconData> _icons = [
      Icons.dashboard,
      Icons.local_shipping,
      Icons.shopping_bag,
      Icons.payment,
      Icons.person_outline,
    ];

    final List<String> _labels = [
      'Dashboard',
      'Delivery',
      'Products',
      'History',
      isLoggedIn ? 'Profile' : 'Login',
    ];

    final List<Color> _activeColors = [
      Colors.pink[300]!,
      Colors.pink[400]!,
      Colors.pink[500]!,
      Colors.pink[600]!,
      Colors.pink[700]!
    ];

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.only(bottom: 15, left: 20, right: 20),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.blue[50]!.withOpacity(0.8),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_icons.length, (index) {
            bool isSelected = currentIndex == index;

            Widget iconWidget;
            if (index == 1 && deliveryCount! > 0) {
              iconWidget = Badge(
                label: Text(
                  deliveryCount.toString(),
                  style: const TextStyle(fontSize: 10, color: Colors.white),
                ),
                isLabelVisible: deliveryCount! > 0,
                child: Icon(
                  _icons[index],
                  size: 24,
                  color: isSelected ? Colors.white : Colors.grey[700],
                ),
              );
            } else {
              iconWidget = Icon(
                _icons[index],
                size: 24,
                color: isSelected ? Colors.white : Colors.grey[700],
              );
            }

            return GestureDetector(
              onTap: () => _handleNavigation(context, index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      padding: isSelected
                          ? const EdgeInsets.all(10)
                          : const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isSelected ? _activeColors[index] : Colors.transparent,
                        shape: BoxShape.circle,
                        boxShadow: isSelected
                            ? [
                          BoxShadow(
                            color: _activeColors[index].withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                            : [],
                      ),
                      child: iconWidget,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _labels[index],
                      style: TextStyle(
                        color: isSelected
                            ? _activeColors[index]
                            : Colors.grey[700],
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}