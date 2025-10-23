import 'package:equatable/equatable.dart';

class EventData extends Equatable {
  final String? id;
  final String title;
  final String? description;
  final String date;
  final String? time;
  final String? venue;
  final String? mapLink;
  final String? type;
  final String? status;
  final int? attendeesExpected;
  final List<String>? agenda;
  final Map<String, List<String>>? rsvp; // interested, going, not_going

  const EventData({
    this.id,
    required this.title,
    this.description,
    required this.date,
    this.time,
    this.venue,
    this.mapLink,
    this.type,
    this.status,
    this.attendeesExpected,
    this.agenda,
    this.rsvp,
  });

  factory EventData.fromJson(Map<String, dynamic> json) {
    return EventData(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      date: json['date'],
      time: json['time'],
      venue: json['venue'],
      mapLink: json['map_link'],
      type: json['type'],
      status: json['status'],
      attendeesExpected: json['attendees_expected'],
      agenda: json['agenda'] != null ? List<String>.from(json['agenda']) : null,
      rsvp: json['rsvp'] != null
          ? Map<String, List<String>>.from(
              json['rsvp'].map(
                (key, value) => MapEntry(
                  key,
                  value is List ? List<String>.from(value) : [],
                ),
              ),
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date,
      'time': time,
      'venue': venue,
      'map_link': mapLink,
      'type': type,
      'status': status,
      'attendees_expected': attendeesExpected,
      'agenda': agenda,
      'rsvp': rsvp,
    };
  }

  // Helper methods for RSVP
  int getInterestedCount() => rsvp?['interested']?.length ?? 0;
  int getGoingCount() => rsvp?['going']?.length ?? 0;
  int getNotGoingCount() => rsvp?['not_going']?.length ?? 0;

  bool isUserInterested(String userId) =>
      rsvp?['interested']?.contains(userId) ?? false;
  bool isUserGoing(String userId) => rsvp?['going']?.contains(userId) ?? false;
  bool isUserNotGoing(String userId) =>
      rsvp?['not_going']?.contains(userId) ?? false;

  EventData copyWith({
    String? id,
    String? title,
    String? description,
    String? date,
    String? time,
    String? venue,
    String? mapLink,
    String? type,
    String? status,
    int? attendeesExpected,
    List<String>? agenda,
    Map<String, List<String>>? rsvp,
  }) {
    return EventData(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      time: time ?? this.time,
      venue: venue ?? this.venue,
      mapLink: mapLink ?? this.mapLink,
      type: type ?? this.type,
      status: status ?? this.status,
      attendeesExpected: attendeesExpected ?? this.attendeesExpected,
      agenda: agenda ?? this.agenda,
      rsvp: rsvp ?? this.rsvp,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        date,
        time,
        venue,
        mapLink,
        type,
        status,
        attendeesExpected,
        agenda,
        rsvp,
      ];
}
