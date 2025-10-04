import 'package:flutter/material.dart';
import 'add.dart'; //引入新增弹框
import 'edit.dart'; //引入编辑弹框

class MotionDetailsPage extends StatefulWidget {
  @override
  State<MotionDetailsPage> createState() => _MotionDetailsPageState();
}

class _MotionDetailsPageState extends State<MotionDetailsPage> {
  List<Map<String, dynamic>> motionBlocks = List.generate(6, (index) {
    return {
      'title': '关节 ${index + 1}',
      'details': List.generate(3, (i) {
        return {
          'time': '1000ms',
          'angle': '${30 + i * 10}°',
          'timingFunction': '0.25, 0.1, 0.25, 1.0',
        };
      }),
    };
  });

  void _editDetail(int blockIndex, int detailIndex) async {
    var detail = motionBlocks[blockIndex]['details'][detailIndex];
    await showDialog(
      context: context,
      builder: (context) {
        return EditMotionDetailDialog(
          detail: detail,
          onSave: (newDetail) {
            setState(() {
              motionBlocks[blockIndex]['details'][detailIndex] = newDetail;
            });
          },
        );
      },
    );
  }

  void _addDetail(int blockIndex) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AddMotionDetailDialog(
          onAdd: (newDetail) {
            setState(() {
              motionBlocks[blockIndex]['details'].add(newDetail);
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('动作详情'),
      ),
      body: ListView.builder(
        itemCount: motionBlocks.length,
        itemBuilder: (context, blockIndex) {
          final block = motionBlocks[blockIndex];
          return ExpansionTile(
            title: Text(block['title']),
            children: [
              ...block['details'].asMap().entries.map((entry) {
                int detailIndex = entry.key;
                var detail = entry.value;
                return ListTile(
                  leading: Icon(Icons.access_time),
                  title: Text('时间：${detail['time']}'),
                  subtitle: Text(
                      '角度：${detail['angle']} 贝塞尔曲线: ${detail['timingFunction']}'),
                  trailing: IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () => _editDetail(blockIndex, detailIndex),
                  ),
                );
              }).toList(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    icon: Icon(Icons.add),
                    label: Text('新增动作'),
                    onPressed: () => _addDetail(blockIndex),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
