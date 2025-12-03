// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:eClassify/data/model/category_model.dart';
import 'package:eClassify/data/model/data_output.dart';
import 'package:eClassify/data/repositories/category_repository.dart';
import 'package:eClassify/utils/helper_utils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class FetchSubCategoriesState {}

class FetchSubCategoriesInitial extends FetchSubCategoriesState {}

class FetchSubCategoriesInProgress extends FetchSubCategoriesState {}

class FetchSubCategoriesSuccess extends FetchSubCategoriesState {
  final int total;
  final int page;
  final bool isLoadingMore;
  final bool hasError;
  final List<CategoryModel> categories;

  FetchSubCategoriesSuccess({
    required this.total,
    required this.page,
    required this.isLoadingMore,
    required this.hasError,
    required this.categories,
  });

  FetchSubCategoriesSuccess copyWith({
    int? total,
    int? page,
    bool? isLoadingMore,
    bool? hasError,
    List<CategoryModel>? categories,
  }) {
    return FetchSubCategoriesSuccess(
      total: total ?? this.total,
      page: page ?? this.page,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasError: hasError ?? this.hasError,
      categories: categories ?? this.categories,
    );
  }

  @override
  String toString() {
    return 'FetchSubCategoriesSuccess(total: $total,  page: $page, isLoadingMore: $isLoadingMore, hasError: $hasError, categories: $categories)';
  }
}

class FetchSubCategoriesFailure extends FetchSubCategoriesState {
  final String errorMessage;

  FetchSubCategoriesFailure(this.errorMessage);
}

class FetchSubCategoriesCubit extends Cubit<FetchSubCategoriesState> {
  FetchSubCategoriesCubit() : super(FetchSubCategoriesInitial());

  final CategoryRepository _categoryRepository = CategoryRepository();

  Future<void> fetchSubCategories({
    bool? forceRefresh,
    bool? loadWithoutDelay,
    required int categoryId,
  }) async {
    try {
      emit(FetchSubCategoriesInProgress());

      DataOutput<CategoryModel> categories = await _categoryRepository
          .fetchCategories(page: 1, categoryId: categoryId);

      emit(
        FetchSubCategoriesSuccess(
          total: categories.total,
          categories: categories.modelList,
          page: 1,
          hasError: false,
          isLoadingMore: false,
        ),
      );
    } catch (e) {
      emit(FetchSubCategoriesFailure(e.toString()));
    }
  }

  List<CategoryModel> getSubCategories() {
    if (state is FetchSubCategoriesSuccess) {
      return (state as FetchSubCategoriesSuccess).categories;
    }

    return <CategoryModel>[];
  }

  Future<void> fetchSubCategoriesMore() async {
    try {
      if (state is FetchSubCategoriesSuccess) {
        if ((state as FetchSubCategoriesSuccess).isLoadingMore) {
          return;
        }
        emit(
          (state as FetchSubCategoriesSuccess).copyWith(isLoadingMore: true),
        );
        DataOutput<CategoryModel> result = await _categoryRepository
            .fetchCategories(
              page: (state as FetchSubCategoriesSuccess).page + 1,
            );

        FetchSubCategoriesSuccess categoryState =
            (state as FetchSubCategoriesSuccess);
        categoryState.categories.addAll(result.modelList);

        List<String> list = categoryState.categories
            .map((e) => e.url!)
            .toList();
        await HelperUtils.precacheSVG(list);

        emit(
          FetchSubCategoriesSuccess(
            isLoadingMore: false,
            hasError: false,
            categories: categoryState.categories,
            page: (state as FetchSubCategoriesSuccess).page + 1,
            total: result.total,
          ),
        );
      }
    } catch (e) {
      emit(
        (state as FetchSubCategoriesSuccess).copyWith(
          isLoadingMore: false,
          hasError: true,
        ),
      );
    }
  }

  bool hasMoreData() {
    if (state is FetchSubCategoriesSuccess) {
      return (state as FetchSubCategoriesSuccess).categories.length <
          (state as FetchSubCategoriesSuccess).total;
    }
    return false;
  }

  FetchSubCategoriesState? fromJson(Map<String, dynamic> json) {
    return null;
  }

  Map<String, dynamic>? toJson(FetchSubCategoriesState state) {
    return null;
  }
}
