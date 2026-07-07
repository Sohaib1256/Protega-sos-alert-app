import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

enum UserRole { patient, guardian, caretaker, safetyOfficer }

enum UserPurpose { medical, personal }

class UserModel {
 final String id;
 final String name;
 final String email;
 final UserRole role;
 final UserPurpose purpose;
 final String? guardianPhone;
 final String phone;
 final String countryCode;
 String avatarUrl;
 String? occupation;
 int? age;
 bool isOnline;
 int batteryLevel;
 bool deviceConfigured;
 double? lat;
 double? lng;
 final String? deviceId;
 List<String> friends;
 List<String> sentRequests;
 List<String> receivedRequests;

 UserModel({
 String? id,
 required this.name,
 required this.email,
 required this.role,
 required this.purpose,
 this.guardianPhone,
 this.phone = '',
 this.countryCode = '+92',
 String? avatarUrl,
 this.occupation,
 this.age,
 this.isOnline = true,
 this.batteryLevel = 85,
this.deviceConfigured = false,
this.lat,
 this.lng,
 this.deviceId,
 List<String>? friends,
 List<String>? sentRequests,
 List<String>? receivedRequests,
 }) : id = id ?? 'PID-${_uuid.v4().substring(0, 6).toUpperCase()}',
      friends = friends ?? [],
      sentRequests = sentRequests ?? [],
      receivedRequests = receivedRequests ?? [],
  avatarUrl = avatarUrl ??
      'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&size=200&background=random&color=fff';

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    UserPurpose? purpose,
    String? guardianPhone,
    String? phone,
    String? countryCode,
    String? avatarUrl,
    String? occupation,
    int? age,
    bool? isOnline,
    int? batteryLevel,
    bool? deviceConfigured,
    double? lat,
    double? lng,
    String? deviceId,
    List<String>? friends,
    List<String>? sentRequests,
    List<String>? receivedRequests,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      purpose: purpose ?? this.purpose,
      guardianPhone: guardianPhone ?? this.guardianPhone,
      phone: phone ?? this.phone,
      countryCode: countryCode ?? this.countryCode,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      occupation: occupation ?? this.occupation,
      age: age ?? this.age,
      isOnline: isOnline ?? this.isOnline,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      deviceConfigured: deviceConfigured ?? this.deviceConfigured,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      deviceId: deviceId ?? this.deviceId,
      friends: friends ?? this.friends,
      sentRequests: sentRequests ?? this.sentRequests,
      receivedRequests: receivedRequests ?? this.receivedRequests,
    );
  }

 String get displayRole {
switch (role) {
case UserRole.patient:
 return 'Patient';
 case UserRole.guardian:
return 'Guardian';
 case UserRole.caretaker:
return 'Caretaker';
 case UserRole.safetyOfficer:
 return 'Safety Officer';
 }
 }

 IconData get roleIcon {
 switch (role) {
 case UserRole.patient:
 return Icons.favorite_rounded;
 case UserRole.guardian:
 return Icons.shield_rounded;
 case UserRole.caretaker:
 return Icons.volunteer_activism_rounded;
 case UserRole.safetyOfficer:
 return Icons.local_police_rounded;
 }}
}

class AlertModel {
 final String id;
 final String userId;
 final String userName;
 final DateTime timestamp;
 final double? lat;
 final double? lng;
 final bool isActive;
 final String type;
 final String? note;

 AlertModel({
 String? id,
 required this.userId,
 required this.userName,
 DateTime? timestamp,
 this.lat,
 this.lng,
 this.isActive = true,
this.type = 'SOS',
 this.note,
 }) : id = id ?? 'ALR-${_uuid.v4().substring(0, 6).toUpperCase()}',
timestamp = timestamp ?? DateTime.now();

 String get timeAgo {
 final diff = DateTime.now().difference(timestamp);
 if (diff.inMinutes < 1) return 'Just now';
 if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
 if (diff.inHours < 24) return '${diff.inHours}h ago';
 return '${diff.inDays}d ago';
 }
}

class ChatMessage {
 final String id;
 final String senderId;
 final String receiverId;
 final String text;
 final DateTime timestamp;
 final bool isAI;
 final List<String>? mapLinks;

 ChatMessage({
 String? id,
 required this.senderId,
 required this.receiverId,
required this.text,
 DateTime? timestamp,
this.isAI = false,
 this.mapLinks,
 }) : id = id ?? _uuid.v4(),
 timestamp = timestamp ?? DateTime.now();
}

class FriendModel {
  final String id;
  final String name;
  final String avatarUrl;
  bool isOnline;
  final String? lastMessage;
  final DateTime? lastSeen;
  final bool isAI;
  final bool isPending;

  FriendModel({
    required this.id,
    required this.name,
    required this.avatarUrl,
    this.isOnline = false,
    this.lastMessage,
    this.lastSeen,
    this.isAI = false,
    this.isPending = false,
  });
}

class EmergencyContact {
 final String id;
 final String name;
 final String phone;
 final String countryCode;
 final String relation;

 EmergencyContact({
 String? id,
 required this.name,
 required this.phone,
 this.countryCode = '+92',
 required this.relation,
 }) : id = id ?? _uuid.v4();
}

class NotificationItem {
 final String id;
 final String title;
 final String message;
 final DateTime time;
 final bool isRead;
 final String type;

 NotificationItem({
 String? id,
 required this.title,
 required this.message,
 DateTime? time,
 this.isRead = false,
 this.type = 'info',
 }) : id = id ?? _uuid.v4(),
 time = time ?? DateTime.now();
}
