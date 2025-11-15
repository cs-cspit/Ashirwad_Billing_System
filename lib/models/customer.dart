class Customer {
  final String id;
  final String name;
  final String contactNumber;
  final String address;
  final String? gstNumber;
  final DateTime dateAdded;

  Customer({
    String? id,
    required this.name,
    required this.contactNumber,
    required this.address,
    this.gstNumber,
    DateTime? dateAdded,
  }) : id = id ?? '',
       dateAdded = dateAdded ?? DateTime.now();

  // Convert from Supabase data
  factory Customer.fromSupabase(Map<String, dynamic> data) {
    return Customer(
      id: data['id'],
      name: data['name'],
      contactNumber: data['contact_number'],
      address: data['address'],
      gstNumber: data['gst_number'],
      dateAdded: DateTime.parse(data['created_at']),
    );
  }

  // Convert to Supabase data
  Map<String, dynamic> toSupabase() {
    return {
      'name': name,
      'contact_number': contactNumber,
      'address': address,
      'gst_number': gstNumber,
    };
  }

  // Backward compatibility
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'contactNumber': contactNumber,
      'gstNumber': gstNumber,
      'address': address,
    };
  }

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'],
      name: json['name'],
      contactNumber: json['contactNumber'],
      address: json['address'],
      gstNumber: json['gstNumber'],
      dateAdded: json['dateAdded'] != null ? DateTime.parse(json['dateAdded']) : DateTime.now(),
    );
  }
}
