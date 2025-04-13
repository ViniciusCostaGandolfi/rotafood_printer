import 'package:flutter/material.dart';
import 'package:rotafood_printer/models/merchant_user_dto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

const tokenKey = 'ROTAFOOD_TOKEN';

class TokenWidget extends StatefulWidget {
  /// Callback para notificar o widget pai sempre que o token for alterado.
  final Function(String? token, MerchantUserDto? user) onTokenChanged;

  const TokenWidget({
    super.key,
    required this.onTokenChanged,
  });

  @override
  _TokenWidgetState createState() => _TokenWidgetState();
}

class _TokenWidgetState extends State<TokenWidget> {
  final TextEditingController _tokenController = TextEditingController();
  String? _error;
  MerchantUserDto? _merchantUser;
  String? _maskedToken; 

  @override
  void initState() {
    super.initState();
    _loadSavedToken();
  }

  Future<void> _loadSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString(tokenKey);

    if (savedToken != null && savedToken.isNotEmpty) {
      _validateAndSetToken(context, savedToken);
    }
  }

  void _validateAndSetToken(BuildContext context, String token) async {
    try {
      if (JwtDecoder.isExpired(token)) {
        throw Exception("Token expirado!");
      }

      final decodedToken = JwtDecoder.decode(token);

      if (!decodedToken.containsKey("merchantUser")) {
        throw Exception("Token inválido! Sem dados de usuário.");
      }

      final user = MerchantUserDto.fromJson(decodedToken["merchantUser"]);

      setState(() {
        _merchantUser = user;
        _maskedToken = '*******';
        _error = null;
      });
      await _saveToken(token);

      widget.onTokenChanged(token, user);
    } catch (e) {
      await _clearToken();
      _showErrorSnackbar(context, e.toString());
    }
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
  }

  void _onSaveTokenPressed(BuildContext context) async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      setState(() => _error = 'Token vazio!');
      return;
    }

    _validateAndSetToken(context, token);
  }

  Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);

    setState(() {
      _tokenController.clear();
      _merchantUser = null;
      _maskedToken = null;
      _error = null;
    });

    widget.onTokenChanged(null, null);
  }

  // Exibe snackbar de erro
  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_merchantUser != null)
          _buildUserInfoView()
        else
          _buildTokenInputView(),

        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              _error!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
      ],
    );
  }

  // Se não temos token salvo, mostra input
  Widget _buildTokenInputView() {
    return Column(
      children: [
        TextField(
          controller: _tokenController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Cole seu token (JWT) aqui',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => _onSaveTokenPressed(context),
          child: const Text('Salvar Token'),
        ),
      ],
    );
  }

  // Se já temos token salvo, mostra dados do usuário
  Widget _buildUserInfoView() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(Icons.account_circle, size: 32),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _merchantUser!.name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  _maskedToken ?? '*****',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.red),
          onPressed: _clearToken,
        ),
      ],
    );
  }
}
