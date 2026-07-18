import 'package:flutter/material.dart';

const int avatarCount = 47;

// "Домашні улюбленці" — окрема секція внизу пікера аватарів (не входить у
// avatarCount, щоб НЕ зсунути існуючі avatarIndex-значення вже збережених
// членів родини — індекси 47+ додаються ПОВЕРХ, а не замість).
const List<String> petAvatarFiles = [
  'profile-photo-cat-1',
  'profile-photo-cat-2',
  'profile-photo-cat-3',
  'profile-photo-cat-4',
  'profile-photo-dog-1',
  'profile-photo-dog-2',
  'profile-photo-dog-3',
  'profile-photo-dog-4',
  'profile-photo-dog-5',
  'profile-photo-dog-6',
  'profile-photo-rabbit-1',
  'profile-photo-rabbit-2',
  'profile-photo-parrot-1',
  'profile-photo-parrot-2',
  'profile-photo-hamster-1',
  'profile-photo-hamster-2',
  'profile-photo-fish-1',
  'profile-photo-fish-2',
];

// Тримати в синхроні з довжиною petAvatarFiles вище (18 файлів).
const int petAvatarCount = 18;

/// Загальна кількість позицій у пікері — людські аватари + вихованці,
/// саме стільки `itemCount` має пікер, щоб показати обидві секції.
const int totalAvatarCount = avatarCount + petAvatarCount;

String avatarAssetPath(int index) {
  if (index >= avatarCount && index < totalAvatarCount) {
    return 'assets/avatars/${petAvatarFiles[index - avatarCount]}.png';
  }
  return 'assets/avatars/profile-photo-${(index % avatarCount) + 1}.png';
}

class AvatarImage extends StatelessWidget {
  final int index;
  final double size;
  const AvatarImage({super.key, required this.index, required this.size});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Image.asset(
        avatarAssetPath(index),
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
}
