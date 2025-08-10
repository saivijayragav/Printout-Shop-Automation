import 'package:flutter/material.dart';
import 'newtypes.dart';
class OptionBuilder<T> extends StatelessWidget {

  final T value;
  final T groupvalue;
  final String title;
  final Function(T?) change;
  OptionBuilder ({super.key, required this.value, required this.groupvalue, required this.title, required this.change});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      leading: Radio<T>
        (value: value,
          groupValue: groupvalue,
          onChanged: (T? value){
              change(value);}
          ),
    );
  }
}
