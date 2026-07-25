import 'package:eClassify/data/model/category_model.dart';
import 'package:eClassify/data/repositories/category_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class PopularCategoriesState {}

class PopularCategoriesInitial extends PopularCategoriesState {}

class PopularCategoriesLoading extends PopularCategoriesState {}

class PopularCategoriesSuccess extends PopularCategoriesState {
  PopularCategoriesSuccess({required this.categories});

  final List<CategoryModel> categories;
}

class PopularCategoriesFailure extends PopularCategoriesState {
  PopularCategoriesFailure({required this.message});

  final String message;
}

class PopularCategoriesCubit extends Cubit<PopularCategoriesState> {
  final CategoryRepository _categoryRepository;

  PopularCategoriesCubit({CategoryRepository? categoryRepository})
      : _categoryRepository = categoryRepository ?? CategoryRepository(),
        super(PopularCategoriesInitial());

  Future<void> fetchPopularCategories() async {
    try {
      emit(PopularCategoriesLoading());

      final categories = await _categoryRepository.fetchPopularCategories();

      emit(PopularCategoriesSuccess(categories: categories));
    } catch (e) {
      emit(PopularCategoriesFailure(message: e.toString()));
    }
  }
}
