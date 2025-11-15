import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/invoice.dart';

class PDFService {
  static Future<void> generateInvoicePDF(Invoice invoice) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildHeader(),
            pw.SizedBox(height: 20),
            _buildInvoiceInfo(invoice),
            pw.SizedBox(height: 20),
            _buildCustomerInfo(invoice),
            pw.SizedBox(height: 20),
            _buildItemsTable(invoice),
            pw.SizedBox(height: 20),
            _buildTotalSection(invoice),
            pw.SizedBox(height: 30),
            _buildFooter(),
          ];
        },
      ),
    );

    final Uint8List bytes = await pdf.save();
    
    await Printing.sharePdf(bytes: bytes, filename: '${invoice.invoiceNumber}.pdf');
  }

  static pw.Widget _buildHeader() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#1565C0'),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'ASHIRWAD INDUSTRIES',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Plastic Granules Manufacturing',
                style: pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.white,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'INVOICE',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildInvoiceInfo(Invoice invoice) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Invoice Number: ${invoice.invoiceNumber}',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 12,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Date: ${_formatDate(invoice.date)}',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Due Date: ${_formatDate(invoice.dueDate)}',
              style: const pw.TextStyle(fontSize: 10),
            ),
          ],
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: pw.BoxDecoration(
            color: _getStatusColor(invoice.status),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Text(
            invoice.status.toString().split('.').last.toUpperCase(),
            style: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildCustomerInfo(Invoice invoice) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Bill To:',
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          invoice.customerName,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Customer ID: ${invoice.customerId}',
          style: const pw.TextStyle(fontSize: 10),
        ),
      ],
    );
  }

  static pw.Widget _buildItemsTable(Invoice invoice) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 1),
      columnWidths: {
        0: const pw.FlexColumnWidth(4),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(2),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey),
          children: [
            _buildTableCell('Product', isHeader: true),
            _buildTableCell('Qty', isHeader: true),
            _buildTableCell('Rate', isHeader: true),
            _buildTableCell('Amount', isHeader: true),
          ],
        ),
        // Items
        ...invoice.items.map((item) {
          return pw.TableRow(
            decoration: pw.BoxDecoration(color: PdfColor.fromHex('#F5F5DC')),
            children: [
              _buildTableCell(item.product.name),
              _buildTableCell('${item.quantity}'),
              _buildTableCell('Rs ${item.unitPrice.toStringAsFixed(2)}'),
              _buildTableCell('Rs ${item.totalPrice.toStringAsFixed(2)}'),
            ],
          );
        }).toList(),
      ],
    );
  }

  static pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontSize: isHeader ? 12 : 10,
          color: isHeader ? PdfColors.white : PdfColors.black,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _buildTotalSection(Invoice invoice) {
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Container(
              width: 250,
              child: pw.Column(
                children: [
                  _buildTotalRow('Subtotal:', 'Rs ${invoice.subtotal.toStringAsFixed(2)}'),
                  pw.SizedBox(height: 4),
                  _buildTotalRow('Tax (${invoice.taxPercentage.toStringAsFixed(0)}%):', 'Rs ${invoice.taxAmount.toStringAsFixed(2)}'),
                  pw.SizedBox(height: 8),
                  pw.Divider(thickness: 1.5, color: PdfColors.black),
                  pw.SizedBox(height: 4),
                  _buildTotalRow(
                    'Total Amount:',
                    'Rs ${invoice.totalAmount.toStringAsFixed(2)}',
                    isTotal: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildTotalRow(String label, String amount, {bool isTotal = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
              fontSize: isTotal ? 14 : 12,
            ),
          ),
          pw.Text(
            amount,
            style: pw.TextStyle(
              fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
              fontSize: isTotal ? 14 : 12,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(16),
          decoration: const pw.BoxDecoration(
            color: PdfColors.grey,
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Terms & Conditions:',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                '- Payment is due within 30 days of invoice date',
                style: const pw.TextStyle(fontSize: 8),
              ),
              pw.Text(
                '- Late payments may incur additional charges',
                style: const pw.TextStyle(fontSize: 8),
              ),
              pw.Text(
                '- All products are subject to quality inspection',
                style: const pw.TextStyle(fontSize: 8),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Center(
          child: pw.Text(
            'Thank you for your business!',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  static PdfColor _getStatusColor(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.draft:
        return PdfColors.grey;
      case InvoiceStatus.pending:
        return PdfColor.fromHex('#FF9800');
      case InvoiceStatus.paid:
        return PdfColor.fromHex('#4CAF50');
      case InvoiceStatus.unpaid:
        return PdfColor.fromHex('#FF9800');
      case InvoiceStatus.overdue:
        return PdfColor.fromHex('#D32F2F');
    }
  }
}
