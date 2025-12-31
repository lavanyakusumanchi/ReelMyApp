import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ?? AppLocalizations(const Locale('en'));
  }

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_title': 'ReelMyApp',
      'home': 'Home',
      'profile': 'Profile',
      'my_reels': 'My Reels',
      'saved': 'Saved',
      'settings': 'Settings',
      'delete': 'Delete',
      'cancel': 'Cancel',
      'save': 'Save',
      'share': 'Share',
      'login': 'Login',
      'logout': 'Log Out',
      'email': 'Email',
      'password': 'Password',
      'account': 'Account',
      'notifications': 'Notifications',
      'appearance': 'Appearance',
      'video_preferences': 'Video Preferences',
      'change_password': 'Change Password',
      'privacy': 'Privacy',
      'push_notifications': 'Push Notifications',
      'dark_mode': 'Dark Mode',
      'language': 'Language',
      'auto_play': 'Auto-Play Videos',
      'download_quality': 'Download Quality',
      'data_usage': 'Data Usage',
      'update_password': 'Update Password',
      'set_password': 'Set Password',
      'english': 'English',
      'telugu': 'Telugu',
      'auto_scroll': 'Auto Scroll Reels',
      'download_app': 'Download App',
      'no_reels': 'No reels found',
      'edit_profile': 'Edit Profile',
      'name_label': 'Name',
      'email_label': 'Email',
      'name_required': 'Name is required',
      'email_required': 'Email is required',
      'save_changes': 'Save Changes',
      'profile_updated': 'Profile Updated Successfully',
      'update_failed': 'Update Failed',
      'something_wrong': 'Something went wrong',
      'cat_all': 'All',
      'cat_business': 'Business',
      'cat_entertainment': 'Entertainment',
      'cat_education': 'Education',
      'cat_lifestyle': 'Lifestyle',
      'cat_technology': 'Technology',
      'cat_foodi': 'Foodi',
      'cat_other': 'Other',
      'paid_label': 'Paid: \$',
      'free_label': 'Free App',
      'install_app': 'Install',
      'reels': 'Reels',
    },
    'te': {
      'app_title': 'రీల్ ఫ్లో',
      'home': 'హోమ్',
      'profile': 'ప్రొఫైల్',
      'my_reels': 'నా రీల్స్',
      'saved': 'సేవ్ చేసినవి',
      'settings': 'సెట్టింగ్స్',
      'delete': 'తొలగించు',
      'cancel': 'రద్దు చేయండి',
      'save': 'సేవ్',
      'share': 'షేర్',
      'login': 'లాగిన్',
      'logout': 'లాగ్ అవుట్',
      'email': 'ఈమెయిల్',
      'password': 'పాస్వర్డ్',
      'account': 'ఖాతా',
      'notifications': 'నోటిఫికేషన్లు',
      'appearance': 'రూపము',
      'video_preferences': 'వీడియో ప్రాధాన్యతలు',
      'change_password': 'పాస్వర్డ్ మార్చండి',
      'privacy': 'గోప్యత',
      'push_notifications': 'పుష్ నోటిఫికేషన్లు',
      'dark_mode': 'డార్క్ మోడ్',
      'language': 'భాష',
      'auto_play': 'వీడియో ఆటో-ప్లే',
      'download_quality': 'డౌన్‌లోడ్ క్వాలిటీ',
      'data_usage': 'డేటా వినియోగం',
      'update_password': 'పాస్వర్డ్ అప్‌డేట్ చేయండి',
      'set_password': 'పాస్వర్డ్ సెట్ చేయండి',
      'english': 'English',
      'telugu': 'తెలుగు',
      'auto_scroll': 'రీల్స్ ఆటో స్క్రోల్',
      'download_app': 'యాప్ డౌన్‌లోడ్',
      'no_reels': 'రీల్స్ లేవు',
      'edit_profile': 'ప్రొఫైల్ సవరించండి',
      'name_label': 'పేరు',
      'email_label': 'ఈమెయిల్',
      'name_required': 'పేరు అవసరం',
      'email_required': 'ఈమెయిల్ అవసరం',
      'save_changes': 'మార్పులను సేవ్ చేయండి',
      'profile_updated': 'ప్రొఫైల్ విజయవంతంగా అప్‌డేట్ చేయబడింది',
      'update_failed': 'అప్‌డేట్ విఫలమైంది',
      'something_wrong': 'ఏదో తప్పు జరిగింది',
      'cat_all': 'అన్నీ',
      'cat_business': 'వ్యాపారం',
      'cat_entertainment': 'వినోదం',
      'cat_education': 'విద్య',
      'cat_lifestyle': 'జీవనశైలి',
      'cat_technology': 'టెక్నాలజీ',
      'cat_foodi': 'భోజన ప్రియులు',
      'cat_other': 'ఇతర',
      'paid_label': 'చెల్లించినది: \$',
      'free_label': 'ఉచిత యాప్',
      'install_app': 'ఇన్స్టాల్',
      'reels': 'రీల్స్',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'te'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
