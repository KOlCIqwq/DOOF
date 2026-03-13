import 'package:flutter/material.dart';
import '../pages/ai_chat.dart';
import '../models/food_item.dart';

class GlobalAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? extraActions;

  final Function(FoodItem)? onFoodAdded;

  const GlobalAppBar({
    super.key,
    required this.title,
    this.onFoodAdded,
    this.extraActions,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.auto_awesome, color: Colors.blueAccent),
        tooltip: 'Ask to AI',
        onPressed: () {
          Navigator.of(context).push(
            PageRouteBuilder(
              opaque: false,
              pageBuilder: (BuildContext context, _, __) {
                return AIChatOverlay();
              },
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
            ),
          );
        },
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      centerTitle: true,
      actions: extraActions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
