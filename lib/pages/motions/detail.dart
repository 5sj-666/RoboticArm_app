import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:carousel_slider/carousel_slider.dart';

@RoutePage()
class DetailPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // final screenHeight = MediaQuery.of(context).size.height;

    // Future.delayed({duration: Duration(seconds: 3)});

    // DialogSetBezier(context: context);
    return Scaffold(
      // backgroundColor: Colors.white,
      appBar: AppBar(title: Text('详情')),
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          // decoration: BoxDecoration(color: Colors.yellow),
          child: Stack(
            children: [
              Column(
                children: [
                  SizedBox(
                    width: screenWidth,
                    height: 300,
                    // decoration: BoxDecoration(color: Colors.green.shade300),
                    // child: Image(image: image)
                    child: CarouselSlider(
                      options: CarouselOptions(height: 400.0),
                      items: [1, 2, 3, 4, 5].map((i) {
                        return Builder(
                          builder: (BuildContext context) {
                            return Image(
                              width: screenWidth,
                              // height: screenWidth / 2 + 10,
                              fit: BoxFit.cover,
                              image: AssetImage('assets/wallfall1.jpg'),
                            );
                            // return Container(
                            //   width: MediaQuery.of(context).size.width,
                            //   margin: EdgeInsets.symmetric(horizontal: 5.0),
                            //   decoration: BoxDecoration(color: Colors.amber),
                            //   child: Text(
                            //     'text $i',
                            //     style: TextStyle(fontSize: 16.0),
                            //   ),
                            // );
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(top: 10),
                    width: screenWidth,
                    height: 120,
                    decoration: BoxDecoration(color: Colors.white),
                    child: Padding(
                      padding: EdgeInsetsGeometry.all(8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '动作1',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '描述文字',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '作者名字',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.fromLTRB(8, 2, 8, 2),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    width: 0.5,
                                    color: Colors.black54,
                                  ),
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  '关注',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  Container(
                    width: double.infinity,
                    height: 100,
                    margin: EdgeInsets.only(top: 10),
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white),
                    child: Text(
                      '评论',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              Positioned(
                left: 0,
                bottom: 0,
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: BoxBorder.fromLTRB(
                      top: BorderSide(color: Colors.grey.shade300, width: 0.5),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsetsGeometry.all(10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(Icons.favorite, color: Colors.grey.shade400),
                        SizedBox(
                          width: screenWidth / 2,
                          child: FilledButton(
                            onPressed: () {},
                            child: Text('应用'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
