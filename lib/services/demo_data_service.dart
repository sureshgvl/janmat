import '../models/achievement_model.dart';

class DemoDataService {
  static const Map<String, Map<String, String>> bioTemplates = {
    'professional': {
      'en': 'Dedicated public servant committed to community development, transparency, and inclusive governance. Working tirelessly to address local issues and improve quality of life for all citizens.',
      'mr': 'समुदाय विकास, पारदर्शकता आणि सर्वसमावेशक शासन यासाठी वचनबद्ध असलेला समर्पित सार्वजनिक सेवक. स्थानिक समस्या सोडवण्यासाठी आणि सर्व नागरिकांच्या जीवनाच्या गुणवत्तेत सुधारणा करण्यासाठी अथक परिश्रम करणे.',
    },
    'visionary': {
      'en': 'Visionary leader focused on sustainable development, education reform, and economic growth. Committed to building a prosperous future for our community through innovative solutions and collaborative partnerships.',
      'mr': 'शाश्वत विकास, शिक्षण सुधारणा आणि आर्थिक वाढ यावर लक्ष केंद्रित करणारा दूरदर्शी नेता. नाविन्यपूर्ण उपाय आणि सहयोगी भागीदारीद्वारे आमच्या समुदायासाठी समृद्ध भविष्य घडवण्यासाठी वचनबद्ध.',
    },
    'experienced': {
      'en': 'Seasoned administrator with extensive experience in public service and community engagement. Proven track record in implementing successful development projects and fostering positive change.',
      'mr': 'सार्वजनिक सेवा आणि समुदाय सहभागात मोठ्या अनुभव असलेला अनुभवी प्रशासक. यशस्वी विकास प्रकल्पांची अंमलबजावणी आणि सकारात्मक बदल घडवण्यात सिद्ध कार्यपद्धती.',
    },
    'youthful': {
      'en': 'Young, dynamic leader bringing fresh perspectives and modern solutions to traditional challenges. Committed to bridging the gap between youth aspirations and community needs.',
      'mr': 'परंपरागत आव्हानांना नवीन दृष्टिकोन आणि आधुनिक उपाय आणणारा तरुण, गतिशील नेता. युवा आकांक्षा आणि समुदाय गरजा यांच्यातील दरी भरून काढण्यासाठी वचनबद्ध.',
    },
  };

  static const Map<String, Map<String, String>> manifestoTemplates = {
    'development': {
      'en': '''**Infrastructure Development:**
• Modern road networks and public transportation
• Clean water supply and sanitation facilities
• Reliable electricity and digital connectivity

**Education & Healthcare:**
• Quality education for all children
• Accessible healthcare services
• Skill development programs

**Economic Growth:**
• Job creation through local industries
• Support for small businesses
• Agricultural modernization

**Social Welfare:**
• Senior citizen care programs
• Women empowerment initiatives
• Environmental conservation''',
      'mr': '''**पायाभूत सुविधा विकास:**
• आधुनिक रस्ते नेटवर्क आणि सार्वजनिक वाहतूक
• स्वच्छ पाणी पुरवठा आणि स्वच्छता सुविधा
• विश्वासार्ह वीज आणि डिजिटल कनेक्टिव्हिटी

**शिक्षण आणि आरोग्य:**
• सर्व मुलांसाठी दर्जेदार शिक्षण
• प्रवेशयोग्य आरोग्य सेवा
• कौशल्य विकास कार्यक्रम

**आर्थिक वाढ:**
• स्थानिक उद्योगांद्वारे रोजगार निर्मिती
• लहान व्यवसायांना समर्थन
• कृषी आधुनिकीकरण

**सामाजिक कल्याण:**
• वृद्ध नागरिक काळजी कार्यक्रम
• महिला सशक्तीकरण उपक्रम
• पर्यावरण संरक्षण''',
    },
    'transparency': {
      'en': '''**Transparency & Accountability:**
• Regular public meetings and updates
• Open budget discussions
• Performance tracking and reporting

**Digital Governance:**
• Online complaint and suggestion system
• Real-time project monitoring
• Digital service delivery

**Community Participation:**
• Ward committee involvement
• Youth and women representation
• Regular feedback mechanisms

**Anti-Corruption Measures:**
• Transparent tender processes
• Regular audits and reviews
• Whistleblower protection''',
      'mr': '''**पारदर्शकता आणि जबाबदारी:**
• नियमित सार्वजनिक बैठक आणि अद्यतने
• खुला बजेट चर्चा
• कामगिरी ट्रॅकिंग आणि अहवाल

**डिजिटल शासन:**
• ऑनलाइन तक्रार आणि सूचना प्रणाली
• रिअल-टाइम प्रकल्प देखरेख
• डिजिटल सेवा वितरण

**समुदाय सहभाग:**
• वॉर्ड समिती सहभाग
• युवा आणि महिला प्रतिनिधित्व
• नियमित अभिप्राय यंत्रणा

**भ्रष्टाचार विरोधी उपाय:**
• पारदर्शक निविदा प्रक्रिया
• नियमित ऑडिट आणि पुनरावलोकन
• व्हिसलब्लोअर संरक्षण''',
    },
  };

  static const Map<String, Map<String, List<Map<String, dynamic>>>> achievementTemplates = {
    'community_service': {
      'en': [
        {
          'title': 'Clean Water Project',
          'description': 'Successfully implemented clean water project serving 500+ households with sustainable water supply',
          'year': 2023,
        },
        {
          'title': 'Vaccination Drive',
          'description': 'Organized vaccination drives reaching 2000+ residents and achieving 95% vaccination coverage',
          'year': 2022,
        },
        {
          'title': 'Tree Plantation Initiative',
          'description': 'Led tree plantation initiative planting 1000+ trees in the community area',
          'year': 2021,
        },
        {
          'title': 'Disaster Relief Coordination',
          'description': 'Coordinated disaster relief efforts during monsoon floods, providing aid to 300+ affected families',
          'year': 2020,
        },
        {
          'title': 'Community Learning Center',
          'description': 'Established community learning center for underprivileged children with 150+ enrolled students',
          'year': 2019,
        },
      ],
      'mr': [
        {
          'title': 'स्वच्छ पाणी प्रकल्प',
          'description': '500+ कुटुंबांना शाश्वत पाणी पुरवठा देणारा स्वच्छ पाणी प्रकल्प यशस्वीरीत्या अंमलात आणला',
          'year': 2023,
        },
        {
          'title': 'लसीकरण मोहीम',
          'description': '2000+ रहिवाशांना पोहोचणारे लसीकरण मोहीम आयोजित केले आणि 95% लसीकरण कव्हरेज प्राप्त केले',
          'year': 2022,
        },
        {
          'title': 'वृक्षारोपण मोहीम',
          'description': 'समुदाय क्षेत्रात 1000+ झाडे लावणारी वृक्षारोपण मोहीम सुरू केली',
          'year': 2021,
        },
        {
          'title': 'आपत्ती मदत समन्वय',
          'description': 'पावसाळी पुरात आपत्ती मदत प्रयत्न समन्वयित केले, 300+ प्रभावित कुटुंबांना मदत पुरवली',
          'year': 2020,
        },
        {
          'title': 'समुदाय शिक्षण केंद्र',
          'description': 'वंचित मुलांसाठी समुदाय शिक्षण केंद्र स्थापन केले, 150+ विद्यार्थी नोंदणीकृत',
          'year': 2019,
        },
      ],
    },
    'administrative': {
      'en': [
        {
          'title': 'Service Delivery Optimization',
          'description': 'Streamlined municipal service delivery reducing response time by 40% through process improvements',
          'year': 2023,
        },
        {
          'title': 'Digital Record System',
          'description': 'Implemented digital record-keeping system improving efficiency and reducing paperwork by 60%',
          'year': 2022,
        },
        {
          'title': 'Budget Management',
          'description': 'Successfully managed ward development budget of ₹50 lakhs with 100% utilization and positive outcomes',
          'year': 2021,
        },
        {
          'title': 'Infrastructure Coordination',
          'description': 'Coordinated with state agencies for infrastructure projects worth ₹2 crores',
          'year': 2020,
        },
        {
          'title': 'Best Administrator Award',
          'description': 'Received "Best Ward Administrator" award for outstanding performance and community service',
          'year': 2019,
        },
      ],
      'mr': [
        {
          'title': 'सेवा वितरण ऑप्टिमायझेशन',
          'description': 'प्रक्रिया सुधारणेद्वारे 40% प्रतिसाद वेळ कमी करून महानगरपालिका सेवा वितरण सुव्यवस्थित केले',
          'year': 2023,
        },
        {
          'title': 'डिजिटल रेकॉर्ड सिस्टम',
          'description': 'कार्यक्षमता सुधारणारे आणि 60% कागदपत्रे कमी करणारे डिजिटल रेकॉर्ड-कीपिंग सिस्टम अंमलात आणले',
          'year': 2022,
        },
        {
          'title': 'बजेट व्यवस्थापन',
          'description': '₹50 लाख वार्ड विकास बजेट यशस्वीरीत्या व्यवस्थापित केले, 100% वापर आणि सकारात्मक परिणाम',
          'year': 2021,
        },
        {
          'title': 'पायाभूत सुविधा समन्वय',
          'description': '₹2 कोटी किमतीच्या पायाभूत सुविधा प्रकल्पांसाठी राज्य एजन्सींसह समन्वय साधला',
          'year': 2020,
        },
        {
          'title': 'सर्वोत्कृष्ट प्रशासक पुरस्कार',
          'description': 'उत्कृष्ट कामगिरी आणि समुदाय सेवेसाठी "सर्वोत्कृष्ट वार्ड प्रशासक" पुरस्कार प्राप्त केला',
          'year': 2019,
        },
      ],
    },
  };

  static const Map<String, Map<String, String>> highlightTemplates = {
    'vision': {
      'en': 'Building a sustainable, inclusive, and prosperous community where every citizen has access to quality education, healthcare, and economic opportunities. Together, we can create a brighter future for our ward and inspire positive change across our city.',
      'mr': 'शाश्वत, सर्वसमावेशक आणि समृद्ध समुदाय घडवणे जिथे प्रत्येक नागरिकाला दर्जेदार शिक्षण, आरोग्य आणि आर्थिक संधी मिळतील. एकत्रितपणे, आपण आपल्या वार्डसाठी उज्ज्वल भविष्य निर्माण करू शकतो आणि आपल्या शहरात सकारात्मक बदलाला प्रेरणा देऊ शकतो.',
    },
    'commitment': {
      'en': 'My commitment is simple: to serve with integrity, transparency, and dedication. Every decision I make will prioritize the welfare of our community members. I believe in collaborative governance and will work tirelessly to ensure that every voice is heard and every need is addressed.',
      'mr': 'माझे वचन सोपे आहे: ईमानदारी, पारदर्शकता आणि समर्पणाने सेवा देणे. मी घेतलेला प्रत्येक निर्णय आमच्या समुदाय सदस्यांच्या कल्याणाला प्राधान्य देईल. मी सहयोगी शासनात विश्वास ठेवतो आणि प्रत्येक आवाज ऐकला जातो आणि प्रत्येक गरज पूर्ण केली जाते याची खात्री करण्यासाठी अथक परिश्रम करेन.',
    },
  };

  // Get demo data for a specific category and language
  static dynamic getDemoData(String category, String type, String language) {
    switch (category) {
      case 'bio':
        return bioTemplates[type]?[language] ?? bioTemplates['professional']!['en']!;
      case 'manifesto':
        return manifestoTemplates[type]?[language] ?? manifestoTemplates['development']!['en']!;
      case 'achievements':
        final data = achievementTemplates[type]?[language] ?? achievementTemplates['community_service']!['en']!;
        return data.map((item) => Achievement.fromJson(item)).toList();
      case 'highlight':
        return highlightTemplates[type]?[language] ?? highlightTemplates['vision']!['en']!;
      default:
        return '';
    }
  }

  // Get available types for a category
  static List<String> getAvailableTypes(String category) {
    switch (category) {
      case 'bio':
        return bioTemplates.keys.toList();
      case 'manifesto':
        return manifestoTemplates.keys.toList();
      case 'achievements':
        return achievementTemplates.keys.toList();
      case 'highlight':
        return highlightTemplates.keys.toList();
      default:
        return [];
    }
  }

  // Get display names for types
  static String getTypeDisplayName(String type) {
    switch (type) {
      case 'professional':
        return 'Professional';
      case 'visionary':
        return 'Visionary';
      case 'experienced':
        return 'Experienced';
      case 'youthful':
        return 'Youthful';
      case 'development':
        return 'Development Focus';
      case 'transparency':
        return 'Transparency Focus';
      case 'community_service':
        return 'Community Service';
      case 'administrative':
        return 'Administrative';
      case 'vision':
        return 'Vision Statement';
      case 'commitment':
        return 'Commitment Statement';
      default:
        return type;
    }
  }
}