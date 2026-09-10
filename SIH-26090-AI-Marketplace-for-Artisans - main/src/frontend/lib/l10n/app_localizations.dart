import 'package:flutter/widgets.dart';
import 'app_locale.dart';

class AppLocalizations {
  AppLocalizations(Locale locale)
      : locale = AppLocale.supportedLanguageCodes.contains(locale.languageCode)
            ? Locale(locale.languageCode)
            : const Locale('en');
  final Locale locale;

  static const supported = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('mr'),
    Locale('ta'),
    Locale('bn'),
  ];

  static const _copy = <String, Map<String, String>>{
    'en': {
      'language': 'Language',
      'choose_language': 'Choose your preferred language.',
      'marketplace': 'Marketplace',
      'discover': 'Discover handmade products',
      'categories': 'Categories',
      'all': 'All',
      'notifications': 'Notifications',
      'weekly_tip': 'Weekly business tip',
      'orders': 'My Orders',
      'crafted_by': 'Crafted by',
      'add_to_cart': 'Add to Cart',
      'revenue': 'Revenue',
      'products_sold': 'Products Sold',
      'order_status': 'Order status',
    },
    'hi': {
      'language': 'भाषा',
      'choose_language': 'अपनी पसंदीदा भाषा चुनें।',
      'marketplace': 'मार्केटप्लेस',
      'discover': 'हस्तनिर्मित उत्पाद देखें',
      'categories': 'श्रेणियाँ',
      'all': 'सभी',
      'notifications': 'सूचनाएँ',
      'weekly_tip': 'साप्ताहिक व्यवसाय सुझाव',
      'orders': 'मेरे ऑर्डर',
      'crafted_by': 'कारीगर',
      'add_to_cart': 'कार्ट में जोड़ें',
      'revenue': 'आय',
      'products_sold': 'बिके उत्पाद',
      'order_status': 'ऑर्डर स्थिति',
    },
    'mr': {
      'language': 'भाषा',
      'choose_language': 'आपली पसंतीची भाषा निवडा.',
      'marketplace': 'मार्केटप्लेस',
      'discover': 'हस्तनिर्मित उत्पादने शोधा',
      'categories': 'श्रेणी',
      'all': 'सर्व',
      'notifications': 'सूचना',
      'weekly_tip': 'साप्ताहिक व्यवसाय सूचना',
      'orders': 'माझ्या ऑर्डर्स',
      'crafted_by': 'कारागिराने बनवले',
      'add_to_cart': 'कार्टमध्ये जोडा',
      'revenue': 'उत्पन्न',
      'products_sold': 'विकलेली उत्पादने',
      'order_status': 'ऑर्डर स्थिती',
    },
    'ta': {
      'language': 'மொழி',
      'choose_language': 'உங்களுக்கு விருப்பமான மொழியைத் தேர்ந்தெடுக்கவும்.',
      'marketplace': 'சந்தை',
      'discover': 'கைவினைப் பொருட்களைக் கண்டறியுங்கள்',
      'categories': 'வகைகள்',
      'all': 'அனைத்தும்',
      'notifications': 'அறிவிப்புகள்',
      'weekly_tip': 'வாராந்திர வணிகக் குறிப்பு',
      'orders': 'எனது ஆர்டர்கள்',
      'crafted_by': 'கைவினைஞர்',
      'add_to_cart': 'வண்டியில் சேர்',
      'revenue': 'வருவாய்',
      'products_sold': 'விற்கப்பட்ட பொருட்கள்',
      'order_status': 'ஆர்டர் நிலை',
    },
    'bn': {
      'language': 'ভাষা',
      'choose_language': 'আপনার পছন্দের ভাষা বেছে নিন।',
      'marketplace': 'মার্কেটপ্লেস',
      'discover': 'হস্তশিল্পের পণ্য খুঁজুন',
      'categories': 'বিভাগ',
      'all': 'সব',
      'notifications': 'বিজ্ঞপ্তি',
      'weekly_tip': 'সাপ্তাহিক ব্যবসায়িক পরামর্শ',
      'orders': 'আমার অর্ডার',
      'crafted_by': 'কারিগর',
      'add_to_cart': 'কার্টে যোগ করুন',
      'revenue': 'আয়',
      'products_sold': 'বিক্রি হওয়া পণ্য',
      'order_status': 'অর্ডারের অবস্থা',
    },
  };

  String text(String key) {
    final languageCopy = _copy[locale.languageCode];
    final englishCopy = _copy['en'];
    return languageCopy?[key] ?? englishCopy?[key] ?? key;
  }
}

extension AppLocalizationContext on BuildContext {
  AppLocalizations get strings => AppLocalizations(AppLocale.instance.locale);
}