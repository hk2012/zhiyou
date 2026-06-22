import 'package:flutter/widgets.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../l10n/generated/app_localizations_zh.dart';

extension AppLocalizationsContext on BuildContext {
  AppLocalizations get l10n =>
      Localizations.of<AppLocalizations>(this, AppLocalizations) ??
      AppLocalizationsZh();
}
