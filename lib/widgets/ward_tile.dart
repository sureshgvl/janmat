import 'package:flutter/material.dart';
import '../models/ward_model.dart';

class WardTile extends StatelessWidget {
  final Ward ward;
  final VoidCallback onTap;
  final bool isSelected;

  const WardTile({
    super.key,
    required this.ward,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(ward.name),
      subtitle: Text('${ward.cityId} - ${ward.areas.join(", ")}'),
      trailing: isSelected ? const Icon(Icons.check) : null,
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      tileColor: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
    );
  }
}