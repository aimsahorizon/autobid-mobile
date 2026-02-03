class VehicleBrand {
  final String id;
  final String name;
  final String? logoUrl;

  const VehicleBrand({required this.id, required this.name, this.logoUrl});
}

class VehicleModel {
  final String id;
  final String brandId;
  final String name;
  final String? bodyType;

  const VehicleModel({
    required this.id,
    required this.brandId,
    required this.name,
    this.bodyType,
  });
}

class VehicleVariant {
  final String id;
  final String modelId;
  final String name;
  final String? transmission;
  final String? fuelType;

  const VehicleVariant({
    required this.id,
    required this.modelId,
    required this.name,
    this.transmission,
    this.fuelType,
  });
}
