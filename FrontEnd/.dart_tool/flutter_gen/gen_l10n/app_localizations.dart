import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_th.dart';

/// Callers can lookup localized strings with an instance of S
/// returned by `S.of(context)`.
///
/// Applications need to include `S.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen_l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: S.localizationsDelegates,
///   supportedLocales: S.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the S.supportedLocales
/// property.
abstract class S {
  S(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static S? of(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  static const LocalizationsDelegate<S> delegate = _SDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('th')
  ];

  /// No description provided for @my_profile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get my_profile;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @personal_settings.
  ///
  /// In en, this message translates to:
  /// **'Personal Settings'**
  String get personal_settings;

  /// No description provided for @change_password.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get change_password;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @log_out.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get log_out;

  /// No description provided for @edit_profile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get edit_profile;

  /// No description provided for @save_changes.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get save_changes;

  /// No description provided for @current_password.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get current_password;

  /// No description provided for @new_password.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get new_password;

  /// No description provided for @confirm_new_password.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirm_new_password;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @language_changed.
  ///
  /// In en, this message translates to:
  /// **'Language changed to {language}.'**
  String language_changed(Object language);

  /// No description provided for @profile_updated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully.'**
  String get profile_updated;

  /// No description provided for @password_changed.
  ///
  /// In en, this message translates to:
  /// **'Password Changed'**
  String get password_changed;

  /// No description provided for @fill_out_fields.
  ///
  /// In en, this message translates to:
  /// **'Please fill out all fields.'**
  String get fill_out_fields;

  /// No description provided for @passwords_do_not_match.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get passwords_do_not_match;

  /// No description provided for @logout_confirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get logout_confirmation;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @surname.
  ///
  /// In en, this message translates to:
  /// **'Surname'**
  String get surname;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @forgot_password.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgot_password;

  /// No description provided for @user_not_found.
  ///
  /// In en, this message translates to:
  /// **'User not found'**
  String get user_not_found;

  /// No description provided for @user_not_found_prompt.
  ///
  /// In en, this message translates to:
  /// **'User not found. Would you like to sign up or enter a different email?'**
  String get user_not_found_prompt;

  /// No description provided for @enter_email_verification.
  ///
  /// In en, this message translates to:
  /// **'Please Enter Your Email To Receive a Verification Code'**
  String get enter_email_verification;

  /// No description provided for @field_required.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get field_required;

  /// No description provided for @invalid_email_format.
  ///
  /// In en, this message translates to:
  /// **'Invalid email format'**
  String get invalid_email_format;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @correct_errors.
  ///
  /// In en, this message translates to:
  /// **'Please correct the errors.'**
  String get correct_errors;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @login_description.
  ///
  /// In en, this message translates to:
  /// **'Paddy Rice Drying Silo \nControl Notification'**
  String get login_description;

  /// No description provided for @email_or_phone.
  ///
  /// In en, this message translates to:
  /// **'Email or Phone number'**
  String get email_or_phone;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @incorrect_password.
  ///
  /// In en, this message translates to:
  /// **'Invalid password. Please try again.'**
  String get incorrect_password;

  /// No description provided for @sign_in.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get sign_in;

  /// No description provided for @no_account_prompt.
  ///
  /// In en, this message translates to:
  /// **'Don’t have an account?'**
  String get no_account_prompt;

  /// No description provided for @verification.
  ///
  /// In en, this message translates to:
  /// **'Verification Code'**
  String get verification;

  /// No description provided for @verification_code_sent.
  ///
  /// In en, this message translates to:
  /// **'we have sent the varification\nemail code to your email address'**
  String get verification_code_sent;

  /// No description provided for @enter_valid_otp.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid 4-digit OTP.'**
  String get enter_valid_otp;

  /// No description provided for @resend_otp.
  ///
  /// In en, this message translates to:
  /// **'Resend OTP'**
  String get resend_otp;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @password_too_short.
  ///
  /// In en, this message translates to:
  /// **'Password too Short'**
  String get password_too_short;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Silo'**
  String get title;

  /// No description provided for @no_devices.
  ///
  /// In en, this message translates to:
  /// **'No devices'**
  String get no_devices;

  /// No description provided for @bluetooth.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth'**
  String get bluetooth;

  /// No description provided for @qr_code.
  ///
  /// In en, this message translates to:
  /// **'QR Code'**
  String get qr_code;

  /// No description provided for @setting.
  ///
  /// In en, this message translates to:
  /// **'Setting'**
  String get setting;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @temp.
  ///
  /// In en, this message translates to:
  /// **'Temp'**
  String get temp;

  /// No description provided for @humidity_.
  ///
  /// In en, this message translates to:
  /// **'Humidity'**
  String get humidity_;

  /// No description provided for @front.
  ///
  /// In en, this message translates to:
  /// **'front'**
  String get front;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'back'**
  String get back;

  /// No description provided for @device_already_exists.
  ///
  /// In en, this message translates to:
  /// **'Device already exists'**
  String get device_already_exists;

  /// No description provided for @scan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get scan;

  /// No description provided for @no_qr_code.
  ///
  /// In en, this message translates to:
  /// **'No QR code available'**
  String get no_qr_code;

  /// No description provided for @notification.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get notification;

  /// No description provided for @temp_back.
  ///
  /// In en, this message translates to:
  /// **'Temp, back'**
  String get temp_back;

  /// No description provided for @temp_exceeds.
  ///
  /// In en, this message translates to:
  /// **'Temp exceeds'**
  String get temp_exceeds;

  /// No description provided for @temp_front.
  ///
  /// In en, this message translates to:
  /// **'Temp, front'**
  String get temp_front;

  /// No description provided for @humidity.
  ///
  /// In en, this message translates to:
  /// **'Humidity close to 12%'**
  String get humidity;

  /// No description provided for @monitor_dryness.
  ///
  /// In en, this message translates to:
  /// **'monitor for dryness'**
  String get monitor_dryness;

  /// No description provided for @no_notifications.
  ///
  /// In en, this message translates to:
  /// **'No Notification'**
  String get no_notifications;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @device_messages.
  ///
  /// In en, this message translates to:
  /// **'Device Messages'**
  String get device_messages;

  /// No description provided for @devices.
  ///
  /// In en, this message translates to:
  /// **'Devices'**
  String get devices;

  /// No description provided for @device_management.
  ///
  /// In en, this message translates to:
  /// **'Device Management'**
  String get device_management;

  /// No description provided for @temp_alert.
  ///
  /// In en, this message translates to:
  /// **'Temperature Alert'**
  String get temp_alert;

  /// No description provided for @humi_alert.
  ///
  /// In en, this message translates to:
  /// **'Humidity Alert'**
  String get humi_alert;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @create_new_account.
  ///
  /// In en, this message translates to:
  /// **'Create New Account'**
  String get create_new_account;

  /// No description provided for @phone_number.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phone_number;

  /// No description provided for @confirm_password.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirm_password;

  /// No description provided for @sign_up.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get sign_up;

  /// No description provided for @name_error.
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 2 characters long'**
  String get name_error;

  /// No description provided for @surname_error.
  ///
  /// In en, this message translates to:
  /// **'Surname must be at least 2 characters long'**
  String get surname_error;

  /// No description provided for @phone_error.
  ///
  /// In en, this message translates to:
  /// **'Phone number must be 10 digits'**
  String get phone_error;

  /// No description provided for @email_error.
  ///
  /// In en, this message translates to:
  /// **'Invalid email format'**
  String get email_error;

  /// No description provided for @password_error.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get password_error;

  /// No description provided for @success_message.
  ///
  /// In en, this message translates to:
  /// **'Registration successful. Please log in.'**
  String get success_message;

  /// No description provided for @error_message.
  ///
  /// In en, this message translates to:
  /// **'Error occurred'**
  String get error_message;

  /// No description provided for @email_phone_exists.
  ///
  /// In en, this message translates to:
  /// **'Email or phone number already exists'**
  String get email_phone_exists;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @reset_password.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get reset_password;

  /// No description provided for @new_password_instruction.
  ///
  /// In en, this message translates to:
  /// **'Your new password must be different \nfrom any previously used passwords.'**
  String get new_password_instruction;

  /// No description provided for @please_enter_new_password.
  ///
  /// In en, this message translates to:
  /// **'Please enter a new password'**
  String get please_enter_new_password;

  /// No description provided for @please_confirm_your_password.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get please_confirm_your_password;

  /// No description provided for @password_reset_successful.
  ///
  /// In en, this message translates to:
  /// **'Password reset successful (simulated).'**
  String get password_reset_successful;

  /// No description provided for @add_device.
  ///
  /// In en, this message translates to:
  /// **'Add Device'**
  String get add_device;

  /// No description provided for @turn_on_now.
  ///
  /// In en, this message translates to:
  /// **'Turn on now'**
  String get turn_on_now;

  /// No description provided for @connected_to.
  ///
  /// In en, this message translates to:
  /// **'Connected to {deviceName}'**
  String connected_to(Object deviceName);

  /// No description provided for @failed_to_connect.
  ///
  /// In en, this message translates to:
  /// **'Failed to connect: {error}'**
  String failed_to_connect(Object error);

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @automatic_device_detection.
  ///
  /// In en, this message translates to:
  /// **'Automatic device detection'**
  String get automatic_device_detection;

  /// No description provided for @keep_mobile_near_device.
  ///
  /// In en, this message translates to:
  /// **'Keep your mobile near the device'**
  String get keep_mobile_near_device;

  /// No description provided for @turn_on_bluetooth.
  ///
  /// In en, this message translates to:
  /// **'Turn on Bluetooth'**
  String get turn_on_bluetooth;

  /// No description provided for @start_searching_for_devices.
  ///
  /// In en, this message translates to:
  /// **'Start searching for devices'**
  String get start_searching_for_devices;

  /// No description provided for @device_settings.
  ///
  /// In en, this message translates to:
  /// **'Setting for {deviceName}'**
  String device_settings(Object deviceName);

  /// No description provided for @device_name.
  ///
  /// In en, this message translates to:
  /// **'Device Name'**
  String get device_name;

  /// No description provided for @front_temperature.
  ///
  /// In en, this message translates to:
  /// **'Front Temp'**
  String get front_temperature;

  /// No description provided for @back_temperature.
  ///
  /// In en, this message translates to:
  /// **'Back Temp'**
  String get back_temperature;

  /// No description provided for @select_wifi_network.
  ///
  /// In en, this message translates to:
  /// **'Select Wi-Fi network'**
  String get select_wifi_network;

  /// No description provided for @this_device_supports.
  ///
  /// In en, this message translates to:
  /// **'This device only supports 2.4GHz Wi-Fi'**
  String get this_device_supports;

  /// No description provided for @enter_password.
  ///
  /// In en, this message translates to:
  /// **'Enter password'**
  String get enter_password;

  /// No description provided for @select_wifi_network_hint.
  ///
  /// In en, this message translates to:
  /// **'Select Wi-Fi network'**
  String get select_wifi_network_hint;

  /// No description provided for @please_connect_wifi.
  ///
  /// In en, this message translates to:
  /// **'Please Connect Wi-Fi'**
  String get please_connect_wifi;

  /// No description provided for @please_enter_password.
  ///
  /// In en, this message translates to:
  /// **'Please enter the Wi-Fi password.'**
  String get please_enter_password;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @please_enter_device_name.
  ///
  /// In en, this message translates to:
  /// **'Please enter device name'**
  String get please_enter_device_name;

  /// No description provided for @please_enter_front_temp.
  ///
  /// In en, this message translates to:
  /// **'Please enter front_temp'**
  String get please_enter_front_temp;

  /// No description provided for @please_enter_back_temp.
  ///
  /// In en, this message translates to:
  /// **'Please enter back_temp'**
  String get please_enter_back_temp;

  /// No description provided for @allow_notifications.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications'**
  String get allow_notifications;

  /// No description provided for @delete_confirmation.
  ///
  /// In en, this message translates to:
  /// **'Delete Confirmation'**
  String get delete_confirmation;

  /// No description provided for @running.
  ///
  /// In en, this message translates to:
  /// **'Runnig'**
  String get running;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @please_turn_on_bluetooth.
  ///
  /// In en, this message translates to:
  /// **'Please turn on Bluetooth'**
  String get please_turn_on_bluetooth;

  /// No description provided for @bluetooth_required.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth is required'**
  String get bluetooth_required;

  /// No description provided for @login_failed_prompt.
  ///
  /// In en, this message translates to:
  /// **'Login failed notification'**
  String get login_failed_prompt;

  /// No description provided for @fields_cannot_be_empty.
  ///
  /// In en, this message translates to:
  /// **'Fields cannot be empty'**
  String get fields_cannot_be_empty;

  /// No description provided for @current.
  ///
  /// In en, this message translates to:
  /// **'Current : '**
  String get current;

  /// No description provided for @target.
  ///
  /// In en, this message translates to:
  /// **'Target : '**
  String get target;

  /// No description provided for @target_.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get target_;

  /// No description provided for @adjust_temp_type.
  ///
  /// In en, this message translates to:
  /// **'Adjust {tempType} ({value})'**
  String adjust_temp_type(Object tempType, Object value);

  /// No description provided for @change_language.
  ///
  /// In en, this message translates to:
  /// **'Change language'**
  String get change_language;

  /// No description provided for @profile_update_success.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profile_update_success;

  /// No description provided for @profile_update_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update profile'**
  String get profile_update_failed;

  /// No description provided for @password_changed_success.
  ///
  /// In en, this message translates to:
  /// **'Your password has been changed successfully'**
  String get password_changed_success;

  /// No description provided for @error_current_password.
  ///
  /// In en, this message translates to:
  /// **'Please fill out current password'**
  String get error_current_password;

  /// No description provided for @error_new_password.
  ///
  /// In en, this message translates to:
  /// **'Please fill out new password'**
  String get error_new_password;

  /// No description provided for @error_confirm_password.
  ///
  /// In en, this message translates to:
  /// **'Please confirm new password'**
  String get error_confirm_password;

  /// No description provided for @error_passwords_do_not_match.
  ///
  /// In en, this message translates to:
  /// **'New passwords do not match'**
  String get error_passwords_do_not_match;

  /// No description provided for @error_incorrect_password.
  ///
  /// In en, this message translates to:
  /// **'Current password is incorrect'**
  String get error_incorrect_password;

  /// No description provided for @request_timeout.
  ///
  /// In en, this message translates to:
  /// **'Request timeout'**
  String get request_timeout;

  /// No description provided for @something_went_wrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get something_went_wrong;

  /// No description provided for @time_left_to_resend.
  ///
  /// In en, this message translates to:
  /// **'Resend in {time}'**
  String time_left_to_resend(Object time);

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @otp_sent_successfully.
  ///
  /// In en, this message translates to:
  /// **'OTP sent successfully'**
  String get otp_sent_successfully;

  /// No description provided for @otp_send_failed.
  ///
  /// In en, this message translates to:
  /// **'OTP send failed'**
  String get otp_send_failed;

  /// No description provided for @failed_update_target.
  ///
  /// In en, this message translates to:
  /// **'Failed to update target values'**
  String get failed_update_target;

  /// No description provided for @updated_Successfully.
  ///
  /// In en, this message translates to:
  /// **'Updated Successfully'**
  String get updated_Successfully;
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  Future<S> load(Locale locale) {
    return SynchronousFuture<S>(lookupS(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'th'].contains(locale.languageCode);

  @override
  bool shouldReload(_SDelegate old) => false;
}

S lookupS(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return SEn();
    case 'th': return STh();
  }

  throw FlutterError(
    'S.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
