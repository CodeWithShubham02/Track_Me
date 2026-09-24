import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../api_urls.dart';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:universal_html/html.dart' as html;
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

class MtdStatusScreen extends StatefulWidget {
  final String cid;

  const MtdStatusScreen({
    super.key,
    required this.cid,
  });

  @override
  State<MtdStatusScreen> createState() => _MtdStatusScreenState();
}

class _MtdStatusScreenState extends State<MtdStatusScreen> {
  DateTime? selectedFromDate;
  DateTime? selectedToDate;

  bool isLoading = false;

  List<Map<String, dynamic>> reports = [];


  // =====================================================
  // STATUS LIST
  // =====================================================

  final List<String> statuses = [
    'CARDED',
    'PARTIAL',
    'PARTIAL/Refused',
    'REJECTED',
    'REVIEW',
    'TECH ISSUE',
  ];
  String getEffectiveStatus(Map<String, dynamic> report) {
    final rawStatus =
    (report['status'] ?? '').toString().trim();

    final remark =
    (report['remarks'] ?? '').toString().trim().toLowerCase();

    final status = normalizeStatus(rawStatus);

    // =====================================================
    // PARTIAL + TECHNICAL REMARK = TECH ISSUE
    // =====================================================

    if (status == 'PARTIAL') {
      final bool isTechnicalIssue =
          remark.contains('technical error') ||
              remark.contains('technical issue') ||
              remark.contains('technical issues') ||
              remark.contains('tech issue') ||
              remark.contains('tech issues') ||
              remark.contains('technical error') ||
              remark.contains('technical problem') ||
              remark.contains('technical problems');

      if (isTechnicalIssue) {
        return 'TECH ISSUE';
      }
    }

    return status;
  }

  // =====================================================
  // NORMALIZE STATUS
  // =====================================================

  String normalizeStatus(String status) {
    final value = status.trim().toUpperCase();

    if (value == 'CARDED') {
      return 'CARDED';
    }

    if (value == 'PARTIAL') {
      return 'PARTIAL';
    }

    if (value == 'PARTIAL/REFUSED' ||
        value == 'PARTIAL / REFUSED') {
      return 'PARTIAL/Refused';
    }

    if (value == 'REJECTED') {
      return 'REJECTED';
    }

    if (value == 'REVIEW') {
      return 'REVIEW';
    }

    if (value == 'TECH ISSUE' ||
        value == 'TECH_ISSUE') {
      return 'TECH ISSUE';
    }

    return value;
  }

  // =====================================================
  // INIT
  // =====================================================

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    selectedFromDate = DateTime(
      now.year,
      now.month,
      1,
    );

    selectedToDate = now;

    fetchReports();
  }

  // =====================================================
  // FETCH REPORTS
  // =====================================================

  Future<void> fetchReports() async {
    if (selectedFromDate == null ||
        selectedToDate == null) {
      return;
    }

    if (mounted) {
      setState(() {
        isLoading = true;
        reports = [];
      });
    }

    final String fromDate =
    DateFormat('yyyy-MM-dd').format(selectedFromDate!);

    final String toDate =
    DateFormat('yyyy-MM-dd').format(selectedToDate!);

    final uri = Uri.parse(
      'https://trackme.joizone.com/attendance/mtd_status_report.php',
    ).replace(
      queryParameters: {
        'cid': widget.cid,
        'from_date': fromDate,
        'to_date': toDate,
      },
    );

    debugPrint('=================================');
    debugPrint('MTD STATUS API');
    debugPrint(uri.toString());
    debugPrint('=================================');

    try {
      final response = await http.get(uri);

      debugPrint(
        'STATUS CODE: ${response.statusCode}',
      );

      debugPrint(
        'RESPONSE: ${response.body}',
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Server Error: ${response.statusCode}',
        );
      }

      final jsonResponse = jsonDecode(response.body);

      if (jsonResponse['status'] != true) {
        throw Exception(
          jsonResponse['message'] ??
              'Unable to fetch report',
        );
      }

      final List<dynamic> data =
          jsonResponse['data'] ?? [];

      final List<Map<String, dynamic>> result =
      data.map((e) {
        return Map<String, dynamic>.from(e);
      }).toList();

      if (!mounted) return;

      setState(() {
        reports = result;
        isLoading = false;
      });

      debugPrint(
        'TOTAL RECORDS: ${reports.length}',
      );
    } catch (e) {
      debugPrint(
        'MTD STATUS ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;
        reports = [];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to load report: $e',
          ),
        ),
      );
    }
  }

  // =====================================================
  // DATE PICKER
  // =====================================================

  Future<void> _pickDateAndFetchReports() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange:
      selectedFromDate != null &&
          selectedToDate != null
          ? DateTimeRange(
        start: selectedFromDate!,
        end: selectedToDate!,
      )
          : DateTimeRange(
        start: DateTime.now(),
        end: DateTime.now(),
      ),
    );

    if (picked == null) {
      return;
    }

    setState(() {
      selectedFromDate = picked.start;
      selectedToDate = picked.end;
    });

    await fetchReports();
  }

  // =====================================================
  // STATUS WISE DATA
  // =====================================================

  Map<String, Map<String, int>> getStatusWiseData() {
    final Map<String, Map<String, int>> result = {};

    for (final report in reports) {
      final kioskName =
      report['kiosk_name']
          ?.toString()
          .trim();

      if (kioskName == null || kioskName.isEmpty) {
        continue;
      }

      // IMPORTANT:
      // Status + Remark dono check honge
      final status = getEffectiveStatus(report);

      if (!statuses.contains(status)) {
        continue;
      }

      result.putIfAbsent(
        kioskName,
            () {
          return {
            for (final s in statuses) s: 0,
          };
        },
      );

      result[kioskName]![status] =
          (result[kioskName]![status] ?? 0) + 1;
    }

    return result;
  }
  // =====================================================
  // OVERALL STATUS COUNT
  // =====================================================

  Map<String, int> getOverallStatusCount() {
    final Map<String, int> result = {
      for (final status in statuses) status: 0,
    };

    for (final report in reports) {
      final status = getEffectiveStatus(report);

      if (!statuses.contains(status)) {
        continue;
      }

      result[status] =
          (result[status] ?? 0) + 1;
    }

    return result;
  }

  // =====================================================
  // GRAND TOTAL
  // =====================================================

  int get grandTotal {
    final counts = getOverallStatusCount();

    int total = 0;

    for (final status in statuses) {
      total += counts[status] ?? 0;
    }

    return total;
  }

  // =====================================================
  // STATUS COLOR
  // =====================================================

  Color statusColor(String status) {
    switch (status) {
      case 'CARDED':
        return Colors.green;

      case 'PARTIAL':
        return Colors.orange;

      case 'PARTIAL/Refused':
        return Colors.deepOrange;

      case 'REJECTED':
        return Colors.red;

      case 'REVIEW':
        return Colors.blue;

      case 'TECH ISSUE':
        return Colors.purple;

      default:
        return Colors.grey;
    }
  }

  // =====================================================
  // BUILD
  // =====================================================
  Future<void> exportStatusReportsToExcel(
      BuildContext context,
      List<Map<String, dynamic>> reports,
      ) async {
    if (reports.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No data available for export"),
        ),
      );
      return;
    }

    try {
      // =====================================================
      // CREATE EXCEL
      // =====================================================

      final Excel excel = Excel.createExcel();

      // =====================================================
      // CREATE STATUS SHEET FIRST
      // =====================================================

      final Sheet statusSheet = excel['Status Wise'];

      // Remove all other default sheets
      for (final sheetName
      in List<String>.from(excel.tables.keys)) {
        if (sheetName != 'Status Wise') {
          excel.delete(sheetName);
        }
      }

      // Create other sheets
      final Sheet executiveSheet =
      excel['Executive Wise'];

      final Sheet citySheet =
      excel['City Wise'];

      // =====================================================
      // STATUS LIST
      // =====================================================

      const List<String> statuses = [
        'CARDED',
        'PARTIAL',
        'PARTIAL/Refused',
        'REJECTED',
        'REVIEW',
        'TECH ISSUE',
      ];

      // =====================================================
      // DATE RANGE
      // =====================================================

      final String fromDate =
      selectedFromDate != null
          ? DateFormat(
        'dd-MM-yyyy',
      ).format(selectedFromDate!)
          : '';

      final String toDate =
      selectedToDate != null
          ? DateFormat(
        'dd-MM-yyyy',
      ).format(selectedToDate!)
          : '';

      // =====================================================
      // =====================================================
      // 1. STATUS WISE SHEET
      // =====================================================
      // =====================================================

      // -----------------------------------------------------
      // TITLE
      // -----------------------------------------------------

      statusSheet.merge(
        CellIndex.indexByString('A1'),
        CellIndex.indexByString('H1'),
      );

      final statusTitle =
      statusSheet.cell(
        CellIndex.indexByString('A1'),
      );

      statusTitle.value = TextCellValue(
        'Status Wise MTD Performance: '
            '$fromDate to $toDate',
      );

      statusTitle.cellStyle = CellStyle(
        bold: true,
        fontSize: 14,
        horizontalAlign:
        HorizontalAlign.Center,
        verticalAlign:
        VerticalAlign.Center,

      );

      // -----------------------------------------------------
      // HEADER
      // -----------------------------------------------------

      statusSheet.appendRow([
        TextCellValue('Kiosk Name'),
        TextCellValue('CARDED'),
        TextCellValue('PARTIAL'),
        TextCellValue('PARTIAL/Refused'),
        TextCellValue('REJECTED'),
        TextCellValue('REVIEW'),
        TextCellValue('TECH ISSUE'),
        TextCellValue('Grand Total'),
      ]);

      // Style header
      for (int col = 0; col < 8; col++) {
        statusSheet
            .cell(
          CellIndex.indexByColumnRow(
            columnIndex: col,
            rowIndex: 1,
          ),
        )
            .cellStyle = CellStyle(
          bold: true,
          fontSize: 11,
          backgroundColorHex:
          ExcelColor.fromHexString('#FFC000'),
          horizontalAlign:
          HorizontalAlign.Center,
          verticalAlign:
          VerticalAlign.Center,
        );
      }

      // -----------------------------------------------------
      // KIOSK DATA
      // -----------------------------------------------------

      final Map<
          String,
          Map<String, int>> kioskData = {};

      for (final report in reports) {
        String kioskName =
        (report['kiosk_name'] ??
            'Unknown Kiosk')
            .toString()
            .trim();

        if (kioskName.isEmpty) {
          kioskName = 'Unknown Kiosk';
        }

        final String status =
        getEffectiveStatus(report);

        if (!statuses.contains(status)) {
          continue;
        }

        kioskData.putIfAbsent(
          kioskName,
              () => {
            for (final status in statuses)
              status: 0,
          },
        );

        kioskData[kioskName]![status] =
            (kioskData[kioskName]![status] ??
                0) +
                1;
      }

      // -----------------------------------------------------
      // GRAND TOTAL
      // -----------------------------------------------------

      final Map<String, int> statusGrandTotal = {
        for (final status in statuses)
          status: 0,
      };

      // -----------------------------------------------------
      // KIOSK ROWS
      // -----------------------------------------------------

      for (final entry
      in kioskData.entries) {
        final String kioskName =
            entry.key;

        final Map<String, int> data =
            entry.value;

        int total = 0;

        for (final status in statuses) {
          final int count =
              data[status] ?? 0;

          total += count;

          statusGrandTotal[status] =
              (statusGrandTotal[status] ??
                  0) +
                  count;
        }

        statusSheet.appendRow([
          TextCellValue(kioskName),
          IntCellValue(
            data['CARDED'] ?? 0,
          ),
          IntCellValue(
            data['PARTIAL'] ?? 0,
          ),
          IntCellValue(
            data['PARTIAL/Refused'] ?? 0,
          ),
          IntCellValue(
            data['REJECTED'] ?? 0,
          ),
          IntCellValue(
            data['REVIEW'] ?? 0,
          ),
          IntCellValue(
            data['TECH ISSUE'] ?? 0,
          ),
          IntCellValue(total),
        ]);
      }

      // -----------------------------------------------------
      // STATUS GRAND TOTAL
      // -----------------------------------------------------

      int statusOverallTotal = 0;

      for (final status in statuses) {
        statusOverallTotal +=
            statusGrandTotal[status] ?? 0;
      }

      statusSheet.appendRow([
        TextCellValue('Grand Total'),
        IntCellValue(
          statusGrandTotal['CARDED'] ?? 0,
        ),
        IntCellValue(
          statusGrandTotal['PARTIAL'] ?? 0,
        ),
        IntCellValue(
          statusGrandTotal['PARTIAL/Refused'] ?? 0,
        ),
        IntCellValue(
          statusGrandTotal['REJECTED'] ?? 0,
        ),
        IntCellValue(
          statusGrandTotal['REVIEW'] ?? 0,
        ),
        IntCellValue(
          statusGrandTotal['TECH ISSUE'] ?? 0,
        ),
        IntCellValue(statusOverallTotal),
      ]);

      // Grand total style
      final int statusGrandRow =
          statusSheet.maxRows - 1;

      for (int col = 0; col < 8; col++) {
        statusSheet
            .cell(
          CellIndex.indexByColumnRow(
            columnIndex: col,
            rowIndex: statusGrandRow,
          ),
        )
            .cellStyle = CellStyle(
          bold: true,
          backgroundColorHex:
          ExcelColor.fromHexString('#FFC000'),
          horizontalAlign:
          HorizontalAlign.Center,
          verticalAlign:
          VerticalAlign.Center,
        );
      }

      // -----------------------------------------------------
      // STATUS COLUMN WIDTH
      // -----------------------------------------------------

      statusSheet.setColumnWidth(0, 28);
      statusSheet.setColumnWidth(1, 12);
      statusSheet.setColumnWidth(2, 12);
      statusSheet.setColumnWidth(3, 18);
      statusSheet.setColumnWidth(4, 12);
      statusSheet.setColumnWidth(5, 12);
      statusSheet.setColumnWidth(6, 14);
      statusSheet.setColumnWidth(7, 14);

      // =====================================================
      // =====================================================
      // 2. EXECUTIVE WISE SHEET
      // =====================================================
      // =====================================================

      // -----------------------------------------------------
      // TITLE
      // -----------------------------------------------------

      executiveSheet.merge(
        CellIndex.indexByString('A1'),
        CellIndex.indexByString('H1'),
      );

      final executiveTitle =
      executiveSheet.cell(
        CellIndex.indexByString('A1'),
      );

      executiveTitle.value = TextCellValue(
        'Executive Wise MTD Performance: '
            '$fromDate to $toDate',
      );

      executiveTitle.cellStyle =
          CellStyle(
            bold: true,
            fontSize: 14,
            horizontalAlign:
            HorizontalAlign.Center,
            verticalAlign:
            VerticalAlign.Center,

          );

      // -----------------------------------------------------
      // HEADER
      // -----------------------------------------------------

      executiveSheet.appendRow([
        TextCellValue('Executive Name'),
        TextCellValue('CARDED'),
        TextCellValue('PARTIAL'),
        TextCellValue('PARTIAL/Refused'),
        TextCellValue('REJECTED'),
        TextCellValue('REVIEW'),
        TextCellValue('TECH ISSUE'),
        TextCellValue('Grand Total'),
      ]);

      for (int col = 0; col < 8; col++) {
        executiveSheet
            .cell(
          CellIndex.indexByColumnRow(
            columnIndex: col,
            rowIndex: 1,
          ),
        )
            .cellStyle = CellStyle(
          bold: true,
          fontSize: 11,
       backgroundColorHex:
    ExcelColor.fromHexString('#FFC000'),
          horizontalAlign:
          HorizontalAlign.Center,
          verticalAlign:
          VerticalAlign.Center,

        );
      }

      // -----------------------------------------------------
      // EXECUTIVE DATA
      // -----------------------------------------------------

      final Map<
          String,
          Map<String, int>> executiveData = {};

      for (final report in reports) {
        String executiveName =
        (report['user_name'] ??
            report['user_id'] ??
            'Unknown Executive')
            .toString()
            .trim();

        if (executiveName.isEmpty) {
          executiveName =
          'Unknown Executive';
        }

        final String status =
        getEffectiveStatus(report);

        if (!statuses.contains(status)) {
          continue;
        }

        executiveData.putIfAbsent(
          executiveName,
              () => {
            for (final status in statuses)
              status: 0,
          },
        );

        executiveData[executiveName]![status] =
            (executiveData[executiveName]![status] ??
                0) +
                1;
      }

      // -----------------------------------------------------
      // GRAND TOTAL
      // -----------------------------------------------------

      final Map<String, int>
      executiveGrandTotal = {
        for (final status in statuses)
          status: 0,
      };

      // -----------------------------------------------------
      // EXECUTIVE ROWS
      // -----------------------------------------------------

      for (final entry
      in executiveData.entries) {
        final String executiveName =
            entry.key;

        final Map<String, int> data =
            entry.value;

        int total = 0;

        for (final status in statuses) {
          final int count =
              data[status] ?? 0;

          total += count;

          executiveGrandTotal[status] =
              (executiveGrandTotal[status] ??
                  0) +
                  count;
        }

        executiveSheet.appendRow([
          TextCellValue(executiveName),
          IntCellValue(
            data['CARDED'] ?? 0,
          ),
          IntCellValue(
            data['PARTIAL'] ?? 0,
          ),
          IntCellValue(
            data['PARTIAL/Refused'] ?? 0,
          ),
          IntCellValue(
            data['REJECTED'] ?? 0,
          ),
          IntCellValue(
            data['REVIEW'] ?? 0,
          ),
          IntCellValue(
            data['TECH ISSUE'] ?? 0,
          ),
          IntCellValue(total),
        ]);
      }

      // -----------------------------------------------------
      // EXECUTIVE GRAND TOTAL
      // -----------------------------------------------------

      int executiveOverallTotal = 0;

      for (final status in statuses) {
        executiveOverallTotal +=
            executiveGrandTotal[status] ?? 0;
      }

      executiveSheet.appendRow([
        TextCellValue('Grand Total'),
        IntCellValue(
          executiveGrandTotal['CARDED'] ?? 0,
        ),
        IntCellValue(
          executiveGrandTotal['PARTIAL'] ?? 0,
        ),
        IntCellValue(
          executiveGrandTotal['PARTIAL/Refused'] ?? 0,
        ),
        IntCellValue(
          executiveGrandTotal['REJECTED'] ?? 0,
        ),
        IntCellValue(
          executiveGrandTotal['REVIEW'] ?? 0,
        ),
        IntCellValue(
          executiveGrandTotal['TECH ISSUE'] ?? 0,
        ),
        IntCellValue(
          executiveOverallTotal,
        ),
      ]);

      final int executiveGrandRow =
          executiveSheet.maxRows - 1;

      for (int col = 0; col < 8; col++) {
        executiveSheet
            .cell(
          CellIndex.indexByColumnRow(
            columnIndex: col,
            rowIndex: executiveGrandRow,
          ),
        )
            .cellStyle = CellStyle(
          bold: true,
          backgroundColorHex:
          ExcelColor.fromHexString('#FFC000'),
          horizontalAlign:
          HorizontalAlign.Center,
          verticalAlign:
          VerticalAlign.Center,
        );
      }

      // -----------------------------------------------------
      // EXECUTIVE COLUMN WIDTH
      // -----------------------------------------------------

      executiveSheet.setColumnWidth(0, 32);
      executiveSheet.setColumnWidth(1, 12);
      executiveSheet.setColumnWidth(2, 12);
      executiveSheet.setColumnWidth(3, 18);
      executiveSheet.setColumnWidth(4, 12);
      executiveSheet.setColumnWidth(5, 12);
      executiveSheet.setColumnWidth(6, 14);
      executiveSheet.setColumnWidth(7, 14);

      // =====================================================
// 3. CITY WISE SHEET
// CITY TOTAL + EMPLOYEE WISE DATA
// =====================================================

// -----------------------------------------------------
// TITLE
// -----------------------------------------------------

      citySheet.merge(
        CellIndex.indexByString('A1'),
        CellIndex.indexByString('H1'),
      );

      final cityTitle = citySheet.cell(
        CellIndex.indexByString('A1'),
      );

      cityTitle.value = TextCellValue(
        'City Wise MTD Performance: $fromDate to $toDate',
      );

      cityTitle.cellStyle = CellStyle(
        bold: true,
        fontSize: 14,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

      citySheet.setRowHeight(0, 25);

// -----------------------------------------------------
// COLORS
// -----------------------------------------------------

      final ExcelColor orangeColor =
      ExcelColor.fromHexString('#FFC000');

      final ExcelColor greenColor =
      ExcelColor.fromHexString('#C6E0B4');

      final ExcelColor lightColor =
      ExcelColor.fromHexString('#F2F2F2');

// -----------------------------------------------------
// HEADER
// -----------------------------------------------------

      citySheet.appendRow([
        TextCellValue('City Name'),
        TextCellValue('CARDED'),
        TextCellValue('PARTIAL'),
        TextCellValue('PARTIAL/Refused'),
        TextCellValue('REJECTED'),
        TextCellValue('REVIEW'),
        TextCellValue('TECH ISSUE'),
        TextCellValue('Grand Total'),
      ]);

      for (int col = 0; col < 8; col++) {
        citySheet
            .cell(
          CellIndex.indexByColumnRow(
            columnIndex: col,
            rowIndex: 1,
          ),
        )
            .cellStyle = CellStyle(
          bold: true,
          fontSize: 11,
          backgroundColorHex: orangeColor,
          horizontalAlign: HorizontalAlign.Center,
          verticalAlign: VerticalAlign.Center,
        );
      }

      citySheet.setRowHeight(1, 25);

// =====================================================
// CITY + EMPLOYEE DATA
// =====================================================
//
// Structure:
//
// cityEmployeeData[cityName][employeeName][status]
// =====================================================

      final Map<
          String,
          Map<String, Map<String, int>>> cityEmployeeData = {};

      final List<String> cityStatuses = [
        'CARDED',
        'PARTIAL',
        'PARTIAL/Refused',
        'REJECTED',
        'REVIEW',
        'TECH ISSUE',
      ];

// -----------------------------------------------------
// READ REPORT DATA
// -----------------------------------------------------

      for (final report in reports) {

        // -----------------------------
        // CITY NAME
        // -----------------------------

        String cityName = (
            report['city_name'] ??
                report['site_name'] ??
                'Unknown City'
        )
            .toString()
            .trim();

        if (cityName.isEmpty) {
          cityName = 'Unknown City';
        }

        // -----------------------------
        // EMPLOYEE NAME
        // -----------------------------

        String employeeName = (
            report['full_name'] ??
                report['name'] ??
                report['user_name'] ??
                report['employee_name'] ??
                'Unknown Employee'
        )
            .toString()
            .trim();

        if (employeeName.isEmpty) {
          employeeName = 'Unknown Employee';
        }

        // -----------------------------
        // STATUS
        // -----------------------------

        final String status = getEffectiveStatus(report);

        if (!cityStatuses.contains(status)) {
          continue;
        }

        // -----------------------------
        // CREATE CITY
        // -----------------------------

        cityEmployeeData.putIfAbsent(
          cityName,
              () => {},
        );

        // -----------------------------
        // CREATE EMPLOYEE
        // -----------------------------

        cityEmployeeData[cityName]!.putIfAbsent(
          employeeName,
              () => {
            'CARDED': 0,
            'PARTIAL': 0,
            'PARTIAL/Refused': 0,
            'REJECTED': 0,
            'REVIEW': 0,
            'TECH ISSUE': 0,
          },
        );

        // -----------------------------
        // INCREMENT STATUS
        // -----------------------------

        cityEmployeeData[cityName]![employeeName]![status] =
            (cityEmployeeData[cityName]![employeeName]![status] ?? 0) + 1;
      }

// =====================================================
// GRAND TOTAL
// =====================================================

      final Map<String, int> cityGrandTotal = {
        'CARDED': 0,
        'PARTIAL': 0,
        'PARTIAL/Refused': 0,
        'REJECTED': 0,
        'REVIEW': 0,
        'TECH ISSUE': 0,
      };

// =====================================================
// CITY LOOP
// =====================================================

      for (final cityEntry in cityEmployeeData.entries) {

        final String cityName = cityEntry.key;

        final Map<String, Map<String, int>> employees =
            cityEntry.value;

        // ---------------------------------------------------
        // CITY TOTAL
        // ---------------------------------------------------

        final Map<String, int> cityTotal = {
          'CARDED': 0,
          'PARTIAL': 0,
          'PARTIAL/Refused': 0,
          'REJECTED': 0,
          'REVIEW': 0,
          'TECH ISSUE': 0,
        };

        // Calculate city total from employees
        for (final employeeData in employees.values) {

          for (final status in cityStatuses) {

            cityTotal[status] =
                (cityTotal[status] ?? 0) +
                    (employeeData[status] ?? 0);
          }
        }

        // ---------------------------------------------------
        // CITY GRAND TOTAL
        // ---------------------------------------------------

        final int cityOverallTotal =
            (cityTotal['CARDED'] ?? 0) +
                (cityTotal['PARTIAL'] ?? 0) +
                (cityTotal['PARTIAL/Refused'] ?? 0) +
                (cityTotal['REJECTED'] ?? 0) +
                (cityTotal['REVIEW'] ?? 0) +
                (cityTotal['TECH ISSUE'] ?? 0);

        // ---------------------------------------------------
        // ADD TO OVERALL GRAND TOTAL
        // ---------------------------------------------------

        for (final status in cityStatuses) {

          cityGrandTotal[status] =
              (cityGrandTotal[status] ?? 0) +
                  (cityTotal[status] ?? 0);
        }

        // ===================================================
        // CITY TOTAL ROW
        // ===================================================

        citySheet.appendRow([
          TextCellValue('$cityName Total'),

          IntCellValue(
            cityTotal['CARDED'] ?? 0,
          ),

          IntCellValue(
            cityTotal['PARTIAL'] ?? 0,
          ),

          IntCellValue(
            cityTotal['PARTIAL/Refused'] ?? 0,
          ),

          IntCellValue(
            cityTotal['REJECTED'] ?? 0,
          ),

          IntCellValue(
            cityTotal['REVIEW'] ?? 0,
          ),

          IntCellValue(
            cityTotal['TECH ISSUE'] ?? 0,
          ),

          IntCellValue(
            cityOverallTotal,
          ),
        ]);

        final int cityRow =
            citySheet.maxRows - 1;

        // ---------------------------------------------------
        // CITY TOTAL STYLE
        // ---------------------------------------------------

        for (int col = 0; col < 8; col++) {

          citySheet
              .cell(
            CellIndex.indexByColumnRow(
              columnIndex: col,
              rowIndex: cityRow,
            ),
          )
              .cellStyle = CellStyle(
            bold: true,
            fontSize: 10,
            backgroundColorHex: greenColor,
            horizontalAlign: HorizontalAlign.Center,
            verticalAlign: VerticalAlign.Center,
          );
        }

        citySheet.setRowHeight(cityRow, 22);

        // ===================================================
        // EMPLOYEE ROWS
        // ===================================================

        for (final employeeEntry in employees.entries) {

          final String employeeName =
              employeeEntry.key;

          final Map<String, int> employeeData =
              employeeEntry.value;

          // -------------------------------------------------
          // EMPLOYEE COUNTS
          // -------------------------------------------------

          final int carded =
              employeeData['CARDED'] ?? 0;

          final int partial =
              employeeData['PARTIAL'] ?? 0;

          final int partialRefused =
              employeeData['PARTIAL/Refused'] ?? 0;

          final int rejected =
              employeeData['REJECTED'] ?? 0;

          final int review =
              employeeData['REVIEW'] ?? 0;

          final int techIssue =
              employeeData['TECH ISSUE'] ?? 0;

          // -------------------------------------------------
          // EMPLOYEE TOTAL
          // -------------------------------------------------

          final int employeeTotal =
              carded +
                  partial +
                  partialRefused +
                  rejected +
                  review +
                  techIssue;

          // -------------------------------------------------
          // ADD EMPLOYEE ROW
          // -------------------------------------------------

          citySheet.appendRow([
            TextCellValue('    $employeeName'),

            IntCellValue(carded),

            IntCellValue(partial),

            IntCellValue(partialRefused),

            IntCellValue(rejected),

            IntCellValue(review),

            IntCellValue(techIssue),

            IntCellValue(employeeTotal),
          ]);

          final int employeeRow =
              citySheet.maxRows - 1;

          // -------------------------------------------------
          // EMPLOYEE STYLE
          // -------------------------------------------------

          for (int col = 0; col < 8; col++) {

            citySheet
                .cell(
              CellIndex.indexByColumnRow(
                columnIndex: col,
                rowIndex: employeeRow,
              ),
            )
                .cellStyle = CellStyle(
              fontSize: 9,
              backgroundColorHex: lightColor,
              horizontalAlign: HorizontalAlign.Center,
              verticalAlign: VerticalAlign.Center,
            );
          }

          // Employee name left aligned
          citySheet
              .cell(
            CellIndex.indexByColumnRow(
              columnIndex: 0,
              rowIndex: employeeRow,
            ),
          )
              .cellStyle = CellStyle(
            fontSize: 9,
            backgroundColorHex: lightColor,
            horizontalAlign: HorizontalAlign.Left,
            verticalAlign: VerticalAlign.Center,
          );

          citySheet.setRowHeight(employeeRow, 20);
        }
      }

// =====================================================
// FINAL GRAND TOTAL
// =====================================================

      final int overallTotal =
          (cityGrandTotal['CARDED'] ?? 0) +
              (cityGrandTotal['PARTIAL'] ?? 0) +
              (cityGrandTotal['PARTIAL/Refused'] ?? 0) +
              (cityGrandTotal['REJECTED'] ?? 0) +
              (cityGrandTotal['REVIEW'] ?? 0) +
              (cityGrandTotal['TECH ISSUE'] ?? 0);

// -----------------------------------------------------
// GRAND TOTAL ROW
// -----------------------------------------------------

      citySheet.appendRow([
        TextCellValue('Grand Total'),

        IntCellValue(
          cityGrandTotal['CARDED'] ?? 0,
        ),

        IntCellValue(
          cityGrandTotal['PARTIAL'] ?? 0,
        ),

        IntCellValue(
          cityGrandTotal['PARTIAL/Refused'] ?? 0,
        ),

        IntCellValue(
          cityGrandTotal['REJECTED'] ?? 0,
        ),

        IntCellValue(
          cityGrandTotal['REVIEW'] ?? 0,
        ),

        IntCellValue(
          cityGrandTotal['TECH ISSUE'] ?? 0,
        ),

        IntCellValue(
          overallTotal,
        ),
      ]);

      final int grandTotalRow =
          citySheet.maxRows - 1;

// -----------------------------------------------------
// GRAND TOTAL STYLE
// -----------------------------------------------------

      for (int col = 0; col < 8; col++) {

        citySheet
            .cell(
          CellIndex.indexByColumnRow(
            columnIndex: col,
            rowIndex: grandTotalRow,
          ),
        )
            .cellStyle = CellStyle(
          bold: true,
          fontSize: 11,
          backgroundColorHex: orangeColor,
          horizontalAlign: HorizontalAlign.Center,
          verticalAlign: VerticalAlign.Center,
        );
      }

      citySheet.setRowHeight(grandTotalRow, 25);

// =====================================================
// COLUMN WIDTH
// =====================================================

      citySheet.setColumnWidth(0, 32); // City / Employee Name
      citySheet.setColumnWidth(1, 12); // CARDED
      citySheet.setColumnWidth(2, 12); // PARTIAL
      citySheet.setColumnWidth(3, 20); // PARTIAL/Refused
      citySheet.setColumnWidth(4, 12); // REJECTED
      citySheet.setColumnWidth(5, 12); // REVIEW
      citySheet.setColumnWidth(6, 14); // TECH ISSUE
      citySheet.setColumnWidth(7, 14); // Grand Total

      // =====================================================
      // GENERATE EXCEL
      // =====================================================

      final List<int>? bytes = excel.encode();

      if (bytes == null) {
        throw Exception(
          "Unable to generate Excel file",
        );
      }

      // =====================================================
      // FILE NAME
      // =====================================================

      final DateTime now = DateTime.now();

      final String date =
          "${now.day.toString().padLeft(2, '0')}-"
          "${now.month.toString().padLeft(2, '0')}-"
          "${now.year}";

      final String fileName =
          "MTD_Status_Performance_"
          "${fromDate}_to_${toDate}_$date.xlsx";

      // =====================================================
      // WEB DOWNLOAD
      // =====================================================

      if (kIsWeb) {
        final blob = html.Blob([
          Uint8List.fromList(bytes),
        ]);

        final url =
        html.Url.createObjectUrlFromBlob(
          blob,
        );

        final anchor =
        html.AnchorElement(
          href: url,
        )
          ..setAttribute(
            "download",
            fileName,
          )
          ..click();

        html.Url.revokeObjectUrl(url);

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              "Excel downloaded successfully",
            ),
          ),
        );
      }

      // =====================================================
      // ANDROID / IOS
      // =====================================================

      else {
        final directory =
        await getApplicationDocumentsDirectory();

        final String filePath =
            "${directory.path}/$fileName";

        final File file =
        File(filePath);

        await file.writeAsBytes(
          bytes,
          flush: true,
        );

        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              "Excel saved to:\n$filePath",
            ),
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint(
        "EXPORT STATUS EXCEL ERROR: $e",
      );

      debugPrint(
        stackTrace.toString(),
      );

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            "Excel export failed: $e",
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    final statusWiseData =
    getStatusWiseData();

    final overallCount =
    getOverallStatusCount();

    return Scaffold(
      appBar: AppBar(
        elevation: 0,

        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xff2563EB),
                Color(0xff1D4ED8),
              ],
            ),
          ),
        ),

        backgroundColor: Colors.blue,

        title: Text(
          'MTD Status Performance ${widget.cid}',
          style: const TextStyle(
            fontSize: 18,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),

        iconTheme: const IconThemeData(
          color: Colors.white,
        ),

        actions: [
          const SizedBox(width: 8),
          SizedBox(
            height: 42,
            child: ElevatedButton.icon(
              onPressed: isLoading || reports.isEmpty
                  ? null
                  : () {
                exportStatusReportsToExcel(
                  context,
                  reports,
                );
              },
              icon: const Icon(
                Icons.file_download_outlined,
                size: 20,
              ),
              label: const Text(
                "Export Status",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                Colors.grey.shade300,
                disabledForegroundColor:
                Colors.grey.shade600,
                elevation: 2,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          InkWell(
            onTap: isLoading
                ? null
                : _pickDateAndFetchReports,

            borderRadius:
            BorderRadius.circular(10),

            child: Container(
              margin:
              const EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 5,
              ),

              padding:
              const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),

              decoration: BoxDecoration(
                borderRadius:
                BorderRadius.circular(10),
                color: Colors.white,
              ),

              child: Row(
                mainAxisSize:
                MainAxisSize.min,

                children: [
                  const Icon(
                    Icons.calendar_month_rounded,
                    size: 19,
                    color: Color(0xFF2563EB),
                  ),

                  const SizedBox(width: 8),

                  Text(
                    selectedFromDate != null &&
                        selectedToDate != null
                        ? '${DateFormat('dd-MM-yyyy').format(selectedFromDate!)}'
                        ' → '
                        '${DateFormat('dd-MM-yyyy').format(selectedToDate!)}'
                        : 'Select Date Range',

                    style:
                    const TextStyle(
                      fontSize: 13,
                      fontWeight:
                      FontWeight.w600,
                      color:
                      Color(0xFF374151),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),
        ],
      ),

      // ===================================================
      // BODY
      // ===================================================

      body: isLoading
          ? _buildLoading()
          : reports.isEmpty
          ? _buildNoData()
          : Center(
            child: _buildReportBody(
                    statusWiseData,
                    overallCount,
                  ),
          ),
    );
  }

  // =====================================================
  // LOADING
  // =====================================================

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            strokeWidth: 3,
          ),

          SizedBox(height: 16),

          Text(
            'Loading MTD Status Report...',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),

          SizedBox(height: 5),

          Text(
            'Please wait',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // NO DATA
  // =====================================================

  Widget _buildNoData() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 60,
            color: Colors.grey.shade400,
          ),

          const SizedBox(height: 12),

          const Text(
            'No reports found',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            'Select another date range',
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // REPORT BODY
  // =====================================================

  Widget _buildReportBody(
      Map<String, Map<String, int>> statusWiseData,
      Map<String, int> overallCount,
      ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),

      child: Center(
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [

            // =============================================
            // TITLE
            // =============================================

            Center(
              child: const Text(
                'Status Wise MTD Performance',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 5),

            if (selectedFromDate != null &&
                selectedToDate != null)
              Center(
                child: Text(
                  'MTD Performance: '
                      '${DateFormat('dd-MM-yyyy').format(selectedFromDate!)}'
                      ' → '
                      '${DateFormat('dd-MM-yyyy').format(selectedToDate!)}',

                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),

            const SizedBox(height: 18),

            // =============================================
            // SUMMARY CARDS
            // =============================================

            Center(
              child: _buildSummaryCards(
                overallCount,
              ),
            ),

            const SizedBox(height: 20),

            // =============================================
            // KIOSK WISE TABLE
            // =============================================

            Center(
              child: _buildStatusTable(
                statusWiseData,
                overallCount,
              ),
            ),


            // =============================================
            const SizedBox(height: 30),
            // EXECUTIVE WISE TABLE
            // =============================================

            Center(child: _buildExecutiveWiseTable()),

            const SizedBox(height: 30),

            Center(child: _buildCityWiseTable()),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // SUMMARY CARDS
  // =====================================================

  Widget _buildSummaryCards(
      Map<String, int> overallCount,
      ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,

      child: Row(
        children: [
          for (final status in statuses)
            Padding(
              padding:
              const EdgeInsets.only(
                right: 10,
              ),
              child: _statusBox(
                status,
                overallCount[status] ?? 0,
              ),
            ),

          _statusBox(
            'Grand Total',
            grandTotal,
          ),
        ],
      ),
    );
  }

  // =====================================================
  // STATUS TABLE / KIOSK WISE
  // =====================================================

  Widget _buildStatusTable(
      Map<String, Map<String, int>> statusWiseData,
      Map<String, int> overallCount,
      ) {
    final kioskNames =
    statusWiseData.keys.toList();

    return Card(
      elevation: 3,

      clipBehavior: Clip.antiAlias,

      child: Scrollbar(
        child: SingleChildScrollView(
          scrollDirection:
          Axis.horizontal,

          child: SingleChildScrollView(
            child: DataTable(
              headingRowHeight: 58,

              dataRowMinHeight: 48,
              dataRowMaxHeight: 55,

              columnSpacing: 30,

              headingRowColor:
              WidgetStateProperty.all(
                const Color(0xffEFF6FF),
              ),

              columns: [
                const DataColumn(
                  label: Text(
                    'Kiosk Name',
                    style: TextStyle(
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                ),

                ...statuses.map(
                      (status) {
                    return DataColumn(
                      label: Text(
                        status,
                        style: TextStyle(
                          fontWeight:
                          FontWeight.bold,
                          color:
                          statusColor(
                            status,
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const DataColumn(
                  label: Text(
                    'Grand Total',
                    style: TextStyle(
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                ),
              ],

              rows: [
                ...kioskNames.map(
                      (kioskName) {
                    final kioskData =
                    statusWiseData[
                    kioskName]!;

                    int kioskTotal = 0;

                    for (final status
                    in statuses) {
                      kioskTotal +=
                          kioskData[
                          status] ??
                              0;
                    }

                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            kioskName,
                            style:
                            const TextStyle(
                              fontWeight:
                              FontWeight.w600,
                            ),
                          ),
                        ),

                        ...statuses.map(
                              (status) {
                            return DataCell(
                              Center(
                                child: Text(
                                  '${kioskData[status] ?? 0}',
                                ),
                              ),
                            );
                          },
                        ),

                        DataCell(
                          Center(
                            child: Text(
                              '$kioskTotal',
                              style:
                              const TextStyle(
                                fontWeight:
                                FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),

                // ========================================
                // GRAND TOTAL
                // ========================================

                DataRow(
                  color:
                  WidgetStateProperty.all(
                    const Color(0xffF3F4F6),
                  ),

                  cells: [
                    const DataCell(
                      Text(
                        'Grand Total',
                        style:
                        TextStyle(
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                    ),

                    ...statuses.map(
                          (status) {
                        return DataCell(
                          Center(
                            child: Text(
                              '${overallCount[status] ?? 0}',
                              style:
                              const TextStyle(
                                fontWeight:
                                FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    DataCell(
                      Center(
                        child: Text(
                          '$grandTotal',
                          style:
                          const TextStyle(
                            fontWeight:
                            FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =====================================================
  // EXECUTIVE WISE TABLE
  // =====================================================

  Widget _buildExecutiveWiseTable() {
    final Map<String, Map<String, int>> userData =
    {};

    // ==========================================
    // USER WISE COUNT
    // ==========================================

    for (final report in reports) {
      final userName =
      (report['user_name'] ??
          report['full_name'] ??
          'Unknown User')
          .toString()
          .trim();

      final status = getEffectiveStatus(report);

      if (userName.isEmpty) {
        continue;
      }

      if (!statuses.contains(status)) {
        continue;
      }

      if (!userData.containsKey(userName)) {
        userData[userName] = {
          for (final s in statuses) s: 0,
        };
      }

      userData[userName]![status] =
          (userData[userName]![status] ?? 0) + 1;
    }

    // ==========================================
    // GRAND TOTAL
    // ==========================================

    final Map<String, int> executiveGrandTotal = {
      for (final s in statuses) s: 0,
    };

    for (final user in userData.values) {
      for (final status in statuses) {
        executiveGrandTotal[status] =
            (executiveGrandTotal[status] ?? 0) +
                (user[status] ?? 0);
      }
    }

    final int executiveOverallTotal =
    statuses.fold<int>(
      0,
          (sum, status) =>
      sum +
          (executiveGrandTotal[status] ?? 0),
    );

    return Card(
      elevation: 3,

      clipBehavior: Clip.antiAlias,

      child: Padding(
        padding: const EdgeInsets.all(12),

        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [

            // ==========================================
            // TITLE
            // ==========================================

            Center(
              child: Column(
                children: [
                  const Text(
                    'Exc Wise MTD Performance',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  if (selectedFromDate != null &&
                      selectedToDate != null)
                    Text(
                      '${DateFormat('dd-MM-yyyy').format(selectedFromDate!)}'
                          ' to '
                          '${DateFormat('dd-MM-yyyy').format(selectedToDate!)}',

                      style:
                      const TextStyle(
                        fontSize: 14,
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            // ==========================================
            // TABLE
            // ==========================================

            Scrollbar(
              child: SingleChildScrollView(
                scrollDirection:
                Axis.horizontal,

                child: Center(
                  child: DataTable(
                    headingRowHeight: 55,

                    dataRowMinHeight: 45,
                    dataRowMaxHeight: 55,

                    border: TableBorder.all(
                      color:
                      Colors.grey.shade400,
                    ),

                    columnSpacing: 0,

                    headingRowColor:
                    WidgetStateProperty.all(
                      Colors.amber.shade600,
                    ),

                    columns: const [

                      // USER NAME
                      DataColumn(
                        label: SizedBox(
                          width: 220,
                          child: Text(
                            'User Name',
                            style: TextStyle(
                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      // CARDED
                      DataColumn(
                        label: SizedBox(
                          width: 75,
                          child: Center(
                            child: Text(
                              'CARDED',
                              style: TextStyle(
                                fontWeight:
                                FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // PARTIAL
                      DataColumn(
                        label: SizedBox(
                          width: 75,
                          child: Center(
                            child: Text(
                              'PARTIAL',
                              style: TextStyle(
                                fontWeight:
                                FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // PARTIAL / REFUSED
                      DataColumn(
                        label: SizedBox(
                          width: 110,
                          child: Center(
                            child: Text(
                              'PARTIAL/\nRefused',
                              textAlign:
                              TextAlign.center,
                              style: TextStyle(
                                fontWeight:
                                FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // REJECTED
                      DataColumn(
                        label: SizedBox(
                          width: 80,
                          child: Center(
                            child: Text(
                              'REJECTED',
                              style: TextStyle(
                                fontWeight:
                                FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // REVIEW
                      DataColumn(
                        label: SizedBox(
                          width: 75,
                          child: Center(
                            child: Text(
                              'REVIEW',
                              style: TextStyle(
                                fontWeight:
                                FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // TECH ISSUE
                      DataColumn(
                        label: SizedBox(
                          width: 90,
                          child: Center(
                            child: Text(
                              'TECH ISSUE',
                              textAlign:
                              TextAlign.center,
                              style: TextStyle(
                                fontWeight:
                                FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // GRAND TOTAL
                      DataColumn(
                        label: SizedBox(
                          width: 90,
                          child: Center(
                            child: Text(
                              'Grand Total',
                              textAlign:
                              TextAlign.center,
                              style: TextStyle(
                                fontWeight:
                                FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],

                    rows: [

                      // =====================================
                      // USER ROWS
                      // =====================================

                      ...userData.entries.map(
                            (entry) {
                          final userName =
                              entry.key;

                          final data =
                              entry.value;

                          final total =
                          statuses.fold<int>(
                            0,
                                (sum, status) =>
                            sum +
                                (data[
                                status] ??
                                    0),
                          );

                          return DataRow(
                            cells: [

                              // USER NAME
                              DataCell(
                                SizedBox(
                                  width: 220,
                                  child: Text(
                                    userName,
                                    overflow:
                                    TextOverflow
                                        .ellipsis,
                                    style:
                                    const TextStyle(
                                      fontWeight:
                                      FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),

                              // CARDED
                              _numberCell(
                                data['CARDED'],
                              ),

                              // PARTIAL
                              _numberCell(
                                data['PARTIAL'],
                              ),

                              // PARTIAL/REFUSED
                              _numberCell(
                                data[
                                'PARTIAL/Refused'],
                              ),

                              // REJECTED
                              _numberCell(
                                data['REJECTED'],
                              ),

                              // REVIEW
                              _numberCell(
                                data['REVIEW'],
                              ),

                              // TECH ISSUE
                              _numberCell(
                                data['TECH ISSUE'],
                              ),

                              // TOTAL
                              _numberCell(
                                total,
                              ),
                            ],
                          );
                        },
                      ),

                      // =====================================
                      // GRAND TOTAL ROW
                      // =====================================

                      DataRow(
                        color:
                        WidgetStateProperty.all(
                          Colors.lightBlue.shade100,
                        ),

                        cells: [

                          const DataCell(
                            SizedBox(
                              width: 220,
                              child: Text(
                                'Grand Total',
                                style:
                                TextStyle(
                                  fontWeight:
                                  FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                          _numberCell(
                            executiveGrandTotal[
                            'CARDED'],
                            bold: true,
                          ),

                          _numberCell(
                            executiveGrandTotal[
                            'PARTIAL'],
                            bold: true,
                          ),

                          _numberCell(
                            executiveGrandTotal[
                            'PARTIAL/Refused'],
                            bold: true,
                          ),

                          _numberCell(
                            executiveGrandTotal[
                            'REJECTED'],
                            bold: true,
                          ),

                          _numberCell(
                            executiveGrandTotal[
                            'REVIEW'],
                            bold: true,
                          ),

                          _numberCell(
                            executiveGrandTotal[
                            'TECH ISSUE'],
                            bold: true,
                          ),

                          _numberCell(
                            executiveOverallTotal,
                            bold: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

// =====================================================
  // CITY WISE TABLE
  // =====================================================
  Widget _buildCityWiseTable() {
    const cityStatuses = [
      'CARDED',
      'PARTIAL',
      'PARTIAL/Refused',
      'REJECTED',
      'REVIEW',
      'TECH ISSUE',
    ];

    // =====================================================
    // CITY -> USER -> STATUS COUNT
    // =====================================================

    final Map<String, Map<String, Map<String, int>>> cityData = {};

    for (final report in reports) {
      final cityName =
      (report['city_name'] ??
          'Unknown City')
          .toString()
          .trim();

      final userName =
      (report['user_name'] ??
          report['full_name'] ??
          'Unknown User')
          .toString()
          .trim();

      final status =
      getEffectiveStatus(report);

      if (cityName.isEmpty ||
          userName.isEmpty) {
        continue;
      }

      if (!cityStatuses.contains(status)) {
        continue;
      }

      // Create city
      cityData.putIfAbsent(
        cityName,
            () => {},
      );

      // Create user
      cityData[cityName]!.putIfAbsent(
        userName,
            () {
          return {
            for (final s in cityStatuses) s: 0,
          };
        },
      );

      // Increment
      cityData[cityName]![userName]![status] =
          (cityData[cityName]![userName]![status] ?? 0) + 1;
    }

    // =====================================================
    // CITY TOTALS
    // =====================================================

    final Map<String, Map<String, int>> cityTotals = {};

    for (final cityEntry in cityData.entries) {
      final cityName = cityEntry.key;
      final users = cityEntry.value;

      cityTotals[cityName] = {
        for (final status in cityStatuses)
          status: users.values.fold<int>(
            0,
                (sum, user) =>
            sum + (user[status] ?? 0),
          ),
      };
    }

    // =====================================================
    // GRAND TOTAL
    // =====================================================

    final Map<String, int> grandCityTotal = {
      for (final status in cityStatuses)
        status: cityTotals.values.fold<int>(
          0,
              (sum, city) =>
          sum + (city[status] ?? 0),
        ),
    };

    final int grandTotal =
    cityStatuses.fold<int>(
      0,
          (sum, status) =>
      sum + (grandCityTotal[status] ?? 0),
    );

    return Card(
      elevation: 3,
      clipBehavior: Clip.antiAlias,

      child: Padding(
        padding: const EdgeInsets.all(12),

        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [

            // =================================================
            // HEADER
            // =================================================

            Center(
              child: Column(
                children: [

                  const Text(
                    'City Wise MTD Performance',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  if (selectedFromDate != null &&
                      selectedToDate != null)
                    Text(
                      'MTD Performance: '
                          '${DateFormat('dd-MM-yyyy').format(selectedFromDate!)}'
                          ' to '
                          '${DateFormat('dd-MM-yyyy').format(selectedToDate!)}',

                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            // =================================================
            // TABLE
            // =================================================

            Scrollbar(
              child: SingleChildScrollView(
                scrollDirection:
                Axis.horizontal,

                child: DataTable(
                  border: TableBorder.all(
                    color:
                    Colors.grey.shade400,
                  ),

                  headingRowHeight: 55,

                  dataRowMinHeight: 45,
                  dataRowMaxHeight: 55,

                  columnSpacing: 0,

                  headingRowColor:
                  WidgetStateProperty.all(
                    Colors.amber.shade600,
                  ),

                  columns: const [

                    // CITY NAME
                    DataColumn(
                      label: SizedBox(
                        width: 220,
                        child: Text(
                          'City Name',
                          style: TextStyle(
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    // CARDED
                    DataColumn(
                      label: SizedBox(
                        width: 75,
                        child: Center(
                          child: Text(
                            'CARDED',
                            style: TextStyle(
                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // PARTIAL
                    DataColumn(
                      label: SizedBox(
                        width: 75,
                        child: Center(
                          child: Text(
                            'PARTIAL',
                            style: TextStyle(
                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // PARTIAL REFUSED
                    DataColumn(
                      label: SizedBox(
                        width: 110,
                        child: Center(
                          child: Text(
                            'PARTIAL/\nRefused',
                            textAlign:
                            TextAlign.center,
                            style: TextStyle(
                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // REJECTED
                    DataColumn(
                      label: SizedBox(
                        width: 80,
                        child: Center(
                          child: Text(
                            'REJECTED',
                            style: TextStyle(
                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // REVIEW
                    DataColumn(
                      label: SizedBox(
                        width: 75,
                        child: Center(
                          child: Text(
                            'REVIEW',
                            style: TextStyle(
                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // TECH ISSUE
                    DataColumn(
                      label: SizedBox(
                        width: 90,
                        child: Center(
                          child: Text(
                            'TECH ISSUE',
                            textAlign:
                            TextAlign.center,
                            style: TextStyle(
                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // GRAND TOTAL
                    DataColumn(
                      label: SizedBox(
                        width: 90,
                        child: Center(
                          child: Text(
                            'Grand Total',
                            textAlign:
                            TextAlign.center,
                            style: TextStyle(
                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],

                  rows: [

                    // =================================================
                    // CITY + USER ROWS
                    // =================================================

                    for (final cityEntry
                    in cityData.entries) ...[

                      // =============================================
                      // CITY TOTAL ROW
                      // =============================================

                      DataRow(
                        color:
                        WidgetStateProperty.all(
                          Colors.lightGreen.shade200,
                        ),

                        cells: [

                          DataCell(
                            SizedBox(
                              width: 220,
                              child: Text(
                                '${cityEntry.key} Total',
                                style:
                                const TextStyle(
                                  fontWeight:
                                  FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                          ...cityStatuses.map(
                                (status) {
                              return DataCell(
                                Center(
                                  child: Text(
                                    '${cityTotals[cityEntry.key]![status] ?? 0}',
                                    style:
                                    const TextStyle(
                                      fontWeight:
                                      FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                          DataCell(
                            Center(
                              child: Text(
                                '${cityStatuses.fold<int>(
                                  0,
                                      (sum, status) =>
                                  sum +
                                      (cityTotals[
                                      cityEntry
                                          .key]![status] ??
                                          0),
                                )}',
                                style:
                                const TextStyle(
                                  fontWeight:
                                  FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // =============================================
                      // USERS UNDER CITY
                      // =============================================

                      ...cityEntry.value.entries.map(
                            (userEntry) {

                          final userName =
                              userEntry.key;

                          final userStatus =
                              userEntry.value;

                          final userTotal =
                          cityStatuses.fold<int>(
                            0,
                                (sum, status) =>
                            sum +
                                (userStatus[
                                status] ??
                                    0),
                          );

                          return DataRow(
                            cells: [

                              // USER NAME
                              DataCell(
                                SizedBox(
                                  width: 220,

                                  child: Padding(
                                    padding:
                                    const EdgeInsets
                                        .only(
                                      left: 16,
                                    ),

                                    child: Text(
                                      userName,
                                      overflow:
                                      TextOverflow
                                          .ellipsis,
                                    ),
                                  ),
                                ),
                              ),

                              // STATUS COUNTS
                              ...cityStatuses.map(
                                    (status) {
                                  return DataCell(
                                    Center(
                                      child: Text(
                                        '${userStatus[status] ?? 0}',
                                      ),
                                    ),
                                  );
                                },
                              ),

                              // USER TOTAL
                              DataCell(
                                Center(
                                  child: Text(
                                    '$userTotal',
                                    style:
                                    const TextStyle(
                                      fontWeight:
                                      FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],

                    // =================================================
                    // GRAND TOTAL
                    // =================================================

                    DataRow(
                      color:
                      WidgetStateProperty.all(
                        Colors.lightBlue.shade100,
                      ),

                      cells: [

                        const DataCell(
                          SizedBox(
                            width: 220,
                            child: Text(
                              'Grand Total',
                              style:
                              TextStyle(
                                fontWeight:
                                FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        ...cityStatuses.map(
                              (status) {
                            return DataCell(
                              Center(
                                child: Text(
                                  '${grandCityTotal[status] ?? 0}',
                                  style:
                                  const TextStyle(
                                    fontWeight:
                                    FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        DataCell(
                          Center(
                            child: Text(
                              '$grandTotal',
                              style:
                              const TextStyle(
                                fontWeight:
                                FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // NUMBER CELL
  // =====================================================

  DataCell _numberCell(
      int? value, {
        bool bold = false,
      }) {
    return DataCell(
      SizedBox(
        width: 70,

        child: Center(
          child: Text(
            '${value ?? 0}',

            style: TextStyle(
              fontWeight: bold
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  // =====================================================
  // STATUS BOX
  // =====================================================

  Widget _statusBox(
      String title,
      int count,
      ) {
    return Container(
      constraints:
      const BoxConstraints(
        minWidth: 100,
      ),

      padding:
      const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 12,
      ),

      decoration: BoxDecoration(
        borderRadius:
        BorderRadius.circular(10),


        color: Colors.white,
      ),

      child: Column(
        children: [
          Text(
            title,

            style: TextStyle(
              fontSize: 12,
              fontWeight:
              FontWeight.w600,
              color:
              statusColor(title),
            ),
          ),

          const SizedBox(height: 5),

          Text(
            count.toString(),

            style: const TextStyle(
              fontSize: 20,
              fontWeight:
              FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}