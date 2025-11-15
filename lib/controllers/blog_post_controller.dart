import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/topic_models.dart';
import '../models/test_model.dart';
import '../models/question_model.dart';

class BlogPostController extends GetxController {
  // Firebase Database Reference - lazy initialization
  DatabaseReference? _databaseRef;
  var primaryColor = Colors.purple;
  var textColor = Colors.black;
  var lightTextColor = Colors.grey.shade700;
  var bgColor = Colors.white;
  var appPadding = 16.0;    
  var isDeletingTopic=false.obs;
  DatabaseReference? get databaseRef {
    if (_databaseRef == null) {
      try {
        if (Firebase.apps.isNotEmpty) {
          _databaseRef = FirebaseDatabase.instance.ref();
        }
      } catch (e) {
        print('Firebase not initialized: $e');
      }
    }
    return _databaseRef;
  }
  
  bool get isFirebaseAvailable {
    try {
      return Firebase.apps.isNotEmpty && _databaseRef != null;
    } catch (e) {
      return false;
    }
  }

  // Gemini AI
  static const String apiKey = 'AIzaSyAwUG6ZECAiS6Xm7MD_7DsCdA6XIpJsVds'; // Replace with your API key
  late GenerativeModel model;

  // Observable Lists
  final RxList<TopicModel> topics = <TopicModel>[].obs;
  final RxList<TopicModel> filteredTopics = <TopicModel>[].obs;
  final RxList<TestModel> tests = <TestModel>[].obs;
  final RxList<QuestionModel> questions = <QuestionModel>[].obs;

  // Selected Values
  final RxString selectedCategory = 'Biology'.obs;
  final RxString selectedTopicId = ''.obs;
  final RxString selectedTestId = ''.obs;
  final RxString searchQuery = ''.obs;

  // Loading States
  final RxBool isLoadingTopics = false.obs;
  final RxBool isLoadingTests = false.obs;
  final RxBool isLoadingQuestions = false.obs;
  final RxBool isGeneratingQuestions = false.obs;
  final RxBool isGeneratingTopics = false.obs;

  // Add these new progress tracking variables
  final RxInt currentTestProgress = 0.obs; // Current test being created (1-5 or 1-10)
  final RxInt totalTestsToCreate = 0.obs; // Total tests to create (5 or 10)
  final RxInt currentQuestionProgress = 0.obs; // Current question being generated (1-20)
  final RxInt totalQuestionsToCreate = 0.obs; // Total questions to create (20)
  final RxString currentTestName = ''.obs; // Current test name

  // Form Controllers
  final searchController = TextEditingController();

  // Categories - Load from Firebase
  final RxList<String> categories = <String>[].obs;

  // Load categories from Firebase
  Future<void> loadCategories() async {
    if (!isFirebaseAvailable) {
      // Default categories if Firebase not available
      if (categories.isEmpty) {
        categories.value = ['Biology', 'Chemistry', 'Physics', 'Math', 'Intelligence'];
      }
      return;
    }
    
    try {
      final snapshot = await databaseRef!.child('categories').get();
      
      if (snapshot.exists) {
        final data = snapshot.value;
        if (data is List) {
          categories.value = data.map((e) => e.toString()).toList();
        } else if (data is Map) {
          categories.value = data.values.map((e) => e.toString()).toList();
        }
      } else {
        // Initialize with default categories
        if (categories.isEmpty) {
          final defaultCategories = ['Biology', 'Chemistry', 'Physics', 'Math', 'Intelligence'];
          categories.value = defaultCategories;
          
          // Save to Firebase
          for (var category in defaultCategories) {
            await databaseRef!.child('categories').push().set(category);
          }
        }
      }
    } catch (e) {
      print('Error loading categories: $e');
      // Fallback to default
      if (categories.isEmpty) {
        categories.value = ['Biology', 'Chemistry', 'Physics', 'Math', 'Intelligence'];
      }
    }
  }

  // Add custom category to Firebase
  Future<void> addCustomCategory(String categoryName) async {
    if (categoryName.trim().isEmpty) {
      if (!isClosed) {
        Get.snackbar('Error', 'Category name cannot be empty');
      }
      return;
    }
    if (categories.contains(categoryName.trim())) {
      if (!isClosed) {
        Get.snackbar('Info', 'Category already exists');
      }
      return;
    }
    
    try {
      if (isFirebaseAvailable) {
        await databaseRef!.child('categories').push().set(categoryName.trim());
      }
      categories.add(categoryName.trim());
      if (!isClosed) {
        Get.snackbar('Success', 'Category added successfully');
      }
    } catch (e) {
      if (!isClosed) {
        Get.snackbar('Error', 'Failed to add category: $e');
      }
    }
  }

  // Delete category from Firebase
  Future<void> deleteCategory(String categoryName) async {
    if (categories.length <= 1) {
      if (!isClosed) {
        Get.snackbar('Error', 'Cannot delete. At least one category is required');
      }
      return;
    }
    
    try {
      if (isFirebaseAvailable) {
        final snapshot = await databaseRef!.child('categories').get();
        if (snapshot.exists) {
          final data = snapshot.value as Map<dynamic, dynamic>;
          for (var entry in data.entries) {
            if (entry.value == categoryName) {
              await databaseRef!.child('categories').child(entry.key).remove();
              break;
            }
          }
        }
      }
      categories.remove(categoryName);
      if (!isClosed) {
        Get.snackbar('Success', 'Category deleted successfully');
      }
    } catch (e) {
      if (!isClosed) {
        Get.snackbar('Error', 'Failed to delete category: $e');
      }
    }
  }

  // Create custom topic manually
  Future<void> createCustomTopic(String topicName, String category) async {
    if (!isFirebaseAvailable) {
      if (!isClosed) {
        Get.snackbar('Error', 'Firebase is not available');
      }
      return;
    }
    
    if (topicName.trim().isEmpty) {
      if (!isClosed) {
      Get.snackbar('Error', 'Please enter topic name');
      }
      return;
    }

    try {
      isLoadingTopics.value = true;

      final topicId = databaseRef!.child('topics').push().key!;
      final topic = TopicModel(
        id: topicId,
        name: topicName.trim(),
        category: category,
        createdAt: DateTime.now(),
      );

      await databaseRef!.child('topics').child(topicId).set(topic.toJson());

      if (!isClosed) {
      Get.snackbar('Success', 'Topic created successfully!');
      }
      loadTopics();
    } catch (e) {
      if (!isClosed) {
      Get.snackbar('Error', 'Failed to create topic: $e');
      }
    } finally {
      isLoadingTopics.value = false;
    }
  }

  // Delete all topics in selected category
  Future<void> deleteAllTopicsInCategory(String category) async {
    if (!isFirebaseAvailable) {
      if (!isClosed) {
        Get.snackbar('Error', 'Firebase is not available');
      }
      return;
    }
    
    try {
      isDeletingTopic.value = true;
      
      final categoryTopics = topics.where((t) => t.category == category).toList();
      int deletedCount = 0;
      int totalTopics = categoryTopics.length;

      for (var topic in categoryTopics) {
        if (isClosed) break;
        
        try {
          // Delete topic
          await databaseRef!.child('topics').child(topic.id).remove();

          // Delete all tests under this topic
          final testsSnapshot = await databaseRef!
              .child('tests')
              .orderByChild('topicId')
              .equalTo(topic.id)
              .get();

          if (testsSnapshot.exists) {
            final testsData = testsSnapshot.value as Map<dynamic, dynamic>;
            for (var testEntry in testsData.entries) {
              final testId = testEntry.key;
              // Delete all questions under this test
              await databaseRef!
                  .child('questions')
                  .orderByChild('testId')
                  .equalTo(testId)
                  .get()
                  .then((questionsSnapshot) {
                if (questionsSnapshot.exists) {
                  final questionsData =
                      questionsSnapshot.value as Map<dynamic, dynamic>;
                  for (var questionEntry in questionsData.entries) {
                    databaseRef!
                        .child('questions')
                        .child(questionEntry.key)
                        .remove();
                  }
                }
              });
              // Delete test
              await databaseRef!.child('tests').child(testId).remove();
            }
          }
          deletedCount++;
        } catch (e) {
          print('Error deleting topic ${topic.id}: $e');
        }
      }

      if (!isClosed) {
        Get.snackbar('Success', '$deletedCount/$totalTopics topics deleted successfully!');
        loadTopics();
      }
    } catch (e) {
      if (!isClosed) {
        Get.snackbar('Error', 'Failed to delete topics: $e');
      }
    } finally {
      if (!isClosed) {
        isDeletingTopic.value = false;
      }
    }
  }

  // ============ TOPIC MANAGEMENT ============

  // Generate Topics using AI based on selected category
  Future<void> generateTopicsWithAI() async {
    if (apiKey == 'YOUR_GEMINI_API_KEY') {
      if (!isClosed) {
        Get.snackbar(
          'API Key Required',
          'Please add your Gemini API key in blog_post_controller.dart',
        );
      }
      return;
    }

    if (!isFirebaseAvailable) {
      if (!isClosed) {
        Get.snackbar('Error', 'Firebase is not available');
      }
      return;
    }

    try {
      if (isClosed) return;
      isGeneratingTopics.value = true;

      final prompt = '''
You are an expert in ${selectedCategory.value} subject for AFNS test preparation.

Generate exactly 10 relevant topics for ${selectedCategory.value} subject that are important for competitive exam preparation.

Requirements:
1. Topics should be relevant to ${selectedCategory.value} subject
2. Topics should be suitable for competitive exam preparation
3. Topics should be educational and comprehensive
4. Return ONLY a valid JSON array of topic names

Return ONLY a valid JSON array in this exact format:
[
  "Topic 1 Name",
  "Topic 2 Name",
  "Topic 3 Name",
  ...
]

Important:
- Return ONLY the JSON array, no other text
- Make sure all topics are unique and relevant to ${selectedCategory.value}
- Return exactly 10 topics
''';

      final response = await model.generateContent([Content.text(prompt)]);
      
      if (isClosed) return;
      
      final responseText = response.text ?? '';

      if (responseText.isEmpty) {
        throw Exception('Empty response from AI');
      }

      // Extract JSON from response
      String jsonText = responseText.trim();
      if (jsonText.startsWith('```json')) {
        jsonText = jsonText.substring(7);
      }
      if (jsonText.startsWith('```')) {
        jsonText = jsonText.substring(3);
      }
      if (jsonText.endsWith('```')) {
        jsonText = jsonText.substring(0, jsonText.length - 3);
      }
      jsonText = jsonText.trim();

      // Parse JSON
      final List<dynamic> topicsList = json.decode(jsonText) as List<dynamic>;

      // Save topics to Firebase
      int savedCount = 0;
      for (var topicName in topicsList) {
        final topicId = databaseRef!.child('topics').push().key!;
        final topic = TopicModel(
          id: topicId,
          name: topicName.toString(),
          category: selectedCategory.value,
          createdAt: DateTime.now(),
        );

        await databaseRef!.child('topics').child(topicId).set(topic.toJson());
        savedCount++;
      }

      if (!isClosed) {
        Get.snackbar(
          'Success',
          '$savedCount topics generated and saved for ${selectedCategory.value}!',
        );
        loadTopics();
      }
    } catch (e) {
      print('Error generating topics: $e');
      if (!isClosed) {
        Get.snackbar('Error', 'Failed to generate topics: ${e.toString()}');
      }
    } finally {
      if (!isClosed) {
        isGeneratingTopics.value = false;
      }
    }
  }

  Future<void> loadTopics() async {
    if (!isFirebaseAvailable) {
      if (!isClosed) {
        Get.snackbar('Error', 'Firebase is not available');
      }
      return;
    }
    
    try {
      if (isClosed) return;
      isLoadingTopics.value = true;

      final snapshot = await databaseRef!.child('topics').get();

      if (isClosed) return;

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        if (!isClosed) {
        topics.value = data.entries.map((entry) {
          return TopicModel.fromJson(Map<String, dynamic>.from(entry.value));
        }).toList();

        topics.sort((a, b) {
          if (a.category != b.category) {
            return a.category.compareTo(b.category);
          }
          return a.name.compareTo(b.name);
        });

        filterTopics();
        }
      } else {
        if (!isClosed) {
        topics.clear();
        filteredTopics.clear();
        }
      }
    } catch (e) {
      if (!isClosed) {
      Get.snackbar('Error', 'Failed to load topics: $e');
      }
    } finally {
      if (!isClosed) {
      isLoadingTopics.value = false;
      }
    }
  }

  void filterTopics() {
    final query = searchQuery.value.toLowerCase();
    
    // First filter by selected category
    var filtered = topics.where((topic) {
      return topic.category == selectedCategory.value;
    }).toList();
    
    // Then filter by search query if provided
    if (query.isNotEmpty) {
      filtered = filtered.where((topic) {
        return topic.name.toLowerCase().contains(query) ||
            topic.category.toLowerCase().contains(query);
      }).toList();
    }
    
    filteredTopics.value = filtered;
  }

  Future<void> deleteTopic(String topicId) async {
    if (!isFirebaseAvailable) {
      if (!isClosed) {
        Get.snackbar('Error', 'Firebase is not available');
      }
      return;
    }
    
    try {
      if (isClosed) return;
      
      // Delete topic
      await databaseRef!.child('topics').child(topicId).remove();

      // Delete all tests under this topic
      final testsSnapshot = await databaseRef!
          .child('tests')
          .orderByChild('topicId')
          .equalTo(topicId)
          .get();

      if (isClosed) return;

      if (testsSnapshot.exists) {
        final testsData = testsSnapshot.value as Map<dynamic, dynamic>;
        for (var testEntry in testsData.entries) {
          if (isClosed) break;
          
          final testId = testEntry.key;
          // Delete all questions under this test
          await databaseRef!
              .child('questions')
              .orderByChild('testId')
              .equalTo(testId)
              .get()
              .then((questionsSnapshot) {
            if (questionsSnapshot.exists && !isClosed) {
              final questionsData =
                  questionsSnapshot.value as Map<dynamic, dynamic>;
              for (var questionEntry in questionsData.entries) {
                databaseRef!
                    .child('questions')
                    .child(questionEntry.key)
                    .remove();
              }
            }
          });
          // Delete test
          await databaseRef!.child('tests').child(testId).remove();
        }
      }

      if (!isClosed) {
      Get.snackbar('Success', 'Topic deleted successfully!');
      loadTopics();
      }
    } catch (e) {
      if (!isClosed) {
      Get.snackbar('Error', 'Failed to delete topic: $e');
      }
    }
  }

  // ============ TEST MANAGEMENT ============

  Future<void> loadTests(String topicId) async {
    if (!isFirebaseAvailable) {
      if (!isClosed) {
        Get.snackbar('Error', 'Firebase is not available');
      }
      return;
    }
    
    try {
      if (isClosed) return;
      isLoadingTests.value = true;
      selectedTopicId.value = topicId;

      final snapshot = await databaseRef!
          .child('tests')
          .orderByChild('topicId')
          .equalTo(topicId)
          .get();

      if (isClosed) return;

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        if (!isClosed) {
        tests.value = data.entries.map((entry) {
          return TestModel.fromJson(Map<String, dynamic>.from(entry.value));
        }).toList();

        tests.sort((a, b) => a.name.compareTo(b.name));
          
          // Update topic test count in real-time
          final testCount = tests.length;
          // Update in topics list
          final topicIndex = topics.indexWhere((t) => t.id == topicId);
          if (topicIndex != -1) {
            // Update testCount directly
            topics[topicIndex] = topics[topicIndex].copyWith(testCount: testCount);
            filterTopics(); // Refresh filtered list to show updated count
          }
        }
      } else {
        if (!isClosed) {
        tests.clear();
        }
      }
    } catch (e) {
      print('Error loading tests: $e');
      if (!isClosed) {
      Get.snackbar('Error', 'Failed to load tests: $e');
      }
    } finally {
      if (!isClosed) {
      isLoadingTests.value = false;
      }
    }
  }

  Future<void> createTest(String topicId, String testName) async {
    if (!isFirebaseAvailable) {
      if (!isClosed) {
        Get.snackbar('Error', 'Firebase is not available');
      }
      return;
    }
    
    try {
      if (isClosed) return;
      isLoadingTests.value = true;

      final testId = databaseRef!.child('tests').push().key!;
      final test = TestModel(
        id: testId,
        topicId: topicId,
        name: testName,
        createdAt: DateTime.now(),
      );

      await databaseRef!.child('tests').child(testId).set(test.toJson());

      if (isClosed) return;

      // Update topic test count
      final topicSnapshot =
          await databaseRef!.child('topics').child(topicId).get();
      if (topicSnapshot.exists && !isClosed) {
        final topicData = Map<String, dynamic>.from(
            topicSnapshot.value as Map<dynamic, dynamic>);
        final currentCount = topicData['testCount'] ?? 0;
        await databaseRef!
            .child('topics')
            .child(topicId)
            .update({'testCount': currentCount + 1});
      }

      if (!isClosed) {
      Get.snackbar('Success', 'Test created successfully!');
      loadTests(topicId);
      }
    } catch (e) {
      print('Error creating test: $e');
      if (!isClosed) {
      Get.snackbar('Error', 'Failed to create test: $e');
    }
    } finally {
      if (!isClosed) {
        isLoadingTests.value = false;
  }
    }
  }
  final RxBool isDeletingTest = false.obs;
  Future<void> deleteTest(String testId, String topicId) async {
    try {
      if (isClosed) return;
      isDeletingTest.value = true;
      
      // Delete all questions
      final questionsSnapshot = await databaseRef!
          .child('questions')
          .orderByChild('testId')
          .equalTo(testId)
          .get();

      if (isClosed) return;

      if (questionsSnapshot.exists) {
        final questionsData =
            questionsSnapshot.value as Map<dynamic, dynamic>;
        for (var questionEntry in questionsData.entries) {
          if (isClosed) break;
          await databaseRef!.child('questions').child(questionEntry.key).remove();
        }
      }

      if (isClosed) return;

      // Delete test
      await databaseRef!.child('tests').child(testId).remove();

      // Update topic test count
      final topicSnapshot =
          await databaseRef!.child('topics').child(topicId).get();
      if (topicSnapshot.exists && !isClosed) {
        final topicData = Map<String, dynamic>.from(
            topicSnapshot.value as Map<dynamic, dynamic>);
        final currentCount = topicData['testCount'] ?? 0;
        if (currentCount > 0) {
          await databaseRef!
              .child('topics')
              .child(topicId)
              .update({'testCount': currentCount - 1});
        }
      }

      if (!isClosed) {
      Get.snackbar('Success', 'Test deleted successfully!');
      loadTests(topicId);
      }
    } catch (e) {
      if (!isClosed) {
      Get.snackbar('Error', 'Failed to delete test: $e');
      }
    } finally {
      if (!isClosed) {
        isDeletingTest.value = false;
      }
    }
  }

  // ============ QUESTION MANAGEMENT ============

  // Load questions and generate if not exist
  Future<void> loadQuestions(String testId) async {
    // Don't load if already loading or if same test is selected
    if (isLoadingQuestions.value && selectedTestId.value == testId) {
      return;
    }
    
    try {
      if (isClosed) return;
      isLoadingQuestions.value = true;
      selectedTestId.value = testId;

      // Check if questions exist
      final snapshot = await databaseRef!
          .child('questions')
          .orderByChild('testId')
          .equalTo(testId)
          .get();

      if (isClosed) return;

      if (snapshot.exists) {
        // Questions already exist, just load them
        final data = snapshot.value as Map<dynamic, dynamic>;
        if (!isClosed) {
        questions.value = data.entries.map((entry) {
          return QuestionModel.fromJson(
              Map<String, dynamic>.from(entry.value));
        }).toList();

        questions.sort((a, b) => a.question.compareTo(b.question));
        }
      } else {
        // No questions exist, generate them
        questions.clear();
        
        // Get test details to generate questions
        final testSnapshot = await databaseRef!.child('tests').child(testId).get();
        if (testSnapshot.exists && !isClosed) {
          final testData = Map<String, dynamic>.from(
              testSnapshot.value as Map<dynamic, dynamic>);
          
          // Get topic details
          final topicId = testData['topicId'] as String?;
          if (topicId != null) {
            final topicSnapshot = await databaseRef!.child('topics').child(topicId).get();
            if (topicSnapshot.exists) {
              final topicData = Map<String, dynamic>.from(
                  topicSnapshot.value as Map<dynamic, dynamic>);
              final topicName = topicData['name'] as String? ?? '';
              final category = topicData['category'] as String? ?? '';
              
              // Generate 20 MCQs for this test
              try {
                await generateQuestionsWithAI(
                  testId,
                  topicName,
                  category,
                  20,
                );
                
                // Reload questions after generation
                final questionsSnapshot = await databaseRef!
                    .child('questions')
                    .orderByChild('testId')
                    .equalTo(testId)
                    .get();
                
                if (questionsSnapshot.exists && !isClosed) {
                  final questionsData = questionsSnapshot.value as Map<dynamic, dynamic>;
                  questions.value = questionsData.entries.map((entry) {
                    return QuestionModel.fromJson(
                        Map<String, dynamic>.from(entry.value));
                  }).toList();
                  questions.sort((a, b) => a.question.compareTo(b.question));
                }
              } catch (e) {
                print('Error generating questions: $e');
                if (!isClosed) {
                  Get.snackbar('Error', 'Failed to generate MCQs: ${e.toString()}');
                }
              }
            }
          }
        }
      }

      // Update test question count
      if (!isClosed) {
        final testSnapshot = await databaseRef!.child('tests').child(testId).get();
      if (testSnapshot.exists) {
          final testData = Map<String, dynamic>.from(
              testSnapshot.value as Map<dynamic, dynamic>);
          final currentCount = testData['questionCount'] ?? 0;
          if (currentCount != questions.length) {
            await databaseRef!.child('tests').child(testId).update({
          'questionCount': questions.length,
        });
          }
        }
      }
    } catch (e) {
      if (!isClosed) {
      Get.snackbar('Error', 'Failed to load questions: $e');
      }
    } finally {
      if (!isClosed) {
      isLoadingQuestions.value = false;
      }
    }
  }

  Future<void> generateQuestionsWithAI(
    String testId,
    String topicName,
    String category,
    int numberOfQuestions,
  ) async {
    if (apiKey == 'YOUR_GEMINI_API_KEY') {
      if (!isClosed) {
      Get.snackbar(
        'API Key Required',
        'Please add your Gemini API key in blog_post_controller.dart',
      );
      }
      throw Exception('API Key Required'); // Throw instead of return
    }

    // Check if questions already exist for this test
    try {
      final existingQuestions = await databaseRef!
          .child('questions')
          .orderByChild('testId')
          .equalTo(testId)
          .get();
      
      if (existingQuestions.exists) {
        final questionsData = existingQuestions.value as Map<dynamic, dynamic>;
        if (questionsData.length >= numberOfQuestions) {
          // Questions already exist, don't regenerate
          print('Questions already exist for test $testId, skipping generation');
          // Don't show snackbar here, just return silently
          return; // Return silently, test is already created
        }
      }
    } catch (e) {
      // Continue if check fails
      print('Error checking existing questions: $e');
    }

    try {
      if (isClosed) return; // Check before starting
      isGeneratingQuestions.value = true;
      
      // Initialize question progress
      if (!isClosed) {
        currentQuestionProgress.value = 0;
        totalQuestionsToCreate.value = numberOfQuestions;
      }

      final prompt = '''
You are an expert MCQ question generator for AFNS test preparation.

Generate exactly $numberOfQuestions multiple choice questions for the topic "$topicName" in the subject "$category".

CRITICAL JSON FORMATTING RULES:
1. Use ONLY ASCII characters - NO Unicode symbols like √, π, etc.
2. For square root, write "sqrt(65)" instead of "√65"
3. For mathematical expressions, use simple text: "x squared" instead of "x²"
4. DO NOT use quotes inside question text or options
5. DO NOT use newlines or line breaks
6. Keep all text on single lines
7. Escape all special characters properly

Requirements:
1. Each question must be relevant to the topic and subject
2. Each question must have exactly 4 options (A, B, C, D)
3. Questions should be educational and test understanding
4. Include brief explanations for each answer
5. Questions should be suitable for competitive exam preparation

Return ONLY a valid JSON array in this exact format (NO markdown, NO code blocks):
[
  {
    "question": "Question text here?",
    "options": ["Option A", "Option B", "Option C", "Option D"],
    "correctAnswerIndex": 0,
    "explanation": "Brief explanation here"
  }
]

Important:
- correctAnswerIndex must be 0, 1, 2, or 3
- Return ONLY the JSON array, no other text
- Use simple ASCII text only - NO special Unicode characters
- For math: use "sqrt()" not "√", use "pi" not "π"
''';

      final response = await model.generateContent([Content.text(prompt)]);
      
      if (isClosed) return; // Check after async operation
      
      final responseText = response.text ?? '';

      if (responseText.isEmpty) {
        throw Exception('Empty response from AI');
      }

      // Extract JSON from response
      String jsonText = responseText.trim();
      if (jsonText.startsWith('```json')) {
        jsonText = jsonText.substring(7);
      }
      if (jsonText.startsWith('```')) {
        jsonText = jsonText.substring(3);
      }
      if (jsonText.endsWith('```')) {
        jsonText = jsonText.substring(0, jsonText.length - 3);
      }
      jsonText = jsonText.trim();

      // Try to find JSON array in the response
      int jsonStart = jsonText.indexOf('[');
      int jsonEnd = jsonText.lastIndexOf(']');
      
      if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
        jsonText = jsonText.substring(jsonStart, jsonEnd + 1);
      }

      // Better JSON repair function
      String repairJson(String json) {
        StringBuffer result = StringBuffer();
        bool inString = false;
        bool escapeNext = false;
        
        for (int i = 0; i < json.length; i++) {
          String char = json[i];
          
          if (escapeNext) {
            // If we're escaping, just add the character
            result.write(char);
            escapeNext = false;
            continue;
          }
          
          if (char == '\\') {
            escapeNext = true;
            result.write(char);
            continue;
          }
          
          if (char == '"' && !escapeNext) {
            inString = !inString;
            result.write(char);
            continue;
          }
          
          if (inString) {
            // Inside string: escape control characters but keep Unicode
            if (char == '\n' || char == '\r' || char == '\t') {
              result.write(' '); // Replace with space
            } else if (char == '"') {
              result.write('\\"'); // Escape quote
            } else {
              result.write(char); // Keep other characters including Unicode
            }
          } else {
            // Outside string: normalize whitespace
            if (char == '\n' || char == '\r' || char == '\t') {
              result.write(' ');
            } else {
              result.write(char);
            }
          }
        }
        
        return result.toString().replaceAll(RegExp(r'\s+'), ' ');
      }

      // Parse JSON with better error handling
      List<dynamic> jsonList;
      try {
        jsonList = json.decode(jsonText) as List<dynamic>;
      } catch (parseError) {
        print('JSON Parse Error: $parseError');
        print('JSON Text length: ${jsonText.length}');
        
        // Try to repair JSON
        try {
          String repairedJson = repairJson(jsonText);
          jsonList = json.decode(repairedJson) as List<dynamic>;
          print('JSON parsed successfully after repair');
        } catch (repairError) {
          print('Repair also failed: $repairError');
          
          // Last resort: Extract valid questions one by one
          try {
            List<Map<String, dynamic>> validQuestions = [];
            String remaining = jsonText;
            
            // Try to extract each question object separately
            int questionStart = remaining.indexOf('{');
            while (questionStart != -1) {
              int questionEnd = remaining.indexOf('}', questionStart);
              if (questionEnd == -1) break;
              
              String questionJson = remaining.substring(questionStart, questionEnd + 1);
              
              try {
                Map<String, dynamic> question = json.decode(questionJson) as Map<String, dynamic>;
                if (question.containsKey('question') && question.containsKey('options')) {
                  validQuestions.add(question);
                }
              } catch (e) {
                // Skip invalid question
                print('Skipped invalid question: $e');
              }
              
              questionStart = remaining.indexOf('{', questionEnd + 1);
            }
            
            if (validQuestions.isNotEmpty) {
              jsonList = validQuestions;
              print('Extracted ${validQuestions.length} valid questions');
            } else {
              throw Exception('Could not extract any valid questions from response');
            }
          } catch (extractError) {
            print('Extraction also failed: $extractError');
            throw Exception('Failed to parse AI response. Please try generating questions again.');
          }
        }
      }
      // Save questions to Firebase
      int savedCount = 0;
      for (var questionData in jsonList) {
        if (isClosed) return; // Check in loop
        
        // Update progress
        if (!isClosed) {
          currentQuestionProgress.value = savedCount + 1;
        }
        
        final questionJson = questionData as Map<String, dynamic>;
        final questionId = databaseRef!.child('questions').push().key!;
  // Clean question text and options to remove any problematic characters
        String questionText = (questionJson['question'] ?? '').toString()
            .replaceAll('\n', ' ')
            .replaceAll('\r', ' ')
            .replaceAll('\t', ' ')
            .trim();

              List<String> options = [];
        if (questionJson['options'] != null && questionJson['options'] is List) {
          final optionsList = questionJson['options'] as List;
          for (var opt in optionsList) {
            String cleanOption = opt.toString()
                .replaceAll('\n', ' ')
                .replaceAll('\r', ' ')
                .replaceAll('\t', ' ')
                .trim();
            if (cleanOption.isNotEmpty) {
              options.add(cleanOption);
            }
          }
        }
           // Ensure exactly 4 options
        while (options.length < 4) {
          options.add('');
        }
        if (options.length > 4) {
          options = options.sublist(0, 4);
        }
          String? explanation = questionJson['explanation']?.toString()
            .replaceAll('\n', ' ')
            .replaceAll('\r', ' ')
            .replaceAll('\t', ' ')
            .trim();
        
        if (explanation != null && explanation.isEmpty) {
          explanation = null;
        }
        final question = QuestionModel(
          id: questionId,
          testId: testId,
          question: questionText,
          options: options,
          correctAnswerIndex: questionJson['correctAnswerIndex'] ?? 0,
          explanation: explanation,
        );

        await databaseRef!
            .child('questions')
            .child(questionId)
            .set(question.toJson());
        savedCount++;
      }

      if (isClosed) return; // Check before updating

      // Update test question count
      await databaseRef!.child('tests').child(testId).update({
        'questionCount': savedCount,
      });

      // Reload the specific test from Firebase for real-time update
      if (!isClosed) {
        final testSnapshot = await databaseRef!.child('tests').child(testId).get();
        if (testSnapshot.exists) {
          final testData = Map<String, dynamic>.from(
              testSnapshot.value as Map<dynamic, dynamic>);
          final updatedTest = TestModel.fromJson(testData);
          
          final testIndex = tests.indexWhere((t) => t.id == testId);
          if (testIndex != -1) {
            tests[testIndex] = updatedTest;
            tests.refresh();
          }
        }
      }
      
      // Reset question progress
      if (!isClosed) {
        currentQuestionProgress.value = 0;
        totalQuestionsToCreate.value = 0;
      }
      
      print('Successfully generated $savedCount questions for test $testId');
      
    } catch (e) {
      print('Error generating questions for test $testId: $e');
      if (!isClosed) {
        currentQuestionProgress.value = 0;
        totalQuestionsToCreate.value = 0;
      }
      rethrow; // Re-throw so parent can handle
    } finally {
      if (!isClosed) {
      isGeneratingQuestions.value = false;
      }
    }
  }

  Future<void> saveQuestion(QuestionModel question) async {
    try {
      if (isClosed) return;
      
      if (question.id.isEmpty) {
        // Create new question
        final questionId = databaseRef!.child('questions').push().key!;
        final newQuestion = question.copyWith(id: questionId);
        await databaseRef!
            .child('questions')
            .child(questionId)
            .set(newQuestion.toJson());
      } else {
        // Update existing question
        await databaseRef!
            .child('questions')
            .child(question.id)
            .update(question.toJson());
      }

      if (!isClosed) {
      loadQuestions(question.testId);
      Get.snackbar('Success', 'Question saved successfully!');
      }
    } catch (e) {
      if (!isClosed) {
      Get.snackbar('Error', 'Failed to save question: $e');
      }
    }
  }

  Future<void> deleteQuestion(String questionId, String testId) async {
    try {
      if (isClosed) return;
      
      await databaseRef!.child('questions').child(questionId).remove();

      if (isClosed) return;

      // Update test question count
      final testSnapshot = await databaseRef!.child('tests').child(testId).get();
      if (testSnapshot.exists && !isClosed) {
        final testData =
            Map<String, dynamic>.from(testSnapshot.value as Map<dynamic, dynamic>);
        final currentCount = testData['questionCount'] ?? 0;
        if (currentCount > 0) {
          await databaseRef!.child('tests').child(testId).update({
            'questionCount': currentCount - 1,
          });
        }
      }

      if (!isClosed) {
      Get.snackbar('Success', 'Question deleted successfully!');
      loadQuestions(testId);
      }
    } catch (e) {
      if (!isClosed) {
      Get.snackbar('Error', 'Failed to delete question: $e');
    }
  }
}

  // Create multiple tests WITHOUT questions (questions will be generated on-demand)
  Future<void> createTestsWithQuestions(
    String topicId,
    String topicName,
    String category,
    int numberOfTests,
  ) async {
    if (!isFirebaseAvailable) {
      if (!isClosed) {
        Get.snackbar('Error', 'Firebase is not available');
      }
      return;
    }

    // Prevent multiple simultaneous calls
    if (isLoadingTests.value) {
      if (!isClosed) {
        Get.snackbar('Info', 'Tests are already being created. Please wait...');
      }
      return;
    }

    try {
      if (isClosed) return;
      isLoadingTests.value = true;
      
      // Initialize progress tracking for test creation only
      totalTestsToCreate.value = numberOfTests;
      currentTestProgress.value = 0;
      currentTestName.value = '';

      List<String> createdTestIds = [];

      // Create tests one by one (without MCQs)
      for (int i = 1; i <= numberOfTests; i++) {
        if (isClosed) break;
        
        // Update progress
        if (!isClosed) {
          currentTestProgress.value = i;
          currentTestName.value = 'Test $i';
        }
        
        try {
          final testId = databaseRef!.child('tests').push().key!;
          final test = TestModel(
            id: testId,
            topicId: topicId,
            name: 'Test $i',
            createdAt: DateTime.now(),
            questionCount: 0, // No questions yet
          );

          // Create test only (no MCQs generation)
          await databaseRef!.child('tests').child(testId).set(test.toJson());
          createdTestIds.add(testId);
          
          print('Test $i created successfully with ID: $testId');

          if (isClosed) break;

        } catch (e) {
          print('Test $i: Error creating test: $e');
          // Continue with next test even if one fails
        }
      }

      // Reset progress
      if (!isClosed) {
        currentTestProgress.value = 0;
        totalTestsToCreate.value = 0;
        currentTestName.value = '';
      }

      // Update topic test count
      if (!isClosed && createdTestIds.isNotEmpty) {
        try {
          final topicSnapshot =
              await databaseRef!.child('topics').child(topicId).get();
          if (topicSnapshot.exists) {
            final topicData = Map<String, dynamic>.from(
                topicSnapshot.value as Map<dynamic, dynamic>);
            final currentCount = topicData['testCount'] ?? 0;
            await databaseRef!
                .child('topics')
                .child(topicId)
                .update({'testCount': currentCount + createdTestIds.length});
          }
        } catch (e) {
          print('Error updating topic test count: $e');
        }
      }

      if (isClosed) return;

      if (!isClosed) {
        Get.snackbar(
          'Success',
          '${createdTestIds.length} test boxes created! Click on a test to generate MCQs.',
        );
      }

      // Load tests after creation
      if (!isClosed) {
        await loadTests(topicId);
      }
      
    } catch (e) {
      print('Error in createTestsWithQuestions: $e');
      if (!isClosed) {
        Get.snackbar('Error', 'Failed to create tests: ${e.toString()}');
      }
    } finally {
      if (!isClosed) {
        isLoadingTests.value = false;
        currentTestProgress.value = 0;
        totalTestsToCreate.value = 0;
        currentTestName.value = '';
      }
    }
  }

  void _showTestCountDialog(BlogPostController controller, TopicModel topic) {
    final selectedTestCount = ValueNotifier<int>(5);
    
                                    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: EdgeInsets.all(24),
      child: Column(
            mainAxisSize: MainAxisSize.min,
        children: [
          Container(
                padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.quiz,
                  color: Colors.purple,
                  size: 32,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Create Tests',
                      style: TextStyle(
                  fontSize: 20,
                        fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'How many tests for "${topic.name}"?',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              ValueListenableBuilder<int>(
                valueListenable: selectedTestCount,
                builder: (context, value, child) {
                  return Column(
                    children: [
                      _buildTestOption(
                        '5 Tests',
                        5,
                        value,
                        selectedTestCount,
                        Icons.looks_5,
                      ),
                      SizedBox(height: 12),
                      _buildTestOption(
                        '10 Tests',
                        10,
                        value,
                        selectedTestCount,
                        Icons.looks_6,
                      ),
                    ],
                  );
                },
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
            children: [
                        TextButton(
                    onPressed: () {
                      selectedTestCount.dispose();
                      Get.back();
                    },
                          child: Text('Cancel'),
                        ),
                  SizedBox(width: 12),
                  ValueListenableBuilder<int>(
                    valueListenable: selectedTestCount,
                    builder: (context, testCount, child) {
                      return ElevatedButton(
                          onPressed: () {
                          final count = testCount;
                          selectedTestCount.dispose();
                            Get.back();
                          
                          controller.createTestsWithQuestions(
                            topic.id,
                            topic.name,
                            topic.category,
                            count,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text('Create Tests'),
                  );
                },
              ),
            ],
          ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTestOption(
    String label,
    int value,
    int selectedValue,
    ValueNotifier<int> notifier,
    IconData icon,
  ) {
    final isSelected = value == selectedValue;
    return InkWell(
      onTap: () => notifier.value = value,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
          color: isSelected ? Colors.purple.withOpacity(0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
                border: Border.all(
            color: isSelected ? Colors.purple : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
              padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                color: isSelected ? Colors.purple : Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
              child: Icon(
                icon,
                          color: Colors.white,
                size: 20,
              ),
            ),
            SizedBox(width: 16),
                  Expanded(
                    child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: isSelected ? primaryColor : textColor,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: primaryColor,
              ),
          ],
        ),
      ),
    );
  }

  // Add this helper method at the top of the class (after other methods)
  void _safeSnackbar(String title, String message) {
    if (!isClosed) {
      Get.snackbar(title, message);
    }
  }

  @override
  void onInit() {
    super.onInit();
    
    // Initialize Firebase Database reference if available
    try {
      if (Firebase.apps.isNotEmpty) {
        _databaseRef = FirebaseDatabase.instance.ref();
        print('Firebase Database initialized');
      } else {
        print('Firebase apps is empty');
      }
    } catch (e) {
      print('Error initializing Firebase Database: $e');
    }
    
    if (apiKey != 'AIzaSyB7JsWALSa7ccGAr4R8jqApRFO0IESI9tg') {
      model = GenerativeModel(
        model: 'gemini-flash-latest',
        apiKey: apiKey,
      );
    }
    
    // Load categories from Firebase
    loadCategories();
    
    // Only load topics if Firebase is available
    if (isFirebaseAvailable) {
      loadTopics();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!isClosed) {
          Get.snackbar(
            'Firebase Not Available',
            'Firebase is not initialized. Please check Firebase configuration.',
            duration: Duration(seconds: 3),
          );
        }
      });
    }
    searchController.addListener(() {
      filterTopics();
    });
    
    // Listen to category changes and clear tests/questions
    ever(selectedCategory, (_) {
      if (!isClosed) {
        tests.clear();
        questions.clear();
        selectedTopicId.value = '';
        selectedTestId.value = '';
        filterTopics();
      }
    });
  }
}

