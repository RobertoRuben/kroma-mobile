import 'package:flutter/material.dart';
import 'package:ultralytics_yolo_example/core/core.dart';

/// Pagination controls bar with smart ellipsis for large page counts
class PaginationBar extends StatelessWidget {
  const PaginationBar({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.startIndex,
    required this.endIndex,
    required this.totalItems,
    required this.onPageChanged,
  });

  final int currentPage;
  final int totalPages;
  final int startIndex;
  final int endIndex;
  final int totalItems;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          // Range indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${startIndex + 1}-$endIndex de $totalItems',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: context.textSecondaryColor,
              ),
            ),
          ),
          const Spacer(),
          _PageButton(
            icon: Icons.chevron_left_rounded,
            onPressed:
                currentPage > 0 ? () => onPageChanged(currentPage - 1) : null,
          ),
          const SizedBox(width: 4),
          ..._buildPageIndicators(context),
          const SizedBox(width: 4),
          _PageButton(
            icon: Icons.chevron_right_rounded,
            onPressed: currentPage < totalPages - 1
                ? () => onPageChanged(currentPage + 1)
                : null,
          ),
        ],
      ),
    );
  }

  /// Builds page indicators with smart ellipsis placement.
  ///
  /// Returns up to 7 items: page dots and ellipsis markers.
  /// -1 is used as sentinel for ellipsis positions.
  List<Widget> _buildPageIndicators(BuildContext context) {
    final maxVisible = totalPages.clamp(0, 7);

    return List.generate(maxVisible, (i) {
      final pageIndex = _resolvePageIndex(i);

      if (pageIndex == -1) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(
            '…',
            style: TextStyle(
              fontSize: 12,
              color: context.textSecondaryColor,
            ),
          ),
        );
      }

      return _PageDot(
        page: pageIndex,
        isActive: pageIndex == currentPage,
        onTap: () => onPageChanged(pageIndex),
      );
    });
  }

  /// Resolves the page index for a given slot position.
  /// Returns -1 for ellipsis positions.
  int _resolvePageIndex(int slot) {
    if (totalPages <= 7) return slot;

    // Near the beginning: [0, 1, 2, 3, 4, …, last]
    if (currentPage < 3) {
      if (slot < 5) return slot;
      if (slot == 5) return -1;
      return totalPages - 1;
    }

    // Near the end: [0, …, last-4, last-3, last-2, last-1, last]
    if (currentPage > totalPages - 4) {
      if (slot == 0) return 0;
      if (slot == 1) return -1;
      return totalPages - 5 + (slot - 2);
    }

    // Middle: [0, …, current-1, current, current+1, …, last]
    if (slot == 0) return 0;
    if (slot == 1) return -1;
    if (slot <= 4) return currentPage + (slot - 3);
    if (slot == 5) return -1;
    return totalPages - 1;
  }
}

class _PageButton extends StatelessWidget {
  const _PageButton({required this.icon, this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final enabled = onPressed != null;
    return Material(
      color: enabled
          ? (isDark ? AppColors.cardDark : AppColors.background)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(
            icon,
            size: 20,
            color: enabled
                ? context.textPrimaryColor
                : context.textSecondaryColor.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }
}

class _PageDot extends StatelessWidget {
  const _PageDot({
    required this.page,
    required this.isActive,
    required this.onTap,
  });

  final int page;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 28,
        height: 28,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          '${page + 1}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? Colors.white : context.textSecondaryColor,
          ),
        ),
      ),
    );
  }
}
