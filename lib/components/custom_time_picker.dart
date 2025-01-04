import 'package:flutter/material.dart';

class TimeRangePicker extends StatefulWidget {
  final Function(String) onTimeRangeSelected;

  const TimeRangePicker({Key? key, required this.onTimeRangeSelected})
      : super(key: key);

  @override
  State<TimeRangePicker> createState() => _TimeRangePickerState();
}

class _TimeRangePickerState extends State<TimeRangePicker> {
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final initialTime = isStartTime
        ? _startTime ?? TimeOfDay.now()
        : _endTime ?? TimeOfDay.now();

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
                child: Text(_startTime == null
                    ? 'Hora Inicial'
                    : _startTime!.format(context)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  textStyle: const TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _selectTime(context, false),
                child: Text(_endTime == null
                    ? 'Hora Final'
                    : _endTime!.format(context)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  textStyle: const TextStyle(color: Colors.white),
                ),
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
