/// ЗАСТАРІЛЕ — раніше контрольований словник симптомів для вибору в
/// самопочутті, замінений вільними тегами (TagsField). Лишається лише як
/// довідник ключ→назва для одноразової міграції старих записів
/// WellbeingLogs.symptomsJson у tagsJson (див. app_database.dart, from < 28).
class SymptomLibraryService {
  static const List<(String key, String label)> common = [
    ('headache', 'головний біль'),
    ('nausea', 'нудота'),
    ('dizziness', 'запаморочення'),
    ('weakness', 'слабість'),
    ('shortness_of_breath', 'задишка'),
    ('rash', 'висип'),
    ('pain', 'біль'),
    ('fever', 'температура'),
    ('cough', 'кашель'),
    ('sore_throat', 'біль у горлі'),
    ('runny_nose', 'нежить'),
    ('stuffy_nose', 'закладеність носа'),
    ('sneezing', 'чхання'),
    ('vomiting', 'блювота'),
    ('diarrhea', 'діарея'),
    ('constipation', 'запор'),
    ('bloating', 'здуття живота'),
    ('heartburn', 'печія'),
    ('stomach_pain', 'біль у животі'),
    ('loss_of_appetite', 'втрата апетиту'),
    ('increased_appetite', 'підвищений апетит'),
    ('insomnia', 'безсоння'),
    ('drowsiness', 'сонливість'),
    ('fatigue', 'втома'),
    ('chest_pain', 'біль у грудях'),
    ('palpitations', 'прискорене серцебиття'),
    ('high_blood_pressure', 'підвищений тиск'),
    ('low_blood_pressure', 'знижений тиск'),
    ('back_pain', 'біль у спині'),
    ('joint_pain', 'біль у суглобах'),
    ('muscle_pain', 'біль у м\'язах'),
    ('cramps', 'судоми'),
    ('swelling', 'набряки'),
    ('itching', 'свербіж'),
    ('dry_skin', 'сухість шкіри'),
    ('bruising', 'синці'),
    ('dry_mouth', 'сухість у роті'),
    ('excessive_sweating', 'підвищена пітливість'),
    ('chills', 'озноб'),
    ('blurred_vision', 'розмитий зір'),
    ('ringing_in_ears', 'дзвін у вухах'),
    ('numbness', 'оніміння'),
    ('tremor', 'тремтіння'),
    ('memory_issues', 'проблеми з пам\'яттю'),
    ('concentration_issues', 'проблеми з концентрацією'),
    ('anxiety', 'тривожність'),
    ('irritability', 'дратівливість'),
    ('mood_swings', 'перепади настрою'),
    ('weight_loss', 'втрата ваги'),
    ('weight_gain', 'набір ваги'),
  ];

  static final Map<String, String> _commonLabels = {
    for (final s in common) s.$1: s.$2,
  };

  /// Людяна назва за ключем — для стандартних симптомів мапа, для
  /// `custom_...` — сам текст після префіксу.
  static String labelFor(String key) {
    if (key.startsWith('custom_')) return key.substring(7);
    return _commonLabels[key] ?? key;
  }
}
