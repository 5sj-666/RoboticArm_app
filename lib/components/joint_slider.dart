import "package:flutter/material.dart";

typedef ValueChangeWithKeyName = void Function(double newVal, int index);

class JointSlider extends StatelessWidget {
  final String title;
  final double value;
  final ValueChangeWithKeyName onValueChanged;
  final ValueChangeWithKeyName? onChangeEnd;
  final int index;
  final double min;
  final double max;
  final bool disable;

  const JointSlider({
    super.key,
    required this.value,
    required this.onValueChanged,
    required this.index,
    required this.title,
    this.min = -135.0,
    this.max = 135.0,
    this.onChangeEnd,
    this.disable = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Container(
          alignment: Alignment(-1.0, 0.0),
          width: 160,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(2),
            border: Border(
              bottom: BorderSide(
                color: Colors.blue.shade100,
                width: 0.8,
                style: BorderStyle.solid,
              ),
            ),
          ),
          child: Text(
            '$title: ${value.toStringAsFixed(2)}°',
            textAlign: TextAlign.left,
            style: TextStyle(
              fontSize: 12,
              color: Colors.black87,
              fontWeight: FontWeight.w200,
            ),
          ),
        ),
        SizedBox(
          width: 160,
          child: Slider(
            label: title,
            min: min,
            max: max,
            activeColor: Colors.blue,
            value: value,
            // padding: EdgeInsets.fromLTRB(15, 15, 15, 15),
            padding: EdgeInsets.fromLTRB(5, 15, 5, 15),
            onChanged: disable
                ? null
                : (double newVal) {
                    onValueChanged(newVal, index);
                  },
            onChangeEnd: disable
                ? null
                : (double newVal) {
                    if (onChangeEnd != null) {
                      onChangeEnd!(newVal, index);
                    }
                  },
          ),
        ),
      ],
    );
  }
}
