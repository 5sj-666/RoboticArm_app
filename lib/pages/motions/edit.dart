import 'package:flutter/material.dart';

// 编辑动作弹窗组件
class EditMotionDetailDialog extends StatefulWidget {
  final Map<String, dynamic> detail;
  final void Function(Map<String, dynamic>) onSave;

  const EditMotionDetailDialog(
      {Key? key, required this.detail, required this.onSave})
      : super(key: key);

  @override
  State<EditMotionDetailDialog> createState() => _EditMotionDetailDialogState();
}

class _EditMotionDetailDialogState extends State<EditMotionDetailDialog> {
  late TextEditingController timeController;
  late TextEditingController angleController;
  late TextEditingController timingController;

  @override
  void initState() {
    super.initState();
    timeController = TextEditingController(text: widget.detail['time'] ?? '');
    angleController = TextEditingController(text: widget.detail['angle'] ?? '');
    timingController =
        TextEditingController(text: widget.detail['timingFunction'] ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('编辑动作'),
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
            widget.onSave({
              'time': timeController.text,
              'angle': angleController.text,
              'timingFunction': timingController.text,
            });
            Navigator.pop(context);
          },
          child: Text('保存'),
        ),
      ],
    );
  }
}
