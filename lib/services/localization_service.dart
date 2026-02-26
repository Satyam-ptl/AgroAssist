import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalizationService {
  static const String _storageKey = 'app_language';
  static const List<String> supportedLanguages = ['English', 'Hindi', 'Marathi'];

  static final ValueNotifier<String> languageNotifier = ValueNotifier<String>('English');

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_storageKey);
    if (saved != null && supportedLanguages.contains(saved)) {
      languageNotifier.value = saved;
    }
  }

  static Future<void> setLanguage(String language) async {
    if (!supportedLanguages.contains(language)) return;
    languageNotifier.value = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, language);
  }

  static String tr(String key) {
    final lang = languageNotifier.value;
    return _translations[lang]?[key] ?? key;
  }

  static const Map<String, Map<String, String>> _translations = {
    'English': {
      'Farm Buddy': 'Farm Buddy',
      'Dashboard': 'Dashboard',
      'Crops': 'Crops',
      'Farmers': 'Farmers',
      'Tasks': 'Tasks',
      'Weather & Alerts': 'Weather & Alerts',
      'Refresh': 'Refresh',
      'Retry': 'Retry',
      'No crops found': 'No crops found',
      'No farmers found': 'No farmers found',
      'No tasks found': 'No tasks found',
      'Season': 'Season',
      'Soil': 'Soil',
      'All': 'All',
      'Recommendations': 'Recommendations',
      'Get Recommendations': 'Get Recommendations',
      'Crop Guide': 'Crop Guide',
      'Watering': 'Watering',
      'Fertilizer': 'Fertilizer',
      'Disease': 'Disease',
      'Harvest': 'Harvest',
      'Close': 'Close',
      'Language': 'Language',
      'Welcome to Farm Buddy': 'Welcome to Farm Buddy',
      'Your Multi-Crop Growth Assistant': 'Your Multi-Crop Growth Assistant',
      'Quick Actions': 'Quick Actions',
      'Browse Crops': 'Browse Crops',
      'Manage Farmers': 'Manage Farmers',
      'View Tasks': 'View Tasks',
      'Weather Alerts': 'Weather Alerts',
      'Basic Rain Info': 'Basic Rain Info',
      'Rainfall': 'Rainfall',
      'Temperature': 'Temperature',
      'Humidity': 'Humidity',
      'No weather alerts at the moment': 'No weather alerts at the moment',
      'Check back later for updates': 'Check back later for updates',
      'Simple Mode': 'Simple Mode',
    },
    'Hindi': {
      'Farm Buddy': 'फार्म बडी',
      'Dashboard': 'डैशबोर्ड',
      'Crops': 'फसलें',
      'Farmers': 'किसान',
      'Tasks': 'काम',
      'Weather & Alerts': 'मौसम और अलर्ट',
      'Refresh': 'रीफ्रेश',
      'Retry': 'फिर कोशिश करें',
      'No crops found': 'कोई फसल नहीं मिली',
      'No farmers found': 'कोई किसान नहीं मिला',
      'No tasks found': 'कोई काम नहीं मिला',
      'Season': 'सीजन',
      'Soil': 'मिट्टी',
      'All': 'सभी',
      'Recommendations': 'सुझाव',
      'Get Recommendations': 'सुझाव देखें',
      'Crop Guide': 'फसल गाइड',
      'Watering': 'सिंचाई',
      'Fertilizer': 'खाद',
      'Disease': 'रोग',
      'Harvest': 'कटाई',
      'Close': 'बंद करें',
      'Language': 'भाषा',
      'Welcome to Farm Buddy': 'फार्म बडी में आपका स्वागत है',
      'Your Multi-Crop Growth Assistant': 'आपका मल्टी-क्रॉप ग्रोथ असिस्टेंट',
      'Quick Actions': 'त्वरित कार्य',
      'Browse Crops': 'फसलें देखें',
      'Manage Farmers': 'किसान प्रबंधन',
      'View Tasks': 'काम देखें',
      'Weather Alerts': 'मौसम अलर्ट',
      'Basic Rain Info': 'बुनियादी वर्षा जानकारी',
      'Rainfall': 'वर्षा',
      'Temperature': 'तापमान',
      'Humidity': 'नमी',
      'No weather alerts at the moment': 'अभी कोई मौसम अलर्ट नहीं है',
      'Check back later for updates': 'अपडेट के लिए बाद में देखें',
      'Simple Mode': 'सरल मोड',
    },
    'Marathi': {
      'Farm Buddy': 'फार्म बडी',
      'Dashboard': 'डॅशबोर्ड',
      'Crops': 'पिके',
      'Farmers': 'शेतकरी',
      'Tasks': 'कामे',
      'Weather & Alerts': 'हवामान आणि सूचना',
      'Refresh': 'रिफ्रेश',
      'Retry': 'पुन्हा प्रयत्न करा',
      'No crops found': 'पिके सापडली नाहीत',
      'No farmers found': 'शेतकरी सापडले नाहीत',
      'No tasks found': 'कामे सापडली नाहीत',
      'Season': 'हंगाम',
      'Soil': 'माती',
      'All': 'सर्व',
      'Recommendations': 'शिफारसी',
      'Get Recommendations': 'शिफारसी पहा',
      'Crop Guide': 'पीक मार्गदर्शक',
      'Watering': 'पाणी',
      'Fertilizer': 'खत',
      'Disease': 'रोग',
      'Harvest': 'कापणी',
      'Close': 'बंद',
      'Language': 'भाषा',
      'Welcome to Farm Buddy': 'फार्म बडी मध्ये स्वागत आहे',
      'Your Multi-Crop Growth Assistant': 'तुमचा मल्टी-क्रॉप सहाय्यक',
      'Quick Actions': 'जलद कृती',
      'Browse Crops': 'पिके पहा',
      'Manage Farmers': 'शेतकरी व्यवस्थापन',
      'View Tasks': 'कामे पहा',
      'Weather Alerts': 'हवामान सूचना',
      'Basic Rain Info': 'मूलभूत पावसाची माहिती',
      'Rainfall': 'पाऊस',
      'Temperature': 'तापमान',
      'Humidity': 'आर्द्रता',
      'No weather alerts at the moment': 'सध्या हवामान सूचना नाहीत',
      'Check back later for updates': 'नंतर पुन्हा तपासा',
      'Simple Mode': 'सोपे मोड',
    },
  };
}
