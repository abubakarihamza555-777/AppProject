import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/report_model.dart';
import '../../customer/models/order_model.dart';
import '../../auth/models/user_model.dart';

class ReportService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<OrderReport> generateOrderReport(DateTime startDate, DateTime endDate) async {
    try {
      final orders = await _supabase
          .from('orders')
          .select()
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String());

      final orderList = (orders as List)
          .map((order) => OrderModel.fromJson(order))
          .toList();

      final completedOrders = orderList
          .where((o) => o.status == 'delivered' || o.status == 'completed')
          .toList();
      
      final cancelledOrders = orderList
          .where((o) => o.status == 'cancelled' || o.status == 'rejected')
          .toList();

      final ordersByStatus = {
        'pending': orderList.where((o) => o.status == 'pending').length,
        'confirmed': orderList.where((o) => o.status == 'confirmed').length,
        'preparing': orderList.where((o) => o.status == 'preparing').length,
        'out_for_delivery': orderList.where((o) => o.status == 'out_for_delivery').length,
        'delivered': orderList.where((o) => o.status == 'delivered').length,
        'completed': orderList.where((o) => o.status == 'completed').length,
        'cancelled': cancelledOrders.length,
        'rejected': orderList.where((o) => o.status == 'rejected').length,
      };

      final revenueByVendor = <String, double>{};
      for (var order in completedOrders) {
        revenueByVendor[order.vendorId] =
            (revenueByVendor[order.vendorId] ?? 0) + order.totalAmount;
      }

      final dailyOrders = <Map<String, dynamic>>[];
      for (var i = 0; i <= endDate.difference(startDate).inDays; i++) {
        final date = startDate.add(Duration(days: i));
        final dayOrders = orderList.where((o) =>
            o.createdAt.year == date.year &&
            o.createdAt.month == date.month &&
            o.createdAt.day == date.day).length;
        
        dailyOrders.add({
          'date': date,
          'orders': dayOrders,
        });
      }

      final totalRevenue = completedOrders.fold(0.0, (sum, o) => sum + o.totalAmount);
      final averageOrderValue = completedOrders.isEmpty ? 0 : totalRevenue / completedOrders.length;

      return OrderReport(
        totalOrders: orderList.length,
        completedOrders: completedOrders.length,
        cancelledOrders: cancelledOrders.length,
        totalRevenue: totalRevenue,
        averageOrderValue: averageOrderValue.toDouble(),
        ordersByStatus: ordersByStatus,
        revenueByVendor: revenueByVendor,
        dailyOrders: dailyOrders,
      );
    } catch (e) {
      throw Exception('Failed to generate order report: $e');
    }
  }

  Future<UserReport> generateUserReport(DateTime startDate, DateTime endDate) async {
    try {
      final users = await _supabase
          .from('users')
          .select()
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String());

      final userList = (users as List)
          .map((user) => UserModel.fromJson(user))
          .toList();

      final newUsers = userList.length;
      
      final activeUsers = userList.where((u) => u.isActive).length;
      final inactiveUsers = userList.length - activeUsers;

      final usersByRole = {
        'customer': userList.where((u) => u.role == 'customer').length,
        'vendor': userList.where((u) => u.role == 'vendor').length,
        'admin': userList.where((u) => u.role == 'admin').length,
      };

      final userGrowth = <Map<String, dynamic>>[];
      for (var i = 0; i <= endDate.difference(startDate).inDays; i++) {
        final date = startDate.add(Duration(days: i));
        final dayUsers = userList.where((u) =>
            u.createdAt.year == date.year &&
            u.createdAt.month == date.month &&
            u.createdAt.day == date.day).length;
        
        userGrowth.add({
          'date': date,
          'new_users': dayUsers,
        });
      }

      return UserReport(
        totalUsers: userList.length,
        newUsers: newUsers,
        activeUsers: activeUsers,
        inactiveUsers: inactiveUsers,
        usersByRole: usersByRole,
        usersByRegion: {}, // Implement if you have region data
        userGrowth: userGrowth,
      );
    } catch (e) {
      throw Exception('Failed to generate user report: $e');
    }
  }

  Future<String> exportReportToCSV(OrderReport report) async {
    try {
      String esc(Object? v) {
        final s = (v ?? '').toString().replaceAll('"', '""');
        return '"$s"';
      }

      final rows = <List<Object?>>[
        ['Metric', 'Value'],
        ['Total Orders', report.totalOrders],
        ['Completed Orders', report.completedOrders],
        ['Cancelled Orders', report.cancelledOrders],
        ['Total Revenue', report.totalRevenue],
        ['Average Order Value', report.averageOrderValue],
        [null, null],
        ['Orders by Status', null],
        ...report.ordersByStatus.entries.map((e) => [e.key, e.value]),
        [null, null],
        ['Revenue by Vendor', null],
        ...report.revenueByVendor.entries.map((e) => [e.key, e.value]),
      ];

      final csv = rows.map((r) => r.map(esc).join(',')).join('\n');
      
      // Store in Supabase storage
      final fileName = 'report_${DateTime.now().millisecondsSinceEpoch}.csv';
      await _supabase.storage.from('reports').uploadBinary(
        fileName,
        utf8.encode(csv),
      );
      
      return _supabase.storage.from('reports').getPublicUrl(fileName);
    } catch (e) {
      throw Exception('Failed to export report to CSV: $e');
    }
  }

  Future<String> exportReportToPDF(OrderReport report) async {
    try {
      final pdf = pw.Document();
      
      pdf.addPage(
        pw.MultiPage(
          build: (context) => [
            pw.Header(
              level: 0,
              child: pw.Text('Order Report', style: const pw.TextStyle(fontSize: 24)),
            ),
            pw.SizedBox(height: 20),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Total Orders: ${report.totalOrders}'),
                pw.Text('Completed Orders: ${report.completedOrders}'),
                pw.Text('Total Revenue: TZS ${report.totalRevenue.toStringAsFixed(2)}'),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Header(
              level: 1,
              child: pw.Text('Orders by Status'),
            ),
            pw.Table(
              border: pw.TableBorder.all(),
              children: [
                pw.TableRow(
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Status')),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Count')),
                  ],
                ),
                ...report.ordersByStatus.entries.map((entry) => pw.TableRow(
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(entry.key)),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(entry.value.toString())),
                  ],
                )),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Header(
              level: 1,
              child: pw.Text('Daily Orders'),
            ),
            pw.Table(
              border: pw.TableBorder.all(),
              children: [
                pw.TableRow(
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Date')),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Orders')),
                  ],
                ),
                ...report.dailyOrders.map((day) => pw.TableRow(
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(day['date'].toString())),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(day['orders'].toString())),
                  ],
                )),
              ],
            ),
          ],
        ),
      );

      final pdfBytes = await pdf.save();
      
      final fileName = 'report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      await _supabase.storage.from('reports').uploadBinary(
        fileName,
        pdfBytes,
      );
      
      return _supabase.storage.from('reports').getPublicUrl(fileName);
    } catch (e) {
      throw Exception('Failed to export report to PDF: $e');
    }
  }
} 
