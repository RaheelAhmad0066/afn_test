import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:afn_test_admin/constants/constants.dart';
import 'package:afn_test_admin/screens/components/custom_appbar.dart';
import 'package:afn_test_admin/controllers/blog_post_controller.dart';
import 'package:afn_test_admin/models/question_model.dart';
import 'package:afn_test_admin/models/topic_models.dart';

class BlogPostScreen extends StatelessWidget {
  const BlogPostScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(BlogPostController());

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            CustomAppbar(),
            Expanded(
              child: Row(
                children: [
                  // Left Sidebar - Topics List
                  Expanded(
                    flex: 2,
                    child: _buildTopicsSection(controller),
                  ),
                  // Right Side - Tests and Questions
                  Expanded(
                    flex: 3,
                    child: Obx(() {
                      if (controller.selectedTopicId.value.isEmpty) {
                        return _buildEmptyState('Select a topic to view tests');
                      }
                      return _buildTestsSection(controller);
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicsSection(BlogPostController controller) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 4,
            offset: Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Create Topic Section - Improved Design
          Container(
            padding: EdgeInsets.all(appPadding),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryColor.withOpacity(0.1),
                  primaryColor.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Generate Topics',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.settings, color: primaryColor),
                      onPressed: () => _showCategoryManagementDialog(controller),
                      tooltip: 'Manage Categories',
                    ),
                  ],
                ),
                SizedBox(height: 16),
                // Subject Dropdown with Add Button
                Row(
                  children: [
                    Expanded(
                      child: Obx(() => DropdownButtonFormField<String>(
                            value: controller.selectedCategory.value,
                            decoration: InputDecoration(
                              labelText: 'Subject',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              prefixIcon: Icon(Icons.category, color: primaryColor),
                            ),
                            items: controller.categories.map((category) {
                              return DropdownMenuItem(
                                value: category,
                                child: Text(
                                  category,
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                controller.selectedCategory.value = value;
                                controller.filterTopics();
                              }
                            },
                          )),
                    ),
                    SizedBox(width: 8),
                    // Add Category Button
                    Container(
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.add, color: Colors.white),
                        onPressed: () => _showAddCategoryDialog(controller),
                        tooltip: 'Add Category',
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                // Generate Topics with AI Button - Better Design
                Obx(() => Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: controller.isGeneratingTopics.value
                              ? [Colors.grey.shade400, Colors.grey.shade500]
                              : [purple, purple.withOpacity(0.8)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: purple.withOpacity(0.3),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: controller.isGeneratingTopics.value
                            ? null
                            : () => controller.generateTopicsWithAI(),
                        icon: Icon(
                          Icons.auto_awesome,
                          color: Colors.white,
                        ),
                        label: Text(
                          controller.isGeneratingTopics.value
                              ? 'Generating...'
                              : 'Generate Topics with AI',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    )),
                SizedBox(height: 12),
                Divider(height: 1),
                SizedBox(height: 12),
                // Custom Topic Creation - Better Design
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Or Create Custom Topic',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: lightTextColor,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showCustomTopicDialog(controller),
                      icon: Icon(Icons.add_circle_outline, size: 18),
                      label: Text('Add Topic'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Search Field
          Padding(
            padding: EdgeInsets.all(appPadding),
            child: TextField(
              controller: controller.searchController,
              decoration: InputDecoration(
                hintText: 'Search topics...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
          ),
          // Topics List
          Expanded(
            child: Obx(() {
              if (controller.isLoadingTopics.value) {
                return Center(child: CircularProgressIndicator());
              }

              if (controller.filteredTopics.isEmpty) {
                return Center(
                  child: Text(
                    'No topics found',
                    style: TextStyle(color: lightTextColor),
                  ),
                );
              }

              return ListView.builder(
                itemCount: controller.filteredTopics.length,
                itemBuilder: (context, index) {
                  final topic = controller.filteredTopics[index];
                  
                  return Obx(() {
                    final isSelected = controller.selectedTopicId.value == topic.id;
                    final hasTests = (topic.testCount ?? 0) > 0; // Check if topic has tests
                    
                    return AnimatedContainer(
                      duration: Duration(milliseconds: 200),
                      margin: EdgeInsets.symmetric(
                        horizontal: appPadding,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? primaryColor.withOpacity(0.1)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected 
                              ? primaryColor 
                              : (hasTests ? Colors.green : Colors.grey.shade200),
                          width: isSelected ? 2 : (hasTests ? 2 : 1),
                        ),
                        boxShadow: hasTests ? [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.2),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ] : null,
                      ),
                      child: ListTile(
                        leading: Stack(
                          children: [
                            CircleAvatar(
                              backgroundColor: primaryColor,
                              child: Text(
                                topic.name[0].toUpperCase(),
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            // Green check indicator if tests exist
                            if (hasTests)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: Icon(
                                    Icons.check,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                topic.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                            ),
                            if (hasTests)
                              Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 18,
                              ),
                          ],
                        ),
                        subtitle: Row(
                          children: [
                            Chip(
                              label: Text(
                                topic.category,
                                style: TextStyle(fontSize: 10),
                              ),
                              backgroundColor: primaryColor.withOpacity(0.1),
                            ),
                            SizedBox(width: 8),
                            Text(
                              '${topic.testCount ?? 0} tests',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: hasTests ? FontWeight.w600 : FontWeight.normal,
                                color: hasTests ? Colors.green : lightTextColor,
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          // If tests already exist, load directly without popup
                          if (hasTests) {
                            controller.loadTests(topic.id);
                          } else {
                            // Show popup to create tests
                            _showTestCountDialog(controller, topic);
                          }
                        },
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              child: Text('Delete'),
                              onTap: () {
                                Future.delayed(Duration.zero, () {
                                  Get.dialog(
                                    AlertDialog(
                                      title: Text('Delete Topic'),
                                      content: Text(
                                          'Are you sure you want to delete "${topic.name}"? This will delete all tests and questions.'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Get.back(),
                                          child: Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            controller.deleteTopic(topic.id);
                                            Get.back();
                                          },
                                          child: Text(
                                            'Delete',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  });
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTestsSection(BlogPostController controller) {
    return Container(
      color: Colors.grey.shade50,
      child: Column(
        children: [
          // Tests Header
          Container(
            padding: EdgeInsets.all(appPadding),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Obx(() => Text(
                          'Tests (${controller.tests.length})',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        )),
                    ElevatedButton.icon(
                      onPressed: () => _showCreateTestDialog(controller),
                      icon: Icon(Icons.add, color: Colors.white),
                      label: Text('Create Test', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                      ),
                    ),
                  ],
                ),
                // Test Creation Progress (only show when creating test boxes)
                Obx(() {
                  if (controller.isLoadingTests.value && 
                      controller.totalTestsToCreate.value > 0) {
                    final progress = controller.totalTestsToCreate.value > 0
                        ? controller.currentTestProgress.value / 
                          controller.totalTestsToCreate.value
                        : 0.0;
                    final percentage = (progress * 100).toInt();
                    return AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      padding: EdgeInsets.only(top: 12),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                              minHeight: 12, // Increased height
                            ),
                          ),
                          SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Creating Test ${controller.currentTestProgress.value}/${controller.totalTestsToCreate.value}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                              Text(
                                '$percentage%',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }
                  return SizedBox.shrink();
                }),
                // Question Generation Progress (show when generating MCQs)
                Obx(() {
                  if (controller.isGeneratingQuestions.value && 
                      controller.totalQuestionsToCreate.value > 0) {
                    final progress = controller.totalQuestionsToCreate.value > 0
                        ? controller.currentQuestionProgress.value / 
                          controller.totalQuestionsToCreate.value
                        : 0.0;
                    final percentage = (progress * 100).toInt();
                    return AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      padding: EdgeInsets.only(top: 8),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
                              minHeight: 10, // Increased height
                            ),
                          ),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Generating MCQs: ${controller.currentQuestionProgress.value}/${controller.totalQuestionsToCreate.value}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.purple,
                                ),
                              ),
                              Text(
                                '$percentage%',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }
                  return SizedBox.shrink();
                }),
              ],
            ),
          ),
          // Tests List
          Expanded(
            flex: 2,
            child: Obx(() {
              if (controller.isLoadingTests.value) {
                return Center(child: CircularProgressIndicator());
              }

              if (controller.tests.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.quiz, size: 64, color: lightTextColor),
                      SizedBox(height: 16),
                      Text(
                        'No tests yet',
                        style: TextStyle(color: lightTextColor),
                      ),
                      SizedBox(height: 8),
                      TextButton(
                        onPressed: () => _showCreateTestDialog(controller),
                        child: Text('Create First Test'),
                      ),
                    ],
                  ),
                );
              }

              return GridView.builder(
                padding: EdgeInsets.all(appPadding),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemCount: controller.tests.length,
                itemBuilder: (context, index) {
                  final test = controller.tests[index];
                  
                  return Obx(() {
                    final isSelected = controller.selectedTestId.value == test.id;
                    final hasQuestions = (test.questionCount ?? 0) > 0; // Check if questions exist
                    
                    return GestureDetector(
                        onTap: () {
                          // Only load if not already selected
                          if (!isSelected) {
                            controller.loadQuestions(test.id);
                          }
                        },
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected 
                                  ? primaryColor 
                                  : (hasQuestions ? Colors.green : Colors.grey.shade200),
                              width: isSelected ? 2 : (hasQuestions ? 2 : 1),
                            ),
                            boxShadow: hasQuestions ? [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.2),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ] : [
                              BoxShadow(
                                color: Colors.grey.shade200,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: hasQuestions 
                                          ? Colors.green.withOpacity(0.1)
                                          : primaryColor.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.quiz,
                                      color: hasQuestions ? Colors.green : primaryColor,
                                      size: 32,
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8),
                                    child: Text(
                                      test.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                        fontSize: 14,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '${test.questionCount ?? 0} Qs',
                                        style: TextStyle(
                                          color: hasQuestions ? Colors.green : lightTextColor,
                                          fontSize: 12,
                                          fontWeight: hasQuestions ? FontWeight.w600 : FontWeight.normal,
                                        ),
                                      ),
                                      if (hasQuestions) ...[
                                        SizedBox(width: 4),
                                        Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                          size: 14,
                                        ),
                                      ],
                                    ],
                                  ),
                                  Spacer(),
                                  PopupMenuButton(
                                    icon: Icon(Icons.more_vert, size: 18),
                                    itemBuilder: (context) => [
                                      PopupMenuItem(
                                        child: Text('Delete'),
                                        onTap: () {
                                          Future.delayed(Duration.zero, () {
                                            Get.dialog(
                                              AlertDialog(
                                                title: Text('Delete Test'),
                                                content: Text(
                                                    'Are you sure you want to delete "${test.name}"? This will delete all questions.'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Get.back(),
                                                    child: Text('Cancel'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () {
                                                      controller.deleteTest(
                                                          test.id, test.topicId);
                                                      Get.back();
                                                    },
                                                    child: Text(
                                                      'Delete',
                                                      style: TextStyle(color: Colors.red),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              // Green check badge on top right
                              if (hasQuestions)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.green.withOpacity(0.3),
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.check,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                  });
                },
              );
            }),
          ),
          // Questions Section
          Expanded(
            flex: 3,
            child: Obx(() {
              if (controller.selectedTestId.value.isEmpty) {
                return _buildEmptyState('Select a test to view questions');
              }
              return _buildQuestionsSection(controller);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionsSection(BlogPostController controller) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Questions Header
          Container(
            padding: EdgeInsets.all(appPadding),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Obx(() => Text(
                      'Questions (${controller.questions.length}/20)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    )),
                Row(
                  children: [
                    Obx(() => ElevatedButton.icon(
                          onPressed: controller.isGeneratingQuestions.value
                              ? null
                              : () => _showGenerateQuestionsDialog(controller),
                          icon: Icon(Icons.auto_awesome, color: Colors.white),
                          label: Text(
                            'Generate with AI',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                          ),
                        )),
                    SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _showAddQuestionDialog(controller),
                      icon: Icon(Icons.add, color: Colors.white),
                      label: Text('Add Question', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Questions List
          Expanded(
            child: Obx(() {
              if (controller.isLoadingQuestions.value) {
                return Center(child: CircularProgressIndicator());
              }

              if (controller.questions.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.help_outline, size: 64, color: lightTextColor),
                      SizedBox(height: 16),
                      Text(
                        'No questions yet',
                        style: TextStyle(color: lightTextColor),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _showGenerateQuestionsDialog(controller),
                        icon: Icon(Icons.auto_awesome),
                        label: Text('Generate with AI'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: EdgeInsets.all(appPadding),
                itemCount: controller.questions.length,
                itemBuilder: (context, index) {
                  final question = controller.questions[index];
                  return _buildQuestionCard(controller, question, index);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(
      BlogPostController controller, QuestionModel question, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Q${index + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),
              Spacer(),
              IconButton(
                icon: Icon(Icons.edit, color: primaryColor),
                onPressed: () => _showEditQuestionDialog(controller, question),
              ),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  Get.dialog(
                    AlertDialog(
                      title: Text('Delete Question'),
                      content: Text('Are you sure you want to delete this question?'),
                      actions: [
                        TextButton(
                          onPressed: () => Get.back(),
                          child: Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            controller.deleteQuestion(question.id, question.testId);
                            Get.back();
                          },
                          child: Text('Delete', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            question.question,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          SizedBox(height: 16),
          ...question.options.asMap().entries.map((entry) {
            final optionIndex = entry.key;
            final option = entry.value;
            final isCorrect = optionIndex == question.correctAnswerIndex;

            return Container(
              margin: EdgeInsets.only(bottom: 8),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCorrect
                    ? Colors.green.shade50
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isCorrect ? Colors.green : Colors.grey.shade300,
                  width: isCorrect ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isCorrect ? Colors.green : Colors.grey.shade400,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        String.fromCharCode(65 + optionIndex),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(child: Text(option)),
                  if (isCorrect)
                    Icon(Icons.check_circle, color: Colors.green, size: 20),
                ],
              ),
            );
          }),
          if (question.explanation != null && question.explanation!.isNotEmpty) ...[
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      question.explanation!,
                      style: TextStyle(color: Colors.blue.shade900, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Text(
        message,
        style: TextStyle(color: lightTextColor, fontSize: 16),
      ),
    );
  }

  void _showCreateTestDialog(BlogPostController controller) {
    final testNameController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: Text('Create New Test'),
        content: TextField(
          controller: testNameController,
          decoration: InputDecoration(
            labelText: 'Test Name',
            hintText: 'e.g., Test 1, Chapter 1 Quiz',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (testNameController.text.trim().isNotEmpty) {
                controller.createTest(
                  controller.selectedTopicId.value,
                  testNameController.text.trim(),
                );
                Get.back();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            child: Text('Create', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showGenerateQuestionsDialog(BlogPostController controller) {
    final questionCountController = TextEditingController(text: '20');
    TopicModel? selectedTopic;
    try {
      selectedTopic = controller.topics.firstWhere(
        (topic) => topic.id == controller.selectedTopicId.value,
      );
    } catch (e) {
      selectedTopic = null;
    }

    Get.dialog(
      AlertDialog(
        title: Text('Generate Questions with AI'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selectedTopic != null) ...[
              Text('Topic: ${selectedTopic.name}'),
              Text('Category: ${selectedTopic.category}'),
              SizedBox(height: 16),
            ],
            TextField(
              controller: questionCountController,
              decoration: InputDecoration(
                labelText: 'Number of Questions',
                hintText: '20',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
          Obx(() => ElevatedButton(
                onPressed: controller.isGeneratingQuestions.value
                    ? null
                    : () {
                        final count = int.tryParse(questionCountController.text) ?? 20;
                        if (selectedTopic != null) {
                          controller.generateQuestionsWithAI(
                            controller.selectedTestId.value,
                            selectedTopic.name,
                            selectedTopic.category,
                            count,
                          );
                          Get.back();
                        }
                      },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                child: controller.isGeneratingQuestions.value
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text('Generate', style: TextStyle(color: Colors.white)),
              )),
        ],
      ),
    );
  }

  void _showAddQuestionDialog(BlogPostController controller) {
    _showQuestionFormDialog(controller, QuestionModel(
      id: '',
      testId: controller.selectedTestId.value,
      question: '',
      options: ['', '', '', ''],
      correctAnswerIndex: 0,
    ));
  }

  void _showEditQuestionDialog(BlogPostController controller, QuestionModel question) {
    _showQuestionFormDialog(controller, question);
  }

  void _showQuestionFormDialog(BlogPostController controller, QuestionModel question) {
    final questionController = TextEditingController(text: question.question);
    final optionControllers = question.options.map((opt) => TextEditingController(text: opt)).toList();
    final explanationController = TextEditingController(text: question.explanation ?? '');
    int selectedCorrectAnswer = question.correctAnswerIndex;

    Get.dialog(
      AlertDialog(
        title: Text(question.id.isEmpty ? 'Add Question' : 'Edit Question'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: questionController,
                decoration: InputDecoration(
                  labelText: 'Question',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 16),
              ...optionControllers.asMap().entries.map((entry) {
                final index = entry.key;
                final controller = entry.value;
                return Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Radio<int>(
                        value: index,
                        groupValue: selectedCorrectAnswer,
                        onChanged: (value) {
                          selectedCorrectAnswer = value ?? 0;
                        },
                      ),
                      Expanded(
                        child: TextField(
                          controller: controller,
                          decoration: InputDecoration(
                            labelText: 'Option ${String.fromCharCode(65 + index)}',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              SizedBox(height: 16),
              TextField(
                controller: explanationController,
                decoration: InputDecoration(
                  labelText: 'Explanation (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final updatedQuestion = QuestionModel(
                id: question.id,
                testId: question.testId,
                question: questionController.text.trim(),
                options: optionControllers.map((c) => c.text.trim()).toList(),
                correctAnswerIndex: selectedCorrectAnswer,
                explanation: explanationController.text.trim().isEmpty
                    ? null
                    : explanationController.text.trim(),
              );
              controller.saveQuestion(updatedQuestion);
              Get.back();
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            child: Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showTestCountDialog(BlogPostController controller, TopicModel topic) {
    final selectedTestCount = ValueNotifier<int>(5);
    
    Get.dialog(
      AlertDialog(
        title: Text('Select Number of Tests'),
        content: ValueListenableBuilder<int>(
          valueListenable: selectedTestCount,
          builder: (context, value, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('How many tests do you want to create for "${topic.name}"?'),
                SizedBox(height: 20),
                RadioListTile<int>(
                  title: Text('5 Tests'),
                  value: 5,
                  groupValue: value,
                  onChanged: (newValue) {
                    selectedTestCount.value = newValue!;
                  },
                ),
                RadioListTile<int>(
                  title: Text('10 Tests'),
                  value: 10,
                  groupValue: value,
                  onChanged: (newValue) {
                    selectedTestCount.value = newValue!;
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              selectedTestCount.dispose();
              Get.back();
            },
            child: Text('Cancel'),
          ),
          ValueListenableBuilder<int>(
            valueListenable: selectedTestCount,
            builder: (context, testCount, child) {
              return ElevatedButton(
                onPressed: () {
                  final count = testCount;
                  selectedTestCount.dispose();
                  Get.back(); // Close dialog first
                  
                  // Create tests
                  controller.createTestsWithQuestions(
                    topic.id, 
                    topic.name, 
                    topic.category, 
                    count
                  );
                  
                  // Load tests after a short delay to allow creation to start
                  Future.delayed(Duration(milliseconds: 500), () {
                    if (!controller.isClosed) {
                      controller.loadTests(topic.id);
                    }
                  });
                },
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                child: Text('Create Tests', style: TextStyle(color: Colors.white)),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog(BlogPostController controller) {
    final categoryController = TextEditingController();
    
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Add New Category',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              SizedBox(height: 20),
              TextField(
                controller: categoryController,
                decoration: InputDecoration(
                  labelText: 'Category Name',
                  hintText: 'e.g., English, History',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  prefixIcon: Icon(Icons.category, color: primaryColor),
                ),
                autofocus: true,
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: Text('Cancel'),
                  ),
                  SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      if (categoryController.text.trim().isNotEmpty) {
                        controller.addCustomCategory(categoryController.text.trim());
                        Get.back();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('Add'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCustomTopicDialog(BlogPostController controller) {
    final topicController = TextEditingController();
    
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Create Custom Topic',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              SizedBox(height: 20),
              TextField(
                controller: topicController,
                decoration: InputDecoration(
                  labelText: 'Topic Name',
                  hintText: 'e.g., Chapter 1: Introduction',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  prefixIcon: Icon(Icons.topic, color: primaryColor),
                ),
                autofocus: true,
              ),
              SizedBox(height: 16),
              Obx(() => DropdownButtonFormField<String>(
                value: controller.selectedCategory.value,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  prefixIcon: Icon(Icons.category, color: primaryColor),
                ),
                items: controller.categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    controller.selectedCategory.value = value;
                  }
                },
              )),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: Text('Cancel'),
                  ),
                  SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      if (topicController.text.trim().isNotEmpty) {
                        controller.createCustomTopic(
                          topicController.text.trim(),
                          controller.selectedCategory.value,
                        );
                        Get.back();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('Create'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCategoryManagementDialog(BlogPostController controller) {
    final categoryController = TextEditingController();
    
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: EdgeInsets.all(24),
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Manage Categories',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              SizedBox(height: 20),
              TextField(
                controller: categoryController,
                decoration: InputDecoration(
                  labelText: 'New Category Name',
                  hintText: 'Enter category name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  prefixIcon: Icon(Icons.add, color: primaryColor),
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (categoryController.text.trim().isNotEmpty) {
                    controller.addCustomCategory(categoryController.text.trim());
                    categoryController.clear();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('Add Category'),
              ),
              SizedBox(height: 24),
              Text(
                'Existing Categories',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              SizedBox(height: 12),
              Obx(() => Container(
                    constraints: BoxConstraints(maxHeight: 300),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: controller.categories.length,
                      itemBuilder: (context, index) {
                        final category = controller.categories[index];
                        return Container(
                          margin: EdgeInsets.only(bottom: 8),
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.category, color: primaryColor, size: 20),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  category,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              if (controller.categories.length > 1)
                                IconButton(
                                  icon: Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                  onPressed: () {
                                    controller.deleteCategory(category);
                                  },
                                  padding: EdgeInsets.zero,
                                  constraints: BoxConstraints(),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
