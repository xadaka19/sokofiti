import 'dart:developer';

import 'package:eClassify/data/repositories/item/item_repository.dart';
import 'package:eClassify/utils/api.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class DeleteItemState {}

class DeleteItemInitial extends DeleteItemState {}

class DeleteItemInProgress extends DeleteItemState {}

class DeleteItemSuccess extends DeleteItemState {}

class DeleteItemFailure extends DeleteItemState {
  final String errorMessage;

  DeleteItemFailure(this.errorMessage);
}

class DeleteItemCubit extends Cubit<DeleteItemState> {
  final ItemRepository _itemRepository = ItemRepository();

  DeleteItemCubit() : super(DeleteItemInitial());

  Future<void> deleteItem({required int id}) async {
    try {
      emit(DeleteItemInProgress());

      await _itemRepository.deleteItem(id: id);
      emit(DeleteItemSuccess());
    } catch (e) {
      emit(DeleteItemFailure(e.toString()));
    }
  }

  Future<void> deleteMultiItem({required Iterable<int> ids}) async {
    try {
      emit(DeleteItemInProgress());

      await _itemRepository.deleteItem(ids: ids);
      emit(DeleteItemSuccess());
    } on Exception catch (e, stack) {
      log(e.toString(), name: 'deleteMultiItem');
      log('$stack', name: 'deleteMultiItem');
      throw ApiException(e.toString());
    }
  }
}
