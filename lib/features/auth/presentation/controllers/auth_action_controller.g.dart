// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_action_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AuthActionController)
const authActionControllerProvider = AuthActionControllerProvider._();

final class AuthActionControllerProvider
    extends $AsyncNotifierProvider<AuthActionController, void> {
  const AuthActionControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authActionControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authActionControllerHash();

  @$internal
  @override
  AuthActionController create() => AuthActionController();
}

String _$authActionControllerHash() =>
    r'ae45cb9be1e6236038404f0ecc7aaeabb1dfcb45';

abstract class _$AuthActionController extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    build();
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleValue(ref, null);
  }
}
