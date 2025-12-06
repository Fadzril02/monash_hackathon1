import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/subscription.dart';
import '../models/transaction.dart';
import '../models/safe_balance.dart';
import '../models/chat_message.dart';
import '../models/api_exception.dart';

class ApiService {
  /// Check if backend server is healthy
  Future<bool> checkHealth() async {
    try {
      final response = await http
          .get(Uri.parse('${ApiConfig.baseUrl}${ApiConfig.healthEndpoint}'))
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Get all active subscriptions for a user
  Future<List<Subscription>> getSubscriptions(String userExternalId) async {
    try {
      final uri = Uri.parse(
          '${ApiConfig.baseUrl}${ApiConfig.subscriptionsEndpoint}?userExternalId=$userExternalId');

      print('📡 Fetching subscriptions from: $uri');

      final response = await http.get(uri);

      print('📥 Subscription response status: ${response.statusCode}');
      print('📥 Subscription response body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> subscriptionsList = data['subscriptions'];
          print('✅ Parsing ${subscriptionsList.length} subscriptions...');

          final subscriptions = <Subscription>[];
          for (var i = 0; i < subscriptionsList.length; i++) {
            try {
              final sub = Subscription.fromJson(subscriptionsList[i]);
              subscriptions.add(sub);
            } catch (e) {
              print('❌ Failed to parse subscription $i: $e');
            }
          }

          print('✅ Successfully parsed ${subscriptions.length} subscriptions');
          return subscriptions;
        } else {
          throw ApiException(
            message: data['error'] ?? 'Failed to load subscriptions',
            statusCode: response.statusCode,
          );
        }
      } else {
        final error = jsonDecode(response.body);
        throw ApiException(
          message: error['error'] ?? 'Failed to load subscriptions',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      print('❌ getSubscriptions error: $e');
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Network error: Unable to connect to server. $e',
      );
    }
  }

  /// Add a new subscription
  Future<Map<String, dynamic>> addSubscription({
    required String userExternalId,
    required String subscriptionName,
    required double amount,
    required String type,
    required String nextDueDate,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.addSubscriptionEndpoint}'),
        headers: ApiConfig.jsonHeaders,
        body: jsonEncode({
          'userExternalId': userExternalId,
          'subscriptionName': subscriptionName,
          'amount': amount,
          'type': type,
          'nextDueDate': nextDueDate,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return data;
      } else {
        throw ApiException(
          message: data['error'] ?? 'Failed to add subscription',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Network error: $e');
    }
  }

  /// Cancel a subscription
  Future<Map<String, dynamic>> cancelSubscription({
    required String userExternalId,
    required String liabilityId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(
            '${ApiConfig.baseUrl}${ApiConfig.cancelSubscriptionEndpoint}'),
        headers: ApiConfig.jsonHeaders,
        body: jsonEncode({
          'userExternalId': userExternalId,
          'liabilityId': liabilityId,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return data;
      } else {
        throw ApiException(
          message: data['error'] ?? 'Failed to cancel subscription',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Network error: $e');
    }
  }

  /// Reload money (deposit)
  Future<Transaction> reloadMoney({
    required String userExternalId,
    required double amount,
    String? description,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.reloadEndpoint}'),
        headers: ApiConfig.jsonHeaders,
        body: jsonEncode({
          'userExternalId': userExternalId,
          'amount': amount,
          'description': description ?? 'Reload',
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return Transaction.fromJson(data['transaction']);
      } else {
        throw ApiException(
          message: data['error'] ?? 'Failed to reload money',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Network error: $e');
    }
  }

  /// Withdraw money
  Future<Transaction> withdrawMoney({
    required String userExternalId,
    required double amount,
    required String recipientName,
    String? description,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.withdrawEndpoint}'),
        headers: ApiConfig.jsonHeaders,
        body: jsonEncode({
          'userExternalId': userExternalId,
          'amount': amount,
          'recipientName': recipientName,
          'description': description,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return Transaction.fromJson(data['transaction']);
      } else if (response.statusCode == 400 &&
          data['safeBalance'] != null &&
          data['requestedAmount'] != null) {
        // Safe balance error
        throw SafeBalanceException(
          message: data['error'] ?? 'Insufficient safe balance',
          safeBalance: double.parse(data['safeBalance'].toString()),
          requestedAmount: double.parse(data['requestedAmount'].toString()),
          statusCode: response.statusCode,
        );
      } else {
        throw ApiException(
          message: data['error'] ?? 'Failed to withdraw money',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Network error: $e');
    }
  }

  /// Get safe balance from MCP tools
  Future<SafeBalance> getSafeBalance({
    required String userExternalId,
    int lookaheadDays = 30,
  }) async {
    try {
      // Get safe balance from view
      final balanceResponse = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.queryEndpoint}'),
        headers: ApiConfig.jsonHeaders,
        body: jsonEncode({
          'query': "SELECT * FROM v_user_safe_balance WHERE external_user_id = '$userExternalId'",
        }),
      );

      if (balanceResponse.statusCode != 200) {
        throw ApiException(
          message: 'Failed to get safe balance',
          statusCode: balanceResponse.statusCode,
        );
      }

      final balanceData = jsonDecode(balanceResponse.body);
      if (balanceData['data'] == null || (balanceData['data'] as List).isEmpty) {
        throw ApiException(message: 'User not found');
      }

      final row = balanceData['data'][0];

      // Get next payment info
      final nextPaymentResponse = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.queryEndpoint}'),
        headers: ApiConfig.jsonHeaders,
        body: jsonEncode({
          'query': """
            SELECT payment_date, amount, COUNT(*) as bill_count
            FROM v_upcoming_payments_30days
            WHERE external_user_id = '$userExternalId'
            GROUP BY payment_date, amount
            ORDER BY payment_date ASC
            LIMIT 1
          """,
        }),
      );

      DateTime? nextPaymentDate;
      double? nextPaymentAmount;
      int upcomingCount = 0;

      if (nextPaymentResponse.statusCode == 200) {
        final nextPaymentData = jsonDecode(nextPaymentResponse.body);
        if (nextPaymentData['data'] != null &&
            (nextPaymentData['data'] as List).isNotEmpty) {
          final nextPayment = nextPaymentData['data'][0];
          nextPaymentDate = DateTime.parse(nextPayment['payment_date']);
          nextPaymentAmount = double.parse(nextPayment['amount'].toString());
        }

        // Get count of all upcoming bills
        final countResponse = await http.post(
          Uri.parse('${ApiConfig.baseUrl}${ApiConfig.queryEndpoint}'),
          headers: ApiConfig.jsonHeaders,
          body: jsonEncode({
            'query': """
              SELECT COUNT(*) as count
              FROM v_upcoming_payments_30days
              WHERE external_user_id = '$userExternalId'
            """,
          }),
        );

        if (countResponse.statusCode == 200) {
          final countData = jsonDecode(countResponse.body);
          if (countData['data'] != null && (countData['data'] as List).isNotEmpty) {
            upcomingCount = int.parse(countData['data'][0]['count'].toString());
          }
        }
      }

      // Map the view columns to SafeBalance model
      return SafeBalance(
        userExternalId: row['external_user_id'],
        currentBalance: double.parse(row['current_balance'].toString()),
        upcomingLiabilities:
            double.parse(row['upcoming_liabilities_30days']?.toString() ?? '0'),
        safeBalance: double.parse(row['safe_balance'].toString()),
        status: row['status'] ?? 'HEALTHY',
        upcomingCount: upcomingCount,
        nextPaymentDate: nextPaymentDate,
        nextPaymentAmount: nextPaymentAmount,
        lookaheadDays: lookaheadDays,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Network error: $e');
    }
  }

  /// Chat with Claude AI assistant
  Future<ChatResponse> sendChatMessage({
    required String userExternalId,
    required String message,
    List<Map<String, String>>? conversationHistory,
  }) async {
    try {
      // Build messages array in the format backend expects
      final List<Map<String, String>> messages = [];

      // Add conversation history if exists
      if (conversationHistory != null && conversationHistory.isNotEmpty) {
        messages.addAll(conversationHistory);
      }

      // Add current user message
      messages.add({
        'role': 'user',
        'content': message,
      });

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.chatEndpoint}'),
        headers: ApiConfig.jsonHeaders,
        body: jsonEncode({
          'userExternalId': userExternalId,
          'messages': messages, // Backend expects 'messages' array
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ChatResponse.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        throw ApiException(
          message: error['error'] ?? 'Failed to send message',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Network error: Unable to connect to AI assistant. $e');
    }
  }
}
