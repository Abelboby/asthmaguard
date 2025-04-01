import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class AIService {
  // API Key would typically come from environment variables or secured storage
  // For this demo, we're using a placeholder - you'll need to replace this with a real API key
  final String _apiKey = 'AIzaSyCsv9OG-Z-IO-CBRx4NVXECKisVOXb6Uuo';

  // System prompt that restricts the AI to only provide asthma-related information
  final String _systemPrompt = '''
You are an AI assistant specialized in providing accurate information about asthma. 
Your responses should be focused on medical facts, best practices, and helpful advice related to asthma management.

Only answer questions related to asthma and respiratory health. If asked about unrelated topics, politely redirect 
the conversation back to asthma education. Be supportive, clear, and compassionate in your responses.

Important: Always clarify that you're providing general information, not personalized medical advice, 
and encourage users to consult healthcare professionals for specific concerns. Never provide dangerous advice 
that could harm someone or contradict established medical guidelines for asthma care.
''';

  // Model instance
  GenerativeModel? _model;

  // Chat history as strings for simplicity
  List<String> _chatHistory = [];

  AIService() {
    _initModel();
    // Initialize chat history with system prompt
    _chatHistory.add("System: $_systemPrompt");
  }

  // Initialize the model
  void _initModel() {
    try {
      // Try with gemini-pro first (most widely supported)
      _model = GenerativeModel(
        model: 'gemini-1.5-pro',
        apiKey: _apiKey,
      );

      if (kDebugMode) {
        print('Model initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing model: $e');
      }
    }
  }

  // Get a response from the AI assistant for asthma-related queries
  Future<String> getAsthmaResponse(String query) async {
    if (_model == null) {
      _initModel();

      if (_model == null) {
        throw Exception('Failed to initialize AI model');
      }
    }

    try {
      // Add the user query to chat history
      _chatHistory.add("User: $query");

      // Prepare final prompt with all chat history
      final prompt =
          'Based on the following conversation, please answer the user\'s latest question as an asthma specialist. '
          'Remember to stick to asthma-related information only.\n\n'
          '${_chatHistory.join("\n\n")}';

      // Send the prompt to the AI
      final response = await _model!.generateContent([Content.text(prompt)]);

      // Get the text response from the AI
      final responseText = response.text;

      // Fallback response if the AI response is empty
      if (responseText == null || responseText.isEmpty) {
        return 'I apologize, but I couldn\'t generate a response. Please try asking your question differently.';
      }

      // Add the response to the chat history
      _chatHistory.add("Assistant: $responseText");

      // Keep chat history to a reasonable size
      if (_chatHistory.length > 11) {
        // System prompt + 5 exchanges
        _chatHistory = [_chatHistory.first] +
            _chatHistory.sublist(_chatHistory.length - 10);
      }

      return responseText;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting response from AI: $e');
      }

      // Try to reinitialize the model
      _initModel();

      // Throw a user-friendly error message
      throw Exception('Error getting response from AI: $e');
    }
  }

  // Method for simulating responses when API is not available (development/testing)
  String getSimulatedResponse(String query) {
    query = query.toLowerCase();

    if (!_isAsthmaRelated(query)) {
      return "I'm sorry, but I can only provide information about asthma. For other topics, please consult appropriate resources or healthcare professionals.";
    }

    if (query.contains("trigger") || query.contains("cause")) {
      return "Common asthma triggers include allergens (pollen, dust mites, pet dander), irritants (smoke, pollution), weather changes, exercise, respiratory infections, and stress. Identifying your personal triggers is important for managing asthma effectively.";
    } else if (query.contains("symptom")) {
      return "Common asthma symptoms include wheezing, shortness of breath, chest tightness, and coughing (especially at night). Symptoms can vary from mild to severe and may worsen during an asthma attack.";
    } else if (query.contains("treatment") || query.contains("medication")) {
      return "Asthma treatments typically include quick-relief medications (like albuterol) for immediate symptom relief and long-term control medications (like inhaled corticosteroids). Your doctor will create a personalized asthma action plan based on your specific needs.";
    } else if (query.contains("inhaler")) {
      return "To use an inhaler properly: 1) Shake the inhaler, 2) Exhale completely, 3) Put the mouthpiece in your mouth and close your lips around it, 4) Press down on the inhaler while breathing in slowly, 5) Hold your breath for 10 seconds, then exhale slowly. Using a spacer can help improve medication delivery.";
    } else if (query.contains("attack") || query.contains("emergency")) {
      return "Signs of an asthma attack include severe shortness of breath, rapid breathing, trouble speaking in full sentences, and symptoms not improving with a rescue inhaler. This is a medical emergency - seek immediate medical attention.";
    } else if (query.contains("exercise") ||
        query.contains("physical activity")) {
      return "For exercise-induced asthma: 1) Use your prescribed inhaler before exercise, 2) Warm up properly, 3) Consider indoor exercise during extreme weather, 4) Breathe through your nose to warm the air, 5) Stay hydrated, and 6) Cool down gradually after exercise.";
    } else {
      return "I'm here to help with asthma information. Could you please ask a more specific question about asthma symptoms, triggers, treatments, or management?";
    }
  }

  // Helper method to check if query is asthma-related
  bool _isAsthmaRelated(String query) {
    final asthmaKeywords = [
      'asthma',
      'inhaler',
      'wheezing',
      'breathe',
      'breathing',
      'breath',
      'lung',
      'respiratory',
      'trigger',
      'allergen',
      'attack',
      'symptom',
      'medication',
      'treatment',
      'nebulizer',
      'steroid',
      'corticosteroid',
      'bronchodilator',
      'airway',
      'bronchial',
      'puffer',
      'shortness'
    ];

    return asthmaKeywords.any((keyword) => query.contains(keyword));
  }
}
