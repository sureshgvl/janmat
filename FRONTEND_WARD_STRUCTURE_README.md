# Frontend Ward Structure Integration Guide

This guide provides frontend developers with everything needed to integrate the new hierarchical ward structure into their applications.

## 📊 New Firebase Data Structure

### Hierarchical Structure
```
Firebase Firestore Structure:
districts/{districtId}
├── name: string
├── bodies/{bodyId}
    ├── name: string
    ├── type: string (e.g., "Municipal Corporation", "Municipal Council")
    ├── ward_count: number
    ├── area_to_ward: object (mapping areas to ward IDs)
    ├── source: object (containing source information)
    ├── special: object (special ward information)
    ├── wards/{wardId}
        ├── name: string
        ├── number: number (optional)
        ├── population_total: number (optional)
        ├── sc_population: number (optional)
        ├── st_population: number (optional)
        ├── areas: string[] (optional)
        ├── createdAt: timestamp
```

### Ward Data Fields
```typescript
interface WardData {
  name: string;              // Ward name (e.g., "Kalas-Dhanori")
  number?: number;           // Ward number (e.g., 1)
  population_total?: number; // Total population
  sc_population?: number;    // Scheduled Caste population
  st_population?: number;    // Scheduled Tribe population
  areas?: string[];          // List of areas in the ward
  createdAt: Date;           // Creation timestamp
}
```

## 🔗 API Endpoints

### Get All Districts
```typescript
GET /api/get-districts
Response: { success: true, districts: Array<{id: string, name: string}> }
```

### Get Bodies for a District
```typescript
GET /api/get-bodies?districtId={districtId}
Response: {
  success: true,
  bodies: Array<{
    id: string,
    name: string,
    type: string,
    ward_count: number
  }>
}
```

### Get Wards for a Body
```typescript
GET /api/get-wards?districtId={districtId}&bodyId={bodyId}
Response: {
  success: true,
  wards: Array<{
    id: string,
    name: string,
    number?: number,
    population_total?: number,
    sc_population?: number,
    st_population?: number,
    areas?: string[]
  }>
}
```

## 💻 Frontend Integration Examples

### React Hook for Ward Data
```typescript
// hooks/useWardData.ts
import { useState, useEffect } from 'react'

export interface Ward {
  id: string
  name: string
  number?: number
  population_total?: number
  sc_population?: number
  st_population?: number
  areas?: string[]
}

export interface Body {
  id: string
  name: string
  type: string
  ward_count: number
}

export interface District {
  id: string
  name: string
}

export function useDistricts() {
  const [districts, setDistricts] = useState<District[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetch('/api/get-districts')
      .then(res => res.json())
      .then(data => {
        if (data.success) {
          setDistricts(data.districts)
        }
      })
      .finally(() => setLoading(false))
  }, [])

  return { districts, loading }
}

export function useBodies(districtId: string | null) {
  const [bodies, setBodies] = useState<Body[]>([])
  const [loading, setLoading] = useState(false)

  useEffect(() => {
    if (!districtId) {
      setBodies([])
      return
    }

    setLoading(true)
    fetch(`/api/get-bodies?districtId=${districtId}`)
      .then(res => res.json())
      .then(data => {
        if (data.success) {
          setBodies(data.bodies)
        }
      })
      .finally(() => setLoading(false))
  }, [districtId])

  return { bodies, loading }
}

export function useWards(districtId: string | null, bodyId: string | null) {
  const [wards, setWards] = useState<Ward[]>([])
  const [loading, setLoading] = useState(false)

  useEffect(() => {
    if (!districtId || !bodyId) {
      setWards([])
      return
    }

    setLoading(true)
    fetch(`/api/get-wards?districtId=${districtId}&bodyId=${bodyId}`)
      .then(res => res.json())
      .then(data => {
        if (data.success) {
          setWards(data.wards)
        }
      })
      .finally(() => setLoading(false))
  }, [districtId, bodyId])

  return { wards, loading }
}
```

### Ward Selection Component
```typescript
// components/WardSelector.tsx
import React, { useState } from 'react'
import { useDistricts, useBodies, useWards, District, Body, Ward } from '../hooks/useWardData'

interface WardSelectorProps {
  onWardSelect: (ward: Ward) => void
  selectedWardId?: string
}

export default function WardSelector({ onWardSelect, selectedWardId }: WardSelectorProps) {
  const [selectedDistrict, setSelectedDistrict] = useState<string>('')
  const [selectedBody, setSelectedBody] = useState<string>('')

  const { districts, loading: districtsLoading } = useDistricts()
  const { bodies, loading: bodiesLoading } = useBodies(selectedDistrict)
  const { wards, loading: wardsLoading } = useWards(selectedDistrict, selectedBody)

  const handleDistrictChange = (districtId: string) => {
    setSelectedDistrict(districtId)
    setSelectedBody('')
  }

  const handleBodyChange = (bodyId: string) => {
    setSelectedBody(bodyId)
  }

  const handleWardSelect = (ward: Ward) => {
    onWardSelect(ward)
  }

  return (
    <div className="space-y-4">
      {/* District Selector */}
      <div>
        <label className="block text-sm font-medium text-gray-700">
          Select District
        </label>
        <select
          value={selectedDistrict}
          onChange={(e) => handleDistrictChange(e.target.value)}
          className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md"
          disabled={districtsLoading}
        >
          <option value="">Choose District</option>
          {districts.map(district => (
            <option key={district.id} value={district.id}>
              {district.name}
            </option>
          ))}
        </select>
      </div>

      {/* Body Selector */}
      {selectedDistrict && (
        <div>
          <label className="block text-sm font-medium text-gray-700">
            Select Body
          </label>
          <select
            value={selectedBody}
            onChange={(e) => handleBodyChange(e.target.value)}
            className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md"
            disabled={bodiesLoading}
          >
            <option value="">Choose Body</option>
            {bodies.map(body => (
              <option key={body.id} value={body.id}>
                {body.name} ({body.type})
              </option>
            ))}
          </select>
        </div>
      )}

      {/* Ward Selector */}
      {selectedBody && (
        <div>
          <label className="block text-sm font-medium text-gray-700">
            Select Ward
          </label>
          <div className="grid grid-cols-1 gap-2 max-h-60 overflow-y-auto">
            {wardsLoading ? (
              <div>Loading wards...</div>
            ) : (
              wards.map(ward => (
                <div
                  key={ward.id}
                  onClick={() => handleWardSelect(ward)}
                  className={`p-3 border rounded-md cursor-pointer hover:bg-gray-50 ${
                    selectedWardId === ward.id ? 'border-blue-500 bg-blue-50' : 'border-gray-300'
                  }`}
                >
                  <div className="font-medium">{ward.name}</div>
                  {ward.number && (
                    <div className="text-sm text-gray-600">Ward No: {ward.number}</div>
                  )}
                  {ward.population_total && (
                    <div className="text-sm text-gray-600">
                      Population: {ward.population_total.toLocaleString()}
                    </div>
                  )}
                  {ward.areas && ward.areas.length > 0 && (
                    <div className="text-sm text-gray-600">
                      Areas: {ward.areas.slice(0, 3).join(', ')}
                      {ward.areas.length > 3 && ` +${ward.areas.length - 3} more`}
                    </div>
                  )}
                </div>
              ))
            )}
          </div>
        </div>
      )}
    </div>
  )
}
```

### Ward Information Display Component
```typescript
// components/WardInfo.tsx
import React from 'react'
import { Ward } from '../hooks/useWardData'

interface WardInfoProps {
  ward: Ward
}

export default function WardInfo({ ward }: WardInfoProps) {
  return (
    <div className="bg-white p-6 rounded-lg shadow-md">
      <h3 className="text-xl font-semibold mb-4">{ward.name}</h3>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {ward.number && (
          <div>
            <span className="font-medium text-gray-700">Ward Number:</span>
            <span className="ml-2">{ward.number}</span>
          </div>
        )}

        {ward.population_total && (
          <div>
            <span className="font-medium text-gray-700">Total Population:</span>
            <span className="ml-2">{ward.population_total.toLocaleString()}</span>
          </div>
        )}

        {ward.sc_population && (
          <div>
            <span className="font-medium text-gray-700">SC Population:</span>
            <span className="ml-2">{ward.sc_population.toLocaleString()}</span>
          </div>
        )}

        {ward.st_population && (
          <div>
            <span className="font-medium text-gray-700">ST Population:</span>
            <span className="ml-2">{ward.st_population.toLocaleString()}</span>
          </div>
        )}
      </div>

      {ward.areas && ward.areas.length > 0 && (
        <div className="mt-4">
          <span className="font-medium text-gray-700">Areas:</span>
          <div className="mt-2 flex flex-wrap gap-2">
            {ward.areas.map((area, index) => (
              <span
                key={index}
                className="px-2 py-1 bg-gray-100 text-gray-800 text-sm rounded-md"
              >
                {area}
              </span>
            ))}
          </div>
        </div>
      )}
    </div>
  )
}
```

## 🔄 Migration from Old Structure

### Old Structure (Flat)
```typescript
// Old way - direct city/ward relationship
interface OldWard {
  id: string
  name: string
  number: number
  cityId: string
}
```

### New Structure (Hierarchical)
```typescript
// New way - district/body/ward hierarchy
interface NewWard {
  id: string
  name: string
  number?: number
  population_total?: number
  sc_population?: number
  st_population?: number
  areas?: string[]
}

// Migration helper
function migrateWardData(oldWard: OldWard): NewWard {
  return {
    id: oldWard.id,
    name: oldWard.name,
    number: oldWard.number,
    // Add default values for new fields
    population_total: undefined,
    sc_population: undefined,
    st_population: undefined,
    areas: []
  }
}
```

## 📱 Mobile Responsiveness

```css
/* Add to your CSS for mobile-friendly ward selection */
@media (max-width: 768px) {
  .ward-grid {
    grid-template-columns: 1fr;
  }

  .ward-info {
    padding: 1rem;
  }

  .area-tags {
    flex-direction: column;
    align-items: flex-start;
  }
}
```

## 🚀 Best Practices

### 1. Loading States
```typescript
// Always handle loading states
const { wards, loading } = useWards(districtId, bodyId)

if (loading) {
  return <div className="animate-pulse">Loading wards...</div>
}
```

### 2. Error Handling
```typescript
// Handle API errors gracefully
const [error, setError] = useState<string>('')

try {
  const response = await fetch('/api/get-wards?districtId=' + districtId)
  const data = await response.json()

  if (!data.success) {
    setError('Failed to load wards')
  }
} catch (err) {
  setError('Network error occurred')
}
```

### 3. Caching Strategy
```typescript
// Implement caching for better performance
const [cache, setCache] = useState<Map<string, Ward[]>>(new Map())

const getCachedWards = (districtId: string, bodyId: string) => {
  const key = `${districtId}-${bodyId}`
  return cache.get(key)
}

const setCachedWards = (districtId: string, bodyId: string, wards: Ward[]) => {
  const key = `${districtId}-${bodyId}`
  setCache(prev => new Map(prev.set(key, wards)))
}
```

### 4. Search Functionality
```typescript
// Add search/filter functionality
const [searchTerm, setSearchTerm] = useState('')

const filteredWards = wards.filter(ward =>
  ward.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
  ward.areas?.some(area => area.toLowerCase().includes(searchTerm.toLowerCase()))
)
```

## 🔧 TypeScript Types

```typescript
// types/ward.ts
export interface WardData {
  id: string
  name: string
  number?: number
  population_total?: number
  sc_population?: number
  st_population?: number
  areas?: string[]
  createdAt: Date
}

export interface BodyData {
  id: string
  name: string
  type: string
  ward_count: number
  area_to_ward?: Record<string, string>
  source?: Record<string, unknown>
  special?: Record<string, unknown>
}

export interface DistrictData {
  id: string
  name: string
}

export interface WardAPIResponse {
  success: boolean
  wards: WardData[]
  error?: string
}

export interface BodyAPIResponse {
  success: boolean
  bodies: BodyData[]
  error?: string
}

export interface DistrictAPIResponse {
  success: boolean
  districts: DistrictData[]
  error?: string
}
```

## 🎯 Usage Examples

### Basic Ward Selection
```typescript
function CandidateRegistrationForm() {
  const [selectedWard, setSelectedWard] = useState<Ward | null>(null)

  return (
    <div>
      <WardSelector onWardSelect={setSelectedWard} />
      {selectedWard && (
        <WardInfo ward={selectedWard} />
      )}
    </div>
  )
}
```

### Advanced Ward Search
```typescript
function WardSearchComponent() {
  const [searchResults, setSearchResults] = useState<Ward[]>([])
  const [searchTerm, setSearchTerm] = useState('')

  const handleSearch = async (term: string) => {
    // Implement search logic across districts/bodies/wards
    const results = await searchWards(term)
    setSearchResults(results)
  }

  return (
    <div>
      <input
        type="text"
        placeholder="Search wards, areas..."
        value={searchTerm}
        onChange={(e) => {
          setSearchTerm(e.target.value)
          handleSearch(e.target.value)
        }}
      />
      <WardList wards={searchResults} />
    </div>
  )
}
```

## 📊 Performance Considerations

1. **Lazy Loading**: Only load ward data when needed
2. **Pagination**: For large ward lists, implement pagination
3. **Memoization**: Use React.memo for ward components
4. **Debouncing**: For search inputs to reduce API calls

## 🐛 Troubleshooting

### Common Issues

**Issue**: Ward data not loading
```typescript
// Check if districtId and bodyId are properly set
console.log('District ID:', districtId)
console.log('Body ID:', bodyId)
```

**Issue**: Marathi text not displaying correctly
```css
/* Ensure Marathi font is applied */
.marathi-text {
  font-family: 'Mangal', 'Arial Unicode MS', 'Nirmala UI', sans-serif;
}
```

**Issue**: API calls failing
```typescript
// Check network tab in browser dev tools
// Verify API endpoints are correct
// Check for CORS issues
```

## 📞 Support

For questions about frontend integration:
- Check the API response formats
- Verify TypeScript types match your implementation
- Test with the provided example components
- Refer to the admin README for data structure details

---

**Last Updated**: January 2025
**Version**: 1.0.0