import 'package:flutter/material.dart';

/// Hand-written localizations — no code generation required.
/// Add strings here and call AppLocalizations.of(context).someKey in any widget.
class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  bool get isAr => locale.languageCode == 'ar';

  // ── Shared / common ─────────────────────────────────────────────────────────
  String get appName => 'PlayNow';
  String get cancel => isAr ? 'إلغاء' : 'Cancel';
  String get confirm => isAr ? 'تأكيد' : 'Confirm';
  String get save => isAr ? 'حفظ' : 'Save';
  String get goBack => isAr ? 'رجوع' : 'Go Back';
  String get retry => isAr ? 'إعادة المحاولة' : 'Retry';
  String get loading => isAr ? 'جار التحميل...' : 'Loading...';
  String get somethingWentWrong =>
      isAr ? 'حدث خطأ ما.' : 'Something went wrong.';
  String get yes => isAr ? 'نعم' : 'Yes';
  String get no => isAr ? 'لا' : 'No';
  String get pending => isAr ? 'في الانتظار' : 'Pending';
  String get approved => isAr ? 'موافق عليه' : 'Approved';
  String get declined => isAr ? 'مرفوض' : 'Declined';
  String get cancelled => isAr ? 'ملغي' : 'Cancelled';
  String get notes => isAr ? 'ملاحظات' : 'Notes';
  String get date => isAr ? 'التاريخ' : 'Date';
  String get start => isAr ? 'البداية' : 'Start';
  String get end => isAr ? 'النهاية' : 'End';
  String get players => isAr ? 'لاعبون' : 'Players';
  String get price => isAr ? 'السعر' : 'Price';
  String get accept => isAr ? 'قبول' : 'Accept';
  String get reject => isAr ? 'رفض' : 'Reject';
  String get approve => isAr ? 'موافقة' : 'Approve';
  String get decline => isAr ? 'رفض' : 'Decline';
  String get noDataYet => isAr ? 'لا يوجد بيانات بعد' : 'No data yet';
  String get newTime => isAr ? 'وقت جديد' : 'New Time';
  String get other => isAr ? 'أخرى' : 'Other';
  String get history => isAr ? 'السجل' : 'History';
  String get sessions => isAr ? 'الجلسات' : 'Sessions';

  // ── Bottom nav tabs ──────────────────────────────────────────────────────────
  String get tabVenues => isAr ? 'الملاعب' : 'Venues';
  String get tabGames => isAr ? 'المباريات' : 'Games';
  String get tabBookings => isAr ? 'حجوزاتي' : 'Bookings';
  String get tabNotifications => isAr ? 'الإشعارات' : 'Notifications';
  String get tabProfile => isAr ? 'الملف الشخصي' : 'Profile';
  String get tabMyVenue => isAr ? 'ملعبي' : 'My Venue';
  String get tabDashboard => isAr ? 'لوحة التحكم' : 'Dashboard';
  String get tabAdmin => isAr ? 'الإدارة' : 'Admin';
  String get tabSports => isAr ? 'الرياضات' : 'Sports';

  // ── Auth — Login ─────────────────────────────────────────────────────────────
  String get signInToPlay => isAr ? 'سجّل دخولك للعب' : 'Sign in to play';
  String get email => isAr ? 'البريد الإلكتروني' : 'Email';
  String get phone => isAr ? 'الهاتف' : 'Phone';
  String get password => isAr ? 'كلمة المرور' : 'Password';
  String get login => isAr ? 'تسجيل الدخول' : 'Login';
  String get sendCode => isAr ? 'إرسال الرمز' : 'Send Code';
  String get verifyAndLogin => isAr ? 'تحقق وسجّل الدخول' : 'Verify & Login';
  String get resendCode => isAr ? 'إعادة إرسال الرمز' : 'Resend Code';
  String get phoneNumber => isAr ? 'رقم الهاتف' : 'Phone Number';
  String get selectCountry => isAr ? 'اختر الدولة' : 'Select Country';
  String get searchCountry => isAr ? 'ابحث عن دولة...' : 'Search country...';
  String get dontHaveAccount =>
      isAr ? 'ليس لديك حساب؟ سجّل' : "Don't have an account? Register";
  String get enterPhoneNumber =>
      isAr ? 'أدخل رقم الهاتف.' : 'Enter a phone number.';
  String get enterSixDigitCode =>
      isAr ? 'أدخل الرمز المكوّن من 6 أرقام.' : 'Enter the 6-digit code.';
  String get invalidCode =>
      isAr ? 'رمز غير صحيح. حاول مرة أخرى.' : 'Invalid code. Please try again.';
  String get verificationFailed =>
      isAr ? 'فشل التحقق. تحقق من رقم الهاتف.' : 'Verification failed. Check the phone number.';
  String codeSentTo(String phone) =>
      isAr ? 'تم إرسال الرمز إلى $phone' : 'Code sent to $phone';

  // ── Auth — Register ───────────────────────────────────────────────────────────
  String get createAccount => isAr ? 'إنشاء حساب' : 'Create Account';
  String get joinAndPlay =>
      isAr ? 'انضم إلى بلاي ناو وابدأ اللعب' : 'Join PlayNow and start playing';
  String get fullName => isAr ? 'الاسم الكامل' : 'Full Name';

  // ── Profile ───────────────────────────────────────────────────────────────────
  String get profile => isAr ? 'الملف الشخصي' : 'Profile';
  String get editInfo => isAr ? 'تعديل المعلومات' : 'Edit Info';
  String get saveChanges => isAr ? 'حفظ التغييرات' : 'Save Changes';
  String get logout => isAr ? 'تسجيل الخروج' : 'Logout';
  String get nameCannotBeEmpty =>
      isAr ? 'لا يمكن ترك الاسم فارغاً.' : 'Name cannot be empty.';
  String get profileUpdated =>
      isAr ? 'تم تحديث الملف الشخصي!' : 'Profile updated!';
  String get tapAvatarToChange =>
      isAr ? 'اضغط على الصورة لتغييرها' : 'Tap avatar to change photo';
  String get noNameSet => isAr ? 'لم يُحدد اسم' : 'No name set';
  String get language => isAr ? 'اللغة' : 'Language';

  // ── Home / Venues ─────────────────────────────────────────────────────────────
  String get findYourGame => isAr ? 'ابحث عن مباراتك' : 'Find your game';
  String get searchVenues =>
      isAr ? 'ابحث عن ملاعب بالاسم أو المدينة...' : 'Search venues by name or city...';
  String get sessionsAvailable => isAr ? 'جلسات متاحة' : 'Sessions available';
  String get active => isAr ? 'نشط' : 'Active';
  String get inactive => isAr ? 'غير نشط' : 'Inactive';
  String get unknownCity => isAr ? 'مدينة غير معروفة' : 'Unknown city';
  String get fiveASide => isAr ? '٥ ضد ٥' : '5-a-side';
  String venuesTotal(int n) =>
      isAr ? '$n ملعب إجمالاً' : '$n venue${n == 1 ? '' : 's'} total';

  // ── Games ─────────────────────────────────────────────────────────────────────
  String get games => isAr ? 'المباريات' : 'Games';
  String get availableOnly => isAr ? 'المتاحة فقط' : 'Available only';
  String get join => isAr ? 'انضم' : 'Join';
  String get joined => isAr ? 'منضم' : 'Joined';
  String get full => isAr ? 'ممتلئة' : 'Full';
  String get noSessionsFound => isAr ? 'لا توجد جلسات' : 'No sessions found';
  String get cancelJoin => isAr ? 'إلغاء الانضمام' : 'Cancel Join';
  String get joinSession => isAr ? 'انضم للجلسة' : 'Join Session';
  String get perPlayer => isAr ? 'لكل لاعب' : 'per player';
  String remainingSpots(int n) =>
      isAr ? '$n مقعد متبقٍ' : '$n spot${n == 1 ? '' : 's'} left';
  String playersCount(int joined, int max) =>
      isAr ? '$joined/$max لاعب' : '$joined/$max players';

  // ── Notifications ─────────────────────────────────────────────────────────────
  String get notifications => isAr ? 'الإشعارات' : 'Notifications';
  String get markAllRead => isAr ? 'تحديد الكل كمقروء' : 'Mark all read';
  String get noNotificationsYet =>
      isAr ? 'لا توجد إشعارات بعد' : 'No notifications yet';
  String get notificationsWillAppear =>
      isAr ? 'ستظهر الإشعارات هنا' : 'Notifications will appear here';
  String get justNow => isAr ? 'الآن' : 'Just now';
  String minutesAgo(int n) => isAr ? 'منذ $n د' : '${n}m ago';
  String hoursAgo(int n) => isAr ? 'منذ $n س' : '${n}h ago';
  String daysAgo(int n) => isAr ? 'منذ $n يوم' : '${n}d ago';
  String weeksAgo(int n) => isAr ? 'منذ $n أسبوع' : '${n}w ago';

  // ── My Bookings (player) ──────────────────────────────────────────────────────
  String get myBookings => isAr ? 'حجوزاتي' : 'My Bookings';
  String get noBookingsYet => isAr ? 'لا توجد حجوزات نشطة بعد' : 'No active bookings yet';
  String get bookingsEmpty =>
      isAr ? 'الحجوزات التي تنضم إليها ستظهر هنا' : 'Sessions you join will appear here';
  String get cancelBooking => isAr ? 'إلغاء الحجز' : 'Cancel Booking';
  String get cancelBookingConfirm =>
      isAr ? 'هل تريد إلغاء حجزك في هذه الجلسة؟' : 'Cancel your booking for this session?';
  String get cancelling => isAr ? 'جار الإلغاء...' : 'Cancelling...';
  String get bookingCancelledSuccess =>
      isAr ? 'تم إلغاء الحجز بنجاح.' : 'Booking cancelled successfully.';
  String get tabActive => isAr ? 'النشطة' : 'Active';
  String get tabLogs => isAr ? 'السجل' : 'Logs';
  String get noPastBookings => isAr ? 'لا توجد جلسات سابقة بعد' : 'No past sessions yet';
  String get pastBookingsEmpty =>
      isAr ? 'ستظهر الجلسات المنتهية هنا' : 'Completed sessions will appear here';
  String cancelBookingForVenue(String name) =>
      isAr ? 'هل تريد إلغاء مقعدك في "$name"؟' : 'Cancel your spot in "$name"?';

  // ── Match Booking — Book ──────────────────────────────────────────────────────
  String get bookAMatch => isAr ? 'احجز مباراة' : 'Book a Match';
  String get fullMatch => isAr ? 'مباراة كاملة' : 'Full Match';
  String get teamTraining => isAr ? 'تدريب فريق' : 'Team Training';
  String get selectPitch => isAr ? 'اختر الملعب' : 'Select Pitch';
  String get teamSize => isAr ? 'حجم الفريق' : 'Team Size';
  String get startTime => isAr ? 'وقت البداية' : 'Start Time';
  String get endTime => isAr ? 'وقت النهاية' : 'End Time';
  String get notesOptional => isAr ? 'ملاحظات (اختياري)' : 'Notes (optional)';
  String get submitBooking => isAr ? 'تأكيد الحجز' : 'Submit Booking';
  String get bookingSubmitted =>
      isAr ? 'تم إرسال الحجز! في انتظار موافقة الملعب.' : 'Booking sent! Waiting for venue approval.';
  String get selectDate => isAr ? 'اختر تاريخاً' : 'Select a date';
  String get numberOfTeams => isAr ? 'عدد الفرق' : 'Number of Teams';
  String get playersPerTeam => isAr ? 'لاعبون لكل فريق' : 'Players per team';

  // ── My Match Bookings ─────────────────────────────────────────────────────────
  String get myMatchRequests => isAr ? 'طلبات مبارياتي' : 'My Match Requests';
  String get noMatchRequestsYet =>
      isAr ? 'لا توجد طلبات مباريات بعد' : 'No match requests yet';
  String get bookPitchHint =>
      isAr ? 'احجز ملعباً من صفحة تفاصيل المكان' : 'Book a pitch from a venue detail page';
  String get newTimeProposed => isAr ? 'وقت جديد مقترح' : 'New Time Proposed';
  String get venueProposedNewTime =>
      isAr ? 'اقترح الملعب وقتاً جديداً:' : 'Venue proposed a new time:';
  String get cancelRequest => isAr ? 'إلغاء الطلب' : 'Cancel Request';
  String get cancelMatchRequest =>
      isAr ? 'إلغاء طلب المباراة' : 'Cancel Booking';
  String get cancelMatchConfirm =>
      isAr ? 'إلغاء طلبك في' : 'Cancel your match request at';
  String get sessionCreated => isAr ? 'تم إنشاء الجلسة' : 'Session Created';
  String sessionCreatedDesc(int reserved, int open) => isAr
      ? 'تم حجز فريقك. $open مقعد مفتوح للاعبين الآخرين للانضمام.'
      : 'Your team is reserved. $open open spots are available for other players to join.';
  String get viewInGamesTab =>
      isAr ? 'عرض في تبويب المباريات' : 'View in Games Tab';
  String get acceptNewTime => isAr ? 'قبول الوقت الجديد' : 'Accept New Time';
  String get acceptNewTimeConfirm =>
      isAr ? 'قبول الوقت المقترح من الملعب؟' : "Accept the venue's proposed time?";
  String get timeAccepted =>
      isAr ? 'تم قبول الوقت! تم تأكيد الحجز.' : 'Time accepted! Booking confirmed.';
  String get rejectNewTime => isAr ? 'رفض الوقت الجديد' : 'Reject New Time';
  String get rejectNewTimeConfirm =>
      isAr ? 'رفض الوقت المقترح؟ سيتم إلغاء الحجز.' : 'Reject the proposed time? This will cancel the booking.';
  String get timeRejected =>
      isAr ? 'تم رفض الوقت، تم إلغاء الحجز.' : 'Time rejected, booking cancelled.';

  // ── Venue — Match Requests ────────────────────────────────────────────────────
  String get matchRequests => isAr ? 'طلبات المباريات' : 'Match Requests';
  String get noPendingRequests =>
      isAr ? 'لا توجد طلبات معلقة' : 'No pending requests';
  String get noHistory => isAr ? 'لا يوجد سجل بعد' : 'No history yet';
  String get approveFullMatch =>
      isAr ? 'موافقة على المباراة الكاملة' : 'Approve Full Match';
  String get bookingApproved => isAr ? 'تمت الموافقة على الحجز! تم إخطار اللاعب.' : 'Booking approved! Player notified.';
  String get bookingCancelled => isAr ? 'تم إلغاء الحجز.' : 'Booking cancelled.';
  String get proposeNewTime => isAr ? 'اقتراح وقت جديد' : 'Propose New Time';
  String get newTimeProposedMsg =>
      isAr ? 'تم اقتراح وقت جديد. في انتظار رد اللاعب.' : 'New time proposed. Waiting for player response.';
  String get setPricePerPlayer =>
      isAr ? 'تحديد سعر اللاعب' : 'Set Price Per Player';
  String get pricePerPlayer => isAr ? 'السعر لكل لاعب (د.أ)' : 'Price per player (JD)';
  String get confirmAndApprove =>
      isAr ? 'تأكيد والموافقة' : 'Confirm & Approve';
  String get proposeThisTime => isAr ? 'اقتراح هذا الوقت' : 'Propose This Time';
  String get playerRequested => isAr ? 'وقت اللاعب المطلوب:' : 'Player requested:';
  String approvedSessionCreated(int total) => isAr
      ? 'تمت الموافقة! تم إنشاء جلسة بـ $total مقعد.'
      : 'Approved! A session with $total spots was created.';
  String approveMatchConfirm(String playerName, String pitchName) => isAr
      ? 'الموافقة على مباراة $playerName في $pitchName؟'
      : 'Approve $playerName\'s match on $pitchName?';
  String spotsSubtitle(int total, int reserved, int open) => isAr
      ? '$total مقعد إجمالاً — $reserved محجوز، $open مفتوح للآخرين.'
      : '$total total spots will be created — $reserved reserved for this team, $open open for others.';

  // ── Session Players ───────────────────────────────────────────────────────────
  String get cancelSession => isAr ? 'إلغاء الجلسة' : 'Cancel Session';
  String get sessionCancelledMsg =>
      isAr ? 'تم إلغاء الجلسة. تم إخطار جميع اللاعبين.' : 'Session cancelled. All players notified.';
  String get sessionCancelledSimple => isAr ? 'تم إلغاء الجلسة' : 'Session cancelled';
  String get noPlayersYet => isAr ? 'لا يوجد لاعبون بعد' : 'No players yet';
  String get checkIn => isAr ? 'تسجيل الحضور' : 'Check In';
  String get cancelSessionTitle => isAr ? 'إلغاء الجلسة' : 'Cancel Session';
  String get cancelSessionSubtitle =>
      isAr ? 'اختر سبباً — سيتم إخطار جميع اللاعبين.' : 'Select a reason — all players will be notified.';
  String get reasonMaintenance =>
      isAr ? 'صيانة الملعب مطلوبة' : 'Pitch maintenance required';
  String get reasonWeather => isAr ? 'ظروف الطقس' : 'Weather conditions';
  String get reasonNotEnoughPlayers =>
      isAr ? 'عدد غير كافٍ من اللاعبين' : 'Not enough players';
  String get reasonEmergency => isAr ? 'طارئ في الملعب' : 'Venue emergency';
  String get reasonDoubleBooking =>
      isAr ? 'خطأ في الحجز المزدوج' : 'Double booking error';
  String get describeReason => isAr ? 'اصف السبب...' : 'Describe the reason...';
  String get confirmCancel => isAr ? 'تأكيد الإلغاء' : 'Confirm Cancel';
  String get noPhone => isAr ? 'لا يوجد هاتف' : 'No phone';
  String checkedInMsg(String name) =>
      isAr ? 'تم تسجيل حضور $name! ✅' : '$name checked in! ✅';
  String cancelSessionOnDate(String date) =>
      isAr ? 'إلغاء الجلسة في $date؟' : 'Cancel the session on $date?';

  // ── Venue Dashboard ───────────────────────────────────────────────────────────
  String get venueDashboard => isAr ? 'لوحة التحكم' : 'Dashboard';
  String get createSession => isAr ? 'إنشاء جلسة' : 'Create Session';
  String get noSessionsCreated =>
      isAr ? 'لم يتم إنشاء جلسات بعد' : 'No sessions created yet';
  String get viewPlayers => isAr ? 'عرض اللاعبين' : 'View Players';
  String get sessionFull => isAr ? 'ممتلئة' : 'Full';
  String get sessionOpen => isAr ? 'مفتوحة' : 'Open';
  String get pastSessions => isAr ? 'الجلسات السابقة' : 'Past Sessions';
  String get upcomingSessions => isAr ? 'الجلسات القادمة' : 'Upcoming Sessions';
  String pendingMatchBanner(int count) => isAr
      ? '$count ${count > 1 ? 'طلبات مباريات معلقة' : 'طلب مباراة معلق'} — اضغط للمراجعة'
      : '$count pending match booking${count > 1 ? 's' : ''} — tap to review';
  String get yesCancelButton => isAr ? 'نعم، إلغاء' : 'Yes, Cancel';

  // ── Create Session ────────────────────────────────────────────────────────────
  String get maxPlayers => isAr ? 'الحد الأقصى للاعبين' : 'Max Players';
  String get sessionCreatedSuccess =>
      isAr ? 'تم إنشاء الجلسة بنجاح!' : 'Session created successfully!';

  // ── My Venue Screen ───────────────────────────────────────────────────────────
  String get myVenue => isAr ? 'ملعبي' : 'My Venue';
  String get viewMatchRequests =>
      isAr ? 'عرض طلبات المباريات' : 'View Match Requests';
  String get noVenueYet => isAr ? 'لم يتم إنشاء أي ملعب بعد' : 'No venue yet';

  // ── Relative time helper strings already in getters above ────────────────────

  // ── Admin ─────────────────────────────────────────────────────────────────────
  String get adminPanel => isAr ? 'لوحة الإدارة' : 'Admin Panel';
  String get addVenue => isAr ? 'إضافة ملعب' : 'Add Venue';
  String get noVenuesYet => isAr ? 'لا توجد ملاعب بعد' : 'No venues yet';
  String get venuesWillAppear => isAr ? 'ستظهر الملاعب هنا بعد إنشائها.' : 'Venues will appear here once created.';
  String get activeVenues => isAr ? 'الملاعب النشطة' : 'Active Venues';
  String get inactiveVenues => isAr ? 'الملاعب غير النشطة' : 'Inactive Venues';
  String get deactivate => isAr ? 'تعطيل' : 'Deactivate';
  String get activate => isAr ? 'تفعيل' : 'Activate';
  String deactivateVenueConfirm(String name) => isAr
      ? 'تعطيل "$name" سيخفيه عن اللاعبين. هل تريد المتابعة؟'
      : 'Deactivating "$name" will hide it from players. Continue?';
  String activateVenueConfirm(String name) => isAr
      ? 'تفعيل "$name" ليتمكن اللاعبون من اكتشافه وحجز جلساته؟'
      : 'Activate "$name" so players can discover and book sessions?';

  // ── Add Venue ─────────────────────────────────────────────────────────────────
  String get venueInfo => isAr ? 'معلومات الملعب' : 'Venue Info';
  String get venueNameLabel => isAr ? 'اسم الملعب *' : 'Venue Name *';
  String get cityLabel => isAr ? 'المدينة' : 'City';
  String get addressLabel => isAr ? 'العنوان' : 'Address';
  String get descriptionLabel => isAr ? 'الوصف' : 'Description';
  String get imageUrlLabel => isAr ? 'رابط الصورة' : 'Image URL';
  String get locationLabel => isAr ? 'الموقع' : 'Location';
  String get tapMapToSetLocation =>
      isAr ? 'اضغط على الخريطة لتحديد موقع الملعب' : 'Tap on the map to set the venue location';
  String get noLocationSelected =>
      isAr ? 'لم يتم تحديد موقع بعد' : 'No location selected yet';
  String get createVenue => isAr ? 'إنشاء ملعب' : 'Create Venue';
  String get requiredField => isAr ? 'مطلوب' : 'Required';
  String get venueCreatedSuccess =>
      isAr ? 'تم إنشاء الملعب بنجاح!' : 'Venue created successfully!';

  // ── Venue Detail ──────────────────────────────────────────────────────────────
  String get tabInfo => isAr ? 'معلومات' : 'Info';
  String get tabBookMatch => isAr ? 'احجز مباراة' : 'Book Match';
  String get venueLabel => isAr ? 'الملعب' : 'Venue';
  String get pickDate => isAr ? 'اختر تاريخاً' : 'Pick date';
  String get clearAll => isAr ? 'مسح الكل' : 'Clear all';
  String get confirmBookingTitle => isAr ? 'تأكيد الحجز' : 'Confirm Booking';
  String get bookNow => isAr ? 'احجز الآن' : 'Book Now';
  String get spotReserved =>
      isAr ? 'تم الحجز! نراك في الملعب!' : 'Spot reserved! See you on the pitch!';
  String get loginToBookSession =>
      isAr ? 'يرجى تسجيل الدخول للحجز.' : 'Please log in to book a session.';
  String get loginToBookMatch =>
      isAr ? 'يرجى تسجيل الدخول لحجز مباراة.' : 'Please log in to book a match.';
  String get bookMatchInfoText => isAr
      ? 'احجز الملعب بالكامل لفريقك أو رتّب مباراة. سيراجع صاحب الملعب طلبك ويؤكده.'
      : 'Book the entire pitch for your team or arrange a match. The venue owner will review and confirm your request.';
  String get requestSentToVenue =>
      isAr ? 'تم إرسال الطلب للملعب!' : 'Request sent to the venue!';
  String sessionsTotal(int n) =>
      isAr ? '$n جلسة إجمالاً' : '$n session${n == 1 ? '' : 's'} total';
  String reserveSpotConfirm(String price, String date, String time) => isAr
      ? 'حجز مقعد بسعر $price JD؟\n\nالجلسة: $date في $time'
      : 'Reserve a spot for $price JD?\n\nSession: $date at $time';
  String get requestMatchBooking => isAr ? 'طلب حجز مباراة' : 'Request a Match Booking';

  // ── Language names ────────────────────────────────────────────────────────────
  String get langEnglish => isAr ? 'الإنجليزية' : 'English';
  String get langArabic  => isAr ? 'العربية'     : 'Arabic';

  // ── Settings ──────────────────────────────────────────────────────────────────
  String get settings           => isAr ? 'الإعدادات'           : 'Settings';
  String get appearance         => isAr ? 'المظهر'              : 'Appearance';
  String get themeMode          => isAr ? 'وضع الثيم'           : 'Theme';
  String get themeLight         => isAr ? 'فاتح'                : 'Light';
  String get themeDark          => isAr ? 'داكن'                : 'Dark';
  String get themeSystem        => isAr ? 'تلقائي (النظام)'    : 'System default';
  String get notificationsSection => isAr ? 'الإشعارات'         : 'Notifications';
  String get enableNotifications => isAr ? 'تفعيل الإشعارات'   : 'Enable notifications';
  String get preferencesSection => isAr ? 'التفضيلات'           : 'Preferences';
  String get accountSection     => isAr ? 'الحساب'              : 'Account';
  String get aboutSection       => isAr ? 'حول التطبيق'         : 'About';
  String get appVersion         => isAr ? 'إصدار التطبيق'       : 'App version';
  String get privacyPolicy      => isAr ? 'سياسة الخصوصية'     : 'Privacy policy';
  String get termsOfService     => isAr ? 'شروط الخدمة'         : 'Terms of service';
  String get editProfile        => isAr ? 'تعديل الملف الشخصي' : 'Edit profile';
  String get logoutFromSettings => isAr ? 'تسجيل الخروج'       : 'Sign out';

  // ── Venue Media ───────────────────────────────────────────────────────────────
  String get photos      => isAr ? 'الصور'            : 'Photos';
  String get videos      => isAr ? 'مقاطع الفيديو'    : 'Videos';
  String get addPhoto    => isAr ? 'إضافة صورة'       : 'Add Photo';
  String get addVideo    => isAr ? 'إضافة فيديو'      : 'Add Video';
  String get watchVideo  => isAr ? 'مشاهدة الفيديو'   : 'Watch Video';
  String get photoUrl    => isAr ? 'رابط الصورة'      : 'Photo URL';
  String get videoUrl    => isAr ? 'رابط الفيديو'     : 'Video URL';
  String get captionEn   => isAr ? 'التعليق (إنجليزي)': 'Caption (English)';
  String get captionAr   => isAr ? 'التعليق (عربي)'  : 'Caption (Arabic)';
  String get titleEn     => isAr ? 'العنوان (إنجليزي)': 'Title (English)';
  String get titleAr     => isAr ? 'العنوان (عربي)'   : 'Title (Arabic)';
  String get thumbnailUrl => isAr ? 'رابط الصورة المصغرة' : 'Thumbnail URL';
  String get setCover    => isAr ? 'تعيين كغلاف'      : 'Set as cover';
  String get cover       => isAr ? 'الغلاف'           : 'Cover';
  String get noPhotos    => isAr ? 'لا توجد صور بعد'  : 'No photos yet';
  String get noVideos    => isAr ? 'لا توجد فيديوهات بعد' : 'No videos yet';
  String get manageMedia => isAr ? 'إدارة الوسائط'    : 'Manage Media';
  String get deletePhoto => isAr ? 'حذف الصورة'       : 'Delete photo';
  String get deleteVideo => isAr ? 'حذف الفيديو'      : 'Delete video';
  String get mediaSection => isAr ? 'الصور والفيديوهات' : 'Photos & Videos';

  // ── Match booking status labels ───────────────────────────────────────────────
  String get statusApproved => isAr ? 'موافق عليه' : 'Approved';
  String get statusCancelled => isAr ? 'ملغي' : 'Cancelled';
  String get statusNewTimeProposed => isAr ? 'وقت جديد مقترح' : 'New Time Proposed';
  String get statusPending => isAr ? 'في الانتظار' : 'Pending';
  String teamsAndPlayers(int teams, int teamSize) => isAr
      ? '$teams ${teams > 1 ? 'فرق' : 'فريق'} × $teamSize لاعب'
      : '$teams team${teams > 1 ? 's' : ''} × $teamSize players';

  // ── Notification type titles (in-app inbox & FCM SnackBar) ───────────────────
  String notificationTypeTitle(String type) => switch (type) {
        'session_joined' => isAr ? 'تأكيد الانضمام للجلسة' : 'Session Confirmed',
        'player_joined' => isAr ? 'لاعب جديد انضم' : 'Player Joined',
        'session_cancelled' => isAr ? 'تم إلغاء الجلسة' : 'Session Cancelled',
        'match_request' => isAr ? 'طلب مباراة جديد' : 'New Match Request',
        'match_approved' => isAr ? 'تمت الموافقة على المباراة' : 'Match Approved',
        'match_cancelled' => isAr ? 'تم إلغاء المباراة' : 'Match Cancelled',
        'match_rescheduled' => isAr ? 'اقتراح وقت جديد للمباراة' : 'Match Rescheduled',
        'reschedule_accepted' => isAr ? 'تم قبول الوقت الجديد' : 'Reschedule Accepted',
        'reschedule_rejected' => isAr ? 'تم رفض الوقت الجديد' : 'Reschedule Rejected',
        _ => '',
      };

  // Localized short month names (for notification timestamps)
  String shortMonth(int month) {
    if (isAr) {
      const months = [
        'يناير','فبراير','مارس','أبريل','مايو','يونيو',
        'يوليو','أغسطس','سبتمبر','أكتوبر','نوفمبر','ديسمبر',
      ];
      return months[month - 1];
    }
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec',
    ];
    return months[month - 1];
  }
}

// ── Delegate ─────────────────────────────────────────────────────────────────

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'ar'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
