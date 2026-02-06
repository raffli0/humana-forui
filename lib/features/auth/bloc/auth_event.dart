import 'dart:io';
import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class AuthRegisterRequested extends AuthEvent {
  final String fullName;
  final String email;
  final String password;
  final String? companyName;
  final String role;

  const AuthRegisterRequested({
    required this.fullName,
    required this.email,
    required this.password,
    this.companyName,
    required this.role,
  });

  @override
  List<Object?> get props => [fullName, email, password, companyName, role];
}

class AuthCheckRequested extends AuthEvent {}

class AuthProfileUpdateRequested extends AuthEvent {
  final String fullName;
  final String email;
  final String? phone;
  final String? department;
  final String? manager;
  final String? companyName;

  const AuthProfileUpdateRequested({
    required this.fullName,
    required this.email,
    this.phone,
    this.department,
    this.manager,
    this.companyName,
  });

  @override
  List<Object?> get props => [
    fullName,
    email,
    phone,
    department,
    manager,
    companyName,
  ];
}

class AuthProfilePhotoUpdateRequested extends AuthEvent {
  final File imageFile;

  const AuthProfilePhotoUpdateRequested(this.imageFile);

  @override
  List<Object?> get props => [imageFile];
}

class AuthLogoutRequested extends AuthEvent {}
