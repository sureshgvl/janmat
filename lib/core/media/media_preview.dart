import 'package:flutter/material.dart';
import 'media_file.dart';

/// Widget for building media previews/thumbnails
Widget buildMediaPreview(MediaFile file, {double size = 50.0}) {
  switch (file.type) {
    case "image":
      return Image.memory(
        file.bytes,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Icon(Icons.image, size: size, color: Colors.grey);
        },
      );

    case "pdf":
      return Icon(Icons.picture_as_pdf, size: size, color: Colors.red);

    case "video":
      return Icon(Icons.videocam, size: size, color: Colors.blue);

    case "audio":
      return Icon(Icons.audiotrack, size: size, color: Colors.green);

    default:
      return Icon(Icons.insert_drive_file, size: size);
  }
}

/// Grid view for multiple media files
class MediaGridView extends StatelessWidget {
  final List<MediaFile> files;
  final int crossAxisCount;
  final double childAspectRatio;
  final Function(MediaFile)? onTap;

  const MediaGridView({
    super.key,
    required this.files,
    this.crossAxisCount = 3,
    this.childAspectRatio = 1.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
      ),
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        return GestureDetector(
          onTap: onTap != null ? () => onTap!(file) : null,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: buildMediaPreview(file, size: 60.0),
          ),
        );
      },
    );
  }
}