import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/order_model.dart';
import '../config/sslcommerz_config.dart';

class PaymentService {
  /// Initiates the SSLCommerz payment session by calling their API.
  /// Returns the GatewayPageURL if successful, otherwise throws an Exception.
  Future<String> initiateSslCommerzPayment(OrderModel order) async {
    final url = Uri.parse('${SSLCommerzConfig.sandboxBaseUrl}/gwprocess/v4/api.php');
    
    // Construct the payload as per SSLCommerz API documentation
    final Map<String, String> body = {
      'store_id': SSLCommerzConfig.storeId,
      'store_passwd': SSLCommerzConfig.storePassword,
      'total_amount': order.totalAmount.toStringAsFixed(2),
      'currency': 'BDT',
      'tran_id': order.id.isEmpty ? DateTime.now().millisecondsSinceEpoch.toString() : order.id,
      'success_url': SSLCommerzConfig.successUrl,
      'fail_url': SSLCommerzConfig.failUrl,
      'cancel_url': SSLCommerzConfig.cancelUrl,
      'cus_name': order.buyerName.isNotEmpty ? order.buyerName : 'Test Customer',
      'cus_email': order.buyerEmail.isNotEmpty ? order.buyerEmail : 'test@test.com',
      'cus_add1': 'Dhaka',
      'cus_city': 'Dhaka',
      'cus_country': 'Bangladesh',
      'cus_phone': order.buyerPhone.isNotEmpty ? order.buyerPhone : '01700000000',
      'shipping_method': 'NO',
      'product_name': 'UniMarket Order',
      'product_category': 'General',
      'product_profile': 'general',
      'num_of_item': order.items.length.toString(),
      'value_a': order.id, // Store orderId for callback tracking if needed
    };

    try {
      final response = await http.post(url, body: body);
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        
        if (data['status'] == 'SUCCESS' && data.containsKey('GatewayPageURL')) {
          return data['GatewayPageURL'];
        } else {
          final errorReason = data['failedreason'] ?? 'Unknown error from SSLCommerz';
          throw Exception('Payment Initialization Failed: $errorReason');
        }
      } else {
        throw Exception('Failed to connect to SSLCommerz API (Status: ${response.statusCode})');
      }
    } catch (e) {
      debugPrint('Error initiating SSLCommerz payment: $e');
      throw Exception('Failed to initiate payment. Please check your connection and try again.');
    }
  }
}
