import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class AsthmaInfoCenterScreen extends StatefulWidget {
  const AsthmaInfoCenterScreen({Key? key}) : super(key: key);

  @override
  State<AsthmaInfoCenterScreen> createState() => _AsthmaInfoCenterScreenState();
}

class _AsthmaInfoCenterScreenState extends State<AsthmaInfoCenterScreen> {
  final List<AsthmaInfoCategory> _categories = [
    AsthmaInfoCategory(
      title: 'Symptoms',
      icon: Icons.sick,
      color: Colors.red.shade400,
      details: [
        'Shortness of breath',
        'Chest tightness or pain',
        'Wheezing when exhaling',
        'Trouble sleeping caused by shortness of breath',
        'Coughing or wheezing attacks worsened by respiratory illness',
        'Difficulty talking due to breathlessness',
      ],
    ),
    AsthmaInfoCategory(
      title: 'Triggers',
      icon: Icons.warning_amber,
      color: Colors.orange.shade400,
      details: [
        'Airborne allergens (pollen, dust mites, pet dander)',
        'Respiratory infections (colds, flu)',
        'Physical activity (exercise-induced asthma)',
        'Cold air exposure',
        'Air pollutants and irritants (smoke, strong odors)',
        'Certain medications (aspirin, NSAIDs)',
        'Strong emotions and stress',
        'Food additives (sulfites)',
      ],
    ),
    AsthmaInfoCategory(
      title: 'Precautions',
      icon: Icons.health_and_safety,
      color: Colors.green.shade400,
      details: [
        'Identify and avoid your asthma triggers',
        'Take prescribed medications regularly',
        'Monitor breathing with peak flow meter',
        'Keep a rescue inhaler readily available',
        'Get vaccinated for flu and pneumonia',
        'Maintain good indoor air quality',
        'Use air purifiers if needed',
        'Create an asthma action plan with your doctor',
      ],
    ),
    AsthmaInfoCategory(
      title: 'Emergency Signs',
      icon: Icons.emergency,
      color: Colors.purple.shade400,
      details: [
        'Severe shortness of breath or wheezing',
        'No improvement after using rescue inhaler',
        'Shortness of breath while talking',
        'Straining chest muscles to breathe',
        'Bluish tint to lips or fingernails',
        'Feelings of panic or anxiety due to breathing difficulty',
        'If experiencing these symptoms, seek emergency medical help immediately',
      ],
    ),
    AsthmaInfoCategory(
      title: 'Managing Asthma',
      icon: Icons.manage_accounts,
      color: Colors.blue.shade400,
      details: [
        'Take medications as prescribed',
        'Use your smart mask to monitor breath parameters',
        'Track your symptoms and triggers in the app',
        'Visit your doctor regularly for checkups',
        'Adjust your treatment plan as needed based on data',
        'Learn proper inhaler technique',
        'Practice breathing exercises',
        'Maintain overall health with proper diet and exercise',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Asthma Information Center',
          style: TextStyle(
            color: AppColors.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppColors.primaryColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Introduction card
              _buildInfoCard(
                title: 'About Asthma',
                content: 'Asthma is a chronic condition affecting the airways in the lungs. '
                    'It causes inflammation and narrowing of the airways, leading to breathing difficulties. '
                    'While there is no cure, proper management can help control symptoms and prevent complications.',
                icon: Icons.info_outline,
                color: AppColors.primaryColor,
              ),
              
              const SizedBox(height: 24),
              
              // Category list
              ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: _categories.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  return _buildCategoryExpansionTile(_categories[index]);
                },
              ),
              
              const SizedBox(height: 24),
              
              // Disclaimer
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.medical_services, color: Colors.grey.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Medical Disclaimer',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'The information provided in this app is for general informational purposes only and should not be considered as professional medical advice. '
                      'Always consult with a qualified healthcare provider for diagnosis and treatment options for asthma.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String content,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            content,
            style: TextStyle(
              fontSize: 15,
              color: AppColors.secondaryTextColor,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryExpansionTile(AsthmaInfoCategory category) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          title: Row(
            children: [
              Icon(category.icon, color: category.color, size: 24),
              const SizedBox(width: 12),
              Text(
                category.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryTextColor,
                ),
              ),
            ],
          ),
          collapsedBackgroundColor: Colors.white,
          backgroundColor: Colors.white,
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: category.details.map((detail) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Expanded(
                          child: Text(
                            detail,
                            style: TextStyle(
                              fontSize: 15,
                              color: AppColors.secondaryTextColor,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AsthmaInfoCategory {
  final String title;
  final IconData icon;
  final Color color;
  final List<String> details;

  AsthmaInfoCategory({
    required this.title,
    required this.icon,
    required this.color,
    required this.details,
  });
} 