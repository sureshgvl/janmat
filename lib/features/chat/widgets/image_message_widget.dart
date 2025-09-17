import 'package:flutter/material.dart';
import '../../../widgets/common/reusable_image_widget.dart';

class ImageMessageWidget extends StatelessWidget {
  final String? imageUrl;
  final bool isCurrentUser;
  final String? text;
  final VoidCallback? onTap;

  const ImageMessageWidget({
    super.key,
    required this.imageUrl,
    required this.isCurrentUser,
    this.text,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (imageUrl != null)
          GestureDetector(
            onTap: onTap,
            child: ReusableImageWidget(
              imageUrl: imageUrl!,
              fit: BoxFit.cover,
              maxWidth: 200,
              maxHeight: 200,
              borderRadius: BorderRadius.circular(8),
              enableFullScreenView: true,
              fullScreenTitle: 'Chat Image',
            ),
          ),
        if (text != null && text!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            text!,
            style: TextStyle(
              color: isCurrentUser ? Colors.white : Colors.black87,
              fontSize: 16,
              height: 1.3,
            ),
          ),
        ],
      ],
    );
  }
}
