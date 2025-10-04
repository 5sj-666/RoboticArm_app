import 'package:flutter/material.dart';

// 新增动作弹窗组件
class AddMotionDetailDialog extends StatefulWidget {
  final void Function(Map<String, dynamic>) onAdd;

  const AddMotionDetailDialog({Key? key, required this.onAdd})
      : super(key: key);

  @override
  State<AddMotionDetailDialog> createState() => _AddMotionDetailDialogState();
}

class _AddMotionDetailDialogState extends State<AddMotionDetailDialog> {
  final TextEditingController timeController = TextEditingController();
  final TextEditingController angleController = TextEditingController();
  final TextEditingController timingController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('新增动作'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: timeController,
            decoration: InputDecoration(labelText: '时间'),
          ),
          TextField(
            controller: angleController,
            decoration: InputDecoration(labelText: '角度'),
          ),
          TextField(
            controller: timingController,
            decoration: InputDecoration(labelText: '贝塞尔曲线'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onAdd({
              'time': timeController.text,
              'angle': angleController.text,
              'timingFunction': timingController.text,
            });
            Navigator.pop(context);
          },
          child: Text('新增'),
        ),
      ],
    );
  }
}
