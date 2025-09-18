# 🎯 Candidate Visibility on Home Screen - Voter Experience Guide

## 📋 **Overview**
This document explains how candidates appear on the home screen for logged-in voters in the Janmat app. The visibility depends on the candidate's subscription plan and the voter's location.

## 🏠 **Home Screen Structure for Voters**

### **4 Main Sections (Top to Bottom):**

```
┌─────────────────────────────────────┐
│ 🔴 PLATINUM BANNER                 │ ← Section 1 (Conditional)
│ (Shows Platinum highlights)         │
├─────────────────────────────────────┤
│ 🟡 HIGHLIGHT CAROUSEL              │ ← Section 2 (Always visible)
│ (Gold & Platinum highlights)        │
├─────────────────────────────────────┤
│ 📢 SPONSORED UPDATES               │ ← Section 3 (Sponsored content)
│ (Paid candidate announcements)      │
├─────────────────────────────────────┤
│ 📰 COMMUNITY FEED                  │ ← Section 4 (Regular content)
│ (All candidates + community posts)  │
└─────────────────────────────────────┘
```

---

## 👁️ **Candidate Visibility Rules**

### **1. Platinum Banner (Section 1)**
**Who sees this:** Voters in the same ward as the Platinum candidate
**What shows:** Large banner advertisement for Platinum candidates
**When:** Only when a Platinum highlight is active in the voter's ward
**Cost:** ₹100,000+ (highest visibility)

**Visibility Logic:**
```dart
if (platinumHighlightExistsInVoterWard && highlight.isActive) {
  showPlatinumBanner();
}
```

### **2. Highlight Carousel (Section 2)**
**Who sees this:** All voters (ward-based content)
**What shows:** Gold and Platinum candidate highlights from voter's ward
**When:** Always visible (shows available highlights or hides if none)
**Cost:** Gold (₹25,000+), Platinum (₹100,000+)

**Visibility Logic:**
```dart
final highlights = await getHighlightsForWard(voterWardId);
if (highlights.isNotEmpty) {
  showHighlightCarousel(highlights);
} else {
  hideSection(); // Section disappears if no highlights
}
```

### **3. Sponsored Updates (Section 3)**
**Who sees this:** Voters in relevant wards
**What shows:** Paid announcements from candidates
**When:** When candidates purchase sponsored push notifications
**Cost:** Included in Gold/Platinum plans

**Visibility Logic:**
```dart
final sponsoredContent = await getSponsoredContentForWard(voterWardId);
if (sponsoredContent.isNotEmpty) {
  showSponsoredUpdates(sponsoredContent);
} else {
  hideSection(); // Section disappears if no sponsored content
}
```

### **4. Community Feed (Section 4)**
**Who sees this:** All voters
**What shows:** All candidates from voter's district/body/ward
**When:** Always visible
**Cost:** Free (basic visibility)

**Visibility Logic:**
```dart
final candidates = await getCandidatesForLocation(
  districtId: voterDistrictId,
  bodyId: voterBodyId,
  wardId: voterWardId
);
showCommunityFeed(candidates);
```

---

## 📊 **Plan-Based Visibility Comparison**

| Feature | Free Plan | Basic Plan | Gold Plan | Platinum Plan |
|---------|-----------|------------|-----------|---------------|
| **Basic Profile** | ✅ Visible | ✅ Visible | ✅ Visible | ✅ Visible |
| **Community Feed** | ✅ Listed | ✅ Listed | ✅ Listed | ✅ Listed |
| **Highlight Carousel** | ❌ No | ❌ No | ✅ Ward-level | ✅ Ward-level |
| **Platinum Banner** | ❌ No | ❌ No | ❌ No | ✅ Exclusive |
| **Sponsored Updates** | ❌ No | ❌ No | ✅ Limited | ✅ Unlimited |
| **Profile Priority** | 🔽 Low | 🔽 Low | 🔼 Medium | 🔝 High |
| **Analytics Access** | ❌ No | ❌ Basic | ✅ Advanced | ✅ Full |

---

## 🎯 **How Voters Discover Candidates**

### **1. Location-Based Discovery**
- Voters see candidates from their **ward** first
- Then candidates from their **body/municipality**
- Finally candidates from their **district**

### **2. Plan-Based Prioritization**
- **Platinum candidates** get banner + carousel + sponsored spots
- **Gold candidates** get carousel + sponsored spots
- **Basic/Free candidates** appear in community feed only

### **3. Content Types Voters See**

#### **From Platinum Candidates:**
- Exclusive top banner (highest visibility)
- Carousel highlight card
- Sponsored announcements
- Full community feed presence

#### **From Gold Candidates:**
- Carousel highlight card
- Sponsored announcements (limited)
- Full community feed presence

#### **From Basic/Free Candidates:**
- Community feed presence only
- Basic profile information
- Limited content visibility

---

## 🔍 **Voter Search & Filter Experience**

### **Browse Candidates Page**
- Shows all candidates in voter's area
- **Plan badges** indicate premium status
- **Sponsored tags** for paid content
- **Location-based sorting** (ward first)

### **Candidate Profile Views**
- **Free candidates:** Basic info, limited media (2 photos)
- **Basic candidates:** Enhanced info, 5 photos + 1 video, limited manifesto
- **Gold candidates:** Full media (50 photos + 10 videos), unlimited achievements
- **Platinum candidates:** Everything unlocked + premium badge

### **Search Results**
- Premium candidates appear higher in search results
- Sponsored content gets priority placement
- Location relevance affects ranking

---

## 📈 **Engagement & Conversion Flow**

### **How Voters Engage with Candidates:**

1. **See highlight** → Tap → View profile → Follow/Like
2. **Read sponsored update** → Tap CTA → Contact candidate
3. **Browse community feed** → Tap candidate → View details
4. **Search candidates** → Filter by location/party → Compare

### **Conversion to Paid Plans:**
- Voters see "Upgrade to Gold" prompts
- Candidates get analytics on profile views
- Success stories encourage upgrades
- Limited features drive conversions

---

## 🎨 **Visual Indicators for Voters**

### **Plan Badges:**
- 🆓 **Free** - No badge (basic listing)
- 🟡 **Basic** - "Basic" badge
- 🟠 **Gold** - "Gold" badge with star
- 🔴 **Platinum** - "Platinum" badge with crown

### **Sponsored Content Tags:**
- 📢 "SPONSORED" label on paid content
- ⭐ "HIGHLIGHT" badge on carousel items
- 👑 "PREMIUM" indicators for Platinum features

### **Priority Indicators:**
- Platinum candidates appear first in lists
- Gold candidates get medium priority
- Basic/Free candidates appear last

---

## 📍 **Location-Based Visibility Logic**

### **Ward-Level Visibility:**
```dart
// Platinum Banner - Exclusive per ward
platinumBanner = getActivePlatinumHighlights(voterWardId).first;

// Carousel - All Gold/Platinum in ward
carouselHighlights = getActiveHighlights(voterWardId, ['gold', 'platinum']);

// Sponsored - Ward-specific content
sponsoredContent = getSponsoredContent(voterWardId);
```

### **Multi-Level Discovery:**
```dart
// Community Feed - Hierarchical discovery
wardCandidates = getCandidates(voterWardId);        // Priority 1
bodyCandidates = getCandidates(voterBodyId);        // Priority 2
districtCandidates = getCandidates(voterDistrictId); // Priority 3

// Remove duplicates and sort by plan priority
allCandidates = deduplicateAndSortByPlan([
  ...wardCandidates,
  ...bodyCandidates,
  ...districtCandidates
]);
```

---

## 📊 **Analytics & Insights for Candidates**

### **What Candidates See:**
- **Profile view counts** (Basic plan+)
- **Highlight impressions** (Gold/Platinum)
- **Sponsored content clicks** (Gold/Platinum)
- **Follower growth** (Gold/Platinum)
- **Demographics** (Platinum only)

### **Performance Metrics:**
- **Banner CTR:** Clicks per impression for Platinum banner
- **Carousel engagement:** Taps on highlight cards
- **Sponsored reach:** Views of sponsored content
- **Profile completion:** % of profile filled out

---

## 🚀 **Premium Upgrade Triggers**

### **For Free/Basic Candidates:**
- "Get Gold highlight for ₹25,000" prompts
- Limited feature messages ("Upgrade to see more")
- Success stories from other candidates
- Analytics previews

### **For Gold Candidates:**
- "Upgrade to Platinum for exclusive banner" offers
- Advanced analytics previews
- Unlimited features temptations
- Competitor success metrics

---

## ⚙️ **Technical Implementation**

### **Backend Logic:**
```dart
class CandidateVisibilityService {
  Future<List<Candidate>> getVisibleCandidatesForVoter(String voterId) async {
    final voterLocation = await getVoterLocation(voterId);

    // Get all candidates by location hierarchy
    final candidates = await getCandidatesByLocation(voterLocation);

    // Apply plan-based prioritization
    final prioritizedCandidates = prioritizeByPlan(candidates);

    // Add visibility metadata
    return addVisibilityMetadata(prioritizedCandidates);
  }

  Future<Map<String, dynamic>> getHomeScreenContent(String voterId) async {
    final location = await getVoterLocation(voterId);

    return {
      'platinumBanner': await getPlatinumBanner(location),
      'highlightCarousel': await getHighlightCarousel(location),
      'sponsoredUpdates': await getSponsoredUpdates(location),
      'communityFeed': await getCommunityFeed(location),
    };
  }
}
```

### **Frontend Logic:**
```dart
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: CandidateVisibilityService.getHomeScreenContent(voterId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return CircularProgressIndicator();

        final content = snapshot.data;

        return ListView(
          children: [
            if (content['platinumBanner'] != null)
              PlatinumBanner(content['platinumBanner']),

            HighlightCarousel(content['highlightCarousel']),

            if (content['sponsoredUpdates'].isNotEmpty)
              SponsoredUpdates(content['sponsoredUpdates']),

            CommunityFeed(content['communityFeed']),
          ],
        );
      },
    );
  }
}
```

---

## 🎯 **Key Takeaways for Voters**

1. **Location matters:** See candidates from your ward first
2. **Premium candidates get more visibility:** Platinum > Gold > Basic > Free
3. **Sponsored content is clearly marked:** Know what's paid vs organic
4. **Multiple discovery paths:** Banner → Carousel → Feed → Search
5. **Easy to compare candidates:** All profiles accessible, plan features clear

## 🎯 **Key Takeaways for Candidates**

1. **Higher plans = more visibility:** Platinum gets banner + carousel + sponsored
2. **Location targeting:** Your content reaches voters in your ward first
3. **Analytics help optimization:** Track what works, improve engagement
4. **Clear upgrade path:** Start free, upgrade based on needs/budget
5. **Sponsored content drives action:** Direct CTAs get results

---

## 📞 **Support & Questions**

**For Voters:**
- How to find candidates in my area?
- What do the different badges mean?
- How to contact candidates?

**For Candidates:**
- Which plan is right for me?
- How do highlights work?
- How to track my campaign performance?

**Technical Support:**
- Visibility not working as expected
- Content approval issues
- Payment processing problems

---

*This system ensures fair visibility for all candidates while rewarding investment in premium features. Free candidates get basic visibility, while Platinum candidates get maximum exposure through multiple channels.*