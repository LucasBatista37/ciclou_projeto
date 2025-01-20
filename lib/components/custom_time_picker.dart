import 'package:flutter/material.dart';

class TimeRangePicker extends StatefulWidget {
  final Function(String) onTimeRangeSelected;

  const TimeRangePicker({super.key, required this.onTimeRangeSelected});

  @override
  State<TimeRangePicker> createState() => _TimeRangePickerState();
}

class _TimeRangePickerState extends State<TimeRangePicker> {
  TimeOfDay? _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay? _endTime = const TimeOfDay(hour: 18, minute: 0);

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final initialTime = isStartTime
        ? _startTime ?? const TimeOfDay(hour: 8, minute: 0)
        : _endTime ?? const TimeOfDay(hour: 18, minute: 0);

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (selectedTime != null) {
      setState(() {
        if (isStartTime) {
          _startTime = selectedTime;
        } else {
          _endTime = selectedTime;
        }
      });

      if (_startTime != null && _endTime != null) {
        final formattedRange =
            // ignore: use_build_context_synchronously
            '${_startTime!.format(context)} - ${_endTime!.format(context)}';
        widget.onTimeRangeSelected(formattedRange);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _selectTime(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  textStyle: const TextStyle(color: Colors.white),
                ),
                child: Text(_startTime == null
                    ? 'Hora Inicial'
                    : _startTime!.format(context)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _selectTime(context, false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  textStyle: const TextStyle(color: Colors.white),
                ),
                child: Text(_endTime == null
                    ? 'Hora Final'
                    : _endTime!.format(context)),
              ),
            ),
          ],
        ),
        if (_startTime != null && _endTime != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Horário Selecionado: ${_startTime!.format(context)} - ${_endTime!.format(context)}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),
      ],
    );
  }
}