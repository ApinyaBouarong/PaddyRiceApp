import 'app_localizations.dart';

/// The translations for Thai (`th`).
class STh extends S {
  STh([String locale = 'th']) : super(locale);

  @override
  String get my_profile => 'โปรไฟล์ของฉัน';

  @override
  String get account => 'บัญชี';

  @override
  String get personal_settings => 'การตั้งค่าส่วนตัว';

  @override
  String get change_password => 'เปลี่ยนรหัสผ่าน';

  @override
  String get language => 'ภาษา';

  @override
  String get log_out => 'ออกจากระบบ';

  @override
  String get edit_profile => 'แก้ไขโปรไฟล์';

  @override
  String get save_changes => 'บันทึกการเปลี่ยนแปลง';

  @override
  String get current_password => 'รหัสผ่านปัจจุบัน';

  @override
  String get new_password => 'รหัสผ่านใหม่';

  @override
  String get confirm_new_password => 'ยืนยันรหัสผ่านใหม่';

  @override
  String get reset => 'รีเซ็ต';

  @override
  String language_changed(Object language) {
    return 'เปลี่ยนภาษาเป็น $language แล้ว.';
  }

  @override
  String get profile_updated => 'อัปเดตโปรไฟล์เรียบร้อยแล้ว.';

  @override
  String get password_changed => 'เปลี่ยนรหัสผ่านแล้ว';

  @override
  String get fill_out_fields => 'กรุณากรอกข้อมูลในทุกช่อง.';

  @override
  String get passwords_do_not_match => 'รหัสผ่านไม่ตรงกัน';

  @override
  String get logout_confirmation => 'คุณแน่ใจหรือไม่ว่าต้องการออกจากระบบ?';

  @override
  String get cancel => 'ยกเลิก';

  @override
  String get name => 'ชื่อ';

  @override
  String get surname => 'นามสกุล';

  @override
  String get email => 'อีเมล';

  @override
  String get phone => 'เบอร์โทรศัพท์';

  @override
  String get ok => 'ตกลง';

  @override
  String get forgot_password => 'ลืมรหัสผ่าน?';

  @override
  String get user_not_found => 'ไม่พบผู้ใช้';

  @override
  String get user_not_found_prompt => 'ไม่พบผู้ใช้นี้ คุณต้องการสมัครสมาชิกหรือป้อนอีเมลใหม่หรือไม่?';

  @override
  String get enter_email_verification => 'กรุณากรอกอีเมลของคุณเพื่อรับรหัสยืนยัน';

  @override
  String get field_required => 'กรุณากรอกข้อมูลนี้';

  @override
  String get invalid_email_format => 'รูปแบบอีเมลไม่ถูกต้อง';

  @override
  String get send => 'ส่ง';

  @override
  String get correct_errors => 'กรุณาแก้ไขข้อผิดพลาด';

  @override
  String get save => 'บันทึก';

  @override
  String get welcome => 'ยินดีต้อนรับ';

  @override
  String get login_description => 'การแจ้งเตือนการควบคุม\nไซโลอบข้าวเปลือก';

  @override
  String get email_or_phone => 'อีเมลหรือเบอร์โทรศัพท์';

  @override
  String get password => 'รหัสผ่าน';

  @override
  String get incorrect_password => 'รหัสผ่านไม่ถูกต้อง กรุณาลองใหม่อีกครั้ง';

  @override
  String get sign_in => 'เข้าสู่ระบบ';

  @override
  String get no_account_prompt => 'ยังไม่มีบัญชี?';

  @override
  String get verification => 'ยืนยันตัวตน';

  @override
  String get verification_code_sent => 'เราได้ส่งรหัสยืนยัน\nไปยังที่อยู่อีเมลของคุณแล้ว';

  @override
  String get enter_valid_otp => 'กรุณาใส่รหัส OTP 4 หลักที่ถูกต้อง';

  @override
  String get resend_otp => 'ส่งรหัส OTP อีกครั้ง';

  @override
  String get verify => 'ยืนยัน';

  @override
  String get password_too_short => 'รหัสผ่านสั้นเกินไป';

  @override
  String get title => 'ไซโล';

  @override
  String get no_devices => 'ไม่มีอุปกรณ์';

  @override
  String get bluetooth => 'บลูทูธ';

  @override
  String get qr_code => 'QR โค้ด';

  @override
  String get setting => 'ตั้งค่า';

  @override
  String get delete => 'ลบอุปกรณ์';

  @override
  String get temp => 'อุณหภูมิ';

  @override
  String get humidity_ => 'ความชื้น';

  @override
  String get front => 'ด้านหน้า';

  @override
  String get back => 'ด้านหลัง';

  @override
  String get device_already_exists => 'อุปกรณ์นี้มีอยู่แล้ว';

  @override
  String get scan => 'สแกน';

  @override
  String get no_qr_code => 'ไม่มีรหัส QR';

  @override
  String get notification => 'การแจ้งเตือน';

  @override
  String get temp_back => 'อุณหภูมิด้านหลัง';

  @override
  String get temp_exceeds => 'อุณหภูมิเกิน';

  @override
  String get temp_front => 'อุณหภูมิด้านหน้า';

  @override
  String get humidity => 'ความชื้นเกิน 12%';

  @override
  String get monitor_dryness => 'ตรวจสอบระดับความแห้ง';

  @override
  String get no_notifications => 'ไม่มีการแจ้งเตือน';

  @override
  String get notifications => 'การแจ้งเตือน';

  @override
  String get device_messages => 'ข้อความจากอุปกรณ์';

  @override
  String get devices => 'อุปกรณ์';

  @override
  String get device_management => 'จัดการอุปกรณ์';

  @override
  String get temp_alert => 'การแจ้งเตือนอุณหภูมิ';

  @override
  String get humi_alert => 'การแจ้งเตือนความชื้น';

  @override
  String get home => 'หน้าหลัก';

  @override
  String get profile => 'โปรไฟล์';

  @override
  String get create_new_account => 'สร้างบัญชีใหม่';

  @override
  String get phone_number => 'เบอร์โทรศัพท์';

  @override
  String get confirm_password => 'ยืนยันรหัสผ่าน';

  @override
  String get sign_up => 'สมัครสมาชิก';

  @override
  String get name_error => 'ชื่อควรมีอย่างน้อย 2 ตัวอักษร';

  @override
  String get surname_error => 'นามสกุลควรมีอย่างน้อย 2 ตัวอักษร';

  @override
  String get phone_error => 'เบอร์โทรศัพท์ควรมี 10 หลัก';

  @override
  String get email_error => 'รูปแบบอีเมลไม่ถูกต้อง';

  @override
  String get password_error => 'รหัสผ่านไม่ตรงกัน';

  @override
  String get success_message => 'สมัครสมาชิกสำเร็จ กรุณาเข้าสู่ระบบ.';

  @override
  String get error_message => 'เกิดข้อผิดพลาด';

  @override
  String get email_phone_exists => 'อีเมลหรือเบอร์โทรศัพท์นี้มีอยู่แล้ว';

  @override
  String get error => 'ข้อผิดพลาด';

  @override
  String get success => 'สำเร็จ';

  @override
  String get reset_password => 'รีเซ็ตรหัสผ่าน';

  @override
  String get new_password_instruction => 'รหัสผ่านใหม่ของคุณต้องไม่ซ้ำกับรหัสผ่านเก่า';

  @override
  String get please_enter_new_password => 'กรุณากรอกรหัสผ่านใหม่';

  @override
  String get please_confirm_your_password => 'กรุณายืนยันรหัสผ่านของคุณ';

  @override
  String get password_reset_successful => 'รีเซ็ตรหัสผ่านสำเร็จ (จำลอง).';

  @override
  String get add_device => 'เพิ่มอุปกรณ์';

  @override
  String get turn_on_now => 'เปิดเดี๋ยวนี้';

  @override
  String connected_to(Object deviceName) {
    return 'เชื่อมต่อกับ $deviceName';
  }

  @override
  String failed_to_connect(Object error) {
    return 'เชื่อมต่อล้มเหลว: $error';
  }

  @override
  String get connect => 'เชื่อมต่อ';

  @override
  String get automatic_device_detection => 'การตรวจจับอุปกรณ์อัตโนมัติ';

  @override
  String get keep_mobile_near_device => 'เก็บมือถือไว้ใกล้กับอุปกรณ์';

  @override
  String get turn_on_bluetooth => 'เปิดบลูทูธ';

  @override
  String get start_searching_for_devices => 'เริ่มค้นหาอุปกรณ์';

  @override
  String device_settings(Object deviceName) {
    return 'ตั้งค่าสำหรับ $deviceName';
  }

  @override
  String get device_name => 'ชื่ออุปกรณ์';

  @override
  String get front_temperature => 'อุณหภูมิด้านหน้า';

  @override
  String get back_temperature => 'อุณหภูมิด้านหลัง';

  @override
  String get select_wifi_network => 'เลือกเครือข่าย Wi-Fi';

  @override
  String get this_device_supports => 'อุปกรณ์นี้รองรับเฉพาะ Wi-Fi 2.4GHz เท่านั้น';

  @override
  String get enter_password => 'กรอกรหัสผ่าน';

  @override
  String get select_wifi_network_hint => 'เลือกเครือข่าย Wi-Fi';

  @override
  String get please_connect_wifi => 'กรุณาเชื่อมต่อ Wi-Fi';

  @override
  String get please_enter_password => 'กรุณากรอกรหัสผ่าน Wi-Fi';

  @override
  String get next => 'ถัดไป';

  @override
  String get please_enter_device_name => 'กรุณากรอกชื่ออุปกรณ์';

  @override
  String get please_enter_front_temp => 'กรุณากรอกอุณหภูมิด้านหน้า';

  @override
  String get please_enter_back_temp => 'กรุณากรอกอุณหภูมิด้านหลัง';

  @override
  String get allow_notifications => 'อนุญาตการแจ้งเตือน';

  @override
  String get delete_confirmation => 'ยืนยันการลบ';

  @override
  String get running => 'กำลังทำงาน';

  @override
  String get close => 'ปิด';

  @override
  String get please_turn_on_bluetooth => 'กรุณาเปิดบลูทูธ';

  @override
  String get bluetooth_required => 'จำเป็นต้องใช้บลูทูธ';

  @override
  String get login_failed_prompt => 'การเข้าสู่ระบบล้มเหลว';

  @override
  String get fields_cannot_be_empty => 'กรุณากรอกข้อมูลให้ครบถ้วน';

  @override
  String get current => 'ปัจจุบัน : ';

  @override
  String get target => 'เป้าหมาย : ';

  @override
  String get target_ => 'เป้าหมาย';

  @override
  String adjust_temp_type(Object tempType, Object value) {
    return 'ปรับ $tempType ($value) ';
  }

  @override
  String get change_language => 'เปลี่ยนภาษา';

  @override
  String get profile_update_success => 'อัปเดตโปรไฟล์สำเร็จแล้ว';

  @override
  String get profile_update_failed => 'ไม่สามารถอัปเดตโปรไฟล์ได้';

  @override
  String get password_changed_success => 'รหัสผ่านของคุณถูกเปลี่ยนเรียบร้อยแล้ว';

  @override
  String get error_current_password => 'กรุณากรอกรหัสผ่านปัจจุบัน';

  @override
  String get error_new_password => 'กรุณากรอกรหัสผ่านใหม่';

  @override
  String get error_confirm_password => 'กรุณายืนยันรหัสผ่านใหม่';

  @override
  String get error_passwords_do_not_match => 'รหัสผ่านใหม่ไม่ตรงกัน';

  @override
  String get error_incorrect_password => 'รหัสผ่านปัจจุบันไม่ถูกต้อง';

  @override
  String get request_timeout => 'คำขอหมดเวลา';

  @override
  String get something_went_wrong => 'มีบางอย่างผิดพลาด';

  @override
  String time_left_to_resend(Object time) {
    return 'ส่งอีกครั้ง $time';
  }

  @override
  String get update => 'อัปเดต';

  @override
  String get otp_sent_successfully => 'ส่ง otp เรียบร้อยแล้ว';

  @override
  String get otp_send_failed => 'การส่ง OTP ล้มเหลว';

  @override
  String get failed_update_target => 'ไม่สามารถอัปเดตค่าเป้าหมายได้';

  @override
  String get updated_Successfully => 'อัปเดตสำเร็จแล้ว';
}
