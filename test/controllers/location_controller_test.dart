import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import '../../lib/features/candidate/controllers/location_controller.dart';
import '../../lib/models/district_model.dart';
import '../../lib/models/body_model.dart';
import '../../lib/models/ward_model.dart';

void main() {
  late LocationController controller;

  setUp(() {
    controller = LocationController();
  });

  tearDown(() {
    Get.reset();
  });

  group('LocationController', () {
    test('should initialize with default values', () {
      expect(controller.selectedStateId.value, 'maharashtra');
      expect(controller.selectedDistrictId.value, null);
      expect(controller.selectedBodyId.value, null);
      expect(controller.selectedWard.value, null);
      expect(controller.districts, isEmpty);
      expect(controller.districtBodies, isEmpty);
      expect(controller.bodyWards, isEmpty);
    });

    test('should have reactive properties', () {
      expect(controller.selectedStateId, isA<RxString>());
      expect(controller.selectedDistrictId, isA<Rx<String?>>());
      expect(controller.selectedBodyId, isA<Rx<String?>>());
      expect(controller.selectedWard, isA<Rx<Ward?>>());
    });

    test('should have loading states', () {
      expect(controller.isLoadingDistricts, isA<RxBool>());
      expect(controller.isLoadingBodies, isA<RxBool>());
      expect(controller.isLoadingWards, isA<RxBool>());
    });

    test('should have error states', () {
      expect(controller.districtsError, isA<Rx<String?>>());
      expect(controller.bodiesError, isA<Rx<String?>>());
      expect(controller.wardsError, isA<Rx<String?>>());
    });

    test('should clear selections correctly', () {
      // Setup initial state
      controller.selectedDistrictId.value = 'district1';
      controller.selectedBodyId.value = 'body1';
      controller.selectedWard.value = Ward(id: 'ward1', name: 'Ward 1', areas: [], districtId: 'district1', bodyId: 'body1', stateId: 'maharashtra');

      // Clear selections
      controller.clearSelections();

      // Verify all selections are cleared
      expect(controller.selectedDistrictId.value, null);
      expect(controller.selectedBodyId.value, null);
      expect(controller.selectedWard.value, null);
    });

    test('should check complete selection correctly', () {
      // Initially no complete selection
      expect(controller.hasCompleteSelection, false);

      // Set partial selection
      controller.selectedDistrictId.value = 'district1';
      expect(controller.hasCompleteSelection, false);

      controller.selectedBodyId.value = 'body1';
      expect(controller.hasCompleteSelection, false);

      // Set complete selection
      controller.selectedWard.value = Ward(id: 'ward1', name: 'Ward 1', areas: [], districtId: 'district1', bodyId: 'body1', stateId: 'maharashtra');
      expect(controller.hasCompleteSelection, true);
    });

    test('should get selected district correctly', () {
      final district = District(id: 'district1', name: 'District 1', stateId: 'maharashtra');
      controller.districts.add(district);
      controller.selectedDistrictId.value = 'district1';

      expect(controller.selectedDistrict, district);
    });

    test('should get selected body correctly', () {
      final body = Body(id: 'body1', name: 'Body 1', type: BodyType.municipal_corporation, districtId: 'district1', stateId: 'maharashtra');
      controller.districtBodies['district1'] = [body];
      controller.selectedDistrictId.value = 'district1';
      controller.selectedBodyId.value = 'body1';

      expect(controller.selectedBody, body);
    });

    test('should get available bodies correctly', () {
      final bodies = [
        Body(id: 'body1', name: 'Body 1', type: BodyType.municipal_corporation, districtId: 'district1', stateId: 'maharashtra'),
        Body(id: 'body2', name: 'Body 2', type: BodyType.municipal_corporation, districtId: 'district1', stateId: 'maharashtra'),
      ];
      controller.districtBodies['district1'] = bodies;
      controller.selectedDistrictId.value = 'district1';

      expect(controller.availableBodies, bodies);
    });

    test('should get available wards correctly', () {
      final wards = [
        Ward(id: 'ward1', name: 'Ward 1', areas: [], districtId: 'district1', bodyId: 'body1', stateId: 'maharashtra'),
        Ward(id: 'ward2', name: 'Ward 2', areas: [], districtId: 'district1', bodyId: 'body1', stateId: 'maharashtra'),
      ];
      controller.bodyWards['district1_body1'] = wards;
      controller.selectedDistrictId.value = 'district1';
      controller.selectedBodyId.value = 'body1';

      expect(controller.availableWards, wards);
    });

    test('should select ward correctly', () {
      final ward = Ward(id: 'ward1', name: 'Ward 1', areas: [], districtId: 'district1', bodyId: 'body1', stateId: 'maharashtra');

      controller.selectWard(ward);

      expect(controller.selectedWard.value, ward);
    });

    test('should handle null selected district', () {
      controller.selectedDistrictId.value = null;
      expect(controller.selectedDistrict, null);
    });

    test('should handle null selected body', () {
      controller.selectedDistrictId.value = 'district1';
      controller.selectedBodyId.value = null;
      expect(controller.selectedBody, null);
    });

    test('should handle empty available bodies', () {
      controller.selectedDistrictId.value = 'nonexistent';
      expect(controller.availableBodies, isEmpty);
    });

    test('should handle empty available wards', () {
      controller.selectedDistrictId.value = 'district1';
      controller.selectedBodyId.value = 'nonexistent';
      expect(controller.availableWards, isEmpty);
    });
  });
}
