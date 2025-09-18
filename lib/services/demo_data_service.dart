import '../features/candidate/models/candidate_achievement_model.dart';
import '../features/candidate/models/candidate_model.dart';

class DemoDataService {
  static const Map<String, Map<String, String>> bioTemplates = {
    'professional': {
      'en':
          'Dedicated public servant committed to community development, transparency, and inclusive governance. Working tirelessly to address local issues and improve quality of life for all citizens.',
      'mr':
          'समुदाय विकास, पारदर्शकता आणि सर्वसमावेशक शासन यासाठी वचनबद्ध असलेला समर्पित सार्वजनिक सेवक. स्थानिक समस्या सोडवण्यासाठी आणि सर्व नागरिकांच्या जीवनाच्या गुणवत्तेत सुधारणा करण्यासाठी अथक परिश्रम करणे.',
    },
    'visionary': {
      'en':
          'Visionary leader focused on sustainable development, education reform, and economic growth. Committed to building a prosperous future for our community through innovative solutions and collaborative partnerships.',
      'mr':
          'शाश्वत विकास, शिक्षण सुधारणा आणि आर्थिक वाढ यावर लक्ष केंद्रित करणारा दूरदर्शी नेता. नाविन्यपूर्ण उपाय आणि सहयोगी भागीदारीद्वारे आमच्या समुदायासाठी समृद्ध भविष्य घडवण्यासाठी वचनबद्ध.',
    },
    'experienced': {
      'en':
          'Seasoned administrator with extensive experience in public service and community engagement. Proven track record in implementing successful development projects and fostering positive change.',
      'mr':
          'सार्वजनिक सेवा आणि समुदाय सहभागात मोठ्या अनुभव असलेला अनुभवी प्रशासक. यशस्वी विकास प्रकल्पांची अंमलबजावणी आणि सकारात्मक बदल घडवण्यात सिद्ध कार्यपद्धती.',
    },
    'youthful': {
      'en':
          'Young, dynamic leader bringing fresh perspectives and modern solutions to traditional challenges. Committed to bridging the gap between youth aspirations and community needs.',
      'mr':
          'परंपरागत आव्हानांना नवीन दृष्टिकोन आणि आधुनिक उपाय आणणारा तरुण, गतिशील नेता. युवा आकांक्षा आणि समुदाय गरजा यांच्यातील दरी भरून काढण्यासाठी वचनबद्ध.',
    },
  };

  static const Map<String, Map<String, String>> manifestoTemplates = {
    'development': {
      'en': '''**Clean Water & Good Roads:**
• 24x7 clean water supply to every household
• pothole-free ward roads within 1 year
• Street lighting for all lanes and bylanes

**Waste Management & Cleanliness:**
• 100% household waste collection
• Ward-level cleanliness app for citizens
• Community composting centers

**Basic Infrastructure:**
• Drainage system improvement
• Park development and maintenance
• Public toilet construction and maintenance''',
      'mr': '''**स्वच्छ पाणी व चांगले रस्ते:**
• प्रत्येक घराला २४x७ स्वच्छ पाणी पुरवठा
• खड्डेमुक्त वॉर्ड रस्ते १ वर्षात
• सर्व गल्ल्या-बोळात स्ट्रीट लाईट

**कचरा व्यवस्थापन व स्वच्छता:**
• १००% घरगुती कचरा संकलन
• वॉर्ड स्तरावर स्वच्छता अॅप – नागरिक थेट तक्रार नोंदवू शकतात
• समुदाय कंपोस्टिंग केंद्र

**मूलभूत पायाभूत सुविधा:**
• नाला प्रणाली सुधारणा
• उद्यान विकास आणि देखभाल
• सार्वजनिक शौचालय बांधणी आणि देखभाल''',
    },
    'transparency': {
      'en': '''**Transparency & Accountability:**
• Online public record of every expense
• Every 3 months "Progress Report" meeting with citizens
• Ward development fund utilization report

**Digital Governance:**
• Online complaint and suggestion system
• Real-time project monitoring dashboard
• Digital ward committee meetings

**Community Participation:**
• Monthly ward sabha meetings
• Youth and women representation in committees
• Regular feedback collection from residents''',
      'mr': '''**पारदर्शकता व जबाबदारी:**
• प्रत्येक खर्चाची ऑनलाईन सार्वजनिक नोंद
• दर ३ महिन्यांनी नागरिकांसोबत "Progress Report" बैठक
• वॉर्ड विकास निधी वापर अहवाल

**डिजिटल शासन:**
• ऑनलाइन तक्रार आणि सूचना प्रणाली
• रिअल-टाइम प्रकल्प देखरेख डॅशबोर्ड
• डिजिटल वॉर्ड समिती बैठक

**समुदाय सहभाग:**
• मासिक वॉर्ड सभा बैठक
• समित्यांमध्ये युवा आणि महिला प्रतिनिधित्व
• रहिवाशांकडून नियमित अभिप्राय संकलन''',
    },
    'youth_education': {
      'en': '''**Education & Youth Development:**
• Digital classrooms in every school
• Employment skill training center for youth
• Career counseling and job placement assistance

**Sports & Cultural Activities:**
• Sports facilities and playground development
• Youth club for cultural activities
• Library and study center establishment

**Digital Literacy:**
• Computer training for youth and senior citizens
• Online education platform access
• Mobile library service for remote areas''',
      'mr': '''**शिक्षण व तरुणाई विकास:**
• प्रत्येक शाळेत डिजिटल क्लासरूम
• तरुणांसाठी रोजगार कौशल्य प्रशिक्षण केंद्र
• करियर सल्ला आणि नोकरी मिळवण्यात मदत

**क्रीडा व सांस्कृतिक उपक्रम:**
• क्रीडा सुविधा आणि खेळाचे मैदान विकास
• सांस्कृतिक उपक्रमांसाठी युवा क्लब
• ग्रंथालय आणि अभ्यास केंद्र स्थापना

**डिजिटल साक्षरता:**
• युवा आणि वृद्ध नागरिकांसाठी संगणक प्रशिक्षण
• ऑनलाइन शिक्षण प्लॅटफॉर्म प्रवेश
• दूरस्थ भागांसाठी मोबाईल ग्रंथालय सेवा''',
    },
    'women_safety': {
      'en': '''**Women & Safety Measures:**
• CCTV cameras at every corner
• Special health centers for women
• Women helpline and support services

**Women Empowerment:**
• Self-defense training camps for women
• Women entrepreneurship development
• Working women hostel facility

**Child & Family Welfare:**
• Crèche facilities for working mothers
• Women and child health check-up camps
• Domestic violence prevention programs''',
      'mr': '''**महिला व सुरक्षा उपाय:**
• प्रत्येक चौकात CCTV कॅमेरे
• महिलांसाठी विशेष आरोग्य केंद्र
• महिला हेल्पलाइन आणि समर्थन सेवा

**महिला सशक्तीकरण:**
• महिलांसाठी स्वयंरक्षण प्रशिक्षण शिबिर
• महिला उद्योजकता विकास
• काम करणाऱ्या महिलांसाठी हॉस्टेल सुविधा

**बालक व कुटुंब कल्याण:**
• काम करणाऱ्या मातांसाठी क्रेच सुविधा
• महिला आणि बाल आरोग्य तपासणी शिबिर
• घरगुती हिंसा प्रतिबंध कार्यक्रम''',
    },
  };

  static const Map<String, Map<String, List<Map<String, dynamic>>>>
  achievementTemplates = {
    'community_service': {
      'en': [
        {
          'title': 'Clean Water Project',
          'description':
              'Successfully implemented clean water project serving 500+ households with sustainable water supply',
          'year': 2023,
        },
        {
          'title': 'Vaccination Drive',
          'description':
              'Organized vaccination drives reaching 2000+ residents and achieving 95% vaccination coverage',
          'year': 2022,
        },
        {
          'title': 'Tree Plantation Initiative',
          'description':
              'Led tree plantation initiative planting 1000+ trees in the community area',
          'year': 2021,
        },
        {
          'title': 'Disaster Relief Coordination',
          'description':
              'Coordinated disaster relief efforts during monsoon floods, providing aid to 300+ affected families',
          'year': 2020,
        },
        {
          'title': 'Community Learning Center',
          'description':
              'Established community learning center for underprivileged children with 150+ enrolled students',
          'year': 2019,
        },
      ],
      'mr': [
        {
          'title': 'स्वच्छ पाणी प्रकल्प',
          'description':
              '500+ कुटुंबांना शाश्वत पाणी पुरवठा देणारा स्वच्छ पाणी प्रकल्प यशस्वीरीत्या अंमलात आणला',
          'year': 2023,
        },
        {
          'title': 'लसीकरण मोहीम',
          'description':
              '2000+ रहिवाशांना पोहोचणारे लसीकरण मोहीम आयोजित केले आणि 95% लसीकरण कव्हरेज प्राप्त केले',
          'year': 2022,
        },
        {
          'title': 'वृक्षारोपण मोहीम',
          'description':
              'समुदाय क्षेत्रात 1000+ झाडे लावणारी वृक्षारोपण मोहीम सुरू केली',
          'year': 2021,
        },
        {
          'title': 'आपत्ती मदत समन्वय',
          'description':
              'पावसाळी पुरात आपत्ती मदत प्रयत्न समन्वयित केले, 300+ प्रभावित कुटुंबांना मदत पुरवली',
          'year': 2020,
        },
        {
          'title': 'समुदाय शिक्षण केंद्र',
          'description':
              'वंचित मुलांसाठी समुदाय शिक्षण केंद्र स्थापन केले, 150+ विद्यार्थी नोंदणीकृत',
          'year': 2019,
        },
      ],
    },
    'administrative': {
      'en': [
        {
          'title': 'Service Delivery Optimization',
          'description':
              'Streamlined municipal service delivery reducing response time by 40% through process improvements',
          'year': 2023,
        },
        {
          'title': 'Digital Record System',
          'description':
              'Implemented digital record-keeping system improving efficiency and reducing paperwork by 60%',
          'year': 2022,
        },
        {
          'title': 'Budget Management',
          'description':
              'Successfully managed ward development budget of ₹50 lakhs with 100% utilization and positive outcomes',
          'year': 2021,
        },
        {
          'title': 'Infrastructure Coordination',
          'description':
              'Coordinated with state agencies for infrastructure projects worth ₹2 crores',
          'year': 2020,
        },
        {
          'title': 'Best Administrator Award',
          'description':
              'Received "Best Ward Administrator" award for outstanding performance and community service',
          'year': 2019,
        },
      ],
      'mr': [
        {
          'title': 'सेवा वितरण ऑप्टिमायझेशन',
          'description':
              'प्रक्रिया सुधारणेद्वारे 40% प्रतिसाद वेळ कमी करून महानगरपालिका सेवा वितरण सुव्यवस्थित केले',
          'year': 2023,
        },
        {
          'title': 'डिजिटल रेकॉर्ड सिस्टम',
          'description':
              'कार्यक्षमता सुधारणारे आणि 60% कागदपत्रे कमी करणारे डिजिटल रेकॉर्ड-कीपिंग सिस्टम अंमलात आणले',
          'year': 2022,
        },
        {
          'title': 'बजेट व्यवस्थापन',
          'description':
              '₹50 लाख वार्ड विकास बजेट यशस्वीरीत्या व्यवस्थापित केले, 100% वापर आणि सकारात्मक परिणाम',
          'year': 2021,
        },
        {
          'title': 'पायाभूत सुविधा समन्वय',
          'description':
              '₹2 कोटी किमतीच्या पायाभूत सुविधा प्रकल्पांसाठी राज्य एजन्सींसह समन्वय साधला',
          'year': 2020,
        },
        {
          'title': 'सर्वोत्कृष्ट प्रशासक पुरस्कार',
          'description':
              'उत्कृष्ट कामगिरी आणि समुदाय सेवेसाठी "सर्वोत्कृष्ट वार्ड प्रशासक" पुरस्कार प्राप्त केला',
          'year': 2019,
        },
      ],
    },
  };

  static const Map<String, Map<String, String>> highlightTemplates = {
    'vision': {
      'en':
          'Building a sustainable, inclusive, and prosperous community where every citizen has access to quality education, healthcare, and economic opportunities. Together, we can create a brighter future for our ward and inspire positive change across our city.',
      'mr':
          'शाश्वत, सर्वसमावेशक आणि समृद्ध समुदाय घडवणे जिथे प्रत्येक नागरिकाला दर्जेदार शिक्षण, आरोग्य आणि आर्थिक संधी मिळतील. एकत्रितपणे, आपण आपल्या वार्डसाठी उज्ज्वल भविष्य निर्माण करू शकतो आणि आपल्या शहरात सकारात्मक बदलाला प्रेरणा देऊ शकतो.',
    },
    'commitment': {
      'en':
          'My commitment is simple: to serve with integrity, transparency, and dedication. Every decision I make will prioritize the welfare of our community members. I believe in collaborative governance and will work tirelessly to ensure that every voice is heard and every need is addressed.',
      'mr':
          'माझे वचन सोपे आहे: ईमानदारी, पारदर्शकता आणि समर्पणाने सेवा देणे. मी घेतलेला प्रत्येक निर्णय आमच्या समुदाय सदस्यांच्या कल्याणाला प्राधान्य देईल. मी सहयोगी शासनात विश्वास ठेवतो आणि प्रत्येक आवाज ऐकला जातो आणि प्रत्येक गरज पूर्ण केली जाते याची खात्री करण्यासाठी अथक परिश्रम करेन.',
    },
  };

  static const Map<String, Map<String, List<Map<String, dynamic>>>>
  eventTemplates = {
    'political': {
      'en': [
        {
          'title': 'जनसंपर्क सभा – वारजे',
          'description':
              'Public meeting to discuss ward development issues and gather feedback from residents',
          'date': '2025-09-15',
          'time': '18:00',
          'venue': 'वारजे बस स्टँड जवळ',
          'map_link': 'https://maps.app.goo.gl/xyz123',
          'type': 'public_meeting',
          'status': 'upcoming',
        },
        {
          'title': 'रॅली – कोंढवा',
          'description':
              'Victory rally showcasing party achievements and future plans',
          'date': '2025-09-20',
          'time': '16:00',
          'venue': 'कोंढवा चौक',
          'map_link': 'https://maps.app.goo.gl/abc456',
          'type': 'rally',
          'status': 'upcoming',
        },
        {
          'title': 'वॉर्ड समिती बैठक',
          'description':
              'Monthly ward committee meeting to review ongoing projects and plan new initiatives',
          'date': '2025-09-25',
          'time': '10:00',
          'venue': 'वॉर्ड ऑफिस, पिंपरी',
          'map_link': 'https://maps.app.goo.gl/def789',
          'type': 'meeting',
          'status': 'upcoming',
        },
      ],
      'mr': [
        {
          'title': 'जनसंपर्क सभा – वारजे',
          'description':
              'वॉर्ड विकासाच्या समस्यांवर चर्चा करण्यासाठी आणि रहिवाशांकडून अभिप्राय गोळा करण्यासाठी सार्वजनिक बैठक',
          'date': '2025-09-15',
          'time': '18:00',
          'venue': 'वारजे बस स्टँड जवळ',
          'map_link': 'https://maps.app.goo.gl/xyz123',
          'type': 'public_meeting',
          'status': 'upcoming',
        },
        {
          'title': 'रॅली – कोंढवा',
          'description':
              'पक्षाच्या कामगिरीचे प्रदर्शन आणि भविष्याच्या योजना दाखवणारी विजय रॅली',
          'date': '2025-09-20',
          'time': '16:00',
          'venue': 'कोंढवा चौक',
          'map_link': 'https://maps.app.goo.gl/abc456',
          'type': 'rally',
          'status': 'upcoming',
        },
        {
          'title': 'वॉर्ड समिती बैठक',
          'description':
              'चालू प्रकल्पांचे पुनरावलोकन आणि नवीन उपक्रमांची योजना करण्यासाठी मासिक वॉर्ड समिती बैठक',
          'date': '2025-09-25',
          'time': '10:00',
          'venue': 'वॉर्ड ऑफिस, पिंपरी',
          'map_link': 'https://maps.app.goo.gl/def789',
          'type': 'meeting',
          'status': 'upcoming',
        },
      ],
    },
    'community': {
      'en': [
        {
          'title': 'Cleanliness Drive',
          'description':
              'Community cleanliness campaign to keep our ward clean and green',
          'date': '2025-09-18',
          'time': '07:00',
          'venue': 'वॉर्ड पार्क',
          'map_link': 'https://maps.app.goo.gl/ghi012',
          'type': 'community_service',
          'status': 'upcoming',
        },
        {
          'title': 'Health Camp',
          'description':
              'Free health check-up camp for senior citizens and children',
          'date': '2025-09-22',
          'time': '09:00',
          'venue': 'कम्युनिटी हॉल',
          'map_link': 'https://maps.app.goo.gl/jkl345',
          'type': 'health_camp',
          'status': 'upcoming',
        },
        {
          'title': 'Youth Sports Tournament',
          'description': 'Inter-ward cricket tournament for youth development',
          'date': '2025-09-28',
          'time': '14:00',
          'venue': 'स्पोर्ट्स ग्राउंड',
          'map_link': 'https://maps.app.goo.gl/mno678',
          'type': 'sports',
          'status': 'upcoming',
        },
      ],
      'mr': [
        {
          'title': 'स्वच्छता मोहीम',
          'description':
              'आमचा वॉर्ड स्वच्छ आणि हिरवा ठेवण्यासाठी समुदाय स्वच्छता मोहीम',
          'date': '2025-09-18',
          'time': '07:00',
          'venue': 'वॉर्ड पार्क',
          'map_link': 'https://maps.app.goo.gl/ghi012',
          'type': 'community_service',
          'status': 'upcoming',
        },
        {
          'title': 'आरोग्य शिबिर',
          'description': 'वृद्ध नागरिक आणि मुलांसाठी मोफत आरोग्य तपासणी शिबिर',
          'date': '2025-09-22',
          'time': '09:00',
          'venue': 'कम्युनिटी हॉल',
          'map_link': 'https://maps.app.goo.gl/jkl345',
          'type': 'health_camp',
          'status': 'upcoming',
        },
        {
          'title': 'युवा क्रीडा स्पर्धा',
          'description': 'युवा विकासासाठी आंतर-वॉर्ड क्रिकेट स्पर्धा',
          'date': '2025-09-28',
          'time': '14:00',
          'venue': 'स्पोर्ट्स ग्राउंड',
          'map_link': 'https://maps.app.goo.gl/mno678',
          'type': 'sports',
          'status': 'upcoming',
        },
      ],
    },
  };

  // Get demo data for a specific category and language
  static dynamic getDemoData(String category, String type, String language) {
    switch (category) {
      case 'bio':
        return bioTemplates[type]?[language] ??
            bioTemplates['professional']!['en']!;
      case 'manifesto':
        return manifestoTemplates[type]?[language] ??
            manifestoTemplates['development']!['en']!;
      case 'achievements':
        final data =
            achievementTemplates[type]?[language] ??
            achievementTemplates['community_service']!['en']!;
        return data.map((item) => Achievement.fromJson(item)).toList();
      case 'events':
        final data =
            eventTemplates[type]?[language] ??
            eventTemplates['political']!['en']!;
        return data.map((item) => EventData.fromJson(item)).toList();
      case 'highlight':
        return highlightTemplates[type]?[language] ??
            highlightTemplates['vision']!['en']!;
      default:
        return '';
    }
  }

  // Get demo manifesto promises as structured format
  static List<Map<String, dynamic>> getDemoManifestoPromises(
    String type,
    String language,
  ) {
    final template = manifestoTemplates[type]?[language] ?? '';
    if (template.isEmpty) return [];

    // Parse the template into structured format
    final sections = template
        .split('**')
        .where((section) => section.trim().isNotEmpty)
        .toList();

    final List<Map<String, dynamic>> structuredPromises = [];

    for (int i = 0; i < sections.length; i += 2) {
      if (i + 1 < sections.length) {
        final title = sections[i].trim();
        final content = sections[i + 1].trim();

        // Extract points from content
        final points = content
            .split('\n')
            .where((line) => line.trim().isNotEmpty && line.contains('•'))
            .map((line) => line.replaceAll('•', '').trim())
            .toList();

        if (title.isNotEmpty && points.isNotEmpty) {
          structuredPromises.add({'title': title, 'points': points});
        }
      }
    }

    return structuredPromises;
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
      case 'events':
        return eventTemplates.keys.toList();
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
        return 'Infrastructure & Cleanliness';
      case 'transparency':
        return 'Transparency & Accountability';
      case 'youth_education':
        return 'Education & Youth Development';
      case 'women_safety':
        return 'Women & Safety Measures';
      case 'community_service':
        return 'Community Service';
      case 'administrative':
        return 'Administrative';
      case 'political':
        return 'Political Events';
      case 'community':
        return 'Community Events';
      case 'vision':
        return 'Vision Statement';
      case 'commitment':
        return 'Commitment Statement';
      default:
        return type;
    }
  }
}
