import 'dart:developer';

import 'package:eClassify/data/model/item/item_model.dart';
import 'package:eClassify/data/repositories/item/item_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class FetchItemState {}

class FetchItemInitial extends FetchItemState {}

class FetchItemLoading extends FetchItemState {}

class FetchItemSuccess extends FetchItemState {
  final ItemModel item;

  FetchItemSuccess({required this.item});
}

class FetchItemFailure extends FetchItemState {
  final String errorMessage;

  FetchItemFailure({required this.errorMessage});
}

class FetchItemCubit extends Cubit<FetchItemState> {
  FetchItemCubit() : super(FetchItemInitial());

  void fetchItem({int? itemId, String? slug}) {
    assert(
      itemId != null || slug != null,
      'Either itemId or slug should be provided to get the item data',
    );
    if (itemId != null) {
      _fetchItemFromId(id: itemId);
    } else {
      _fetchItemFromSlug(slug: slug!);
    }
  }

  Future<void> _fetchItemFromId({required int id}) async {
    try {
      emit(FetchItemLoading());

      final models = await ItemRepository().fetchItemFromItemId(id);
      emit(FetchItemSuccess(item: models.modelList.first));
    } on Exception catch (e, stack) {
      log(e.toString(), name: 'fetchItem');
      log('$stack', name: 'fetchItem');
      emit(FetchItemFailure(errorMessage: e.toString()));
    }
  }

  Future<void> _fetchItemFromSlug({required String slug}) async {
    try {
      emit(FetchItemLoading());

      final models = await ItemRepository().fetchItemFromItemSlug(slug);
      emit(FetchItemSuccess(item: models.modelList.first));
    } on Exception catch (e, stack) {
      log(e.toString(), name: 'fetchItemFromSlug');
      log('$stack', name: 'fetchItemFromSlug');
      emit(FetchItemFailure(errorMessage: e.toString()));
    }
  }
}
