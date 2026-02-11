import 'package:flutter/material.dart';
import 'package:ultralytics_yolo_example/core/core.dart';
import 'package:ultralytics_yolo_example/features/evaluations/domain/models/models.dart';

/// Gallery widget for displaying and managing crop items with pagination
/// Supports multi-image workflow with navigation between images
class CropGallery extends StatefulWidget {
  const CropGallery({
    super.key,
    required this.crops,
    required this.onToggleSelection,
    required this.onClassify,
    required this.selectedCount,
    required this.totalCount,
    this.onSelectAll,
    this.onDeselectAll,
    this.itemsPerPage = 30,
    // Multi-image props
    this.imageCount = 1,
    this.currentImageIndex = 0,
    this.onGoToImage,
    this.onAddFromCamera,
    this.onAddFromGallery,
    this.totalSelectedAllImages = 0,
  });

  final List<CropItem> crops;
  final void Function(String cropId) onToggleSelection;
  final VoidCallback onClassify;
  final int selectedCount;
  final int totalCount;
  final VoidCallback? onSelectAll;
  final VoidCallback? onDeselectAll;
  final int itemsPerPage;

  // Multi-image
  final int imageCount;
  final int currentImageIndex;
  final void Function(int index)? onGoToImage;
  final VoidCallback? onAddFromCamera;
  final VoidCallback? onAddFromGallery;
  final int totalSelectedAllImages;

  @override
  State<CropGallery> createState() => _CropGalleryState();
}

class _CropGalleryState extends State<CropGallery> {
  int _currentPage = 0;

  int get _totalPages => (widget.crops.length / widget.itemsPerPage).ceil().clamp(1, 999);
  int get _startIndex => _currentPage * widget.itemsPerPage;
  int get _endIndex => (_startIndex + widget.itemsPerPage).clamp(0, widget.crops.length);
  List<CropItem> get _visibleCrops => widget.crops.sublist(_startIndex, _endIndex);

  @override
  void didUpdateWidget(CropGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset to last valid page if crops list shrinks
    if (_currentPage >= _totalPages) {
      _currentPage = (_totalPages - 1).clamp(0, _totalPages);
    }
  }

  void _goToPage(int page) {
    if (page >= 0 && page < _totalPages && page != _currentPage) {
      setState(() => _currentPage = page);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Multi-image navigation bar
        if (widget.imageCount > 1)
          _ImageNavBar(
            imageCount: widget.imageCount,
            currentIndex: widget.currentImageIndex,
            onGoToImage: widget.onGoToImage,
          ),
        _Header(
          selectedCount: widget.selectedCount,
          totalCount: widget.totalCount,
          onSelectAll: widget.onSelectAll,
          onDeselectAll: widget.onDeselectAll,
        ),
        if (_totalPages > 1)
          _PaginationBar(
            currentPage: _currentPage,
            totalPages: _totalPages,
            startIndex: _startIndex,
            endIndex: _endIndex,
            totalItems: widget.crops.length,
            onPageChanged: _goToPage,
          ),
        Expanded(
          child: _CropGrid(
            crops: _visibleCrops,
            onToggleSelection: widget.onToggleSelection,
          ),
        ),
        _ActionBar(
          onClassify: widget.totalSelectedAllImages > 0
              ? widget.onClassify
              : null,
          totalSelected: widget.totalSelectedAllImages,
          imageCount: widget.imageCount,
          onAddFromCamera: widget.onAddFromCamera,
          onAddFromGallery: widget.onAddFromGallery,
        ),
      ],
    );
  }
}

/// Pagination controls bar
class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
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
              color: isDark
                  ? AppColors.cardDark
                  : AppColors.background,
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
          // Previous button
          _PageButton(
            icon: Icons.chevron_left_rounded,
            onPressed: currentPage > 0 ? () => onPageChanged(currentPage - 1) : null,
          ),
          const SizedBox(width: 4),
          // Page dots / numbers
          ...List.generate(totalPages.clamp(0, 7), (i) {
            final int pageIndex;
            if (totalPages <= 7) {
              pageIndex = i;
            } else if (currentPage < 3) {
              pageIndex = i < 5 ? i : (i == 5 ? -1 : totalPages - 1);
            } else if (currentPage > totalPages - 4) {
              pageIndex = i == 0 ? 0 : (i == 1 ? -1 : totalPages - 5 + (i - 2));
            } else {
              pageIndex = i == 0
                  ? 0
                  : i == 1
                      ? -1
                      : i <= 4
                          ? currentPage + (i - 3)
                          : i == 5
                              ? -1
                              : totalPages - 1;
            }
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
          }),
          const SizedBox(width: 4),
          // Next button
          _PageButton(
            icon: Icons.chevron_right_rounded,
            onPressed: currentPage < totalPages - 1 ? () => onPageChanged(currentPage + 1) : null,
          ),
        ],
      ),
    );
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

/// Header with selection info and actions
class _Header extends StatelessWidget {
  const _Header({
    required this.selectedCount,
    required this.totalCount,
    this.onSelectAll,
    this.onDeselectAll,
  });

  final int selectedCount;
  final int totalCount;
  final VoidCallback? onSelectAll;
  final VoidCallback? onDeselectAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Recortes Detectados',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: context.textPrimaryColor,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 14),
                  child: Text(
                    '$selectedCount de $totalCount seleccionados',
                    style: TextStyle(
                      fontSize: 14,
                      color: context.textSecondaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _SelectionButton(
            label: 'Todos',
            onPressed: onSelectAll,
            isActive: selectedCount == totalCount,
          ),
          const SizedBox(width: 8),
          _SelectionButton(
            label: 'Ninguno',
            onPressed: onDeselectAll,
            isActive: selectedCount == 0,
          ),
        ],
      ),
    );
  }
}

/// Small selection button
class _SelectionButton extends StatelessWidget {
  const _SelectionButton({
    required this.label,
    required this.onPressed,
    required this.isActive,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    return Material(
      color: isActive
          ? AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.1)
          : context.backgroundColor,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isActive ? AppColors.primary : context.textSecondaryColor,
            ),
          ),
        ),
      ),
    );
  }
}

/// Grid of crop items
class _CropGrid extends StatelessWidget {
  const _CropGrid({
    required this.crops,
    required this.onToggleSelection,
  });

  final List<CropItem> crops;
  final void Function(String cropId) onToggleSelection;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: crops.length,
      itemBuilder: (context, index) {
        return _CropItemCard(
          crop: crops[index],
          onTap: () => onToggleSelection(crops[index].id),
        );
      },
    );
  }
}

/// Individual crop item card
class _CropItemCard extends StatelessWidget {
  const _CropItemCard({
    required this.crop,
    required this.onTap,
  });

  final CropItem crop;
  final VoidCallback onTap;

  void _showPreview(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _CropPreviewDialog(crop: crop),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: crop.isSelected ? AppColors.primary : context.borderColor,
            width: crop.isSelected ? 2.5 : 1,
          ),
          boxShadow: crop.isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Crop image
              ColorFiltered(
                colorFilter: crop.isSelected
                    ? const ColorFilter.mode(
                        Colors.transparent,
                        BlendMode.multiply,
                      )
                    : const ColorFilter.mode(
                        Colors.grey,
                        BlendMode.saturation,
                      ),
                child: Image.memory(
                  crop.imageBytes,
                  fit: BoxFit.cover,
                ),
              ),
              // Selection indicator
              Positioned(
                top: 6,
                right: 6,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: crop.isSelected ? AppColors.primary : Colors.white,
                    border: Border.all(
                      color: crop.isSelected
                          ? AppColors.primary
                          : AppColors.border,
                      width: 2,
                    ),
                  ),
                  child: crop.isSelected
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 14,
                        )
                      : null,
                ),
              ),
              // Preview button
              Positioned(
                top: 6,
                left: 6,
                child: GestureDetector(
                  onTap: () => _showPreview(context),
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Icon(
                      Icons.zoom_in_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
              // Confidence badge
              Positioned(
                bottom: 6,
                left: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${(crop.confidence * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              // Classification result badge
              if (crop.classificationResult != null)
                Positioned(
                  bottom: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      crop.classificationResult!.className,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Multi-image navigation bar — compact design that scales to 50+ images
class _ImageNavBar extends StatelessWidget {
  const _ImageNavBar({
    required this.imageCount,
    required this.currentIndex,
    this.onGoToImage,
  });

  final int imageCount;
  final int currentIndex;
  final void Function(int)? onGoToImage;

  @override
  Widget build(BuildContext context) {
    final hasPrev = currentIndex > 0;
    final hasNext = currentIndex < imageCount - 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: context.cardColor,
        border: Border(
          bottom: BorderSide(color: context.borderSubtleColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Previous button
          _NavArrow(
            icon: Icons.chevron_left_rounded,
            enabled: hasPrev,
            onTap: hasPrev ? () => onGoToImage?.call(currentIndex - 1) : null,
          ),
          const SizedBox(width: 4),
          // Central indicator — tappable to open picker
          Expanded(
            child: GestureDetector(
              onTap: () => _showImagePicker(context),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.photo_library_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Foto ${currentIndex + 1} de $imageCount',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.unfold_more_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Next button
          _NavArrow(
            icon: Icons.chevron_right_rounded,
            enabled: hasNext,
            onTap: hasNext ? () => onGoToImage?.call(currentIndex + 1) : null,
          ),
        ],
      ),
    );
  }

  void _showImagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return _ImagePickerSheet(
          imageCount: imageCount,
          currentIndex: currentIndex,
          onSelect: (i) {
            Navigator.pop(ctx);
            onGoToImage?.call(i);
          },
        );
      },
    );
  }
}

/// Small arrow button for prev/next navigation
class _NavArrow extends StatelessWidget {
  const _NavArrow({
    required this.icon,
    required this.enabled,
    this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled
          ? AppColors.primary.withValues(alpha: 0.1)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            size: 22,
            color: enabled
                ? AppColors.primary
                : context.textSecondaryColor.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet grid for jumping to any image by number
class _ImagePickerSheet extends StatelessWidget {
  const _ImagePickerSheet({
    required this.imageCount,
    required this.currentIndex,
    required this.onSelect,
  });

  final int imageCount;
  final int currentIndex;
  final void Function(int) onSelect;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: context.borderSubtleColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.photo_library_rounded,
                    size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Ir a foto ($imageCount fotos)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimaryColor,
                  ),
                ),
              ],
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            child: GridView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.6,
              ),
              itemCount: imageCount,
              itemBuilder: (context, i) {
                final isActive = i == currentIndex;
                return Material(
                  color: isActive
                      ? AppColors.primary
                      : AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: () => onSelect(i),
                    borderRadius: BorderRadius.circular(10),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color:
                              isActive ? Colors.white : AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Action bar at the bottom with Add Photo + Finalize buttons
class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.onClassify,
    required this.totalSelected,
    required this.imageCount,
    this.onAddFromCamera,
    this.onAddFromGallery,
  });

  final VoidCallback? onClassify;
  final int totalSelected;
  final int imageCount;
  final VoidCallback? onAddFromCamera;
  final VoidCallback? onAddFromGallery;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Add photo buttons row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onAddFromCamera,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.4),
                      ),
                    ),
                    icon: const Icon(Icons.camera_alt_rounded, size: 18),
                    label: const Text(
                      'Tomar otra foto',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onAddFromGallery,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(
                        color: AppColors.accent.withValues(alpha: 0.4),
                      ),
                    ),
                    icon: const Icon(Icons.photo_library_rounded, size: 18),
                    label: const Text(
                      'Agregar galería',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Finalize button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onClassify,
                style: ElevatedButton.styleFrom(
                  backgroundColor: onClassify != null
                      ? AppColors.primary
                      : AppColors.disabled,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.auto_awesome),
                label: Text(
                  totalSelected > 0
                      ? 'Finalizar y Clasificar ($totalSelected recortes · $imageCount fotos)'
                      : 'Selecciona recortes para clasificar',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
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

/// Preview dialog showing crop enlarged
class _CropPreviewDialog extends StatelessWidget {
  const _CropPreviewDialog({required this.crop});

  final CropItem crop;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Image container
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.85,
              maxHeight: MediaQuery.of(context).size.height * 0.55,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Image
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          crop.imageBytes,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  // Info bar
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color:
                          isDark ? AppColors.cardDark : AppColors.background,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Confidence
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color:
                                AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Conf: ${(crop.confidence * 100).toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        if (crop.classificationResult != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.accent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              crop.classificationResult!.className,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.accentLight
                                    : AppColors.accent,
                              ),
                            ),
                          ),
                        ],
                        const Spacer(),
                        Text(
                          crop.id.replaceAll('crop_', '#'),
                          style: TextStyle(
                            fontSize: 12,
                            color: context.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Close button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}