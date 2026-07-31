class SSLCommerzConfig {
  // Note: In production, SSLCommerz session creation should be handled by a secure backend.
  // Note: Store password must not remain inside Flutter client in production.
  // Note: Payment success must be validated through backend/IPN before marking order as paid.

  // IMPORTANT: For sandbox testing only. 
  // In production, these should NEVER be exposed in the frontend app. 
  // You should store these on your backend server.
  static const String storeId = 'unima6a109441506af';
  static const String storePassword = 'unima6a109441506af@ssl';
  static const bool isSandbox = true;

  static const String sandboxBaseUrl = 'https://sandbox.sslcommerz.com';
  
  static const String successUrl = 'https://unimarket.com/success';
  static const String failUrl = 'https://unimarket.com/fail';
  static const String cancelUrl = 'https://unimarket.com/cancel';
}
