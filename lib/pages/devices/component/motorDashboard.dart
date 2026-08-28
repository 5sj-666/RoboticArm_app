import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:robotic_arm_app/cubit/motor_state_cubit.dart';

/// A right-side drawer dashboard that displays the state of six motors.
///
/// When collapsed it shows a small handle on the right edge; tapping the
/// handle expands the drawer. When expanded the full dashboard is shown.
class MotorDashboard extends StatefulWidget {
  final double width;
  final double topOffset;
  final Duration animationDuration;

  const MotorDashboard({
    Key? key,
    this.width = 380.0,
    this.topOffset = 80.0,
    this.animationDuration = const Duration(milliseconds: 240),
  }) : super(key: key);

  @override
  State<MotorDashboard> createState() => _MotorDashboardState();
}

class _MotorDashboardState extends State<MotorDashboard>
    with SingleTickerProviderStateMixin {
  bool _open = false;
  static const double _closedWidth = 36.0;

  void _toggle() => setState(() => _open = !_open);

  @override
  Widget build(BuildContext context) {
    final targetWidth = _open ? widget.width : _closedWidth;
    final media = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    // leave a small bottom margin to avoid exact-fit overflows
    final available =
        media.height -
        widget.topOffset -
        24 -
        padding.top -
        padding.bottom -
        12 -
        200;

    // Estimate the target height based on number of motor tiles and the
    // targetWidth so the AnimatedContainer can animate to a safe fixed
    // height during the open/close transition. This prevents transient
    // layout overflows while animating.
    final motorState = context.read<MotorStateCubit>().state;
    final int itemCount = motorState.ids.length;

    // Layout parameters copied from the GridView and container padding.
    const crossAxisCount = 2;
    const mainAxisSpacing = 6.0;
    const crossAxisSpacing = 6.0;
    const childAspectRatio = 1.6;
    final horizontalPadding = _open ? 8.0 * 2 : 4.0 * 2; // left+right
    final containerVerticalPadding = 8.0 * 2; // top+bottom

    double estimateHeightForWidth(double w) {
      final contentWidth = math.max(0.0, w - horizontalPadding);
      final tileWidth = (contentWidth - crossAxisSpacing) / crossAxisCount;
      final tileHeight = tileWidth / childAspectRatio;
      final rows = (itemCount / crossAxisCount).ceil();
      final gridVerticalPadding = 2.0 + 6.0; // GridView padding top + bottom
      final gridHeight = rows * tileHeight + (rows - 1) * mainAxisSpacing + gridVerticalPadding;
      final headerHeight = 36.0; // title row + small spacing
      final total = containerVerticalPadding + headerHeight + 6.0 /*SizedBox*/ + gridHeight;
      return total;
    }

    final estimatedOpenHeight = estimateHeightForWidth(targetWidth);
    final targetHeight = _open ? math.min(estimatedOpenHeight, available) : 64.0;

    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: EdgeInsets.only(top: widget.topOffset - 20, right: 12),
        child: Material(
          color: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: AnimatedContainer(
              duration: widget.animationDuration,
              curve: Curves.easeInOut,
              width: targetWidth,
              height: targetHeight,
              // Animate to a computed numeric height to avoid transient overflow
              // during the width/height animation.
              decoration: BoxDecoration(
               color: Colors.black.withValues(alpha: 0.65),
               // borderRadius moved to ClipRRect
               boxShadow: [
                 BoxShadow(
                   color: Colors.black26,
                   blurRadius: 8,
                   offset: Offset(-2, 4),
                 ),
               ],
             ),
             padding: EdgeInsets.symmetric(
               vertical: 8,
               horizontal: _open ? 8 : 4,
             ),
             child: AnimatedSize(
               duration: widget.animationDuration,
               curve: Curves.easeInOut,
               // vsync provided by SingleTickerProviderStateMixin
               child: ConstrainedBox(
                 constraints: BoxConstraints(
                   // available computed earlier limits the maximum height the
                   // open drawer can occupy to avoid overflowing the screen.
                   maxHeight: available,
                 ),
                 child: LayoutBuilder(
                   builder: (context, constraints) {
                     final currentWidth = constraints.maxWidth;
                     final currentHeight = constraints.maxHeight;
                     // When animating, the width or height can be very small; render a
                     // simplified handle view until there's enough width *and* height
                     // to safely show full content. This avoids RenderFlex overflow
                     // when one dimension is still animating.
                     if (currentWidth < 100 || currentHeight < 120) {
                       return _buildClosedHandle();
                     }
                     return _buildOpenContent();
                   },
                 ),
               ),
             ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClosedHandle() {
    return GestureDetector(
      onTap: _toggle,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 64,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RotatedBox(
              quarterTurns: 2,
              child: Icon(Icons.chevron_left, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOpenContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRect(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Motor State',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SizedBox(width: 8),
              SizedBox(
                width: 36,
                height: 36,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: _toggle,
                    child: Center(
                      child: Icon(Icons.close, color: Colors.white70, size: 18),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 6),
        Flexible(
          fit: FlexFit.loose,
          child: SafeArea(
            top: false,
            bottom: true,
            // remove extra minimum bottom padding so drawer can match content height
            minimum: EdgeInsets.zero,
            child: BlocBuilder<MotorStateCubit, MotorState>(
              builder: (context, state) {
                return GridView.builder(
                  padding: EdgeInsets.only(top: 2, bottom: 6),
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                    childAspectRatio: 1.6,
                  ),
                  itemCount: state.ids.length,
                  itemBuilder: (context, index) {
                    return _MotorTile(
                      id: state.ids[index],
                      isOnline: state.isOnline[index],
                      torque: state.T[index],
                      angle: state.q[index],
                      angularVelocity: state.dq[index],
                      acceleration: state.ddq[index],
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _MotorTile extends StatelessWidget {
  final int id;
  final bool isOnline;
  final double torque;
  final double angle;
  final double angularVelocity;
  final double acceleration;

  const _MotorTile({
    Key? key,
    required this.id,
    required this.isOnline,
    required this.torque,
    required this.angle,
    required this.angularVelocity,
    required this.acceleration,
  }) : super(key: key);

  String _fmt(double v) => v.isNaN ? '-' : v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(color: Colors.white70, fontSize: 11);
    final valueStyle = TextStyle(
      color: Colors.white,
      fontSize: 11,
      fontWeight: FontWeight.w600,
    );

    return Container(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    _OnlineIndicator(isOnline: isOnline),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Motor $id',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 6),
              Flexible(
                fit: FlexFit.loose,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      isOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                        color: isOnline
                            ? Colors.lightGreenAccent
                            : Colors.redAccent,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2),
          // Put metric rows into an Expanded + SingleChildScrollView so that when
          // the tile becomes very short during animation it won't cause a
          // RenderFlex overflow — the metrics will scroll if they don't fit.
          Expanded(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _MetricRow(
                    label: 'Torque (T)',
                    value: _fmt(torque),
                    labelStyle: textStyle,
                    valueStyle: valueStyle,
                  ),
                  _MetricRow(
                    label: 'Angle (q)',
                    value: _fmt(angle),
                    labelStyle: textStyle,
                    valueStyle: valueStyle,
                  ),
                  _MetricRow(
                    label: 'Ang. Vel. (dq)',
                    value: _fmt(angularVelocity),
                    labelStyle: textStyle,
                    valueStyle: valueStyle,
                  ),
                  _MetricRow(
                    label: 'Accel. (ddq)',
                    value: _fmt(acceleration),
                    labelStyle: textStyle,
                    valueStyle: valueStyle,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnlineIndicator extends StatelessWidget {
  final bool isOnline;
  const _OnlineIndicator({Key? key, required this.isOnline}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: isOnline ? Colors.lightGreenAccent : Colors.redAccent,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: isOnline
                ? Colors.lightGreenAccent.withValues(alpha: 0.5)
                : Colors.redAccent.withValues(alpha: 0.5),
            blurRadius: 4,
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle labelStyle;
  final TextStyle valueStyle;

  const _MetricRow({
    Key? key,
    required this.label,
    required this.value,
    required this.labelStyle,
    required this.valueStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.0),
      child: ClipRect(
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: labelStyle,
              ),
            ),
            SizedBox(width: 6),
            Flexible(
              fit: FlexFit.loose,
              child: Align(
                alignment: Alignment.centerRight,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(value, style: valueStyle),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
