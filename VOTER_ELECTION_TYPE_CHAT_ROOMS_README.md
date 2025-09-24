# Voter Election Type & Chat Room Creation System

## Overview
This document explains the new voter election type selection system and how it affects chat room creation for voters in the Janmat app.

## Election Types for Voters

### Available Election Types:
1. **महापालिका** (Municipal Corporation)
2. **नगरपरिषद** (Municipal Council)
3. **नगर पंचायत** (Nagar Panchayat)
4. **जिल्हा परिषद (ZP) आणि पंचायत समिती (PS)** (Combined)

## Chat Room Creation Logic

### Regular Elections (Types 1-3)
- **Wards Required**: 1 ward selection
- **Chat Rooms Created**: 1 area-based chat room
- **Room Naming**: `{AreaName}_chat`
- **Participants**: All voters from that area

### ZP + PS Combined Election (Type 4)
- **Wards Required**: 2 ward selections
  - Ward 1: Zilla Parishad (ZP) ward
  - Ward 2: Panchayat Samiti (PS) ward
- **Chat Rooms Created**: 2 area-based chat rooms
  - Room 1: `{ZP_Ward_Area}_zp_chat`
  - Room 2: `{PS_Ward_Area}_ps_chat`
- **Participants**: Voters from respective areas

## Data Structure

### User Model Fields:
```dart
{
  'electionType': 'municipal_corporation' | 'municipal_council' | 'nagar_panchayat' | 'zp_ps_combined',
  'wards': [
    {
      'wardId': 'ward_1',
      'area': 'area_name',
      'electionType': 'zp' | 'ps' // Only for zp_ps_combined
    }
  ],
  'electionInfoCompleted': true
}
```

### Chat Room Structure:
```dart
{
  'roomId': 'area_name_zp_chat' | 'area_name_ps_chat' | 'area_name_chat',
  'roomType': 'area_chat',
  'electionType': 'zp' | 'ps' | 'municipal' | 'council' | 'panchayat',
  'wardId': 'ward_1',
  'area': 'area_name',
  'participants': ['userId1', 'userId2', ...],
  'createdAt': Timestamp,
  'createdBy': 'admin_user_id'
}
```

## Admin Implementation Guide

### 1. Ward Setup
- Ensure all wards have proper area mappings in Firestore
- For ZP+PS areas, clearly mark which wards belong to which election type
- Validate that areas exist for all wards

### 2. Chat Room Creation Process

#### For Regular Elections:
```javascript
// Pseudo-code for admin script
const user = await getUser(userId);
if (user.electionType !== 'zp_ps_combined') {
  const ward = user.wards[0];
  const roomId = `${ward.area}_chat`;

  await createChatRoom({
    roomId: roomId,
    roomType: 'area_chat',
    electionType: user.electionType,
    wardId: ward.wardId,
    area: ward.area,
    participants: [userId]
  });
}
```

#### For ZP+PS Combined:
```javascript
// Pseudo-code for admin script
const user = await getUser(userId);
if (user.electionType === 'zp_ps_combined') {
  for (const ward of user.wards) {
    const roomId = `${ward.area}_${ward.electionType}_chat`;

    await createChatRoom({
      roomId: roomId,
      roomType: 'area_chat',
      electionType: ward.electionType, // 'zp' or 'ps'
      wardId: ward.wardId,
      area: ward.area,
      participants: [userId]
    });
  }
}
```

### 3. Room Naming Convention
- **Municipal Corporation**: `{AreaName}_chat`
- **Municipal Council**: `{AreaName}_chat`
- **Nagar Panchayat**: `{AreaName}_chat`
- **ZP**: `{AreaName}_zp_chat`
- **PS**: `{AreaName}_ps_chat`

### 4. User Participation Rules
- Users can only join chat rooms for areas they selected during profile completion
- ZP+PS users get access to both their ZP and PS area chat rooms
- Regular election users get access to only their selected area chat room

## UI Implementation Notes

### Profile Completion Screen:
- Show election type dropdown only for voters (not candidates)
- For ZP+PS option, display clear message: "You will need to select 2 wards"
- Ward selection labels:
  - Regular: "Select Ward"
  - ZP+PS: "Select ZP Ward" and "Select PS Ward"

### Chat Screen:
- Filter available chat rooms based on user's election type and selected areas
- Show appropriate room names with election type indicators
- ZP+PS users see both their ZP and PS rooms

## Migration Considerations

### Existing Users:
- Existing voters without election type will need to complete election type selection
- Admin should run migration script to update existing user records
- Consider providing in-app prompts for election type completion

### Backward Compatibility:
- Ensure old chat rooms continue to work
- New system should not break existing functionality
- Gradual rollout recommended

## Testing Checklist

### Admin Testing:
- [ ] Create test users for each election type
- [ ] Verify correct number of chat rooms created
- [ ] Test room naming conventions
- [ ] Verify user access to appropriate rooms

### User Testing:
- [ ] Test election type selection flow
- [ ] Verify ward selection process
- [ ] Test chat room access
- [ ] Test ZP+PS dual ward selection

## Troubleshooting

### Common Issues:
1. **User can't see chat rooms**: Check if election type is properly set
2. **Wrong number of rooms**: Verify election type and ward count
3. **Room naming issues**: Check area names for special characters
4. **Access denied**: Verify user's selected areas match room areas

### Debug Information:
- Check user document for `electionType` and `wards` fields
- Verify chat room documents have correct `electionType` and `area` fields
- Check Firestore security rules allow proper access

## Future Enhancements

### Potential Improvements:
1. **Dynamic Election Types**: Allow admin to add new election types
2. **Bulk Room Creation**: Scripts for creating rooms for multiple users
3. **Analytics**: Track which election types are most popular
4. **Notifications**: Alert users about new elections in their areas

---

**Last Updated**: September 21, 2025
**Version**: 1.0
**Contact**: Admin Team