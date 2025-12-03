import 'package:flutter_bloc/flutter_bloc.dart';

/// Event types for refreshing My Items lists
enum MyItemsRefreshEvent {
  /// Refresh all item lists
  refreshAll,
  
  /// Refresh items with specific status
  refreshWithStatus,
}

/// State class for My Items refresh events
class MyItemsRefreshState {
  final MyItemsRefreshEvent event;
  final String? status;
  final DateTime timestamp;

  MyItemsRefreshState({
    required this.event,
    this.status,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  MyItemsRefreshState copyWith({
    MyItemsRefreshEvent? event,
    String? status,
  }) {
    return MyItemsRefreshState(
      event: event ?? this.event,
      status: status ?? this.status,
    );
  }
}

/// A centralized cubit for broadcasting refresh events to all My Items tab screens.
/// 
/// This replaces the global `myAdsCubitReference` Map pattern with a proper
/// event-driven approach. Instead of keeping direct references to cubits,
/// screens listen to this cubit for refresh signals.
/// 
/// Usage:
/// ```dart
/// // In ad_details_screen.dart after a successful renew:
/// context.read<MyItemsRefreshCubit>().refreshItemsWithStatus(widget.tabStatus);
/// 
/// // In my_item_tab_screen.dart:
/// BlocListener<MyItemsRefreshCubit, MyItemsRefreshState>(
///   listener: (context, state) {
///     if (state.status == widget.getItemsWithStatus) {
///       context.read<FetchMyItemsCubit>().fetchMyItems(
///         getItemsWithStatus: widget.getItemsWithStatus,
///       );
///     }
///   },
///   child: ...
/// )
/// ```
class MyItemsRefreshCubit extends Cubit<MyItemsRefreshState?> {
  MyItemsRefreshCubit() : super(null);

  /// Triggers a refresh for items with a specific status
  void refreshItemsWithStatus(String? status) {
    emit(MyItemsRefreshState(
      event: MyItemsRefreshEvent.refreshWithStatus,
      status: status,
    ));
  }

  /// Triggers a refresh for all item lists
  void refreshAll() {
    emit(MyItemsRefreshState(
      event: MyItemsRefreshEvent.refreshAll,
    ));
  }

  /// Clear the current state (call after handling the event)
  void clearEvent() {
    emit(null);
  }
}

