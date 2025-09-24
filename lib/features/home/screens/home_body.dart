import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/user_model.dart';
import '../../candidate/models/candidate_model.dart';
import '../widgets/home_sections.dart';

class HomeBody extends StatelessWidget {
  final UserModel? userModel;
  final Candidate? candidateModel;
  final User? currentUser;

  const HomeBody({
    super.key,
    required this.userModel,
    required this.candidateModel,
    required this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    return HomeSections.buildHomeBody(
      userModel: userModel,
      candidateModel: candidateModel,
      currentUser: currentUser,
    );
  }
}
