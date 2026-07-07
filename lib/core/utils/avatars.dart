import 'package:flutter/material.dart';

const int avatarCount = 47;

String avatarAssetPath(int index) =>
    'assets/avatars/profile-photo-${(index % avatarCount) + 1}.png';

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
