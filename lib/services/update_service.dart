import 'package:in_app_update/in_app_update.dart';

/// Releases published with this "in-app update priority" (0-5, set per
/// release in Play Console → Release details) or higher are treated as
/// mandatory: the user is blocked behind Play's full-screen update flow
/// until they update. Anything lower gets a dismissible "update ready,
/// restart when you like" prompt instead.
///
/// This means shipping a forced update later is just a Play Console
/// setting on that release - no app code change needed.
const int kForcedUpdatePriority = 4;

enum UpdateAction { none, forced, optional }

class UpdateCheckResult {
  final UpdateAction action;
  final AppUpdateInfo? info;
  const UpdateCheckResult(this.action, this.info);
}

/// Thin wrapper around the `in_app_update` plugin (Google's official Play
/// Core in-app update API). Every call is defensive: this API only works
/// when the app was installed from Google Play, so it fails on debug/
/// sideloaded builds - callers don't need to special-case that themselves.
class UpdateService {
  static Future<UpdateCheckResult> checkForUpdate() async {
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability != UpdateAvailability.updateAvailable) {
        return const UpdateCheckResult(UpdateAction.none, null);
      }
      final isForced =
          info.updatePriority >= kForcedUpdatePriority && info.immediateUpdateAllowed;
      return UpdateCheckResult(
        isForced ? UpdateAction.forced : UpdateAction.optional,
        info,
      );
    } catch (_) {
      return const UpdateCheckResult(UpdateAction.none, null);
    }
  }

  /// Shows Play's own full-screen, blocking update UI. The user can't reach
  /// the app again until they update (or Play gives up, e.g. on very old
  /// OS versions where immediate updates aren't supported).
  static Future<void> performImmediateUpdate() async {
    try {
      await InAppUpdate.performImmediateUpdate();
    } catch (_) {
      // Interrupted or unsupported - the next resume/launch asks again.
    }
  }

  /// Starts a background download. Resolves true once it's finished and
  /// ready to install.
  static Future<bool> startFlexibleUpdate() async {
    try {
      await InAppUpdate.startFlexibleUpdate();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Installs the already-downloaded flexible update and restarts the app.
  static Future<void> completeFlexibleUpdate() async {
    try {
      await InAppUpdate.completeFlexibleUpdate();
    } catch (_) {}
  }
}
