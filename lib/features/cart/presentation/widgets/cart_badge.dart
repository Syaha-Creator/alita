import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../config/app_constant.dart';
import '../../../../theme/app_colors.dart';
import '../bloc/cart_bloc.dart';
import '../bloc/cart_state.dart';

class CartBadge extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const CartBadge({
    super.key,
    required this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<CartBloc, CartState>(
      buildWhen: (previous, current) {
        if (previous is CartLoaded && current is CartLoaded) {
          return previous.activeCartItems.length !=
              current.activeCartItems.length;
        }
        return true;
      },
      builder: (context, state) {
        int itemCount = 0;

        if (state is CartLoaded) {
          itemCount = state.activeCartItems.fold(
            0,
            (sum, item) => sum + item.quantity,
          );
        }

        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(AppPadding.p8),
                child: child,
              ),
            ),
            if (itemCount > 0)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    itemCount > 99 ? '99+' : itemCount.toString(),
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
