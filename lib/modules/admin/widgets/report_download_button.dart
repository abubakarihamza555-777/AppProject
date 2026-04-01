import 'package:flutter/material.dart';
import '../services/report_service.dart';
import '../models/report_model.dart';

class ReportDownloadButton extends StatelessWidget {
  final ReportService reportService;
  final OrderReport report;
  final String format;

  const ReportDownloadButton({
    super.key,
    required this.reportService,
    required this.report,
    required this.format,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () async {
        try {
          final String url;
          if (format == 'CSV') {
            url = await reportService.exportReportToCSV(report);
          } else {
            url = await reportService.exportReportToPDF(report);
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Report exported successfully!'),
              action: SnackBarAction(
                label: 'View',
                onPressed: () {
                  // TODO: open url (e.g. url_launcher). Keep for now.
                  // ignore: unused_local_variable
                  final _ = url;
                },
              ),
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to export: $e')),
          );
        }
      },
      icon: Icon(format == 'CSV' ? Icons.table_chart : Icons.picture_as_pdf),
      label: Text('Export as $format'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
} 
