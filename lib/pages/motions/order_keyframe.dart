import 'package:flutter/material.dart';
// import 'package:auto_route/auto_route.dart';

// @RoutePage()
class OrderKeyframe extends StatefulWidget {
  const OrderKeyframe({super.key});

  @override
  State<OrderKeyframe> createState() => _orderKeyframe();
}

// ignore: camel_case_types
class _orderKeyframe extends State<OrderKeyframe> {
  Color _targetColor = Colors.grey;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Draggable<Color>(
            data: Colors.blue,
            feedback: Container(
              width: 100,
              height: 100,
              color: Colors.blue,
            ),
            child: Container(
              width: 100,
              height: 100,
              color: Colors.blue,
              child: const Center(child: Text('Drag Me')),
            ),
          ),
          const SizedBox(height: 50),
          DragTarget<Color>(
            onAcceptWithDetails: (DragTargetDetails<Color> details) {
              setState(() {
                _targetColor = details.data;
              });
            },
            builder: (context, candidateData, rejectedData) {
              return Container(
                width: 150,
                height: 150,
                color: _targetColor,
                child: const Center(child: Text('Drop Here')),
              );
            },
          ),
        ],
      ),
    );
  }
}
