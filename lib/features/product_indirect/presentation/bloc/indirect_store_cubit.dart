import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/datasources/store_remote_data_source.dart';
import '../../data/models/store_model.dart';

// States
abstract class IndirectStoreState extends Equatable {
  const IndirectStoreState();

  @override
  List<Object?> get props => [];
}

class IndirectStoreInitial extends IndirectStoreState {}

class IndirectStoreLoading extends IndirectStoreState {}

class IndirectStoreLoaded extends IndirectStoreState {
  final List<StoreModel> stores;
  final StoreModel? selectedStore;

  const IndirectStoreLoaded({
    required this.stores,
    this.selectedStore,
  });

  @override
  List<Object?> get props => [stores, selectedStore];

  IndirectStoreLoaded copyWith({
    List<StoreModel>? stores,
    StoreModel? selectedStore,
    bool clearSelectedStore = false,
  }) {
    return IndirectStoreLoaded(
      stores: stores ?? this.stores,
      selectedStore:
          clearSelectedStore ? null : (selectedStore ?? this.selectedStore),
    );
  }
}

class IndirectStoreError extends IndirectStoreState {
  final String message;

  const IndirectStoreError(this.message);

  @override
  List<Object?> get props => [message];
}

// Cubit
class IndirectStoreCubit extends Cubit<IndirectStoreState> {
  final StoreRemoteDataSource _storeDataSource;

  IndirectStoreCubit({StoreRemoteDataSource? storeDataSource})
      : _storeDataSource = storeDataSource ?? StoreRemoteDataSourceImpl(),
        super(IndirectStoreInitial());

  /// Fetch stores berdasarkan sales_code (address_number user dari login)
  Future<void> fetchStoresBySalesCode({required String salesCode}) async {
    if (salesCode.isEmpty) {
      emit(const IndirectStoreError('Sales code tidak tersedia'));
      return;
    }

    emit(IndirectStoreLoading());

    try {
      final stores = await _storeDataSource.fetchStoresBySalesCode(
        salesCode: salesCode,
      );

      emit(IndirectStoreLoaded(stores: stores));
    } catch (e) {
      emit(IndirectStoreError(e.toString()));
    }
  }

  /// Select a store - auto-detect brand dari alpha_name
  void selectStore(StoreModel? store) {
    final currentState = state;
    if (currentState is IndirectStoreLoaded) {
      emit(currentState.copyWith(selectedStore: store));
    }
  }

  /// Clear selected store (tanpa clear list stores)
  void clearSelectedStore() {
    final currentState = state;
    if (currentState is IndirectStoreLoaded) {
      emit(currentState.copyWith(clearSelectedStore: true));
    }
  }

  /// Clear semua stores
  void clearStores() {
    emit(IndirectStoreInitial());
  }

  /// Reset state
  void reset() {
    emit(IndirectStoreInitial());
  }
}
