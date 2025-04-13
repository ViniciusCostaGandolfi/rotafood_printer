import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:rotafood_printer/models/merchant_user_dto.dart';

MerchantUserDto? decodeToken(BuildContext context, String token) {
  try {
    Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
    
    if (decodedToken.containsKey("merchantUser")) {
      return MerchantUserDto.fromJson(decodedToken["merchantUser"]);
    }
    
    return null;
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Erro ao decodificar o token!"),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
    
    return null;
  }
}
