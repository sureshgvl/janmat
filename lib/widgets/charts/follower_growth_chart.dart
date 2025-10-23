import 'package:flutter/material.dart';
import 'dart:math' as math;

class FollowerGrowthChart extends StatefulWidget {
  final List<Map<String, dynamic>> growthData;
  final bool isLoading;

  const FollowerGrowthChart({
    super.key,
    required this.growthData,
    this.isLoading = false,
  });

  @override
  State<FollowerGrowthChart> createState() => _FollowerGrowthChartState();
}

class _FollowerGrowthChartState extends State<FollowerGrowthChart> {
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.growthData.isEmpty) {
      return _buildEmptyState();
    }

    // Sort data by date
    final sortedData = List<Map<String, dynamic>>.from(widget.growthData)
      ..sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));

    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Follower Growth Trend',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onTapDown: (details) {
                    final index = _getIndexFromPosition(details.localPosition, constraints, sortedData.length);
                    setState(() => _hoveredIndex = index);
                  },
                  onTapUp: (_) => setState(() => _hoveredIndex = null),
                  child: CustomPaint(
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                    painter: _GrowthChartPainter(
                      data: sortedData,
                      hoveredIndex: _hoveredIndex,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          if (_hoveredIndex != null && _hoveredIndex! < sortedData.length)
            _buildTooltip(sortedData[_hoveredIndex!]),
        ],
      ),
    );
  }

  int _getIndexFromPosition(Offset position, BoxConstraints constraints, int dataLength) {
    final chartWidth = constraints.maxWidth - 60; // Account for margins
    final x = position.dx - 30; // Account for left margin
    if (x < 0 || x > chartWidth) return -1;

    final index = ((x / chartWidth) * (dataLength - 1)).round();
    return math.min(math.max(index, 0), dataLength - 1);
  }

  Widget _buildTooltip(Map<String, dynamic> data) {
    final followers = data['followers'] as int;
    final growth = data['growth'] as int;
    final date = _formatDate(data['date'] as DateTime);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.shade600,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$date: $followers followers (${growth >= 0 ? '+' : ''}$growth)',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart,
              size: 48,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No growth data available yet',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Data will appear as followers grow',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '${difference}d ago';
    } else {
      return '${date.month}/${date.day}';
    }
  }
}

class _GrowthChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final int? hoveredIndex;

  _GrowthChartPainter({required this.data, this.hoveredIndex});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    final gridPaint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 1;

    final dotPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    final hoverPaint = Paint()
      ..color = Colors.blue.shade600
      ..style = PaintingStyle.fill;

    // Draw grid lines
    final gridSpacing = size.height / 5;
    for (int i = 0; i <= 5; i++) {
      final y = i * gridSpacing;
      canvas.drawLine(Offset(30, y), Offset(size.width - 10, y), gridPaint);
    }

    // Calculate max followers for scaling
    final maxFollowers = data.map((d) => d['followers'] as int).reduce(math.max);
    final scaleY = maxFollowers > 0 ? (size.height - 40) / maxFollowers : 1.0;

    // Draw area fill
    final path = Path();
    final points = <Offset>[];

    for (int i = 0; i < data.length; i++) {
      final followers = data[i]['followers'] as int;
      final x = 30 + (i * (size.width - 40) / math.max(data.length - 1, 1));
      final y = size.height - 20 - (followers * scaleY);
      points.add(Offset(x, y));

      if (i == 0) {
        path.moveTo(x, size.height - 20);
        path.lineTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    if (points.isNotEmpty) {
      path.lineTo(points.last.dx, size.height - 20);
      path.close();
      canvas.drawPath(path, fillPaint);
    }

    // Draw line
    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], paint);
    }

    // Draw dots
    for (int i = 0; i < points.length; i++) {
      final isHovered = hoveredIndex == i;
      canvas.drawCircle(
        points[i],
        isHovered ? 6 : 4,
        isHovered ? hoverPaint : dotPaint,
      );
    }

    // Draw axes
    final axisPaint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1;

    canvas.drawLine(Offset(30, 20), Offset(30, size.height - 20), axisPaint);
    canvas.drawLine(Offset(30, size.height - 20), Offset(size.width - 10, size.height - 20), axisPaint);

    // Draw Y-axis labels
    final labelStyle = TextStyle(color: Colors.grey.shade600, fontSize: 10);
    for (int i = 0; i <= 5; i++) {
      final value = ((5 - i) * maxFollowers / 5).round();
      final textPainter = TextPainter(
        text: TextSpan(text: value.toString(), style: labelStyle),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(5, i * gridSpacing - textPainter.height / 2));
    }

    // Draw X-axis labels (dates)
    if (data.length <= 7) { // Only show labels if not too crowded
      for (int i = 0; i < data.length; i++) {
        if (i % math.max(1, data.length ~/ 7) == 0) {
          final date = data[i]['date'] as DateTime;
          final dateStr = _formatDateForAxis(date);
          final textPainter = TextPainter(
            text: TextSpan(text: dateStr, style: labelStyle),
            textDirection: TextDirection.ltr,
          );
          textPainter.layout();

          final x = 30 + (i * (size.width - 40) / math.max(data.length - 1, 1));
          textPainter.paint(canvas, Offset(x - textPainter.width / 2, size.height - 15));
        }
      }
    }
  }

  @override
  bool shouldRepaint(_GrowthChartPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.hoveredIndex != hoveredIndex;
  }

  String _formatDateForAxis(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return '1d';
    if (difference < 7) return '${difference}d';
    return '${date.month}/${date.day}';
  }
}
