import 'package:equatable/equatable.dart';

class ExtendedContact extends ContactModel {
  @override
  final String? officeAddress;
  @override
  final String? officeHours;

  const ExtendedContact({
    super.phone,
    super.email,
    super.address,
    super.socialLinks,
    this.officeAddress,
    this.officeHours,
  });

  factory ExtendedContact.fromJson(Map<String, dynamic> json) {
    return ExtendedContact(
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      socialLinks: json['socialLinks'] != null
          ? Map<String, String>.from(json['socialLinks'])
          : null,
      officeAddress: json['officeAddress'] as String?,
      officeHours: json['officeHours'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      if (officeAddress != null) 'officeAddress': officeAddress,
      if (officeHours != null) 'officeHours': officeHours,
    };
  }

  @override
  ExtendedContact copyWith({
    String? phone,
    String? email,
    String? address,
    Map<String, String>? socialLinks,
    String? officeAddress,
    String? officeHours,
  }) {
    return ExtendedContact(
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      socialLinks: socialLinks ?? this.socialLinks,
      officeAddress: officeAddress ?? this.officeAddress,
      officeHours: officeHours ?? this.officeHours,
    );
  }

  @override
  List<Object?> get props => [
        ...super.props,
        officeAddress,
        officeHours,
      ];
}

class ContactModel extends Equatable {
  final String? phone;
  final String? email;
  final String? address;
  final Map<String, String>? socialLinks;
  final String? officeAddress;
  final String? officeHours;

  const ContactModel({
    this.phone,
    this.email,
    this.address,
    this.socialLinks,
    this.officeAddress,
    this.officeHours,
  });

  factory ContactModel.fromJson(Map<String, dynamic> json) {
    return ContactModel(
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      socialLinks: json['socialLinks'] != null
          ? Map<String, String>.from(json['socialLinks'])
          : null,
      officeAddress: json['officeAddress'] as String?,
      officeHours: json['officeHours'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (address != null) 'address': address,
      if (socialLinks != null) 'socialLinks': socialLinks,
      if (officeAddress != null) 'officeAddress': officeAddress,
      if (officeHours != null) 'officeHours': officeHours,
    };
  }

  ContactModel copyWith({
    String? phone,
    String? email,
    String? address,
    Map<String, String>? socialLinks,
    String? officeAddress,
    String? officeHours,
  }) {
    return ContactModel(
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      socialLinks: socialLinks ?? this.socialLinks,
      officeAddress: officeAddress ?? this.officeAddress,
      officeHours: officeHours ?? this.officeHours,
    );
  }

  @override
  List<Object?> get props => [
        phone,
        email,
        address,
        socialLinks,
        officeAddress,
        officeHours,
      ];
}
