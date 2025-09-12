# 📋 Candidate JSON Structure in Firebase

This document shows the complete JSON structure of candidate data as stored in Firebase Firestore.

## 🔥 Firebase Document Structure

### Collection: `candidates`
### Document ID: Auto-generated or `candidate_{id}`

---

## 📄 Complete Candidate JSON Example

```json
{
  "candidateId": "candidate_12345",
  "userId": "user_abc123",
  "name": "राजेश कुमार शिंदे",
  "party": "शिवसेना",
  "symbol": "🌹",
  "cityId": "pune",
  "wardId": "ward_23",
  "manifesto": "Legacy field - basic manifesto text for backward compatibility",
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
  "extra_info": {
    "bio": "15 वर्षांचा राजकीय अनुभव. वार्ड 23 च्या विकासासाठी वचनबद्ध. युवा आणि महिला सशक्तीकरणावर विशेष लक्ष.",
    "achievements": [
      {
        "title": "स्वच्छता मोहीम",
        "description": "वार्डमध्ये 500+ कचरा कंटेनर बसवले आणि स्वच्छता मोहीम राबवली",
        "year": 2023,
        "photoUrl": "https://firebasestorage.googleapis.com/v0/b/janmat-app.appspot.com/o/achievement_photos%2Fcandidate_12345_cleanliness_1694523456789.jpg?alt=media"
      }
    ],
    "manifesto": "Legacy field - basic manifesto text",
    "manifesto_pdf": "https://firebasestorage.googleapis.com/v0/b/janmat-app.appspot.com/o/manifestos%2Fcandidate_12345_1694523456789.pdf?alt=media",
    "manifesto_title": "वॉर्ड 23 विकास आणि पारदर्शकता योजना",
    "manifesto_promises": [
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
    "manifesto_image": "https://firebasestorage.googleapis.com/v0/b/janmat-app.appspot.com/o/manifesto_images%2Fcandidate_12345_1694523456789.jpg?alt=media",
    "manifesto_video": "https://firebasestorage.googleapis.com/v0/b/janmat-app.appspot.com/o/manifesto_videos%2Fcandidate_12345_1694523456789.mp4?alt=media",
    "manifesto_verified": true,
    "manifesto_analytics": {
      "views": 1250,
      "likes": 89,
      "shares": 34,
      "downloads": 67,
      "lastViewed": "2025-09-11T18:30:00.000Z"
    },
    "contact": {
      "phone": "+91 9876543210",
      "email": "rajesh.shinde@email.com"
    },
    "media": {
      "photos": [
        "https://firebasestorage.googleapis.com/v0/b/janmat-app.appspot.com/o/media%2Fcandidate_12345_photo1.jpg?alt=media",
        "https://firebasestorage.googleapis.com/v0/b/janmat-app.appspot.com/o/media%2Fcandidate_12345_photo2.jpg?alt=media"
      ],
      "videos": [
        "https://firebasestorage.googleapis.com/v0/b/janmat-app.appspot.com/o/media%2Fcandidate_12345_video1.mp4?alt=media"
      ]
    },
    "highlight": true,
    "events": [
      {
        "title": "वार्ड विकास बैठक",
        "date": "2025-09-15",
        "time": "10:00 AM",
        "venue": "वार्ड ऑफिस, सेक्टर 5",
        "description": "स्थानिक विकास योजना चर्चा"
      }
    ],
    "age": 45,
    "gender": "male",
    "education": "एम.ए. राजकारण शास्त्र",
    "address": "सector 5, Ward 23, Pune, Maharashtra - 411001"
  }
}
```

---

## 📊 Field Explanations

### 🔑 Core Candidate Fields

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `candidateId` | String | Unique identifier | `"candidate_12345"` |
| `userId` | String | Associated user ID | `"user_abc123"` |
| `name` | String | Full name | `"राजेश कुमार शिंदे"` |
| `party` | String | Political party | `"शिवसेना"` |
| `symbol` | String | Party symbol emoji | `"🌹"` |
| `cityId` | String | City identifier | `"pune"` |
| `wardId` | String | Ward identifier | `"ward_23"` |
| `photo` | String | Profile photo URL | Firebase Storage URL |
| `coverPhoto` | String | Cover photo URL | Firebase Storage URL |
| `sponsored` | Boolean | Sponsored candidate | `false` |
| `premium` | Boolean | Premium features | `true` |
| `createdAt` | Timestamp | Creation date | ISO 8601 format |
| `followersCount` | Number | Number of followers | `1250` |
| `followingCount` | Number | Number following | `89` |
| `approved` | Boolean | Admin approval | `true` |
| `status` | String | Election status | `"pending_election"` |

### 📞 Contact Information

```json
{
  "contact": {
    "phone": "+91 9876543210",
    "email": "rajesh.shinde@email.com",
    "socialLinks": {
      "facebook": "https://facebook.com/username",
      "instagram": "https://instagram.com/username",
      "twitter": "https://twitter.com/username"
    }
  }
}
```

### 📝 Manifesto Structure

#### Legacy Fields (Backward Compatibility)
```json
{
  "manifesto": "Basic text manifesto",
  "manifesto_pdf": "https://storage.googleapis.com/manifestos/file.pdf"
}
```

#### New Structured Manifesto
```json
{
  "manifesto_title": "वॉर्ड 23 विकास योजना",
  "manifesto_promises": [
    {
      "title": "स्वच्छ पाणी व चांगले रस्ते",
      "points": [
        "प्रत्येक घराला २४x७ स्वच्छ पाणी पुरवठा.",
        "खड्डेमुक्त वॉर्ड रस्ते १ वर्षात.",
        "पावसाळी नाले सफाई व देखभाल."
      ]
    }
  ],
  "manifesto_image": "https://storage.googleapis.com/manifesto_images/image.jpg",
  "manifesto_video": "https://storage.googleapis.com/manifesto_videos/video.mp4",
  "manifesto_verified": true,
  "manifesto_analytics": {
    "views": 1250,
    "likes": 89,
    "shares": 34,
    "downloads": 67
  }
}
```

### 🏆 Achievements Structure

```json
{
  "achievements": [
    {
      "title": "स्वच्छता मोहीम",
      "description": "वार्डमध्ये 500+ कचरा कंटेनर बसवले",
      "year": 2023,
      "photoUrl": "https://storage.googleapis.com/achievement_photos/photo.jpg"
    }
  ]
}
```

### 📊 Analytics Structure

```json
{
  "manifesto_analytics": {
    "views": 1250,
    "likes": 89,
    "shares": 34,
    "downloads": 67,
    "lastViewed": "2025-09-11T18:30:00.000Z"
  }
}
```

### 🎥 Media Structure

```json
{
  "media": {
    "photos": [
      "https://storage.googleapis.com/media/photo1.jpg",
      "https://storage.googleapis.com/media/photo2.jpg"
    ],
    "videos": [
      "https://storage.googleapis.com/media/video1.mp4"
    ]
  }
}
```

### 📅 Events Structure

```json
{
  "events": [
    {
      "title": "वार्ड विकास बैठक",
      "date": "2025-09-15",
      "time": "10:00 AM",
      "venue": "वार्ड ऑफिस, सेक्टर 5",
      "description": "स्थानिक विकास योजना चर्चा"
    }
  ]
}
```

---

## 🔄 Data Migration Notes

### From Legacy to New Structure

**Old Format:**
```json
{
  "manifesto": "Basic text only",
  "manifesto_pdf": "pdf_url"
}
```

**New Format:**
```json
{
  "manifesto": "Basic text (kept for compatibility)",
  "manifesto_pdf": "pdf_url (kept for compatibility)",
  "manifesto_title": "Custom title",
  "manifesto_promises": [
    {
      "title": "Promise Title",
      "points": ["Point 1", "Point 2"]
    }
  ],
  "manifesto_image": "image_url",
  "manifesto_video": "video_url",
  "manifesto_verified": true,
  "manifesto_analytics": {
    "views": 0,
    "likes": 0,
    "shares": 0,
    "downloads": 0
  }
}
```

---

## 📂 Firebase Storage Structure

```
janmat-app.appspot.com/
├── candidate_photos/
│   └── candidate_{id}_{timestamp}.jpg
├── cover_photos/
│   └── candidate_{id}_{timestamp}.jpg
├── manifestos/
│   └── candidate_{id}_{timestamp}.pdf
├── manifesto_images/
│   └── candidate_{id}_{timestamp}.jpg
├── manifesto_videos/
│   └── candidate_{id}_{timestamp}.mp4
├── achievement_photos/
│   └── candidate_{id}_{achievement_title}_{timestamp}.jpg
└── media/
    ├── candidate_{id}_photo1.jpg
    └── candidate_{id}_video1.mp4
```

---

## 🔍 Query Examples

### Get All Candidates in a Ward
```javascript
const candidates = await db.collection('candidates')
  .where('cityId', '==', 'pune')
  .where('wardId', '==', 'ward_23')
  .where('approved', '==', true)
  .get();
```

### Get Premium Candidates with Analytics
```javascript
const premiumCandidates = await db.collection('candidates')
  .where('premium', '==', true)
  .where('extra_info.manifesto_verified', '==', true)
  .orderBy('followersCount', 'desc')
  .limit(10)
  .get();
```

---

## ⚡ Real-time Updates

The app listens for real-time updates on candidate documents:

```javascript
// Listen for manifesto updates
db.collection('candidates').doc(candidateId)
  .onSnapshot((doc) => {
    const data = doc.data();
    // Update UI with new manifesto data
  });
```

---

## 🔐 Security Rules

```javascript
// Firestore Security Rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /candidates/{candidateId} {
      allow read: if true; // Public read access
      allow write: if request.auth != null &&
        (request.auth.uid == resource.data.userId ||
         request.auth.token.admin == true);
    }
  }
}
```

This structure provides comprehensive candidate data storage with backward compatibility and room for future enhancements.