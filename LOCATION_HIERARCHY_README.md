# Location Hierarchy System Documentation

## Overview

This document provides comprehensive information about the location hierarchy system used in the Janmat Admin Panel for managing Indian local body elections. The system supports a hierarchical structure of States → Districts → Bodies → Wards.

## 🏗️ System Architecture

### Hierarchical Structure
```
States
├── Districts
    ├── Bodies (Municipal Corporations/Councils/Panchayats)
        ├── Wards
```

### Firebase Collections
```
/states/{stateId}/districts/{districtId}/bodies/{bodyId}/wards/{wardId}
```

## 📊 Data Models

### Core Types

#### TypeScript Enums
```typescript
export type BodyType =
  | 'municipal_corporation'
  | 'municipal_council'
  | 'nagar_panchayat'
  | 'zilla_parishad'
  | 'panchayat_samiti'

export type ElectionType =
  | 'parliamentary'
  | 'assembly'
  | BodyType
```

#### Dart Enums
```dart
enum BodyType {
  municipalCorporation,
  municipalCouncil,
  nagarPanchayat,
  zillaParishad,
  panchayatSamiti,
}
```

### Entity Models

#### State Model
**TypeScript:**
```typescript
interface State {
  id: string                    // "MH"
  name: string                  // "Maharashtra"
  code?: string                 // "MH"
  marathiName?: string          // "महाराष्ट्र"
  isActive?: boolean            // true
  createdAt?: string | Date
  updatedAt?: string | Date
}
```

**Dart:**
```dart
@JsonSerializable()
class State {
  final String id;
  final String name;
  final String? code;
  final String? marathiName;
  final bool? isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}
```

#### District Model
**TypeScript:**
```typescript
interface District {
  id: string                    // "pune"
  name: string                  // "Pune"
  stateId: string               // "MH"
  municipalCorporation?: string // "Pune Municipal Corporation"
  municipalCouncil?: string     // "Pimpri Chinchwad Municipal Council"
  nagarPanchayat?: string       // "Local Nagar Panchayat"
  zillaParishad?: string        // "Pune Zilla Parishad"
  panchayatSamiti?: string      // "Local Panchayat Samiti"
  municipalCorporationPdfUrl?: string
  municipalCouncilPdfUrl?: string
  nagarPanchayatPdfUrl?: string
  zillaParishadPdfUrl?: string
  panchayatSamitiPdfUrl?: string
  createdAt?: string | Date
}
```

**Dart:**
```dart
@JsonSerializable()
class District {
  final String id;
  final String name;
  final String stateId;
  final String? municipalCorporation;
  final String? municipalCouncil;
  final String? nagarPanchayat;
  final String? zillaParishad;
  final String? panchayatSamiti;
  final String? municipalCorporationPdfUrl;
  final String? municipalCouncilPdfUrl;
  final String? nagarPanchayatPdfUrl;
  final String? zillaParishadPdfUrl;
  final String? panchayatSamitiPdfUrl;
  final DateTime? createdAt;
}
```

#### Body Model
**TypeScript:**
```typescript
interface Body {
  id: string                    // "pune_municipal_corporation"
  name: string                  // "Pune Municipal Corporation"
  type: BodyType                // "municipal_corporation"
  districtId: string            // "pune"
  stateId: string               // "MH"
  ward_count?: number           // 41
  area_to_ward?: Record<string, string>
  source?: Record<string, any>
  special?: Record<string, any>
  createdAt?: string | Date
}
```

**Dart:**
```dart
@JsonSerializable()
class Body {
  final String id;
  final String name;
  @JsonKey(fromJson: _bodyTypeFromJson, toJson: _bodyTypeToJson)
  final BodyType type;
  final String districtId;
  final String stateId;
  final int? wardCount;
  final Map<String, String>? areaToWard;
  final Map<String, dynamic>? source;
  final Map<String, dynamic>? special;
  final DateTime? createdAt;
}
```

#### Ward Model
**TypeScript:**
```typescript
interface Ward {
  id: string                    // "ward_1"
  name: string                  // "कळस-धानोरी"
  number?: number               // 1
  bodyId: string                // "pune_municipal_corporation"
  districtId: string            // "pune"
  stateId: string               // "MH"
  population_total?: number     // 92644
  sc_population?: number        // 18010
  st_population?: number        // 2274
  areas?: string[]              // ["धानोरी गावठाण", "कळस गावठाण"]
  assembly_constituency?: string
  parliamentary_constituency?: string
  createdAt?: string | Date
}
```

**Dart:**
```dart
@JsonSerializable()
class Ward {
  final String id;
  final String name;
  final int? number;
  final String bodyId;
  final String districtId;
  final String stateId;
  final int? populationTotal;
  final int? scPopulation;
  final int? stPopulation;
  final List<String>? areas;
  final String? assemblyConstituency;
  final String? parliamentaryConstituency;
  final DateTime? createdAt;
}
```

## 🔗 API Endpoints

### States
- `GET /api/get-states` - Get all active states
- `POST /api/add-state` - Create new state

### Districts
- `GET /api/admin/states/{stateId}/districts` - Get districts for a state
- `POST /api/add-district` - Create new district
- `POST /api/admin/update-district` - Update district with PDFs

### Bodies
- `GET /api/get-bodies?stateId={stateId}&districtId={districtId}` - Get bodies for district
- `POST /api/add-body` - Create new body
- `GET /api/admin/bodies/{bodyId}` - Get body details
- `PUT /api/admin/bodies/{bodyId}` - Update body

### Wards
- `GET /api/admin/states/{stateId}/districts/{districtId}/bodies/{bodyId}/wards` - Get wards for body
- `POST /api/add-ward-structure` - Create new ward
- `PUT /api/add-ward-structure` - Update existing ward

## 📝 Usage Examples

### TypeScript/JavaScript

#### Fetching Data
```typescript
// Get districts for a state
const districts: District[] = await fetch(`/api/admin/states/${stateId}/districts`)
  .then(res => res.json())
  .then(data => data.districts)

// Get bodies for a district
const bodies: Body[] = await fetch(`/api/get-bodies?stateId=${stateId}&districtId=${districtId}`)
  .then(res => res.json())
  .then(data => data.bodies)
```

#### Creating Entities
```typescript
const districtData: CreateDistrictData = {
  stateId: "MH",
  districtId: "pune",
  districtName: "Pune",
  municipalCorporation: "Pune Municipal Corporation"
}

await fetch('/api/add-district', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify(districtData)
})
```

### Dart/Flutter

#### Fetching Data
```dart
Future<List<District>> fetchDistricts(String stateId) async {
  final response = await http.get(Uri.parse('/api/admin/states/$stateId/districts'));
  final data = json.decode(response.body) as Map<String, dynamic>;
  final districtsResponse = DistrictsResponse.fromJson(data);
  return districtsResponse.districts;
}
```

#### Creating Entities
```dart
Future<void> createDistrict(CreateDistrictData data) async {
  final response = await http.post(
    Uri.parse('/api/add-district'),
    headers: {'Content-Type': 'application/json'},
    body: json.encode(data.toJson()),
  );

  if (response.statusCode == 200) {
   debugPrint('District created successfully');
  }
}
```

## 🗂️ Firebase Data Structure

### JSON Structure
```json
{
  "states": {
    "MH": {
      "code": "MH",
      "name": "Maharashtra",
      "marathiName": "महाराष्ट्र",
      "isActive": true,
      "districts": {
        "pune": {
          "name": "Pune",
          "municipalCorporation": "Pune Municipal Corporation",
          "bodies": {
            "pune_municipal_corporation": {
              "name": "Pune Municipal Corporation",
              "type": "municipal_corporation",
              "ward_count": 41,
              "wards": {
                "ward_1": {
                  "name": "कळस-धानोरी",
                  "number": 1,
                  "population_total": 92644,
                  "sc_population": 18010,
                  "st_population": 2274,
                  "areas": ["धानोरी गावठाण", "कळस गावठाण"]
                }
              }
            }
          }
        }
      }
    }
  }
}
```

## 🔐 Security Rules

### Firestore Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // States collection
    match /states/{stateId} {
      allow read, write: if request.auth != null &&
        (request.auth.token.admin == true || request.auth.token.role == 'admin');
    }

    match /states/{stateId}/districts/{districtId} {
      allow read, write: if request.auth != null &&
        (request.auth.token.admin == true || request.auth.token.role == 'admin');
    }

    match /states/{stateId}/districts/{districtId}/bodies/{bodyId} {
      allow read, write: if request.auth != null &&
        (request.auth.token.admin == true || request.auth.token.role == 'admin');
    }

    match /states/{stateId}/districts/{districtId}/bodies/{bodyId}/wards/{wardId} {
      allow read, write: if request.auth != null &&
        (request.auth.token.admin == true || request.auth.token.role == 'admin');
    }
  }
}
```

## 🛠️ Setup Instructions

### TypeScript Setup
1. Copy the interfaces from `src/types/location.ts`
2. Use them in your components and API calls

### Flutter Setup
1. Add dependencies to `pubspec.yaml`:
```yaml
dependencies:
  json_annotation: ^4.8.1

dev_dependencies:
  json_serializable: ^6.7.1
  build_runner: ^2.4.6
```

2. Create model files and run:
```bash
flutter pub run build_runner build
```

## 🎯 Election Types Supported

| Election Type | Description | Ward-based? |
|---------------|-------------|-------------|
| Municipal Corporation | Large city governance | ✅ Yes |
| Municipal Council | Smaller city/town governance | ✅ Yes |
| Nagar Panchayat | Transitional area governance | ✅ Yes |
| Zilla Parishad | District-level rural governance | ✅ Yes |
| Panchayat Samiti | Block-level rural governance | ✅ Yes |

## 🔄 Migration Notes

- **From flat structure**: Districts were previously stored at root `/districts/` level
- **To hierarchical**: Now stored under `/states/{stateId}/districts/`
- **Migration script**: Available at `scripts/migrate-districts-to-states.js`

## 📞 Support

For questions about the location hierarchy system:
1. Check this documentation
2. Review the API endpoints
3. Check Firebase console for data structure
4. Contact development team

---

**Last Updated**: September 25, 2025
**Version**: 1.0.0