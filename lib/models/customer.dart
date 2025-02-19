class Customer {
  final String id;
  final String name;
  final String email;

  Customer({
    required this.id,
    required this.name,
    required this.email,
  });

  Customer.fromJson(Map<String, Object?> json)
      : this(
          id: json['id'] as String,
          name: json['name'] as String,
          email: json['email'] as String,
        );

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
    };
  }
}
