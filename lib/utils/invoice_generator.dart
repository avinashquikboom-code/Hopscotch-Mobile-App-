import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hopscotch/models/order_model.dart';
import 'package:intl/intl.dart';

class InvoiceGenerator {
  /// Generates and previews/prints/downloads a PDF invoice for a given order.
  static Future<void> generateAndDownloadInvoice({
    required OrderModel order,
    String storeName = 'FCI SELLER',
    String storeAddress = 'Plot No. 42, Sector 18, Commercial Hub, Navi Mumbai, MH - 400705',
    String storeGst = '27AAACH1234F1Z9',
    String contactEmail = 'support@fciseller.com',
  }) async {
    final pdf = pw.Document();

    final formattedDate = () {
      try {
        final dt = DateTime.parse(order.orderDate);
        return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
      } catch (_) {
        return order.orderDate.isNotEmpty ? order.orderDate : DateFormat('dd MMM yyyy').format(DateTime.now());
      }
    }();

    final currencyFmt = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 2);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // ── HEADER ───────────────────────────────────────────────────────
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      storeName,
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.teal800,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(storeAddress, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                    pw.Text('GSTIN: $storeGst | Support: $contactEmail', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.teal800,
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text(
                        'TAX INVOICE',
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text('Invoice #: INV-${order.id.replaceAll(RegExp(r'[^0-9A-Za-z]'), '').toUpperCase()}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Date: $formattedDate', style: const pw.TextStyle(fontSize: 8)),
                    pw.Text('Status: ${order.status.toUpperCase()}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 16),
            pw.Divider(thickness: 1, color: PdfColors.grey300),
            pw.SizedBox(height: 12),

            // ── BILLING & SHIPPING DETAILS ──────────────────────────────────
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('SHIPPED TO:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900)),
                        pw.SizedBox(height: 4),
                        pw.Text(order.shippingAddress.isNotEmpty ? order.shippingAddress : 'Customer Shipping Address', style: const pw.TextStyle(fontSize: 8)),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('PAYMENT INFORMATION:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900)),
                        pw.SizedBox(height: 4),
                        pw.Text('Method: ${order.paymentMethod}', style: const pw.TextStyle(fontSize: 8)),
                        if (order.trackingNumber != null && order.trackingNumber!.isNotEmpty)
                          pw.Text('Tracking #: ${order.trackingNumber}', style: const pw.TextStyle(fontSize: 8)),
                        pw.Text('Gateway: SSL 256-bit Encrypted', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 16),

            // ── PRODUCT DETAILS TABLE ───────────────────────────────────────
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(3.5),
                1: const pw.FlexColumnWidth(1),
                2: const pw.FlexColumnWidth(1.5),
                3: const pw.FlexColumnWidth(1.2),
                4: const pw.FlexColumnWidth(1.8),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.teal800),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Item Description', style: pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Qty', textAlign: pw.TextAlign.center, style: pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Price', textAlign: pw.TextAlign.right, style: pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Ship Fee', textAlign: pw.TextAlign.right, style: pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Total', textAlign: pw.TextAlign.right, style: pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold))),
                  ],
                ),
                ...order.items.map((item) {
                  final lineTotal = (item.product.price * item.quantity) + (item.product.shippingCharge * item.quantity);
                  return pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(item.product.title, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                            if (item.selectedSize != null || item.selectedColor != null)
                              pw.Text(
                                'Variant: ${item.selectedSize ?? ''} ${item.selectedColor ?? ''}'.trim(),
                                style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
                              ),
                          ],
                        ),
                      ),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${item.quantity}', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(currencyFmt.format(item.product.price), textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 8))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(item.product.shippingCharge > 0 ? currencyFmt.format(item.product.shippingCharge) : 'FREE', textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 8))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(currencyFmt.format(lineTotal), textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                    ],
                  );
                }),
              ],
            ),

            pw.SizedBox(height: 14),

            // ── SUMMARY & TOTALS BOX ────────────────────────────────────────
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Container(
                  width: 220,
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Column(
                    children: [
                      _pdfPriceRow('Items Subtotal:', currencyFmt.format(order.subtotal)),
                      pw.SizedBox(height: 3),
                      _pdfPriceRow('Shipping Fee:', currencyFmt.format(order.shippingFee)),
                      if (order.giftWrapped || order.giftWrapCharge > 0) ...[
                        pw.SizedBox(height: 3),
                        _pdfPriceRow('Gift Wrapping:', currencyFmt.format(order.giftWrapCharge)),
                      ],
                      pw.SizedBox(height: 3),
                      _pdfPriceRow('Tax Amount:', currencyFmt.format(order.taxAmount)),
                      pw.Divider(thickness: 0.5, color: PdfColors.grey400),
                      _pdfPriceRow('GRAND TOTAL:', currencyFmt.format(order.totalAmount), isTotal: true),
                    ],
                  ),
                ),
              ],
            ),

            pw.Spacer(),

            // ── FOOTER / LEGAL TERMS ────────────────────────────────────────
            pw.Divider(thickness: 0.5, color: PdfColors.grey400),
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Thank you for shopping with FCI Seller!', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900)),
                pw.Text('Computer-generated tax invoice. No signature required.', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
              ],
            ),
          ];
        },
      ),
    );

    final bytes = await pdf.save();
    final fileName = 'Invoice_${order.id.replaceAll(RegExp(r'[^0-9A-Za-z]'), '')}.pdf';

    try {
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(bytes);
      }
      // Opens system PDF share/save modal instantly
      await Printing.sharePdf(bytes: bytes, filename: fileName);
    } catch (e) {
      debugPrint('Share PDF fallback: $e');
      await Printing.layoutPdf(onLayout: (format) async => bytes, name: fileName);
    }
  }

  static pw.Widget _pdfPriceRow(String label, String value, {bool isTotal = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: isTotal ? 9 : 8,
            fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: isTotal ? PdfColors.teal900 : PdfColors.grey800,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: isTotal ? 10 : 8,
            fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: isTotal ? PdfColors.teal900 : PdfColors.black,
          ),
        ),
      ],
    );
  }
}
