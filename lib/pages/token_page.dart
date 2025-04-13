import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:rotafood_printer/widgets/printer_select_url.dart';
import 'package:rotafood_printer/widgets/token_widget.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';


class TokenPage extends StatefulWidget {
  const TokenPage({super.key});

  @override
  State<TokenPage> createState() => _TokenPageState();
}

class _TokenPageState extends State<TokenPage> {
  String? _error;
  String? _currentToken;
  Printer? _selectedPrinter;
  bool _isPrinterReady = false;
  WebSocketChannel? _channel;
  double _selectedWidthMm = 58.0;

  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadPrinterWidth();
  }

  Future<void> _loadPrinterWidth() async {
    final prefs = await SharedPreferences.getInstance();
    final savedWidth = prefs.getDouble('printer_width') ?? 58.0;
    setState(() {
      _selectedWidthMm = savedWidth;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuração de Impressão RotaFood')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TokenWidget(
              onTokenChanged: (token, merchantUser) {
                setState(() {
                  _currentToken = token;
                });
              },
            ),
            const SizedBox(height: 16),
            PrinterSelectionWidget(
              onPrinterSelected: (printer, isReady) {
                setState(() {
                  _selectedPrinter = printer;
                  _isPrinterReady = isReady;
                });
              },
            ),
             const SizedBox(height: 16),
            Row(
              children: [
                const Text("Largura da Impressora: "),
                const SizedBox(width: 12),
                DropdownButton<double>(
                  value: _selectedWidthMm,
                  items: const [
                    DropdownMenuItem(value: 58.0, child: Text('58mm')),
                    DropdownMenuItem(value: 80.0, child: Text('80mm')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedWidthMm = value!;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isPrinterReady && _currentToken != null
                  ? _startWebSocketListening
                  : null,
              child: const Text('Conectar e Imprimir em tempo real'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _startWebSocketListening() {
    if (_currentToken == null || _currentToken!.isEmpty) {
      setState(() => _error = 'Token não encontrado!');
      return;
    }

    final decodedToken = JwtDecoder.decode(_currentToken!);
    final merchantId = decodedToken['merchantUser']['merchantId'];
    final wsUrl = Uri.parse(
        'ws://localhost:8080/v1/ws/print?token=$_currentToken');

    _channel = WebSocketChannel.connect(wsUrl);

    _channel!.stream.listen(
      (message) async {
        await _printDocument(message);
        setState(() => _error = 'Comanda recebida e impressa!');
      },
      onDone: () {
        setState(() => _error = 'Conexão WebSocket fechada.');
      },
      onError: (error) {
        setState(() => _error = 'Erro na conexão WebSocket: $error');
      },
    );

    setState(() => _error = 'Conexão WebSocket iniciada para o merchant $merchantId!');
  }

  Future<void> _printDocument(String text) async {
    if (_selectedPrinter == null) return;

    final doc = pw.Document();

    final customPageFormat = PdfPageFormat(
      _selectedWidthMm * PdfPageFormat.mm,
      double.infinity,
    );

    doc.addPage(
      pw.Page(
        pageFormat: customPageFormat,
        build: (pw.Context context) => pw.Container(
          width: _selectedWidthMm * PdfPageFormat.mm,
          child: pw.Text(text),
        ),
      ),
    );

    await Printing.directPrintPdf(
      printer: _selectedPrinter!,
      onLayout: (format) async => doc.save(),
    );
  }
}
