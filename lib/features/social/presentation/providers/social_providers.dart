import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/firebase/firebase_bootstrap.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/social_remote_data_source.dart';
import '../../data/repositories/social_repository_impl.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/leaderboard_user.dart';
import '../../domain/usecases/ensure_leaderboard_entry_use_case.dart';
import '../../domain/usecases/listen_leaderboard_use_case.dart';
import '../../domain/usecases/listen_messages_use_case.dart';
import '../../domain/usecases/send_message_use_case.dart';

final socialRemoteDataSourceProvider = Provider<SocialRemoteDataSource>((ref) {
  final firebaseBootstrap = ref.watch(firebaseBootstrapProvider);
  if (!firebaseBootstrap.isConfigured) {
    return const UnavailableSocialRemoteDataSource();
  }

  return FirestoreSocialRemoteDataSource(
    firestore: ref.watch(firebaseFirestoreProvider),
  );
});

final socialRepositoryProvider = Provider(
  (ref) => SocialRepositoryImpl(
    remoteDataSource: ref.watch(socialRemoteDataSourceProvider),
  ),
);

final sendMessageUseCaseProvider = Provider(
  (ref) => SendMessageUseCase(ref.watch(socialRepositoryProvider)),
);

final listenMessagesUseCaseProvider = Provider(
  (ref) => ListenMessagesUseCase(ref.watch(socialRepositoryProvider)),
);

final listenLeaderboardUseCaseProvider = Provider(
  (ref) => ListenLeaderboardUseCase(ref.watch(socialRepositoryProvider)),
);

final ensureLeaderboardEntryUseCaseProvider = Provider(
  (ref) => EnsureLeaderboardEntryUseCase(ref.watch(socialRepositoryProvider)),
);

final chatMessagesProvider = StreamProvider.autoDispose<List<ChatMessage>>((
  ref,
) {
  return ref.watch(listenMessagesUseCaseProvider).call();
});

final leaderboardProvider = StreamProvider.autoDispose<List<LeaderboardUser>>((
  ref,
) async* {
  final currentUser = ref.watch(firebaseAuthProvider).currentUser;
  if (currentUser != null) {
    final email = currentUser.email ?? '';
    await ref
        .watch(ensureLeaderboardEntryUseCaseProvider)
        .call(
          userId: currentUser.uid,
          fallbackName: currentUser.displayName ?? email.split('@').first,
          fallbackEmail: email,
        );
  }

  yield* ref.watch(listenLeaderboardUseCaseProvider).call();
});
