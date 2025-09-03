import 'package:flutter/material.dart';

class WaterfallPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text('模型'),
      // ),
      body: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // 每行两列
          crossAxisSpacing: 8.0, // 列间距
          mainAxisSpacing: 8.0, // 行间距
          childAspectRatio: 0.7, // 卡片宽高比
        ),
        padding: EdgeInsets.all(8.0),
        itemCount: 4, // 卡片数量
        itemBuilder: (context, index) {
          return Card(
            elevation: 4.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(12.0)),
                      image: DecorationImage(
                        image: AssetImage(
                          'assets/wallfall1.jpg',
                        ),
                        // image: NetworkImage(
                        //   'https://picsum.photos/200/300?random=$index',
                        // ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Card Title $index',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    'Description for card $index',
                    style: TextStyle(
                      fontSize: 12.0,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
