import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:shared_preferences/shared_preferences.dart';

const printerKey = 'ROTAFOOD_PRINTER_URL';


class PrinterSelectionWidget extends StatefulWidget {
  final Function(Printer?, bool) onPrinterSelected;

  const PrinterSelectionWidget({
    super.key,
    required this.onPrinterSelected,
  });

  @override
  State<PrinterSelectionWidget> createState() => _PrinterSelectionWidgetState();
}

class _PrinterSelectionWidgetState extends State<PrinterSelectionWidget> {
  List<Printer> _availablePrinters = [];
  Printer? _selectedPrinter;
  bool _isPrinterReady = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSavedPrinter();
    _fetchPrinters();
  }

  Future<void> _loadSavedPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPrinterUrl = prefs.getString(printerKey);
    if (savedPrinterUrl != null && savedPrinterUrl.isNotEmpty) {
    }
  }

  Future<void> _savePrinterUrl(String printerUrl) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(printerKey, printerUrl);
  }

  Future<void> _fetchPrinters() async {
    final printers = await Printing.listPrinters();
    setState(() {
      _availablePrinters = printers;
    });

    // Tenta resgatar a impressora que foi salva anteriormente
    final prefs = await SharedPreferences.getInstance();
    final savedPrinterUrl = prefs.getString(printerKey);

    if (savedPrinterUrl != null && savedPrinterUrl.isNotEmpty) {
      final matchingPrinter = _availablePrinters
          .where((p) => p.url == savedPrinterUrl)
          .isNotEmpty
          ? _availablePrinters.firstWhere((p) => p.url == savedPrinterUrl)
          : null;

      if (matchingPrinter != null) {
        _onSelectPrinter(matchingPrinter);
      }
    }
  }

  Future<void> _onSelectPrinter(Printer printer) async {
    setState(() => _error = null);

    // Faz um teste simples de impressão em branco para conferir se a impressora
    // está pronta.
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Container(),
      ),
    );

    try {
      await Printing.directPrintPdf(
        printer: printer,
        onLayout: (format) async => doc.save(),
      );

      _selectedPrinter = printer;
      _isPrinterReady = true;
      await _savePrinterUrl(printer.url);

      setState(() {});

      // Notifica o componente pai da nova seleção
      widget.onPrinterSelected(_selectedPrinter, _isPrinterReady);
    } catch (e) {
      setState(() {
        _error =
            'Não foi possível usar a impressora "${printer.name}". Erro: $e';
        _selectedPrinter = null;
        _isPrinterReady = false;
      });
      // Notifica o pai que houve erro e que não temos uma impressora pronta
      widget.onPrinterSelected(null, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Exibe alguma mensagem de erro se houver
        if (_error != null) ...[
          Text(
            _error!,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 8),
        ],

        DropdownButton<Printer>(
          value: _selectedPrinter,
          hint: const Text('Selecione uma impressora'),
          isExpanded: true,
          items: _availablePrinters.map((printer) {
            return DropdownMenuItem(
              value: printer,
              child: Text(printer.name),
            );
          }).toList(),
          onChanged: (printer) {
            if (printer != null) {
              _onSelectPrinter(printer);
            }
          },
        ),
      ],
    );
  }
}
