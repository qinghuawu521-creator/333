class AppConstants {
  static const String appName = 'Personal Vault';
  static const String appVersion = '1.0.0';
  static const String dbName = 'personal_vault.db';
  static const int dbVersion = 1;

  // Entry types
  static const String typeText = 'text';
  static const String typePassword = 'password';
  static const String typeImage = 'image';
  static const String typeFile = 'file';
  static const String typeLink = 'link';

  // Supported file extensions
  static const List<String> imageExtensions = ['jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp'];
  static const List<String> documentExtensions = ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt', 'csv'];
  static const List<String> archiveExtensions = ['zip', 'rar', '7z', 'tar', 'gz'];

  // Backup
  static const String backupPrefix = 'vault_backup_';
  static const String backupExtension = '.zip';

  // Security
  static const int maxLoginAttempts = 5;
  static const int lockoutDurationMinutes = 5;
  static const String masterPasswordKey = 'master_password_hash';
  static const String biometricEnabledKey = 'biometric_enabled';
  static const String themeModeKey = 'theme_mode';
  static const String encryptionKeyKey = 'encryption_key';
}

class AppIcons {
  static const String category = 'assets/icons/category.svg';
  static const String entry = 'assets/icons/entry.svg';
  static const String password = 'assets/icons/password.svg';
  static const String template = 'assets/icons/template.svg';
  static const String tag = 'assets/icons/tag.svg';
  static const String search = 'assets/icons/search.svg';
  static const String settings = 'assets/icons/settings.svg';
  static const String backup = 'assets/icons/backup.svg';
  static const String lock = 'assets/icons/lock.svg';
  static const String unlock = 'assets/icons/unlock.svg';
  static const String star = 'assets/icons/star.svg';
  static const String starFilled = 'assets/icons/star_filled.svg';
  static const String pin = 'assets/icons/pin.svg';
  static const String export = 'assets/icons/export.svg';
  static const String import = 'assets/icons/import.svg';
  static const String add = 'assets/icons/add.svg';
  static const String edit = 'assets/icons/edit.svg';
  static const String delete = 'assets/icons/delete.svg';
  static const String copy = 'assets/icons/copy.svg';
  static const String folder = 'assets/icons/folder.svg';
  static const String file = 'assets/icons/file.svg';
  static const String image = 'assets/icons/image.svg';
  static const String link = 'assets/icons/link.svg';
  static const String text = 'assets/icons/text.svg';
  static const String eye = 'assets/icons/eye.svg';
  static const String eyeOff = 'assets/icons/eye_off.svg';
  static const String check = 'assets/icons/check.svg';
  static const String close = 'assets/icons/close.svg';
  static const String menu = 'assets/icons/menu.svg';
  static const String back = 'assets/icons/back.svg';
  static const String sort = 'assets/icons/sort.svg';
  static const String filter = 'assets/icons/filter.svg';
  static const String more = 'assets/icons/more.svg';
  static const String calendar = 'assets/icons/calendar.svg';
  static const String clock = 'assets/icons/clock.svg';
  static const String tagIcon = 'assets/icons/tag.svg';
  static const String warning = 'assets/icons/warning.svg';
  static const String info = 'assets/icons/info.svg';
  static const String success = 'assets/icons/success.svg';
  static const String error = 'assets/icons/error.svg';
}
