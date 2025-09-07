import 'package:get/get.dart';
import '../models/candidate_model.dart';
import '../models/ward_model.dart';
import '../models/city_model.dart';
import '../repositories/candidate_repository.dart';

class CandidateController extends GetxController {
  final CandidateRepository _repository = CandidateRepository();

  List<Candidate> candidates = [];
  List<Ward> wards = [];
  List<City> cities = [];
  bool isLoading = false;
  String? errorMessage;

  // Fetch candidates by ward
  Future<void> fetchCandidatesByWard(String cityId, String wardId) async {
    isLoading = true;
    errorMessage = null;
    update();

    try {
      candidates = await _repository.getCandidatesByWard(cityId, wardId);
    } catch (e) {
      errorMessage = e.toString();
      candidates = [];
    }

    isLoading = false;
    update();
  }

  // Fetch candidates by city
  Future<void> fetchCandidatesByCity(String cityId) async {
    isLoading = true;
    errorMessage = null;
    update();

    try {
      candidates = await _repository.getCandidatesByCity(cityId);
    } catch (e) {
      errorMessage = e.toString();
      candidates = [];
    }

    isLoading = false;
    update();
  }

  // Fetch wards for a city
  Future<void> fetchWardsByCity(String cityId) async {
    try {
      wards = await _repository.getWardsByCity(cityId);
      update();
    } catch (e) {
      errorMessage = 'Failed to load wards: $e';
      wards = [];
      update();
    }
  }

  // Fetch all cities
  Future<void> fetchAllCities() async {
    try {
      cities = await _repository.getAllCities();
      update();
    } catch (e) {
      errorMessage = 'Failed to load cities: $e';
      cities = [];
      update();
    }
  }

  // Search candidates
  Future<void> searchCandidates(String query, {String? cityId, String? wardId}) async {
    isLoading = true;
    errorMessage = null;
    update();

    try {
      candidates = await _repository.searchCandidates(query, cityId: cityId, wardId: wardId);
    } catch (e) {
      errorMessage = e.toString();
      candidates = [];
    }

    isLoading = false;
    update();
  }

  // Clear candidates
  void clearCandidates() {
    candidates = [];
    update();
  }

  // Clear error
  void clearError() {
    errorMessage = null;
    update();
  }
}