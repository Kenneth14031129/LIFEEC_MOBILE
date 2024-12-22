class Resident {
  final String id;
  final String name;
  final int age;
  final String gender;
  final String contact;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final String allergies;
  final String medicalCondition;
  final String date;
  final String status;
  final String medication;
  final String dosage;
  final String quantity;
  final String time;
  final String takenOrNot;
  final String healthAssessment;
  final String administrationInstruction;
  final String dietaryNeeds;
  final String nutritionGoals;
  final String breakfast;
  final String lunch;
  final String snacks;
  final String dinner;
  final String activityName;
  final String activityDate;
  final String description;

  Resident({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.contact,
    required this.emergencyContactName,
    required this.emergencyContactPhone,
    this.allergies = '',
    this.medicalCondition = '',
    this.date = '',
    this.status = '',
    this.medication = '',
    this.dosage = '',
    this.quantity = '',
    this.time = '',
    this.takenOrNot = '',
    this.healthAssessment = '',
    this.administrationInstruction = '',
    this.dietaryNeeds = '',
    this.nutritionGoals = '',
    this.breakfast = '',
    this.lunch = '',
    this.snacks = '',
    this.dinner = '',
    this.activityName = '',
    this.activityDate = '',
    this.description = '',
  });

  Resident copyWith({
    String? id,
    String? name,
    int? age,
    String? gender,
    String? contact,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? allergies,
    String? medicalCondition,
    String? date,
    String? status,
    String? medication,
    String? dosage,
    String? quantity,
    String? time,
    String? takenOrNot,
    String? healthAssessment,
    String? administrationInstruction,
    String? dietaryNeeds,
    String? nutritionGoals,
    String? breakfast,
    String? lunch,
    String? snacks,
    String? dinner,
    String? activityName,
    String? activityDate,
    String? description,
  }) {
    return Resident(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      contact: contact ?? this.contact,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone:
          emergencyContactPhone ?? this.emergencyContactPhone,
      allergies: allergies ?? this.allergies,
      medicalCondition: medicalCondition ?? this.medicalCondition,
      date: date ?? this.date,
      status: status ?? this.status,
      medication: medication ?? this.medication,
      dosage: dosage ?? this.dosage,
      quantity: quantity ?? this.quantity,
      time: time ?? this.time,
      takenOrNot: takenOrNot ?? this.takenOrNot,
      healthAssessment: healthAssessment ?? this.healthAssessment,
      administrationInstruction:
          administrationInstruction ?? this.administrationInstruction,
      dietaryNeeds: dietaryNeeds ?? this.dietaryNeeds,
      nutritionGoals: nutritionGoals ?? this.nutritionGoals,
      breakfast: breakfast ?? this.breakfast,
      lunch: lunch ?? this.lunch,
      snacks: snacks ?? this.snacks,
      dinner: dinner ?? this.dinner,
      activityName: activityName ?? this.activityName,
      activityDate: activityDate ?? this.activityDate,
      description: description ?? this.description,
    );
  }
}
