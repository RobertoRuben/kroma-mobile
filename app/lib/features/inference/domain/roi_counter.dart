// Ultralytics 🚀 AGPL-3.0 License - https://ultralytics.com/license

/// Line-crossing counter for counting objects passing a horizontal line
/// 
/// Detects when an object's center crosses the counting line.
/// Uses grid cells along the line to track crossings and prevent duplicates.
/// 
/// Works by tracking previous Y positions and detecting when they cross
/// from above to below (or vice versa) the counting line.
class ROICounter {
  /// Position of counting line as percentage of screen height (0.0 - 1.0)
  final double linePosition;
  
  /// Number of horizontal cells for tracking
  final int gridCols;
  
  /// Cooldown frames per cell after counting
  final int cooldownFrames;
  
  /// Tolerance zone around line (objects within this are "on the line")
  final double lineTolerance;

  /// Total count
  int _totalCount = 0;
  
  /// Cooldown per cell
  late List<int> _cellCooldown;
  
  /// Previous Y position per cell (to detect crossing)
  late List<double?> _prevY;

  ROICounter({
    this.linePosition = 0.45,      // Line at 45% from top (middle-upper)
    this.gridCols = 12,            // 12 horizontal tracking cells
    this.cooldownFrames = 10,      // ~330ms at 30fps
    this.lineTolerance = 0.08,     // 8% tolerance zone
  }) {
    _cellCooldown = List.filled(gridCols, 0);
    _prevY = List.filled(gridCols, null);
  }

  /// For overlay compatibility
  double get roiTopPercent => linePosition - lineTolerance;
  double get roiBottomPercent => linePosition + lineTolerance;

  /// Get current total count
  int get totalCount => _totalCount;

  /// Reset the counter
  void reset() {
    _totalCount = 0;
    _cellCooldown = List.filled(gridCols, 0);
    _prevY = List.filled(gridCols, null);
  }

  /// Process detections from a frame
  int processDetections(List<Map<String, dynamic>> boxes) {
    int newCounts = 0;
    
    // Track which cells have detections this frame
    final Map<int, double> cellDetections = {};
    
    for (final box in boxes) {
      final double x = (box['x'] as num?)?.toDouble() ?? 0;
      final double y = (box['y'] as num?)?.toDouble() ?? 0;
      final double w = (box['w'] as num?)?.toDouble() ?? 0;
      final double h = (box['h'] as num?)?.toDouble() ?? 0;
      
      // Center of bbox
      final centerX = x + w / 2;
      final centerY = y + h / 2;
      
      // Map to cell
      final cellIndex = (centerX * gridCols).floor().clamp(0, gridCols - 1);
      
      // Store the Y position for this cell (take lowest Y if multiple objects)
      if (!cellDetections.containsKey(cellIndex) || centerY > cellDetections[cellIndex]!) {
        cellDetections[cellIndex] = centerY;
      }
    }
    
    // Check for line crossings
    for (int i = 0; i < gridCols; i++) {
      // Decrease cooldown
      if (_cellCooldown[i] > 0) {
        _cellCooldown[i]--;
      }
      
      if (cellDetections.containsKey(i)) {
        final currentY = cellDetections[i]!;
        final prevY = _prevY[i];
        
        // Check for crossing (only if not in cooldown)
        if (prevY != null && _cellCooldown[i] == 0) {
          // Crossed from above to below the line
          final crossedDown = prevY < linePosition && currentY >= linePosition;
          // Crossed from below to above the line  
          final crossedUp = prevY > linePosition && currentY <= linePosition;
          
          if (crossedDown || crossedUp) {
            // COUNT IT!
            _totalCount++;
            newCounts++;
            _cellCooldown[i] = cooldownFrames;
          }
        }
        
        // Update previous position
        _prevY[i] = currentY;
      } else {
        // No detection in this cell - clear previous Y after some frames
        // to avoid false crossings when object reappears
        if (_cellCooldown[i] == 0) {
          _prevY[i] = null;
        }
      }
    }
    
    return newCounts;
  }
  
  void incrementCount([int amount = 1]) {
    _totalCount += amount;
  }
  
  void decrementCount([int amount = 1]) {
    _totalCount = (_totalCount - amount).clamp(0, _totalCount);
  }
}
