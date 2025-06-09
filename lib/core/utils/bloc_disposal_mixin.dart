// File: lib/core/mixins/bloc_disposal_mixin.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Mixin untuk mengelola lifecycle Bloc secara otomatis
/// Gunakan mixin ini pada StatefulWidget untuk mencegah memory leaks dari Bloc
mixin BlocDisposalMixin<T extends StatefulWidget> on State<T> {
  final List<BlocBase> _blocs = [];
  final List<Cubit> _cubits = [];

  /// Register Bloc untuk auto-disposal
  B registerBloc<B extends BlocBase>(B bloc) {
    _blocs.add(bloc);
    return bloc;
  }

  /// Register Cubit untuk auto-disposal
  C registerCubit<C extends Cubit>(C cubit) {
    _cubits.add(cubit);
    return cubit;
  }

  /// Manual disposal untuk bloc tertentu
  void disposeBloc(BlocBase bloc) {
    if (_blocs.contains(bloc)) {
      _blocs.remove(bloc);
      bloc.close();
    }
  }

  /// Manual disposal untuk cubit tertentu
  void disposeCubit(Cubit cubit) {
    if (_cubits.contains(cubit)) {
      _cubits.remove(cubit);
      cubit.close();
    }
  }

  @override
  void dispose() {
    // Dispose all registered blocs
    for (final bloc in _blocs) {
      if (!bloc.isClosed) {
        bloc.close();
      }
    }
    _blocs.clear();

    // Dispose all registered cubits
    for (final cubit in _cubits) {
      if (!cubit.isClosed) {
        cubit.close();
      }
    }
    _cubits.clear();

    super.dispose();
  }
}
