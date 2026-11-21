import '../../domain/entities/order.dart';
import '../models/customer_model.dart';

class CustomerMapper {
  const CustomerMapper._();

  static Customer toEntity(CustomerModel model) => Customer(
    id: model.id,
    name: model.name,
    email: model.email,
    phone: model.phone,
    province: model.province,
    city: model.city,
    district: model.district,
    subdistrict: model.subdistrict,
    rtRw: model.rtRw,
    postalCode: model.postalCode,
    address: model.address,
  );
}
