import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category_model.dart';

class CategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<CategoryModel> _defaultCategories = [
    CategoryModel(id: 'textbooks', name: 'Textbooks', icon: 'menu_book'),
    CategoryModel(id: 'electronics', name: 'Electronics', icon: 'laptop_mac'),
    CategoryModel(id: 'dorm_living', name: 'Dorm & Living', icon: 'home'),
    CategoryModel(id: 'fashion', name: 'Fashion & Apparel', icon: 'checkroom'),
    CategoryModel(id: 'bikes_rides', name: 'Bikes & Rides', icon: 'pedal_bike'),
  ];

  // Stream of all categories
  Stream<List<CategoryModel>> getCategoriesStream() {
    return _firestore.collection('categories').snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return _defaultCategories;
      }
      return snapshot.docs
          .map((doc) => CategoryModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Get categories as list
  Future<List<CategoryModel>> getCategories() async {
    final snapshot = await _firestore.collection('categories').get();
    if (snapshot.docs.isEmpty) {
      // Seed default categories into firestore
      for (var cat in _defaultCategories) {
        await _firestore.collection('categories').doc(cat.id).set(cat.toMap());
      }
      return _defaultCategories;
    }
    return snapshot.docs
        .map((doc) => CategoryModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  // Add category
  Future<void> addCategory(String name, String icon) async {
    final docRef = _firestore.collection('categories').doc();
    final newCat = CategoryModel(id: docRef.id, name: name, icon: icon);
    await docRef.set(newCat.toMap());
  }

  // Edit category
  Future<void> updateCategory(CategoryModel category) async {
    await _firestore.collection('categories').doc(category.id).update(category.toMap());
  }

  // Delete category
  Future<void> deleteCategory(String id) async {
    await _firestore.collection('categories').doc(id).delete();
  }
}
