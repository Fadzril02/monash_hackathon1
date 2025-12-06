import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../services/api_service.dart';
import '../services/projection_service.dart';
import '../models/subscription.dart';
import '../models/transaction.dart';
import '../models/safe_balance.dart';
import '../models/chat_message.dart';
import '../models/api_exception.dart';
import '../models/financial_analysis.dart';
import '../models/monthly_projection.dart';

class AppState extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final ProjectionService _projectionService = ProjectionService();
  final String userExternalId = ApiConfig.defaultUserExternalId;

  // State variables
  bool _isLoading = false;
  bool _isBackendConnected = false;
  String? _errorMessage;

  SafeBalance? _safeBalance;
  List<Subscription> _subscriptions = [];
  List<ChatMessage> _chatHistory = [];
  bool _isChatLoading = false;

  // Projection state
  FinancialAnalysis? _financialAnalysis;
  ProjectionResult? _projectionResult;
  bool _isProjectionLoading = false;

  // Getters
  bool get isLoading => _isLoading;
  bool get isBackendConnected => _isBackendConnected;
  String? get errorMessage => _errorMessage;
  SafeBalance? get safeBalance => _safeBalance;
  List<Subscription> get subscriptions => _subscriptions;
  List<ChatMessage> get chatHistory => _chatHistory;
  bool get isChatLoading => _isChatLoading;
  FinancialAnalysis? get financialAnalysis => _financialAnalysis;
  ProjectionResult? get projectionResult => _projectionResult;
  bool get isProjectionLoading => _isProjectionLoading;

  // Initialize app - check backend health and load data
  Future<void> initialize() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Check backend health
      _isBackendConnected = await _apiService.checkHealth();

      if (_isBackendConnected) {
        // Load initial data (don't wait for financial analysis to avoid blocking)
        await Future.wait([
          loadSafeBalance(),
          loadSubscriptions(),
        ]);

        // Load financial analysis without blocking (optional feature)
        loadFinancialAnalysis().catchError((e) {
          print('⚠️ Financial analysis not available: $e');
          // Don't set error message - this is an optional feature
        });
      } else {
        _errorMessage = 'Cannot connect to backend server';
      }
    } catch (e) {
      _errorMessage = 'Initialization failed: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load safe balance
  Future<void> loadSafeBalance() async {
    try {
      _safeBalance = await _apiService.getSafeBalance(
        userExternalId: userExternalId,
      );
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load safe balance: $e';
      notifyListeners();
    }
  }

  /// Load subscriptions
  Future<void> loadSubscriptions() async {
    try {
      print('📋 Loading subscriptions for $userExternalId...');
      _subscriptions = await _apiService.getSubscriptions(userExternalId);
      print('✅ Loaded ${_subscriptions.length} subscriptions');
      notifyListeners();
    } catch (e) {
      print('❌ Failed to load subscriptions: $e');
      _errorMessage = 'Failed to load subscriptions: $e';
      notifyListeners();
    }
  }

  /// Reload money
  Future<bool> reloadMoney(double amount, {String? description}) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final transaction = await _apiService.reloadMoney(
        userExternalId: userExternalId,
        amount: amount,
        description: description,
      );

      // Refresh data
      await loadSafeBalance();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e is ApiException ? e.message : 'Failed to reload: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Withdraw money
  Future<bool> withdrawMoney(
    double amount,
    String recipientName, {
    String? description,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final transaction = await _apiService.withdrawMoney(
        userExternalId: userExternalId,
        amount: amount,
        recipientName: recipientName,
        description: description,
      );

      // Refresh data
      await loadSafeBalance();

      _isLoading = false;
      notifyListeners();
      return true;
    } on SafeBalanceException catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e is ApiException ? e.message : 'Failed to withdraw: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Add subscription
  Future<bool> addSubscription({
    required String name,
    required double amount,
    required String type,
    required DateTime nextDueDate,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _apiService.addSubscription(
        userExternalId: userExternalId,
        subscriptionName: name,
        amount: amount,
        type: type,
        nextDueDate:
            '${nextDueDate.year}-${nextDueDate.month.toString().padLeft(2, '0')}-${nextDueDate.day.toString().padLeft(2, '0')}',
      );

      // Refresh data
      await Future.wait([
        loadSubscriptions(),
        loadSafeBalance(),
      ]);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage =
          e is ApiException ? e.message : 'Failed to add subscription: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Cancel subscription
  Future<bool> cancelSubscription(String liabilityId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _apiService.cancelSubscription(
        userExternalId: userExternalId,
        liabilityId: liabilityId,
      );

      // Refresh data
      await Future.wait([
        loadSubscriptions(),
        loadSafeBalance(),
      ]);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage =
          e is ApiException ? e.message : 'Failed to cancel subscription: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Send chat message
  Future<void> sendChatMessage(String message) async {
    // Add user message to history first
    final userMessage = ChatMessage(role: 'user', content: message);
    _chatHistory.add(userMessage);
    _isChatLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Convert chat history to API format (excluding the message we just added)
      final conversationHistory = _chatHistory
          .where((msg) => msg != userMessage) // Exclude the current message
          .map((msg) => {
                'role': msg.role,
                'content': msg.content,
              })
          .toList();

      print('📤 Sending chat message to backend...');

      // Send message to API
      final response = await _apiService.sendChatMessage(
        userExternalId: userExternalId,
        message: message,
        conversationHistory: conversationHistory,
      );

      print('✅ Received response from Claude: ${response.response.substring(0, 50)}...');

      // Add assistant response to history
      final assistantMessage = ChatMessage(
        role: 'assistant',
        content: response.response,
        timestamp: response.timestamp,
        toolsUsed: response.toolsUsed,
      );
      _chatHistory.add(assistantMessage);

      _isChatLoading = false;
      notifyListeners();

      // Refresh safe balance in case it changed
      await loadSafeBalance();
    } catch (e) {
      print('❌ Chat error: $e');

      // Add error message to chat
      final errorMessage = ChatMessage(
        role: 'assistant',
        content: '❌ Sorry, I encountered an error: ${e is ApiException ? e.message : e.toString()}',
        timestamp: DateTime.now(),
      );
      _chatHistory.add(errorMessage);

      _errorMessage = e is ApiException ? e.message : 'Failed to send message: $e';
      _isChatLoading = false;
      notifyListeners();
    }
  }

  /// Clear chat history
  void clearChatHistory() {
    _chatHistory.clear();
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Load financial analysis
  Future<void> loadFinancialAnalysis() async {
    try {
      print('📊 Loading financial analysis...');
      _financialAnalysis = await _apiService.getFinancialAnalysis(
        userExternalId: userExternalId,
      );

      print('✅ Financial analysis loaded successfully');

      // Calculate projections after loading analysis
      if (_financialAnalysis != null && _safeBalance != null) {
        print('📈 Calculating projections...');
        calculateProjections();
      }

      notifyListeners();
    } catch (e) {
      print('⚠️ Financial analysis not available: $e');
      // Don't set global error - this is an optional feature
      // The prediction tab will show "No financial data available"
      _financialAnalysis = null;
      notifyListeners();
    }
  }

  /// Calculate baseline and scenario projections
  void calculateProjections({List<WhatIfScenario>? scenarios}) {
    if (_financialAnalysis == null || _safeBalance == null) {
      print('⚠️ Cannot calculate projections: missing data');
      return;
    }

    try {
      _isProjectionLoading = true;
      notifyListeners();

      _projectionResult = _projectionService.calculateProjections(
        analysis: _financialAnalysis!,
        subscriptions: _subscriptions,
        currentBalance: _safeBalance!.currentBalance,
        scenarios: scenarios,
      );

      print('✅ Projections calculated successfully');
      _isProjectionLoading = false;
      notifyListeners();
    } catch (e) {
      print('❌ Failed to calculate projections: $e');
      _isProjectionLoading = false;
      notifyListeners();
    }
  }

  /// Add a What-If scenario
  Future<void> addWhatIfScenario(WhatIfScenario scenario) async {
    if (_financialAnalysis == null || _safeBalance == null) {
      _errorMessage = 'Cannot calculate scenarios without financial data';
      notifyListeners();
      return;
    }

    try {
      _isProjectionLoading = true;
      notifyListeners();

      // Get existing scenarios
      final existingScenarios = _projectionResult?.scenarios.keys
              .map((name) => WhatIfScenario(name: name))
              .toList() ??
          [];

      // Add new scenario
      existingScenarios.add(scenario);

      // Recalculate all projections
      calculateProjections(scenarios: existingScenarios);
    } catch (e) {
      _errorMessage = 'Failed to add scenario: $e';
      _isProjectionLoading = false;
      notifyListeners();
    }
  }

  /// Remove a What-If scenario
  void removeWhatIfScenario(String scenarioName) {
    if (_projectionResult == null) return;

    final updatedScenarios = Map<String, List<MonthlyProjection>>.from(
        _projectionResult!.scenarios);
    updatedScenarios.remove(scenarioName);

    _projectionResult = ProjectionResult(
      baseline: _projectionResult!.baseline,
      scenarios: updatedScenarios,
    );

    notifyListeners();
  }
}
