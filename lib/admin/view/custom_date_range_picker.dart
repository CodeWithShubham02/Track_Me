import 'package:flutter/material.dart';

class CustomDateRangePicker extends StatefulWidget {
  final DateTimeRange? initialRange;
  final DateTime firstDate;
  final DateTime lastDate;

  const CustomDateRangePicker({
    super.key,
    this.initialRange,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  State<CustomDateRangePicker> createState() =>
      _CustomDateRangePickerState();
}

class _CustomDateRangePickerState
    extends State<CustomDateRangePicker> {
  DateTime? startDate;
  DateTime? endDate;

  late DateTime currentMonth;

  @override
  void initState() {
    super.initState();

    startDate = widget.initialRange?.start;
    endDate = widget.initialRange?.end;

    currentMonth =
        widget.initialRange?.start ??
            DateTime.now();

    currentMonth = DateTime(
      currentMonth.year,
      currentMonth.month,
    );
  }

  // =========================================================
  // MONTH NAME
  // =========================================================

  String monthName(DateTime date) {
    const months = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ];

    return "${months[date.month - 1]} ${date.year}";
  }

  // =========================================================
  // DATE FORMAT
  // =========================================================

  String formatDate(DateTime? date) {
    if (date == null) {
      return "Select date";
    }

    return "${date.day.toString().padLeft(2, '0')} "
        "${monthName(date).split(' ')[0].substring(0, 3)} "
        "${date.year}";
  }

  // =========================================================
  // PREVIOUS MONTH
  // =========================================================

  void previousMonth() {
    final previous = DateTime(
      currentMonth.year,
      currentMonth.month - 1,
    );

    if (previous.year < widget.firstDate.year ||
        (previous.year == widget.firstDate.year &&
            previous.month < widget.firstDate.month)) {
      return;
    }

    setState(() {
      currentMonth = previous;
    });
  }

  // =========================================================
  // NEXT MONTH
  // =========================================================

  void nextMonth() {
    final next = DateTime(
      currentMonth.year,
      currentMonth.month + 1,
    );

    if (next.year > widget.lastDate.year ||
        (next.year == widget.lastDate.year &&
            next.month > widget.lastDate.month)) {
      return;
    }

    setState(() {
      currentMonth = next;
    });
  }

  // =========================================================
  // SELECT DATE
  // =========================================================

  void selectDate(DateTime date) {
    if (date.isBefore(widget.firstDate) ||
        date.isAfter(widget.lastDate)) {
      return;
    }

    setState(() {
      // First selection
      if (startDate == null ||
          (startDate != null && endDate != null)) {
        startDate = date;
        endDate = null;
        return;
      }

      // Second selection
      if (date.isBefore(startDate!)) {
        endDate = startDate;
        startDate = date;
      } else {
        endDate = date;
      }
    });
  }

  // =========================================================
  // SAME DAY
  // =========================================================

  bool isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) {
      return false;
    }

    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }

  // =========================================================
  // IS IN RANGE
  // =========================================================

  bool isInRange(DateTime date) {
    if (startDate == null || endDate == null) {
      return false;
    }

    final d = DateTime(
      date.year,
      date.month,
      date.day,
    );

    final start = DateTime(
      startDate!.year,
      startDate!.month,
      startDate!.day,
    );

    final end = DateTime(
      endDate!.year,
      endDate!.month,
      endDate!.day,
    );

    return !d.isBefore(start) && !d.isAfter(end);
  }

  // =========================================================
  // BUILD CALENDAR
  // =========================================================

  Widget buildCalendar() {
    final firstDay = DateTime(
      currentMonth.year,
      currentMonth.month,
      1,
    );

    final daysInMonth = DateTime(
      currentMonth.year,
      currentMonth.month + 1,
      0,
    ).day;

    // Sunday = 0
    final startingWeekday = firstDay.weekday % 7;

    final totalCells =
        ((startingWeekday + daysInMonth) / 7).ceil() * 7;

    const weekDays = [
      "S",
      "M",
      "T",
      "W",
      "T",
      "F",
      "S",
    ];

    return Column(
      children: [
        // ===================================================
        // WEEK DAYS
        // ===================================================

        Row(
          children: weekDays.map((day) {
            return Expanded(
              child: Center(
                child: Text(
                  day,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 10),

        // ===================================================
        // DATES
        // ===================================================

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: totalCells,
          gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 6,
            crossAxisSpacing: 4,
          ),
          itemBuilder: (context, index) {
            final dayNumber =
                index - startingWeekday + 1;

            if (dayNumber < 1 ||
                dayNumber > daysInMonth) {
              return const SizedBox();
            }

            final date = DateTime(
              currentMonth.year,
              currentMonth.month,
              dayNumber,
            );

            final disabled =
                date.isBefore(widget.firstDate) ||
                    date.isAfter(widget.lastDate);

            final selectedStart =
            isSameDay(date, startDate);

            final selectedEnd =
            isSameDay(date, endDate);

            final inRange = isInRange(date);

            return GestureDetector(
              onTap: disabled
                  ? null
                  : () => selectDate(date),
              child: Container(
                margin: const EdgeInsets.symmetric(
                  vertical: 2,
                  horizontal: 2,
                ),
                decoration: BoxDecoration(
                  color: selectedStart || selectedEnd
                      ? Colors.deepPurple
                      : inRange
                      ? Colors.deepPurple.withOpacity(0.12)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    "$dayNumber",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                      selectedStart || selectedEnd
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: disabled
                          ? Colors.grey.shade400
                          : selectedStart ||
                          selectedEnd
                          ? Colors.white
                          : Colors.black87,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 30,
        vertical: 30,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 500,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // =================================================
              // HEADER
              // =================================================

              Row(
                children: [
                  const Expanded(
                    child: Text(
                      "Select Date Range",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              // =================================================
              // SELECTED DATES
              // =================================================

              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: startDate != null
                              ? Colors.deepPurple
                              : Colors.grey.shade300,
                        ),
                        borderRadius:
                        BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Start Date",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formatDate(startDate),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: endDate != null
                              ? Colors.deepPurple
                              : Colors.grey.shade300,
                        ),
                        borderRadius:
                        BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "End Date",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formatDate(endDate),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // =================================================
              // MONTH HEADER
              // =================================================

              Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: previousMonth,
                    icon: const Icon(
                      Icons.chevron_left,
                    ),
                  ),

                  Text(
                    monthName(currentMonth),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  IconButton(
                    onPressed: nextMonth,
                    icon: const Icon(
                      Icons.chevron_right,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 5),

              // =================================================
              // CALENDAR
              // =================================================

              buildCalendar(),

              const SizedBox(height: 20),

              // =================================================
              // SUBMIT BUTTON CENTER
              // =================================================

              Center(
                child: SizedBox(
                  width: 180,
                  height: 45,
                  child: ElevatedButton(
                    onPressed:
                    startDate != null &&
                        endDate != null
                        ? () {
                      Navigator.pop(
                        context,
                        DateTimeRange(
                          start: startDate!,
                          end: endDate!,
                        ),
                      );
                    }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      Colors.deepPurple,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                      Colors.grey.shade300,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "Save",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 5),
            ],
          ),
        ),
      ),
    );
  }
}