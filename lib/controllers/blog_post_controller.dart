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

  // Categories - Make it observable
  final RxList<String> categories = <String>[
    'Biology',
    'Chemistry',
    'Physics',
    'Math',
    'Intelligence',
  ].obs;

  // Add loading state for topic deletion
  final RxBool isDeletingTopic = false.obs;
  final RxBool isDeletingTest = false.obs;

  // Add custom category
  void addCustomCategory(String categoryName) {
    if (categoryName.trim().isEmpty) {
      Get.snackbar('Error', 'Category name cannot be empty');
      return;
    }
    if (categories.contains(categoryName.trim())) {
      Get.snackbar('Info', 'Category already exists');
      return;
    }
    categories.add(categoryName.trim());
    Get.snackbar('Success', 'Category added successfully');
  }

  // Delete category
  void deleteCategory(String categoryName) {
    if (categories.length <= 1) {
      Get.snackbar('Error', 'Cannot delete. At least one category is required');
      return;
    }
    categories.remove(categoryName);
    Get.snackbar('Success', 'Category deleted successfully');
  }

  // Create custom topic manually
  Future<void> createCustomTopic(String topicName, String category) async {
    if (!isFirebaseAvailable) {
      Get.snackbar('Error', 'Firebase is not available');
      return;
    }
    
    if (topicName.trim().isEmpty) {
      Get.snackbar('Error', 'Please enter topic name');
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

      Get.snackbar('Success', 'Topic created successfully!');
      loadTopics();
    } catch (e) {
      Get.snackbar('Error', 'Failed to create topic: $e');
    } finally {
      isLoadingTopics.value = false;
    }
  }

  // Delete all topics in selected category
  Future<void> deleteAllTopicsInCategory(String category) async {
    if (!isFirebaseAvailable) {
      Get.snackbar('Error', 'Firebase is not available');
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

Requirements:
1. Each question must be relevant to the topic and subject
2. Each question must have exactly 4 options (A, B, C, D)
3. Questions should be educational and test understanding
4. Include brief explanations for each answer
5. Questions should be suitable for competitive exam preparation

Return ONLY a valid JSON array in this exact format:
[
  {
    "question": "Question text here?",
    "options": ["Option A", "Option B", "Option C", "Option D"],
    "correctAnswerIndex": 0,
    "explanation": "Brief explanation here"
  }
]

Important:
- correctAnswerIndex must be 0, 1, 2, or 3 (corresponding to options array index)
- Return ONLY the JSON array, no other text
- Make sure all questions are unique and relevant
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

      // Parse JSON
      final List<dynamic> jsonList = json.decode(jsonText) as List<dynamic>;

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

        final question = QuestionModel(
          id: questionId,
          testId: testId,
          question: questionJson['question'] ?? '',
          options: List<String>.from(questionJson['options'] ?? []),
          correctAnswerIndex: questionJson['correctAnswerIndex'] ?? 0,
          explanation: questionJson['explanation'],
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
    int selectedTestCount = 5;
    
    Get.dialog(
      AlertDialog(
        title: Text('Select Number of Tests'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('How many tests do you want to create for "${topic.name}"?'),
                SizedBox(height: 20),
                RadioListTile<int>(
                  title: Text('5 Tests'),
                  value: 5,
                  groupValue: selectedTestCount,
                  onChanged: (value) {
                    setState(() {
                      selectedTestCount = value!;
                    });
                  },
                ),
                RadioListTile<int>(
                  title: Text('10 Tests'),
                  value: 10,
                  groupValue: selectedTestCount,
                  onChanged: (value) {
                    setState(() {
                      selectedTestCount = value!;
                    });
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.loadTests(topic.id);
              controller.createTestsWithQuestions(topic.id, topic.name, topic.category, selectedTestCount);
              Get.back();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: Text('Create Tests', style: TextStyle(color: Colors.white)),
          ),
        ],
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
    
    // Only load topics if Firebase is available
    if (isFirebaseAvailable) {
      loadTopics();
    } else {
      // Defer snackbar until after build is complete
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

