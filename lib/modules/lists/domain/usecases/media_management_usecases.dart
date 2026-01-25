import 'dart:io';
import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import '../repositories/seller_repository.dart';

class UploadListingPhotoUseCase {
  final SellerRepository repository;
  UploadListingPhotoUseCase(this.repository);
  Future<Either<Failure, String>> call({required String userId, required String listingId, required String category, required File imageFile}) => 
    repository.uploadPhoto(userId: userId, listingId: listingId, category: category, imageFile: imageFile);
}

class UploadDeedOfSaleUseCase {
  final SellerRepository repository;
  UploadDeedOfSaleUseCase(this.repository);
  Future<Either<Failure, String>> call({required String userId, required String listingId, required File documentFile}) => 
    repository.uploadDeedOfSale(userId: userId, listingId: listingId, documentFile: documentFile);
}

class DeleteDeedOfSaleUseCase {
  final SellerRepository repository;
  DeleteDeedOfSaleUseCase(this.repository);
  Future<Either<Failure, void>> call(String documentUrl) => repository.deleteDeedOfSale(documentUrl);
}
