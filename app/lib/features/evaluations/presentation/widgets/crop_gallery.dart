import 'package:flutter/material.dart';
import 'package:ultralytics_yolo_example/core/core.dart';
import 'package:ultralytics_yolo_example/features/evaluations/domain/models/models.dart';
import 'package:ultralytics_yolo_example/features/evaluations/presentation/widgets/crop_action_bar.dart';
import 'package:ultralytics_yolo_example/features/evaluations/presentation/widgets/crop_item_card.dart';
import 'package:ultralytics_yolo_example/features/evaluations/presentation/widgets/image_picker_sheet.dart';
import 'package:ultralytics_yolo_example/features/evaluations/presentation/widgets/pagination_bar.dart';
import 'package:ultralytics_yolo_example/shared/widgets/image_nav_arrow.dart';
import 'package:ultralytics_yolo_example/shared/widgets/section_header.dart' show ContentSectionHeader;

/// Gallery widget for displaying and managing crop items with pagination.
/// Supports multi-image workflow with navigation between images.
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

  int get _totalPages =>
      (widget.crops.length / widget.itemsPerPage).ceil().clamp(1, 999);
  int get _startIndex => _currentPage * widget.itemsPerPage;
  int get _endIndex =>
      (_startIndex + widget.itemsPerPage).clamp(0, widget.crops.length);
  List<CropItem> get _visibleCrops =>
      widget.crops.sublist(_startIndex, _endIndex);

  @override
  void didUpdateWidget(CropGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
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
          PaginationBar(
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
        CropActionBar(
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
                const ContentSectionHeader(title: 'Recortes Detectados'),
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
        return CropItemCard(
          crop: crops[index],
          onTap: () => onToggleSelection(crops[index].id),
        );
      },
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
          ImageNavArrow(
            icon: Icons.chevron_left_rounded,
            enabled: hasPrev,
            onTap: hasPrev ? () => onGoToImage?.call(currentIndex - 1) : null,
          ),
          const SizedBox(width: 4),
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
          ImageNavArrow(
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
        return ImagePickerSheet(
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
