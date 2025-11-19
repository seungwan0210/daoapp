// lib/presentation/screens/arena/widgets/organizer_email_input_field.dart
import 'package:flutter/material.dart';

class OrganizerEmailInputField extends StatefulWidget {
  final List<String> emails;
  final Function(String) onAdd;
  final Function(String) onRemove;

  const OrganizerEmailInputField({
    Key? key,
    required this.emails,
    required this.onAdd,
    required this.onRemove,
  }) : super(key: key);

  @override
  State<OrganizerEmailInputField> createState() => _OrganizerEmailInputFieldState();
}

class _OrganizerEmailInputFieldState extends State<OrganizerEmailInputField> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: TextField(controller: _controller, decoration: const InputDecoration(hintText: '공동 주최자 이메일'))),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                if (_controller.text.isNotEmpty && _controller.text.contains('@')) {
                  widget.onAdd(_controller.text.trim());
                  _controller.clear();
                }
              },
            ),
          ],
        ),
        if (widget.emails.isNotEmpty)
          Wrap(
            spacing: 8,
            children: widget.emails
                .map((e) => Chip(label: Text(e), onDeleted: () => widget.onRemove(e)))
                .toList(),
          ),
      ],
    );
  }
}