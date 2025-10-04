import '../../../models/plan_model.dart';

class MonetizationUtils {
  static String formatElectionType(String electionType) {
    switch (electionType) {
      case 'municipal_corporation':
        return 'Municipal Corporation';
      case 'municipal_council':
        return 'Municipal Council';
      case 'nagar_panchayat':
        return 'Nagar Panchayat';
      case 'zilla_parishad':
        return 'Zilla Parishad';
      case 'panchayat_samiti':
        return 'Panchayat Samiti';
      case 'parliamentary':
        return 'Parliamentary';
      case 'assembly':
        return 'Assembly';
      default:
        return electionType;
    }
  }

  static int countEnabledFeatures(SubscriptionPlan plan) {
    int count = 0;

    // Dashboard Tabs
    if (plan.dashboardTabs.basicInfo.enabled) count++;
    if (plan.dashboardTabs.manifesto.enabled) count++;
    if (plan.dashboardTabs.achievements.enabled) count++;
    if (plan.dashboardTabs.media.enabled) count++;
    if (plan.dashboardTabs.contact.enabled) count++;
    if (plan.dashboardTabs.events.enabled) count++;
    if (plan.dashboardTabs.analytics.enabled) count++;

    // Profile Features
    if (plan.profileFeatures.premiumBadge) count++;
    if (plan.profileFeatures.sponsoredBanner) count++;
    if (plan.profileFeatures.highlightCarousel) count++;
    if (plan.profileFeatures.pushNotifications) count++;
    if (plan.profileFeatures.multipleHighlights == true) count++;
    if (plan.profileFeatures.adminSupport == true) count++;
    if (plan.profileFeatures.customBranding == true) count++;

    return count;
  }
}

