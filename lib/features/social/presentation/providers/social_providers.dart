import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/firebase/firebase_bootstrap.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/chat_participant.dart';
import '../../domain/entities/interest_chat_room.dart';
import '../../data/datasources/social_remote_data_source.dart';
import '../../data/repositories/social_repository_impl.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/friend_profile.dart';
import '../../domain/entities/friend_request.dart';
import '../../domain/entities/leaderboard_user.dart';
import '../../domain/entities/social_privacy.dart';
import '../../domain/usecases/ensure_leaderboard_entry_use_case.dart';
import '../../domain/usecases/listen_leaderboard_use_case.dart';
import '../../domain/usecases/listen_messages_use_case.dart';
import '../../domain/usecases/send_message_use_case.dart';
import '../../domain/usecases/update_leaderboard_steps_use_case.dart';

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

final updateLeaderboardStepsUseCaseProvider = Provider(
  (ref) => UpdateLeaderboardStepsUseCase(ref.watch(socialRepositoryProvider)),
);

final interestChatsProvider =
    StreamProvider.autoDispose<List<InterestChatRoom>>((ref) {
      return ref
          .watch(socialRepositoryProvider)
          .listenInterestChats(limit: 100);
    });

final interestChatProvider = StreamProvider.autoDispose
    .family<InterestChatRoom?, String>((ref, chatId) {
      return ref.watch(socialRepositoryProvider).watchInterestChat(chatId);
    });

final chatMessagesProvider = StreamProvider.autoDispose
    .family<List<ChatMessage>, String>((ref, chatId) {
      return ref.watch(listenMessagesUseCaseProvider).call(chatId: chatId);
    });

final chatParticipantsProvider = StreamProvider.autoDispose
    .family<List<ChatParticipant>, String>((ref, chatId) {
      return ref.watch(socialRepositoryProvider).listenParticipants(chatId);
    });

final currentChatParticipantProvider = StreamProvider.autoDispose
    .family<ChatParticipant?, String>((ref, chatId) {
      final currentUser = ref.watch(firebaseAuthProvider).currentUser;
      if (currentUser == null) {
        return Stream<ChatParticipant?>.value(null);
      }

      return ref
          .watch(socialRepositoryProvider)
          .watchParticipant(chatId: chatId, userId: currentUser.uid);
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

  yield* ref.watch(listenLeaderboardUseCaseProvider).call(limit: 100);
});

final friendsProvider = StreamProvider.autoDispose<List<FriendProfile>>((ref) {
  final currentUser = ref.watch(firebaseAuthProvider).currentUser;
  if (currentUser == null) {
    return Stream<List<FriendProfile>>.value(const <FriendProfile>[]);
  }

  return ref.watch(socialRepositoryProvider).listenFriends(currentUser.uid);
});

final incomingFriendRequestsProvider =
    StreamProvider.autoDispose<List<FriendRequest>>((ref) {
      final currentUser = ref.watch(firebaseAuthProvider).currentUser;
      if (currentUser == null) {
        return Stream<List<FriendRequest>>.value(const <FriendRequest>[]);
      }

      return ref
          .watch(socialRepositoryProvider)
          .listenIncomingFriendRequests(currentUser.uid);
    });

final socialPrivacySettingsProvider =
    StreamProvider.autoDispose<SocialPrivacySettings>((ref) {
      final currentUser = ref.watch(firebaseAuthProvider).currentUser;
      if (currentUser == null) {
        return Stream<SocialPrivacySettings>.value(
          SocialPrivacySettings.defaults(),
        );
      }

      return ref
          .watch(socialRepositoryProvider)
          .watchPrivacySettings(currentUser.uid);
    });
