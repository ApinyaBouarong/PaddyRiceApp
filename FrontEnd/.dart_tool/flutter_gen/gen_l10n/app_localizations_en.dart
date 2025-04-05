import 'app_localizations.dart';

/// The translations for English (`en`).
class SEn extends S {
  SEn([String locale = 'en']) : super(locale);

  @override
  String get my_profile => 'My Profile';

  @override
  String get account => 'Account';

  @override
  String get personal_settings => 'Personal Settings';

  @override
  String get change_password => 'Change Password';

  @override
  String get language => 'Language';

  @override
  String get log_out => 'Log Out';

  @override
  String get edit_profile => 'Edit Profile';

  @override
  String get save_changes => 'Save Changes';

  @override
  String get current_password => 'Current Password';

  @override
  String get new_password => 'New Password';

  @override
  String get confirm_new_password => 'Confirm New Password';

  @override
  String get reset => 'Reset';

  @override
  String language_changed(Object language) {
    return 'Language changed to $language.';
  }

  @override
  String get profile_updated => 'Profile updated successfully.';

  @override
  String get password_changed => 'Password Changed';

  @override
  String get fill_out_fields => 'Please fill out all fields.';

  @override
  String get passwords_do_not_match => 'Passwords do not match.';

  @override
  String get logout_confirmation => 'Are you sure you want to log out?';

  @override
  String get cancel => 'Cancel';

  @override
  String get name => 'Name';

  @override
  String get surname => 'Surname';

  @override
  String get email => 'Email';

  @override
  String get phone => 'Phone';

  @override
  String get ok => 'OK';

  @override
  String get forgot_password => 'Forgot Password?';

  @override
  String get user_not_found => 'User not found';

  @override
  String get user_not_found_prompt => 'User not found. Would you like to sign up or enter a different email?';

  @override
  String get enter_email_verification => 'Please Enter Your Email To Receive a Verification Code';

  @override
  String get field_required => 'This field is required';

  @override
  String get invalid_email_format => 'Invalid email format';

  @override
  String get send => 'Send';

  @override
  String get correct_errors => 'Please correct the errors.';

  @override
  String get save => 'Save';

  @override
  String get welcome => 'Welcome';

  @override
  String get login_description => 'Paddy Rice Drying Silo \nControl Notification';

  @override
  String get email_or_phone => 'Email or Phone number';

  @override
  String get password => 'Password';

  @override
  String get incorrect_password => 'Invalid password. Please try again.';

  @override
  String get sign_in => 'Sign in';

  @override
  String get no_account_prompt => 'Don’t have an account?';

  @override
  String get verification => 'Verification Code';

  @override
  String get verification_code_sent => 'we have sent the varification\nemail code to your email address';

  @override
  String get enter_valid_otp => 'Please enter a valid 4-digit OTP.';

  @override
  String get resend_otp => 'Resend OTP';

  @override
  String get verify => 'Verify';

  @override
  String get password_too_short => 'Password too Short';

  @override
  String get title => 'Silo';

  @override
  String get no_devices => 'No devices';

  @override
  String get bluetooth => 'Bluetooth';

  @override
  String get qr_code => 'QR Code';

  @override
  String get setting => 'Setting';

  @override
  String get delete => 'Delete';

  @override
  String get temp => 'Temp';

  @override
  String get humidity_ => 'Humidity';

  @override
  String get front => 'front';

  @override
  String get back => 'back';

  @override
  String get device_already_exists => 'Device already exists';

  @override
  String get scan => 'Scan';

  @override
  String get no_qr_code => 'No QR code available';

  @override
  String get notification => 'Notification';

  @override
  String get temp_back => 'Temp, back';

  @override
  String get temp_exceeds => 'Temp exceeds';

  @override
  String get temp_front => 'Temp, front';

  @override
  String get humidity => 'Humidity close to 12%';

  @override
  String get monitor_dryness => 'monitor for dryness';

  @override
  String get no_notifications => 'No Notification';

  @override
  String get notifications => 'Notifications';

  @override
  String get device_messages => 'Device Messages';

  @override
  String get devices => 'Devices';

  @override
  String get device_management => 'Device Management';

  @override
  String get temp_alert => 'Temperature Alert';

  @override
  String get humi_alert => 'Humidity Alert';

  @override
  String get home => 'Home';

  @override
  String get profile => 'Profile';

  @override
  String get create_new_account => 'Create New Account';

  @override
  String get phone_number => 'Phone number';

  @override
  String get confirm_password => 'Confirm Password';

  @override
  String get sign_up => 'Sign up';

  @override
  String get name_error => 'Name must be at least 2 characters long';

  @override
  String get surname_error => 'Surname must be at least 2 characters long';

  @override
  String get phone_error => 'Phone number must be 10 digits';

  @override
  String get email_error => 'Invalid email format';

  @override
  String get password_error => 'Passwords do not match';

  @override
  String get success_message => 'Registration successful. Please log in.';

  @override
  String get error_message => 'Error occurred';

  @override
  String get email_phone_exists => 'Email or phone number already exists';

  @override
  String get error => 'Error';

  @override
  String get success => 'Success';

  @override
  String get reset_password => 'Reset Password';

  @override
  String get new_password_instruction => 'Your new password must be different \nfrom any previously used passwords.';

  @override
  String get please_enter_new_password => 'Please enter a new password';

  @override
  String get please_confirm_your_password => 'Please confirm your password';

  @override
  String get password_reset_successful => 'Password reset successful (simulated).';

  @override
  String get add_device => 'Add Device';

  @override
  String get turn_on_now => 'Turn on now';

  @override
  String connected_to(Object deviceName) {
    return 'Connected to $deviceName';
  }

  @override
  String failed_to_connect(Object error) {
    return 'Failed to connect: $error';
  }

  @override
  String get connect => 'Connect';

  @override
  String get automatic_device_detection => 'Automatic device detection';

  @override
  String get keep_mobile_near_device => 'Keep your mobile near the device';

  @override
  String get turn_on_bluetooth => 'Turn on Bluetooth';

  @override
  String get start_searching_for_devices => 'Start searching for devices';

  @override
  String device_settings(Object deviceName) {
    return 'Setting for $deviceName';
  }

  @override
  String get device_name => 'Device Name';

  @override
  String get front_temperature => 'Front Temp';

  @override
  String get back_temperature => 'Back Temp';

  @override
  String get select_wifi_network => 'Select Wi-Fi network';

  @override
  String get this_device_supports => 'This device only supports 2.4GHz Wi-Fi';

  @override
  String get enter_password => 'Enter password';

  @override
  String get select_wifi_network_hint => 'Select Wi-Fi network';

  @override
  String get please_connect_wifi => 'Please Connect Wi-Fi';

  @override
  String get please_enter_password => 'Please enter the Wi-Fi password.';

  @override
  String get next => 'Next';

  @override
  String get please_enter_device_name => 'Please enter device name';

  @override
  String get please_enter_front_temp => 'Please enter front_temp';

  @override
  String get please_enter_back_temp => 'Please enter back_temp';

  @override
  String get allow_notifications => 'Allow notifications';

  @override
  String get delete_confirmation => 'Delete Confirmation';

  @override
  String get running => 'Runnig';

  @override
  String get close => 'Close';

  @override
  String get please_turn_on_bluetooth => 'Please turn on Bluetooth';

  @override
  String get bluetooth_required => 'Bluetooth is required';

  @override
  String get login_failed_prompt => 'Login failed notification';

  @override
  String get fields_cannot_be_empty => 'Fields cannot be empty';

  @override
  String get current => 'Current : ';

  @override
  String get target => 'Target : ';

  @override
  String get target_ => 'Target';

  @override
  String adjust_temp_type(Object tempType, Object value) {
    return 'Adjust $tempType ($value)';
  }

  @override
  String get change_language => 'Change language';

  @override
  String get profile_update_success => 'Profile updated successfully';

  @override
  String get profile_update_failed => 'Failed to update profile';

  @override
  String get password_changed_success => 'Your password has been changed successfully';

  @override
  String get error_current_password => 'Please fill out current password';

  @override
  String get error_new_password => 'Please fill out new password';

  @override
  String get error_confirm_password => 'Please confirm new password';

  @override
  String get error_passwords_do_not_match => 'New passwords do not match';

  @override
  String get error_incorrect_password => 'Current password is incorrect';

  @override
  String get request_timeout => 'Request timeout';

  @override
  String get something_went_wrong => 'Something went wrong';

  @override
  String time_left_to_resend(Object time) {
    return 'Resend in $time';
  }

  @override
  String get update => 'Update';

  @override
  String get otp_sent_successfully => 'OTP sent successfully';

  @override
  String get otp_send_failed => 'OTP send failed';

  @override
  String get failed_update_target => 'Failed to update target values';

  @override
  String get updated_Successfully => 'Updated Successfully';
}
