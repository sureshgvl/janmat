# 📋 Candidate Dashboard Sections JSON Structure

This document shows the complete JSON structure for all candidate dashboard sections as stored in Firebase, organized for easy management.

## 🔥 Firebase Document Structure

### Collection: `candidates`
### Document ID: Auto-generated or `candidate_{id}`

---

## 📄 Complete Candidate JSON with Dashboard Sections

```json
{
  // ========== BASIC CANDIDATE FIELDS (Outside extra_info) ==========
  "candidateId": "candidate_12345",
  "userId": "user_abc123",
  "name": "राजेश कुमार शिंदे",
  "party": "शिवसेना",
  "symbol": "🌹",
  "cityId": "pune",
  "wardId": "ward_23",
  "manifesto": "Legacy field - basic manifesto text",
  "photo": "https://firebasestorage.googleapis.com/v0/b/janmat-app.appspot.com/o/candidate_photos%2Fcandidate_12345_1694523456789.jpg?alt=media",
  "coverPhoto": "https://firebasestorage.googleapis.com/v0/b/janmat-app.appspot.com/o/cover_photos%2Fcandidate_12345_1694523456789.jpg?alt=media",
  "contact": {
    "phone": "+91 9876543210",
    "email": "rajesh.shinde@email.com",
    "socialLinks": {
      "facebook": "https://facebook.com/rajeshshinde23",
      "instagram": "https://instagram.com/rajeshshinde23",
      "twitter": "https://twitter.com/rajeshshinde23"
    }
  },
  "sponsored": false,
  "premium": true,
  "createdAt": "2025-09-11T17:11:03.869Z",
  "followersCount": 1250,
  "followingCount": 89,
  "approved": true,
  "status": "pending_election",

  // ========== DASHBOARD SECTIONS (Inside extra_info) ==========
  "extra_info": {

    // ==========================================
    // 🏆 ACHIEVEMENTS SECTION
    // ==========================================
    "achievements": [
      {
        "title": "स्वच्छता मोहीम",
        "description": "वार्डमध्ये 500+ कचरा कंटेनर बसवले आणि स्वच्छता मोहीम राबवली",
        "year": 2023,
        "photoUrl": "https://firebasestorage.googleapis.com/v0/b/janmat-app.appspot.com/o/achievement_photos%2Fcandidate_12345_cleanliness_1694523456789.jpg?alt=media"
      },
      {
        "title": "युवा रोजगार कार्यक्रम",
        "description": "100+ युवकांना रोजगार मिळवून दिले आणि कौशल्य प्रशिक्षण दिले",
        "year": 2022,
        "photoUrl": "https://firebasestorage.googleapis.com/v0/b/janmat-app.appspot.com/o/achievement_photos%2Fcandidate_12345_youth_employment_1694523456789.jpg?alt=media"
      },
      {
        "title": "आरोग्य शिबिर आयोजन",
        "description": "महिला आणि बालकांसाठी मोफत आरोग्य तपासणी शिबिर आयोजित केले",
        "year": 2021,
        "photoUrl": "https://firebasestorage.googleapis.com/v0/b/janmat-app.appspot.com/o/achievement_photos%2Fcandidate_12345_health_camp_1694523456789.jpg?alt=media"
      }
    ],

    // ==========================================
    // 📝 MANIFESTO SECTION
    // ==========================================
    "manifesto": {
      // Legacy fields (backward compatibility)
      "legacy_text": "Basic manifesto text for backward compatibility",
      "pdf_url": "https://firebasestorage.googleapis.com/v0/b/janmat-app.appspot.com/o/manifestos%2Fcandidate_12345_1694523456789.pdf?alt=media",

      // New structured fields
      "title": "वॉर्ड 23 विकास आणि पारदर्शकता योजना",
      "promises": [
        {
          "title": "स्वच्छ पाणी व चांगले रस्ते",
          "points": [
            "प्रत्येक घराला २४x७ स्वच्छ पाणी पुरवठा.",
            "खड्डेमुक्त वॉर्ड रस्ते १ वर्षात.",
            "पावसाळी नाले सफाई व देखभाल.",
            "सार्वजनिक वाहतूक सुविधा वाढवणे."
          ]
        },
        {
          "title": "पारदर्शकता आणि जबाबदारी",
          "points": [
            "नियमित सार्वजनिक बैठक आणि अद्यतने",
            "खुला बजेट चर्चा आणि निर्णय प्रक्रिया",
            "ऑनलाइन तक्रार निवारण प्रणाली",
            "वार्ड विकास निधीचा पारदर्शक वापर"
          ]
        },
        {
          "title": "शिक्षण आणि युवा विकास",
          "points": [
            "डिजिटल लायब्ररी आणि ई-लर्निंग केंद्र",
            "कौशल्य प्रशिक्षण कार्यक्रम",
            "शाळेत आरोग्य तपासणी आणि पोषण कार्यक्रम",
            "युवकांसाठी रोजगार मार्गदर्शन केंद्र"
          ]
        },
        {
          "title": "महिला आणि सुरक्षा",
          "points": [
            "महिलांसाठी विशेष आरोग्य केंद्र",
            "प्रत्येक चौकात CCTV कॅमेरे",
            "स्वयंरक्षण प्रशिक्षण शिबिर",
            "महिला हेल्पलाइन आणि समर्थन सेवा"
          ]
        }
      ],
      "image_url": "https://firebasestorage.googleapis.com/v0/b/janmat-app.appspot.com/o/manifesto_images%2Fcandidate_12345_1694523456789.jpg?alt=media",
      "video_url": "https://firebasestorage.googleapis.com/v0/b/janmat-app.appspot.com/o/manifesto_videos%2Fcandidate_12345_1694523456789.mp4?alt=media",
      "verified": true,
      "analytics": {
        "views": 1250,
        "likes": 89,
        "shares": 34,
        "downloads": 67,
        "last_viewed": "2025-09-11T18:30:00.000Z"
      }
    },

    // ==========================================
    // 📞 CONTACT SECTION
    // ==========================================
    "contact": {
      "phone": "+91 9876543210",
      "email": "rajesh.shinde@email.com",
      "address": "Sector 5, Ward 23, Pune, Maharashtra - 411001",
      "social_links": {
        "facebook": "https://facebook.com/rajeshshinde23",
        "instagram": "https://instagram.com/rajeshshinde23",
        "twitter": "https://twitter.com/rajeshshinde23",
        "whatsapp": "+91 9876543210"
      },
      "office_address": "Ward Office, Sector 5, Ward 23",
      "office_hours": "Monday to Friday: 9:00 AM - 5:00 PM"
    },

    // ==========================================
    // 📷 MEDIA SECTION
    // ==========================================
    "media": {
      "photos": [
        {
          "url": "https://firebasestorage.googleapis.com/v0/b/janmat-app.appspot.com/o/media%2Fcandidate_12345_photo1.jpg?alt=media",
          "caption": "वार्ड विकास कार्यक्रम",
          "uploaded_at": "2025-09-10T10:30:00.000Z"
        },
        {
          "url": "https://firebasestorage.googleapis.com/v0/b/janmat-app.appspot.com/o/media%2Fcandidate_12345_photo2.jpg?alt=media",
          "caption": "युवा साथीदार कार्यक्रम",
          "uploaded_at": "2025-09-09T14:20:00.000Z"
        }
      ],
      "videos": [
        {
          "url": "https://firebasestorage.googleapis.com/v0/b/janmat-app.appspot.com/o/media%2Fcandidate_12345_video1.mp4?alt=media",
          "title": "वार्ड 23 विकास योजना",
          "description": "माझ्या वार्डच्या विकासासाठीचे नियोजन",
          "duration": "00:02:30",
          "uploaded_at": "2025-09-08T16:45:00.000Z"
        }
      ],
      "documents": [
        {
          "url": "https://firebasestorage.googleapis.com/v0/b/janmat-app.appspot.com/o/documents%2Fcandidate_12345_doc1.pdf?alt=media",
          "title": "वार्ड बजेट प्रस्ताव",
          "type": "budget_proposal",
          "uploaded_at": "2025-09-07T11:15:00.000Z"
        }
      ]
    },

    // ==========================================
    // 📅 EVENTS SECTION
    // ==========================================
    "events": [
      {
        "id": "event_001",
        "title": "वार्ड विकास बैठक",
        "description": "स्थानिक विकास योजना आणि बजेट चर्चा",
        "date": "2025-09-15",
        "time": "10:00 AM",
        "venue": "वार्ड ऑफिस, सेक्टर 5",
        "type": "meeting",
        "status": "upcoming",
        "attendees_expected": 50,
        "agenda": [
          "मागील बैठकीचा आढावा",
          "नवीन विकास प्रकल्प प्रस्ताव",
          "बजेट वाटप चर्चा"
        ]
      },
      {
        "id": "event_002",
        "title": "स्वच्छता मोहीम",
        "description": "वार्डमध्ये स्वच्छता आणि पर्यावरण जागरूकता कार्यक्रम",
        "date": "2025-09-20",
        "time": "8:00 AM",
        "venue": "वार्डातील सर्व मुख्य चौक",
        "type": "campaign",
        "status": "upcoming",
        "attendees_expected": 200,
        "agenda": [
          "स्वच्छता उपकरणे वाटप",
          "पर्यावरण जागरूकता कार्यक्रम",
          "कचरा व्यवस्थापन चर्चा"
        ]
      },
      {
        "id": "event_003",
        "title": "युवा संवाद",
        "description": "युवा आणि विद्यार्थ्यांशी संवाद सत्र",
        "date": "2025-09-25",
        "time": "4:00 PM",
        "venue": "स्थानिक शाळा ऑडिटोरियम",
        "type": "interaction",
        "status": "upcoming",
        "attendees_expected": 150,
        "agenda": [
          "युवा समस्या चर्चा",
          "शिक्षण आणि रोजगार संधी",
          "युवा सहभाग वाढवणे"
        ]
      }
    ],

    // ==========================================
    // ⭐ HIGHLIGHT SECTION
    // ==========================================
    "highlight": {
      "enabled": true,
      "title": "वचनबद्ध विकासासाठी",
      "message": "वार्ड 23 च्या सर्वांगीण विकासासाठी आणि पारदर्शक शासनासाठी वचनबद्ध. एकत्रितपणे चांगले भविष्य घडवूया!",
      "image_url": "https://firebasestorage.googleapis.com/v0/b/janmat-app.appspot.com/o/highlights%2Fcandidate_12345_highlight.jpg?alt=media",
      "priority": "high",
      "expires_at": "2025-12-31T23:59:59.000Z"
    },

    // ==========================================
    // 📊 ANALYTICS SECTION (Premium Feature)
    // ==========================================
    "analytics": {
      "profile_views": 2450,
      "manifesto_views": 1250,
      "follower_growth": [
        {"date": "2025-09-01", "count": 1200},
        {"date": "2025-09-11", "count": 1250}
      ],
      "engagement_rate": 0.15,
      "top_performing_content": {
        "manifesto": {"views": 1250, "likes": 89},
        "events": {"attendees": 150, "interactions": 45},
        "media": {"views": 890, "shares": 34}
      },
      "demographics": {
        "age_groups": {"18-25": 30, "26-35": 45, "36-50": 20, "50+": 5},
        "gender": {"male": 65, "female": 35},
        "locations": {"ward_23": 80, "nearby_wards": 20}
      }
    },

    // ==========================================
    // 👤 BASIC INFO (Additional)
    // ==========================================
    "basic_info": {
      "full_name": "राजेश कुमार शिंदे",
      "date_of_birth": "1985-03-15",
      "age": 39,
      "gender": "male",
      "education": "एम.ए. राजकारण शास्त्र, बी.ई. अभियांत्रिकी",
      "profession": "राजकीय कार्यकर्ता, सामाजिक सेवक",
      "languages": ["मराठी", "हिंदी", "इंग्रजी"],
      "experience_years": 15,
      "previous_positions": [
        "वार्ड सदस्य (2015-2020)",
        "जिल्हा युवा अध्यक्ष (2018-2020)",
        "सामाजिक संस्था सचिव (2020-हाल)"
      ]
    }
  }
}
```

---

## 📊 Section-wise Field Breakdown

### 🏆 **ACHIEVEMENTS Section**
```json
"achievements": [
  {
    "title": "Achievement Title",
    "description": "Detailed description",
    "year": 2023,
    "photoUrl": "Firebase Storage URL"
  }
]
```

### 📝 **MANIFESTO Section**
```json
"manifesto": {
  "title": "Manifesto Title",
  "promises": [
    {
      "title": "Promise Category",
      "points": ["Point 1", "Point 2", "Point 3"]
    }
  ],
  "image_url": "Image URL",
  "video_url": "Video URL",
  "verified": true,
  "analytics": {
    "views": 1250,
    "likes": 89,
    "shares": 34,
    "downloads": 67
  }
}
```

### 📞 **CONTACT Section**
```json
"contact": {
  "phone": "+91 9876543210",
  "email": "candidate@email.com",
  "address": "Full address",
  "social_links": {
    "facebook": "URL",
    "instagram": "URL",
    "twitter": "URL"
  }
}
```

### 📷 **MEDIA Section**
```json
"media": {
  "photos": [
    {
      "url": "Photo URL",
      "caption": "Photo description",
      "uploaded_at": "Timestamp"
    }
  ],
  "videos": [
    {
      "url": "Video URL",
      "title": "Video title",
      "duration": "00:02:30"
    }
  ]
}
```

### 📅 **EVENTS Section**
```json
"events": [
  {
    "title": "Event Title",
    "date": "2025-09-15",
    "time": "10:00 AM",
    "venue": "Event location",
    "type": "meeting/campaign/interaction",
    "agenda": ["Point 1", "Point 2"]
  }
]
```

### ⭐ **HIGHLIGHT Section**
```json
"highlight": {
  "enabled": true,
  "title": "Highlight title",
  "message": "Highlight message",
  "priority": "high/medium/low"
}
```

### 📊 **ANALYTICS Section**
```json
"analytics": {
  "profile_views": 2450,
  "follower_growth": [...],
  "engagement_rate": 0.15,
  "demographics": {...}
}
```

---

## 🔄 Data Management Structure

### **Why This Organization?**

1. **Basic Fields Outside `extra_info`:**
   - Core candidate identification
   - Essential contact information
   - System-level metadata

2. **Dashboard Sections in `extra_info`:**
   - **Achievements:** Career highlights and accomplishments
   - **Manifesto:** Political promises and plans
   - **Contact:** Extended contact details
   - **Media:** Photos, videos, documents
   - **Events:** Scheduled activities and meetings
   - **Highlight:** Featured content
   - **Analytics:** Performance metrics (premium)

### **Benefits:**

✅ **Easy Management:** Each section is clearly separated  
✅ **Scalability:** New sections can be added easily  
✅ **Query Optimization:** Can query specific sections  
✅ **Backward Compatibility:** Legacy fields preserved  
✅ **Performance:** Load only required sections  

---

## 📂 Firebase Storage Organization

```
janmat-app.appspot.com/
├── candidate_photos/          # Profile photos
├── cover_photos/             # Cover images
├── manifestos/               # Manifesto PDFs
├── manifesto_images/         # Manifesto images
├── manifesto_videos/         # Manifesto videos
├── achievement_photos/       # Achievement photos
├── media/                    # General media (photos/videos)
├── highlights/               # Highlight images
└── documents/                # Additional documents
```

---

## 🔍 Query Examples

### Get Candidate with Specific Sections
```javascript
// Get only manifesto and achievements
const candidate = await db.collection('candidates')
  .doc(candidateId)
  .get();

const manifesto = candidate.data().extra_info.manifesto;
const achievements = candidate.data().extra_info.achievements;
```

### Update Specific Section
```javascript
// Update only manifesto section
await db.collection('candidates').doc(candidateId)
  .update({
    'extra_info.manifesto.verified': true,
    'extra_info.manifesto.analytics.views': firebase.firestore.FieldValue.increment(1)
  });
```

---

## ⚡ Real-time Updates

```javascript
// Listen for section-specific updates
db.collection('candidates').doc(candidateId)
  .onSnapshot((doc) => {
    const data = doc.data();
    // Handle specific section updates
    if (data.extra_info.manifesto) {
      updateManifesto(data.extra_info.manifesto);
    }
    if (data.extra_info.achievements) {
      updateAchievements(data.extra_info.achievements);
    }
  });
```

This structure provides optimal organization for managing all candidate dashboard sections efficiently!