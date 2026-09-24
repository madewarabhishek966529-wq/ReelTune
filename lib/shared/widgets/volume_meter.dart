import 'package:flutter/material.dart';

class VolumeMeterWidget extends StatelessWidget {
  final double leftDb; // e.g. -60 to 0 dB
  final double rightDb;
  final bool hasClipping;

  const VolumeMeterWidget({
    super.key,
    this.leftDb = -12.0,
    this.rightDb = -12.0,
    this.hasClipping = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF141721),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF2D3346)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('L', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(width: 6),
              _buildBar(leftDb),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('R', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(width: 6),
              _buildBar(rightDb),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBar(double db) {
    // Map -60..0 dB to 0..1 fraction
    final fraction = ((db + 60) / 60).clamp(0.0, 1.0);
    final color = fraction > 0.95
        ? Colors.redAccent
        : (fraction > 0.8 ? Colors.amberAccent : const Color(0xFF10B981));

    return SizedBox(
      width: 100,
      height: 6,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF25293A),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          FractionallySizedBox(
            widthFactor: fraction,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
