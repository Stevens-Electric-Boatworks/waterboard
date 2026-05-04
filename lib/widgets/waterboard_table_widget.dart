// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:collection/collection.dart';

class WaterboardTableWidget extends StatelessWidget {
  final String title;
  final List<String> labels;
  final List<(String, Color)> values;
  const WaterboardTableWidget({
    super.key,
    required this.title,
    required this.labels,
    required this.values,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: AlignmentGeometry.topCenter,
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                child: DataTable(
                  border: TableBorder(
                    horizontalInside: BorderSide(color: Colors.black),
                  ),
                  columns: [
                    DataColumn(label: Container()),
                    DataColumn(label: Container()),
                  ],
                  dataRowMaxHeight:
                      (Theme.of(context).textTheme.bodyLarge!.fontSize)! + 2,
                  dataRowMinHeight: 8,
                  horizontalMargin: 4,
                  rows: labels.mapIndexed((index, e) {
                    WidgetStateProperty<Color> getColor() {
                      if (index % 2 == 0) {
                        return WidgetStateProperty.all(Colors.grey.shade300);
                      }
                      return WidgetStateProperty.all(Colors.grey.shade100);
                    }

                    final rowStyle = Theme.of(
                      context,
                    ).textTheme.bodySmall!.copyWith(color: values[index].$2);
                    return DataRow(
                      color: getColor(),
                      cells: [
                        DataCell(
                          Text(
                            e,
                            style: rowStyle.merge(
                              TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Row(
                            children: [
                              Spacer(),
                              Text(
                                values[index].$1,
                                style: rowStyle,
                                textAlign: TextAlign.right,
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium!.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
