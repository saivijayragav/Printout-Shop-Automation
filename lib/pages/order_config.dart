import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:RITArcade/components/new_types.dart';

class PrintConfigDialog extends StatefulWidget {
  final int pages;
  final Function add;
  final List<FileData> files;
  const PrintConfigDialog({super.key, required this.pages, required this.add, required this.files});

  @override
  State<PrintConfigDialog> createState() => _PrintConfigDialogState();
}

class _PrintConfigDialogState extends State<PrintConfigDialog> {
  PrintColor _color = PrintColor.bw;
  BindingType _binding = BindingType.nobinding;
  Sides _side = Sides.both;

  @override
  Widget build(BuildContext context) {
    final bool showBindingOptions = widget.pages > 5 && widget.files.length == 1;
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView( // in case of overflow on small screens
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Printing Details",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                const SizedBox(height: 20),
                if (showBindingOptions) ...[
                  const Text("Select Binding:",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  RadioListTile<BindingType>(
                    value: BindingType.spiral,
                    groupValue: _binding,
                    onChanged: (value) => setState(() => _binding = value!),
                    title: const Text("Spiral (+₹35)"),
                    dense: true,
                  ),
                  RadioListTile<BindingType>(
                    value: BindingType.soft,
                    groupValue: _binding,
                    onChanged: (value) => setState(() => _binding = value!),
                    title: const Text("Soft Binding (+₹30)"),
                    dense: true,
                  ),
                  RadioListTile<BindingType>(
                    value: BindingType.nobinding,
                    groupValue: _binding,
                    onChanged: (value) => setState(() => _binding = value!),
                    title: const Text("No Binding"),
                    dense: true,
                  ),
                ],
                const SizedBox(height: 20),
                const Text("Select Print Color:",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                RadioListTile<PrintColor>(
                  value: PrintColor.color,
                  groupValue: _color,
                  onChanged: (value) => setState(() => _color = value!),
                  title: const Text("Color (+₹5)"),
                  dense: true,
                ),
                RadioListTile<PrintColor>(
                  value: PrintColor.bw,
                  groupValue: _color,
                  onChanged: (value) => setState(() => _color = value!),
                  title: const Text("Black & White"),
                  dense: true,
                ),
                const SizedBox(height: 20),
                const Text("Select Sides:",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                RadioListTile<Sides>(
                  value: Sides.both,
                  groupValue: _side,
                  onChanged: (value) => setState(() => _side = value!),
                  title: const Text("Double-Side"),
                  dense: true,
                ),
                RadioListTile<Sides>(
                  value: Sides.single,
                  groupValue: _side,
                  onChanged: (value) => setState(() => _side = value!),
                  title: const Text("Single Side"),
                  dense: true,
                ),
                RadioListTile<Sides>(
                  value: Sides.four,
                  groupValue: _side,
                  onChanged: (value) => setState(() => _side = value!),
                  title: const Text("Four Side"),
                  dense: true,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel')
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.add( widget.files, _side, _color, _binding);// dismiss dialog
                      },
                      child: const Text('Done', style: TextStyle(color: Colors.black),),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
