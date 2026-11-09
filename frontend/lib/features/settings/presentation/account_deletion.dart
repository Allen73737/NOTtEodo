import 'package:flutter/material.dart';

import '../../../core/editorial/editorial_kit.dart';
import '../../../core/services/cloud_sync_service.dart';
import '../../../core/services/sanctuary_supabase_service.dart';
import '../../../core/widgets/app_toast_engine.dart';

/// Asks the user to type DELETE, then permanently deletes their account and all cloud
/// data (synced items, uploaded photos and voice notes, feedback). What is on this
/// phone stays until they erase it separately. Required for store listing (Google Play)
/// and by privacy law.
Future<void> confirmAndDeleteAccount(BuildContext context, {VoidCallback? onDeleted}) async {
  final cloud = SanctuarySupabaseService();
  if (cloud.currentUser == null) {
    AppToastEngine().notify(title: 'Not signed in', message: 'There is no account to delete. Your data is only on this phone.');
    return;
  }
  final typed = await showEditorialPrompt(
    context,
    title: 'Delete your account?',
    hint: 'Type DELETE to confirm',
    confirmLabel: 'Delete forever',
  );
  if (typed == null) return;
  if (typed.trim() != 'DELETE') {
    AppToastEngine().notify(title: 'Not deleted', message: 'Type DELETE in capitals to confirm.', type: ToastType.alert);
    return;
  }
  try {
    await cloud.invokeFunction('delete-account', {'confirm': 'DELETE'});
    await cloud.signOut();
    CloudSyncService().resetForAccountChange();
    AppToastEngine().notify(
      title: 'Account deleted',
      message: 'Your account and cloud data are gone. Notes on this phone stay until you erase them in Privacy.',
      type: ToastType.success,
    );
    onDeleted?.call();
  } catch (e) {
    AppToastEngine().notify(
      title: 'Could not delete the account',
      message: 'Check your connection and try again. Nothing was removed.',
      type: ToastType.alert,
    );
  }
}
