import 'package:cloud_firestore/cloud_firestore.dart';
import '/models/customer.dart';

class Loan {
  final String id;
  final DocumentReference<Customer> customerRef;
  final DateTime dateOut;
  final DateTime dateDue;
  DateTime? dateIn;
  bool isRenewal = false;

  Loan({
    required this.id,
    required this.customerRef,
    required this.dateOut,
    required this.dateDue,
    this.dateIn,
    this.isRenewal = false,
  });

  Loan.fromJson(Map<String, Object?> json)
      : id = json['id'] as String,
        customerRef = json['customerRef'] as DocumentReference<Customer>,
        dateOut = (json['dateOut'] as Timestamp).toDate(),
        dateDue = (json['dateDue'] as Timestamp).toDate(),
        dateIn = json['dateIn'] != null
            ? (json['dateIn'] as Timestamp).toDate()
            : null,
        isRenewal = json['isRenewal'] as bool ?? false;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'customerRef': customerRef,
      'dateOut': dateOut.toIso8601String(),
      'dateDue': dateDue.toIso8601String(),
      'dateIn': dateIn?.toIso8601String(),
      'isRenewal': isRenewal,
    };
  }
}
