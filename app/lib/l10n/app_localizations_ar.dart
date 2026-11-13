// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'foodfennec';

  @override
  String get language => 'اللغة';

  @override
  String get langAr => 'العربية';

  @override
  String get langFr => 'Français';

  @override
  String get langEn => 'English';

  @override
  String get back => 'رجوع';

  @override
  String get addToCart => 'أضف إلى السلة';

  @override
  String get cart => 'السلة';

  @override
  String get checkout => 'إتمام الطلب';

  @override
  String get placeOrder => 'أرسل الطلب';

  @override
  String get total => 'المجموع';

  @override
  String get subtotal => 'المجموع الفرعي';

  @override
  String get deliveryFee => 'التوصيل';

  @override
  String get freeDelivery => 'مجاني';

  @override
  String minutes(int count) {
    return '$count د';
  }

  @override
  String get open => 'مفتوح';

  @override
  String get closed => 'مغلق';

  @override
  String get fullName => 'الاسم الكامل';

  @override
  String get phone => 'رقم الهاتف';

  @override
  String get address => 'العنوان';

  @override
  String get area => 'الحي / البلدية';

  @override
  String get notes => 'ملاحظات';

  @override
  String get optional => 'اختياري';

  @override
  String get cashOnDelivery => 'الدفع عند الاستلام';

  @override
  String get otherRestaurants => 'مطاعم أخرى';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get logIn => 'تسجيل الدخول';

  @override
  String get logInSubtitle => 'سجّل الدخول إلى حسابك';

  @override
  String get accept => 'قبول';

  @override
  String get reject => 'رفض';

  @override
  String get ready => 'جاهز';

  @override
  String get cancel => 'إلغاء';

  @override
  String get save => 'حفظ';

  @override
  String get statusPlaced => 'تم إرسال الطلب';

  @override
  String get statusAccepted => 'قبله المطعم';

  @override
  String get statusReady => 'جاهز';

  @override
  String get statusPickedUp => 'في الطريق';

  @override
  String get statusDelivered => 'تم التوصيل';

  @override
  String get statusRejected => 'مرفوض';

  @override
  String get statusCancelled => 'ملغى';

  @override
  String get runningOrders => 'طلبات جارية';

  @override
  String get orderRequests => 'طلبات جديدة';

  @override
  String itemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count عنصر',
      many: '$count عنصرًا',
      few: '$count عناصر',
      two: 'عنصران',
      one: 'عنصر واحد',
      zero: 'لا عناصر',
    );
    return '$_temp0';
  }

  @override
  String get componentGallery => 'معرض المكونات';

  @override
  String get onb1Title => 'كل أطباقك المفضلة';

  @override
  String get onb1Body =>
      'كل أطباقك المفضلة في مكان واحد. اطلب وسنتكفّل بالباقي.';

  @override
  String get onb2Title => 'أفضل المطاعم';

  @override
  String get onb2Body => 'مطاعم حيّك وقوائمها كاملة، في ثوانٍ.';

  @override
  String get onb3Title => 'الدفع عند الاستلام';

  @override
  String get onb3Body => 'لا حاجة لبطاقة: ادفع نقدًا عند وصول طلبك.';

  @override
  String get next => 'التالي';

  @override
  String get skip => 'تخطّي';

  @override
  String get getStarted => 'ابدأ الآن';

  @override
  String get logInTitle => 'تسجيل الدخول';

  @override
  String get logInSubtitleLong => 'سجّل الدخول إلى حسابك';

  @override
  String get signUpTitle => 'إنشاء حساب';

  @override
  String get signUpSubtitle => 'أنشئ حسابك للبدء';

  @override
  String get signUp => 'إنشاء حساب';

  @override
  String get name => 'الاسم';

  @override
  String get namePlaceholder => 'كريم بن علي';

  @override
  String get emailPlaceholder => 'example@gmail.com';

  @override
  String get retypePassword => 'أعد كتابة كلمة المرور';

  @override
  String get rememberMe => 'تذكّرني';

  @override
  String get forgotPassword => 'نسيت كلمة المرور';

  @override
  String get noAccount => 'ليس لديك حساب؟';

  @override
  String get haveAccount => 'لديك حساب بالفعل؟';

  @override
  String get verificationTitle => 'التحقق';

  @override
  String get codeSentTo => 'أرسلنا رمزًا إلى بريدك';

  @override
  String get code => 'الرمز';

  @override
  String get resend => 'إعادة الإرسال';

  @override
  String resendIn(int seconds) {
    return 'بعد $seconds ث';
  }

  @override
  String get verify => 'تحقّق';

  @override
  String get codeResent => 'تم إرسال رمز جديد';

  @override
  String get forgotPasswordTitle => 'نسيت كلمة المرور';

  @override
  String get forgotPasswordSubtitle => 'أدخل بريدك الإلكتروني لتلقّي رمز';

  @override
  String get sendCode => 'أرسل الرمز';

  @override
  String get newPasswordTitle => 'كلمة مرور جديدة';

  @override
  String get newPasswordSubtitle => 'اختر كلمة مرور جديدة';

  @override
  String get newPassword => 'كلمة المرور الجديدة';

  @override
  String get passwordUpdated => 'تم تغيير كلمة المرور';

  @override
  String get logOut => 'تسجيل الخروج';

  @override
  String hello(String name) {
    return 'مرحبًا، $name';
  }

  @override
  String get homeComingSoon => 'المطاعم في الخطوة القادمة.';

  @override
  String get errNameRequired => 'أدخل اسمك (من 2 إلى 80 حرفًا)';

  @override
  String get errEmailInvalid => 'البريد الإلكتروني غير صالح';

  @override
  String get errPasswordShort => '8 أحرف على الأقل';

  @override
  String get errPasswordMismatch => 'كلمتا المرور غير متطابقتين';

  @override
  String get errCodeIncomplete => 'أدخل الرمز المكوّن من 6 أرقام';

  @override
  String get errInvalidCredentials =>
      'البريد الإلكتروني أو كلمة المرور غير صحيحة';

  @override
  String get errUserExists => 'يوجد حساب بهذا البريد الإلكتروني';

  @override
  String get errCodeInvalid => 'الرمز غير صحيح أو منتهي الصلاحية';

  @override
  String get errTooManyRequests => 'محاولات كثيرة، أعد المحاولة بعد قليل';

  @override
  String get errWeakPassword => 'كلمة المرور ضعيفة';

  @override
  String get errNetwork => 'لا يوجد اتصال. تحقّق من الشبكة.';

  @override
  String get errGeneric => 'حدث خطأ، أعد المحاولة';

  @override
  String get errBackendMissing => 'الخادم غير مُعدّ (env.json)';

  @override
  String get showPassword => 'إظهار كلمة المرور';

  @override
  String get hidePassword => 'إخفاء كلمة المرور';

  @override
  String get errEmailSend =>
      'تعذّر إرسال رسالة الرمز إلى هذا البريد. أعد المحاولة لاحقًا.';

  @override
  String get errServer => 'حدث خلل في الخادم. أعد المحاولة بعد قليل.';

  @override
  String get deliverTo => 'التوصيل إلى';

  @override
  String get chooseAddress => 'اختر عنوانًا';

  @override
  String greetingMorning(String name) {
    return 'صباح الخير يا $name!';
  }

  @override
  String greetingAfternoon(String name) {
    return 'مساء الخير يا $name!';
  }

  @override
  String greetingEvening(String name) {
    return 'مساء الخير يا $name!';
  }

  @override
  String get searchHint => 'ابحث عن أطباق أو مطاعم';

  @override
  String get allCategories => 'كل الأصناف';

  @override
  String get seeAll => 'عرض الكل';

  @override
  String get openRestaurants => 'المطاعم';

  @override
  String get all => 'الكل';

  @override
  String fromPrice(String price) {
    return 'ابتداءً من $price';
  }

  @override
  String kmAway(String km) {
    return '$km كم';
  }

  @override
  String get recentKeywords => 'عمليات البحث الأخيرة';

  @override
  String get suggestedRestaurants => 'مطاعم مقترحة';

  @override
  String noResults(String query) {
    return 'لا توجد نتائج لـ «$query»';
  }

  @override
  String get dishes => 'أطباق';

  @override
  String get restaurantsTitle => 'مطاعم';

  @override
  String get restaurant => 'المطعم';

  @override
  String get details => 'التفاصيل';

  @override
  String popularIn(String category) {
    return '$category الأكثر طلبًا';
  }

  @override
  String get addedToCart => 'أُضيف إلى السلة';

  @override
  String cartOtherRestaurant(String name) {
    return 'سلتك تحتوي على أطباق من $name. هل تبدأ سلة جديدة؟';
  }

  @override
  String get newCart => 'سلة جديدة';

  @override
  String get unavailable => 'غير متوفر';

  @override
  String get restaurantNotFound => 'المطعم غير موجود';

  @override
  String get restaurantClosedNote => 'هذا المطعم مغلق حاليًا';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get loadError => 'تعذّر التحميل. تحقّق من الاتصال.';

  @override
  String get accessLocation => 'السماح بالوصول إلى الموقع';

  @override
  String get locationExplain => 'يستخدم FOOD موقعك فقط أثناء استخدام التطبيق';

  @override
  String get notNow => 'ليس الآن';

  @override
  String get locationDenied => 'تم رفض الوصول إلى الموقع';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get personalInfo => 'المعلومات الشخصية';

  @override
  String get addresses => 'العناوين';

  @override
  String get edit => 'تعديل';

  @override
  String get editProfile => 'تعديل الملف الشخصي';

  @override
  String get saved => 'تم الحفظ';

  @override
  String get changePhoto => 'تغيير الصورة';

  @override
  String get phoneOptionalHint => '0550 12 34 56';

  @override
  String get errPhoneInvalid => 'رقم غير صالح (05 أو 06 أو 07 + 8 أرقام)';

  @override
  String get addNewAddress => 'إضافة عنوان جديد';

  @override
  String get editAddress => 'تعديل العنوان';

  @override
  String get saveLocation => 'حفظ العنوان';

  @override
  String get labelAs => 'التصنيف';

  @override
  String get labelHome => 'المنزل';

  @override
  String get labelWork => 'العمل';

  @override
  String get labelOther => 'آخر';

  @override
  String get addressDetails => 'العمارة، الطابق، الباب';

  @override
  String get addressHint => 'حي 200 مسكن، شارع…';

  @override
  String get areaHint => 'القبة، حيدرة، باب الزوار…';

  @override
  String get setDefault => 'تعيين كافتراضي';

  @override
  String get defaultTag => 'افتراضي';

  @override
  String get delete => 'حذف';

  @override
  String get deleteAddressConfirm => 'حذف هذا العنوان؟';

  @override
  String get noAddresses => 'لا توجد عناوين محفوظة';

  @override
  String get moveMapHint => 'حرّك الخريطة لوضع العلامة';

  @override
  String get useMyLocation => 'موقعي';

  @override
  String get errAddressRequired => 'أدخل العنوان (3 أحرف على الأقل)';

  @override
  String get errAddressLimit => 'يمكنك حفظ 10 عناوين كحد أقصى';

  @override
  String get search => 'بحث';

  @override
  String get cartEmpty => 'سلتك فارغة';

  @override
  String get checkoutNextStep => 'إتمام الطلب سيكون متاحًا في الخطوة القادمة.';

  @override
  String get ownRestaurant => 'لديك مطعم؟';

  @override
  String get registerIt => 'سجّله';

  @override
  String get registerRestaurantTitle => 'مطعمك';

  @override
  String get registerRestaurantSubtitle =>
      'انضم إلى foodfennec واستقبل الطلبات';

  @override
  String get yourAccount => 'حسابك';

  @override
  String get restaurantSection => 'المطعم';

  @override
  String get restaurantName => 'اسم المطعم';

  @override
  String get restaurantPhone => 'هاتف المطعم';

  @override
  String get prepTime => 'مدة التحضير (دقيقة)';

  @override
  String get errRestaurantPhone =>
      'رقم غير صالح (مثال 0550123456 أو 021234567)';

  @override
  String get errPrepTime => 'بين 5 و120 دقيقة';

  @override
  String get pendingApprovalTitle => 'في انتظار الموافقة';

  @override
  String get pendingApprovalBody =>
      'نحن نراجع مطعمك. جهّز قائمتك في الأثناء: سيراها الزبائن بعد الموافقة.';

  @override
  String get openForOrders => 'مفتوح للطلبات';

  @override
  String get closedForOrders => 'مغلق';

  @override
  String get openSwitchHint => 'يمكن للزبائن الطلب عند التفعيل';

  @override
  String get cantOpenPending => 'يمكنك الفتح بعد الموافقة';

  @override
  String get dashboard => 'لوحة التحكم';

  @override
  String get menu => 'القائمة';

  @override
  String get orders => 'الطلبات';

  @override
  String get myMenu => 'قائمتي';

  @override
  String totalItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count طبق',
      many: '$count طبقًا',
      few: '$count أطباق',
      two: 'طبقان',
      one: 'طبق واحد',
      zero: 'لا أطباق',
    );
    return '$_temp0';
  }

  @override
  String get addItem => 'إضافة طبق';

  @override
  String get editItem => 'تعديل الطبق';

  @override
  String get reset => 'إعادة تعيين';

  @override
  String get itemName => 'اسم الطبق';

  @override
  String get itemNameHint => 'بيتزا مارغريتا';

  @override
  String get uploadPhoto => 'الصورة';

  @override
  String get add => 'إضافة';

  @override
  String get price => 'السعر (دج)';

  @override
  String get priceHint => '650';

  @override
  String get errPrice => 'السعر بين 10 و100000 دج';

  @override
  String get category => 'الصنف';

  @override
  String get noCategory => 'بدون';

  @override
  String get available => 'متوفر';

  @override
  String get itemDetails => 'الوصف';

  @override
  String get itemDetailsHint => 'المكونات، الحجم…';

  @override
  String get saveChanges => 'حفظ التغييرات';

  @override
  String get deleteItemConfirm => 'حذف هذا الطبق؟';

  @override
  String get emptyMenu => 'قائمتك فارغة. أضف طبقك الأول.';

  @override
  String get ordersComingSoon => 'الطلبات المباشرة تأتي في الخطوة القادمة.';

  @override
  String get restaurantProfile => 'ملف المطعم';

  @override
  String get coverPhoto => 'صورة الغلاف';

  @override
  String get logo => 'الشعار';

  @override
  String get description => 'الوصف';

  @override
  String get descriptionHint => 'بيتزا على الحطب، تاكوس…';

  @override
  String get restaurantLocation => 'الموقع على الخريطة';

  @override
  String get errPhotoTooLarge => 'الصورة كبيرة جدًا (3 ميغابايت كحد أقصى)';

  @override
  String dishesAvailable(int available, int total) {
    return '$available من $total متوفرة';
  }

  @override
  String get seeMenu => 'عرض القائمة';

  @override
  String get registrationDone => 'تم تسجيل المطعم';

  @override
  String get admin => 'الإدارة';

  @override
  String get receipts => 'الكشوف';

  @override
  String get settings => 'الإعدادات';

  @override
  String get customers => 'الزبائن';

  @override
  String get periodToday => 'اليوم';

  @override
  String get periodLast7 => '7 أيام';

  @override
  String get periodThisMonth => 'هذا الشهر';

  @override
  String get periodLastMonth => 'الشهر الماضي';

  @override
  String get periodCustom => 'مخصّص';

  @override
  String get previousHalfMonth => 'نصف الشهر السابق';

  @override
  String get statDelivered => 'طلبات مسلّمة';

  @override
  String get statSales => 'المبيعات (طعام)';

  @override
  String get statDeliveryFees => 'رسوم التوصيل';

  @override
  String get statCommission => 'العمولة المكتسبة';

  @override
  String get statCancelled => 'ملغاة / مرفوضة';

  @override
  String get statActive => 'قيد التنفيذ';

  @override
  String get statPending => 'مطاعم بانتظار الموافقة';

  @override
  String get statActiveRestaurants => 'المطاعم النشطة';

  @override
  String get statUnbilled => 'عمولة غير مفوترة';

  @override
  String get byRestaurant => 'حسب المطعم';

  @override
  String get filterPending => 'بانتظار الموافقة';

  @override
  String get filterActive => 'نشطة';

  @override
  String get filterInactive => 'معطّلة';

  @override
  String get approve => 'موافقة';

  @override
  String get deactivate => 'تعطيل';

  @override
  String get reactivate => 'إعادة التفعيل';

  @override
  String get commissionRate => 'نسبة العمولة';

  @override
  String defaultRate(String rate) {
    return 'افتراضي ($rate)';
  }

  @override
  String get useDefault => 'النسبة الافتراضية';

  @override
  String get errRate => 'بين 0 و50٪';

  @override
  String get owner => 'المسيّر';

  @override
  String toBill(String amount) {
    return 'للفوترة: $amount';
  }

  @override
  String deliveredCount(int count) {
    return '$count مسلّمة';
  }

  @override
  String get noRestaurants => 'لا توجد مطاعم';

  @override
  String get newReceipt => 'كشف جديد';

  @override
  String get receiptPeriod => 'الفترة';

  @override
  String receiptPreview(int count, String food) {
    return '$count طلبات مسلّمة · مبيعات $food';
  }

  @override
  String get commissionDue => 'العمولة المستحقة';

  @override
  String get generateReceipt => 'إنشاء الكشف';

  @override
  String get noOrdersToBill => 'لا توجد طلبات مسلّمة للفوترة في هذه الفترة';

  @override
  String get periodNotFinished => 'اختر فترة منتهية';

  @override
  String get statusPaid => 'مدفوع';

  @override
  String get statusUnpaid => 'غير مدفوع';

  @override
  String get markPaid => 'تأشير كمدفوع';

  @override
  String get markUnpaid => 'تأشير كغير مدفوع';

  @override
  String get downloadPdf => 'تحميل PDF';

  @override
  String get printPdf => 'طباعة';

  @override
  String get cancelReceipt => 'إلغاء الكشف';

  @override
  String get cancelReceiptConfirm =>
      'إلغاء هذا الكشف؟ يمكن فوترة طلباته من جديد.';

  @override
  String get noReceipts => 'لا توجد كشوف بعد';

  @override
  String get allRestaurants => 'كل المطاعم';

  @override
  String get allStatuses => 'كل الحالات';

  @override
  String get noOrders => 'لا توجد طلبات';

  @override
  String get loadMore => 'عرض المزيد';

  @override
  String get itemsTitle => 'العناصر';

  @override
  String get defaultCommission => 'العمولة الافتراضية (٪)';

  @override
  String get deliveryFeeDa => 'رسوم التوصيل (دج)';

  @override
  String get errDeliveryFee => 'بين 0 و5000 دج';

  @override
  String get businessInfo => 'معلوماتك (تُطبع على الكشوف)';

  @override
  String get businessName => 'الاسم التجاري';

  @override
  String get businessPhone => 'الهاتف';

  @override
  String get businessEmail => 'البريد الإلكتروني';

  @override
  String get businessAddress => 'العنوان';

  @override
  String get businessTaxId => 'الرقم الجبائي';

  @override
  String get searchCustomers => 'الاسم أو البريد أو الهاتف';

  @override
  String ordersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count طلب',
      many: '$count طلبًا',
      few: '$count طلبات',
      two: 'طلبان',
      one: 'طلب واحد',
      zero: 'لا طلبات',
    );
    return '$_temp0';
  }

  @override
  String get restaurantFilter => 'المطعم';

  @override
  String get statusFilter => 'الحالة';

  @override
  String issuedOn(String date) {
    return 'صدر في $date';
  }

  @override
  String get deliveryAddress => 'عنوان التوصيل';

  @override
  String get breakdown => 'التفاصيل';

  @override
  String get addDeliveryAddress => 'أضف عنوان التوصيل';

  @override
  String get deliveryDetails => 'تفاصيل التوصيل';

  @override
  String get phoneForDriver => 'سيتصل بك المطعم والسائق على هذا الرقم.';

  @override
  String get notesHint => 'مثال: بدون بصل، الطابق الثاني';

  @override
  String get orderPlacedTitle => 'تم إرسال طلبك!';

  @override
  String orderPlacedBody(String total) {
    return 'سيؤكد المطعم طلبك. ستدفع $total نقدًا عند الاستلام.';
  }

  @override
  String get trackOrder => 'تتبع الطلب';

  @override
  String get backToHome => 'العودة إلى الرئيسية';

  @override
  String get myOrders => 'طلباتي';

  @override
  String get ongoingOrders => 'الجارية';

  @override
  String get orderHistory => 'السجل';

  @override
  String get noOngoingOrders => 'لا توجد طلبات جارية';

  @override
  String get noPastOrders => 'لا توجد طلبات سابقة';

  @override
  String orderNumber(String code) {
    return 'الطلب #$code';
  }

  @override
  String orderedAt(String date) {
    return 'طُلب في $date';
  }

  @override
  String get cancelOrder => 'إلغاء الطلب';

  @override
  String get cancelOrderConfirm => 'هل تريد إلغاء هذا الطلب؟';

  @override
  String get keepOrder => 'لا، احتفظ به';

  @override
  String get orderCancelledMsg => 'تم إلغاء الطلب';

  @override
  String rejectReasonLabel(String reason) {
    return 'السبب: $reason';
  }

  @override
  String get payInCash => 'المبلغ نقدًا';

  @override
  String get orderItems => 'طلبك';

  @override
  String get callRestaurant => 'اتصل بالمطعم';

  @override
  String get errRestaurantClosed => 'هذا المطعم مغلق حاليًا.';

  @override
  String get errRestaurantUnavailable => 'هذا المطعم لم يعد متاحًا.';

  @override
  String get errItemUnavailable => 'أحد الأطباق لم يعد متاحًا. تم تحديث سلتك.';

  @override
  String get errPricesChanged =>
      'تغيرت الأسعار. تم تحديث سلتك، تحقق من المجموع.';

  @override
  String get errTooManyActiveOrders =>
      'لديك 3 طلبات جارية بالفعل. انتظر حتى يتم توصيل أحدها.';

  @override
  String get errTooManyOrders => 'طلبات كثيرة في وقت قصير. حاول لاحقًا.';

  @override
  String get errAddressGone => 'هذا العنوان لم يعد موجودًا. اختر عنوانًا آخر.';

  @override
  String get errCannotCancel =>
      'قبل المطعم الطلب بالفعل، لم يعد بالإمكان إلغاؤه.';

  @override
  String tabNewOrders(int count) {
    return 'جديدة ($count)';
  }

  @override
  String tabInProgress(int count) {
    return 'قيد التنفيذ ($count)';
  }

  @override
  String get markReady => 'جاهز';

  @override
  String get waitingDriver => 'في انتظار السائق';

  @override
  String get rejectOrderTitle => 'رفض الطلب';

  @override
  String get cancelOrderTitleOwner => 'إلغاء الطلب';

  @override
  String get reasonLabel => 'السبب (يراه الزبون)';

  @override
  String get reasonBusy => 'طلبات كثيرة حاليًا';

  @override
  String get reasonItemOut => 'أحد الأطباق غير متوفر';

  @override
  String get reasonClosing => 'سنغلق قريبًا';

  @override
  String get reasonUnreachable => 'تعذّر الاتصال بالزبون';

  @override
  String get errReasonRequired => 'اذكر السبب.';

  @override
  String get errOrderChanged => 'تغيّر هذا الطلب في الأثناء. تم تحديث القائمة.';

  @override
  String get enableSoundAlerts =>
      'اضغط هنا لتفعيل التنبيه الصوتي للطلبات الجديدة';

  @override
  String get soundOn => 'التنبيه الصوتي مفعّل';

  @override
  String get soundOff => 'التنبيه الصوتي متوقف';

  @override
  String minutesAgo(int count) {
    return 'منذ $count د';
  }

  @override
  String get justNow => 'الآن';

  @override
  String get noNewOrders => 'لا توجد طلبات جديدة';

  @override
  String get noOrdersInProgress => 'لا توجد طلبات قيد التنفيذ';

  @override
  String get customer => 'الزبون';

  @override
  String get orderAcceptedMsg => 'تم قبول الطلب';

  @override
  String get orderReadyMsg => 'الطلب جاهز، في انتظار السائق';

  @override
  String get orderRejectedMsg => 'تم رفض الطلب';

  @override
  String newOrderBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count طلبات جديدة بانتظار القبول',
      one: 'طلب جديد بانتظار القبول',
    );
    return '$_temp0';
  }

  @override
  String get deliverWithUs => 'هل أنت سائق توصيل؟';

  @override
  String get joinAsDriver => 'انضم إلينا';

  @override
  String get registerDriverTitle => 'كن سائق توصيل';

  @override
  String get registerDriverSubtitle => 'وصّل الطلبات بالقرب منك';

  @override
  String get driverSection => 'السائق';

  @override
  String get driverPhone => 'الهاتف (محمول)';

  @override
  String get vehicle => 'المركبة';

  @override
  String get vehicleMoto => 'دراجة نارية';

  @override
  String get vehicleCar => 'سيارة';

  @override
  String get vehicleBike => 'دراجة';

  @override
  String get driverRegistered =>
      'تم إرسال التسجيل. سيقوم المسؤول بتفعيل حسابك.';

  @override
  String get driverPendingTitle => 'في انتظار التفعيل';

  @override
  String get driverPendingBody =>
      'يجب أن يفعّل المسؤول حسابك قبل أن تتمكن من التوصيل.';

  @override
  String get onlineLabel => 'متصل';

  @override
  String get offlineLabel => 'غير متصل';

  @override
  String get youAreOnline => 'أنت تستقبل الطلبات الجديدة.';

  @override
  String get youAreOffline => 'اتصل لتستقبل الطلبات.';

  @override
  String get availableOrders => 'الطلبات المتاحة';

  @override
  String get noAvailableOrders =>
      'لا توجد طلبات حاليًا. تتحدث القائمة تلقائيًا.';

  @override
  String get takeOrder => 'سآخذه';

  @override
  String get orderTaken => 'الطلب لك! توجه إلى المطعم.';

  @override
  String get errAlreadyTaken => 'أخذه سائق آخر قبلك.';

  @override
  String get errDriverBusy => 'أنهِ توصيلك الحالي أولًا.';

  @override
  String get errNotOnline => 'اتصل أولًا.';

  @override
  String get errNotApproved => 'لم يتم تفعيل حسابك بعد.';

  @override
  String get currentDelivery => 'التوصيل الحالي';

  @override
  String get pickupAt => 'الاستلام من';

  @override
  String get dropOffAt => 'التسليم إلى';

  @override
  String get cashToCollect => 'المبلغ المحصّل';

  @override
  String get yourFee => 'ربحك';

  @override
  String get handToRestaurant => 'يُسلَّم للمطعم';

  @override
  String get waitRestaurant => 'المطعم يحضّر الطلب. انتظر حتى يصبح جاهزًا.';

  @override
  String get markPickedUp => 'تم الاستلام';

  @override
  String get markDelivered => 'تم التسليم والدفع';

  @override
  String confirmDelivered(String total) {
    return 'تأكيد التسليم؟ دفع لك الزبون $total.';
  }

  @override
  String get confirm => 'تأكيد';

  @override
  String get releaseOrder => 'إرجاع الطلب';

  @override
  String get releaseConfirm => 'إرجاع هذا الطلب للسائقين الآخرين؟';

  @override
  String get callAction => 'اتصال';

  @override
  String get directions => 'الاتجاهات';

  @override
  String get deliveredMsg => 'تم التوصيل. شكرًا!';

  @override
  String get pickedUpMsg => 'في الطريق إلى الزبون';

  @override
  String get cancelledByRestaurant => 'ألغى المطعم هذا الطلب.';

  @override
  String todaySummary(int count, String amount) {
    return 'اليوم: $count توصيلات · $amount';
  }

  @override
  String get driversTitle => 'السائقون';

  @override
  String get noDrivers => 'لا يوجد سائقون';

  @override
  String currentOrderCode(String code) {
    return 'طلب جارٍ: #$code';
  }

  @override
  String get yourDriver => 'سائقك';

  @override
  String driverLabel(String name) {
    return 'السائق: $name';
  }

  @override
  String get myDeliveries => 'توصيلاتي';

  @override
  String get noDeliveries => 'لا توجد توصيلات';

  @override
  String get driverApproved => 'تم تفعيل الحساب';

  @override
  String get proofTitle => 'صورة التسليم';

  @override
  String get proofHint =>
      'التقط صورة للطلب عند تسليمه للزبون (أو أمام بابه). تُستخدم كدليل عند حدوث خلاف.';

  @override
  String get takePhoto => 'التقاط الصورة';

  @override
  String get retakePhoto => 'إعادة';

  @override
  String get errPhotoRequired => 'الصورة إلزامية لتأكيد التسليم.';

  @override
  String get errCashOverdue =>
      'لديك مال لم تسلّمه منذ مدة طويلة. يجب أن يؤكد المطعم الاستلام قبل أن تأخذ طلبات جديدة.';

  @override
  String get cashBlockedTitle => 'الطلبات الجديدة متوقفة';

  @override
  String get moneyToHand => 'مال يجب تسليمه للمطاعم';

  @override
  String moneyToHandTotal(String amount) {
    return 'المجموع للتسليم: $amount';
  }

  @override
  String get iGaveMoney => 'سلّمت المال';

  @override
  String get waitingRestaurantConfirm => 'في انتظار تأكيد المطعم';

  @override
  String get cashHandedMsg => 'تم. يجب أن يؤكد المطعم الاستلام.';

  @override
  String get cashToReceive => 'مال يجب استلامه من السائقين';

  @override
  String get confirmReceived => 'تم الاستلام';

  @override
  String confirmReceivedQ(String amount, String name) {
    return 'تأكيد استلام $amount من $name؟';
  }

  @override
  String get cashConfirmedMsg => 'تم تأكيد الاستلام';

  @override
  String get driverSaysHanded => 'يقول السائق إنه سلّمه';

  @override
  String get proofOfDelivery => 'إثبات التسليم';

  @override
  String cashOwedLine(String amount, int count) {
    return 'عليه $amount ($count طلبات)';
  }

  @override
  String get cashBlockedPill => 'محظور';

  @override
  String get cashStatusConfirmed => 'استلم المطعم المال';

  @override
  String get cashStatusHanded => 'سلّم السائق المال، بانتظار التأكيد';

  @override
  String get cashStatusPending => 'لم يُسلَّم المال للمطعم بعد';

  @override
  String deliveredOnTime(String date) {
    return 'سُلّم $date';
  }

  @override
  String get cashHoursSetting => 'حظر السائق بعد (ساعات دون تسليم)';

  @override
  String get errCashHours => 'بين 1 و168 ساعة';

  @override
  String get downloadReceipt => 'تحميل الإيصال';

  @override
  String get printAction => 'طباعة';

  @override
  String get receiptOrderTitle => 'إيصال الطلب';

  @override
  String get receiptOrderNo => 'الطلب';

  @override
  String get receiptDate => 'التاريخ';

  @override
  String get receiptDeliveredOn => 'سُلّمت في';

  @override
  String get receiptCustomer => 'الزبون';

  @override
  String get receiptItem => 'الصنف';

  @override
  String get receiptQty => 'الكمية';

  @override
  String get receiptUnit => 'سعر الوحدة';

  @override
  String get receiptAmount => 'المبلغ';

  @override
  String get receiptPaidCash => 'مدفوع نقدًا عند الاستلام';

  @override
  String get receiptDeliveredBy => 'سلّمه';

  @override
  String get receiptTotalPaid => 'المجموع المدفوع';

  @override
  String get receiptFooter =>
      'المبالغ بالدينار الجزائري. وثيقة صادرة عن التطبيق.';

  @override
  String get receiptPage => 'صفحة';

  @override
  String get taxIdShort => 'الرقم الجبائي';

  @override
  String get driverStatementTitle => 'كشف السائق';

  @override
  String get downloadStatement => 'تحميل الكشف';

  @override
  String get periodThisWeek => 'هذا الأسبوع';

  @override
  String get periodLastWeek => 'الأسبوع الماضي';

  @override
  String get stDeliveries => 'التوصيلات';

  @override
  String get stCollected => 'المحصّل';

  @override
  String get stToRestaurant => 'للمطعم';

  @override
  String get stFee => 'الربح';

  @override
  String get stMoney => 'المال';

  @override
  String get stConfirmed => 'سُلّم';

  @override
  String get stOpen => 'للتسليم';

  @override
  String get stTotalCollected => 'مجموع المحصّل';

  @override
  String get stTotalToRestaurants => 'المستحق للمطاعم';

  @override
  String get stStillToGive => 'المتبقي للتسليم';

  @override
  String get stEarned => 'أرباحك';

  @override
  String get stDriver => 'السائق';

  @override
  String get noDeliveriesInPeriod => 'لا توجد توصيلات في هذه الفترة';

  @override
  String get myStatements => 'كشوف العمولة';

  @override
  String get chooseFromGallery => 'اختيار من المعرض';

  @override
  String get errCamera =>
      'تعذّر فتح الكاميرا. اسمح باستخدام الكاميرا من الإعدادات، أو اختر صورة من المعرض.';

  @override
  String get reasonNoAnswer => 'لم يرد المطعم في الوقت المحدد';

  @override
  String get autoRejectSetting => 'رفض تلقائي إذا لم يرد المطعم (دقائق)';

  @override
  String get errAutoReject => 'بين 3 و60 دقيقة';

  @override
  String get deleteAccount => 'حذف حسابي';

  @override
  String get deleteAccountConfirm =>
      'حذف حسابك نهائيًا؟ سيتم مسح عناوينك وصورتك. تبقى طلباتك السابقة مجهولة الهوية للمحاسبة.';

  @override
  String get accountDeleted => 'تم حذف الحساب';

  @override
  String get errDeleteActiveOrders => 'لديك طلب جارٍ. حاول مجددًا بعد توصيله.';

  @override
  String get errDeleteNotCustomer =>
      'حسابات المطاعم والسائقين يغلقها المسؤول. تواصل معه.';

  @override
  String get locationServiceOff => 'خدمة الموقع في الهاتف متوقفة.';

  @override
  String get locationBlocked =>
      'تم رفض الموقع لهذا التطبيق. اسمح به من الإعدادات.';

  @override
  String get locationUnavailable =>
      'تعذّر تحديد موقعك. حاول في الخارج أو ابحث عن عنوانك في الخريطة.';

  @override
  String get turnOn => 'تفعيل';

  @override
  String get openSettings => 'الإعدادات';

  @override
  String get searchAddressHint => 'ابحث عن عنوان أو حي…';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navAccount => 'الحساب';

  @override
  String get viewProfile => 'عرض الملف الشخصي';

  @override
  String get general => 'عام';

  @override
  String get helpCenter => 'مركز المساعدة';

  @override
  String get supportSoon => 'رقم خدمة العملاء سيتوفر قريبًا.';

  @override
  String get becomePartner => 'سجّل مطعمك';

  @override
  String get becomeDriver => 'كن سائق توصيل';

  @override
  String get termsTitle => 'الشروط والخصوصية';

  @override
  String get appVersion => 'الإصدار';

  @override
  String get promoCashTitle => 'ادفع عند الاستلام';

  @override
  String get promoCashBody => 'نقدًا عند وصول طلبك. بدون بطاقة.';

  @override
  String promoFeeTitle(String fee) {
    return 'التوصيل $fee';
  }

  @override
  String get promoFeeBody => 'نفس السعر في كل المدينة.';

  @override
  String get promoDiscover => 'مفتوح الآن · اطلب ←';

  @override
  String get termsOrdersTitle => 'الطلبات والدفع';

  @override
  String get termsOrdersBody =>
      'الأسعار هي أسعار المطعم وقت الطلب. تدفع نقدًا عند الاستلام (الأطباق + رسوم التوصيل). يمكن إلغاء الطلب ما دام المطعم لم يقبله.';

  @override
  String get termsDataTitle => 'بياناتك';

  @override
  String get termsDataBody =>
      'نستعمل اسمك وهاتفك وعنوانك فقط لتوصيل طلباتك. يراها المطعم والسائق لطلبك. تُلتقط صورة عند التسليم كدليل.';

  @override
  String get termsDeleteTitle => 'حذف حسابك';

  @override
  String get termsDeleteBody =>
      'الحساب ← حذف حسابي. تُمسح عناوينك وصورتك؛ تبقى طلباتك السابقة مجهولة الهوية للمحاسبة.';

  @override
  String get openNowTitle => 'مفتوحة الآن';

  @override
  String get homeBanners => 'لافتات الصفحة الرئيسية';

  @override
  String get addBanner => 'إضافة لافتة';

  @override
  String get noBanners =>
      'لا توجد لافتات. أضف صورًا (إعلانات، أخبار): تظهر متحركة أعلى الصفحة الرئيسية للزبائن.';

  @override
  String get bannerSizeHint => 'المقاس المنصوح به: 1200 × 500 بكسل.';

  @override
  String get choosePicture => 'اختيار صورة';

  @override
  String get bannerTitle => 'العنوان';

  @override
  String get bannerOpens => 'عند اللمس، افتح';

  @override
  String get bannerNoLink => 'لا شيء (صورة فقط)';

  @override
  String get deleteBannerConfirm => 'حذف هذه اللافتة؟';

  @override
  String get moveUp => 'إلى الأعلى';

  @override
  String get moveDown => 'إلى الأسفل';

  @override
  String get appearance => 'المظهر';

  @override
  String get themeSystem => 'تلقائي (حسب الهاتف)';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get insights => 'الإحصائيات';

  @override
  String get todayTitle => 'اليوم';

  @override
  String get compareYesterday => 'مقارنة بالأمس في نفس الساعة';

  @override
  String get kpiSales => 'المبيعات';

  @override
  String get kpiOrders => 'الطلبات';

  @override
  String get kpiAvgBasket => 'متوسط السلة';

  @override
  String get kpiPrep => 'متوسط التحضير';

  @override
  String get kpiAcceptance => 'نسبة القبول';

  @override
  String get kpiNet => 'الصافي بعد العمولة';

  @override
  String minutesShort(int n) {
    return '$n د';
  }

  @override
  String get last7Days => 'آخر 7 أيام';

  @override
  String get seeInsights => 'عرض الإحصائيات';

  @override
  String get shortcuts => 'اختصارات';

  @override
  String get ordersTable => 'جدول الطلبات';

  @override
  String get liveOrders => 'الطلبات المباشرة';

  @override
  String dishesNoPhoto(int n) {
    return '$n أطباق بدون صورة: الصور تزيد المبيعات';
  }

  @override
  String dishesUnavailable(int n) {
    return '$n أطباق غير متوفرة';
  }

  @override
  String get menuHealthGood => 'القائمة مكتملة، أحسنت!';

  @override
  String get rangeYesterday => 'أمس';

  @override
  String get range7 => '7 أيام';

  @override
  String get range30 => '30 يومًا';

  @override
  String get range90 => '90 يومًا';

  @override
  String get rangeMonth => 'هذا الشهر';

  @override
  String get rangeCustom => 'تواريخ…';

  @override
  String get filterAll => 'الكل';

  @override
  String get filterInProgress => 'قيد التنفيذ';

  @override
  String get searchOrdersHint => 'الرمز، الزبون، الطبق…';

  @override
  String get exportCsv => 'تصدير CSV';

  @override
  String get csvReady => 'ملف CSV جاهز';

  @override
  String get noOrdersPeriod => 'لا توجد طلبات في هذه الفترة';

  @override
  String get tableTotals => 'مجموع التحديد';

  @override
  String get csvCode => 'الرمز';

  @override
  String get csvDate => 'التاريخ';

  @override
  String get csvTime => 'الساعة';

  @override
  String get csvStatus => 'الحالة';

  @override
  String get csvCustomer => 'الزبون';

  @override
  String get csvArea => 'الحي';

  @override
  String get csvItems => 'الأصناف';

  @override
  String get csvItemCount => 'عدد الأصناف';

  @override
  String get csvFood => 'الأطباق (دج)';

  @override
  String get csvDeliveryFee => 'التوصيل (دج)';

  @override
  String get csvTotal => 'المجموع (دج)';

  @override
  String get csvCommission => 'العمولة (دج)';

  @override
  String get csvNet => 'الصافي (دج)';

  @override
  String get csvDriver => 'السائق';

  @override
  String get csvPrepMinutes => 'التحضير (د)';

  @override
  String get csvReason => 'السبب';

  @override
  String comparedPrevious(int n) {
    return 'مقارنة بالـ $n يومًا السابقة';
  }

  @override
  String get salesChartTitle => 'المبيعات اليومية';

  @override
  String get tapBarHint => 'المس عمودًا لرؤية التفاصيل';

  @override
  String get hoursChartTitle => 'ساعات الذروة';

  @override
  String get weekdayChartTitle => 'أيام الأسبوع';

  @override
  String get topDishesTitle => 'الأطباق الأكثر مبيعًا';

  @override
  String get outcomesTitle => 'مآل الطلبات';

  @override
  String soldTimes(int n) {
    return '$n مبيعة';
  }

  @override
  String get tipsTitle => 'نصائح لزيادة المبيعات';

  @override
  String tipSalesUp(int n) {
    return 'ارتفعت مبيعاتك بنسبة $n% مقارنة بالفترة السابقة. واصل!';
  }

  @override
  String tipSalesDown(int n) {
    return 'انخفضت المبيعات بنسبة $n%. راجع أوقات العمل وأضف صورًا لأطباقك.';
  }

  @override
  String tipRefusals(int n, String amount) {
    return '$n طلبات مرفوضة أو بلا رد: $amount مبيعات ضائعة. أغلق المطعم عندما لا تستطيع الخدمة.';
  }

  @override
  String tipSlowResponse(int n) {
    return 'تستغرق $n د في المتوسط لقبول الطلب. الزبائن ينتظرون، والطلب بلا رد يُرفض تلقائيًا.';
  }

  @override
  String tipSlowPrep(int n, int announced) {
    return 'يستغرق التحضير $n د بينما تعلن $announced د. حدّث الوقت في ملفك أو سرّع التحضير.';
  }

  @override
  String tipPeakHour(String hour, int share) {
    return 'ساعة الذروة: $hour ($share% من الطلبات). جهّز المكونات مسبقًا.';
  }

  @override
  String tipTopDish(String dish, int share) {
    return '«$dish» يمثل $share% من مبيعاتك. اجعله متوفرًا دائمًا مع صورة جميلة.';
  }

  @override
  String tipQuietDay(String day) {
    return '$day هو أهدأ أيامك: وقت مناسب لعرض أو طبق جديد.';
  }

  @override
  String get tipNoOrders =>
      'لا توجد طلبات بعد في هذه الفترة. افتح في أوقات الوجبات وأكمل قائمتك بالصور.';

  @override
  String get myBusiness => 'نشاطي';

  @override
  String get accountApproved => 'معتمد';

  @override
  String get accountPending => 'قيد المراجعة';

  @override
  String get deleteRestaurantConfirm =>
      'سيتم حذف حسابك وإزالة مطعمك من التطبيق. تبقى طلباتك وكشوفك محفوظة للمحاسبة. هذا الإجراء نهائي.';

  @override
  String get errDeleteCashPending => 'أكّد أولًا استلام المال من السائقين.';

  @override
  String get errDeleteUnpaidCommission =>
      'هناك عمولات غير مسددة. تواصل مع الإدارة.';

  @override
  String get restaurantDetailsHint => 'الصور، العنوان، الهاتف، وقت التحضير';

  @override
  String get outlets => 'الفروع';

  @override
  String get roleOwner => 'المالك';

  @override
  String get roleManager => 'المسير';

  @override
  String get roleStaff => 'موظف';

  @override
  String get csvOutlet => 'الفرع';

  @override
  String get portalTitle => 'بوابة الشركاء';

  @override
  String get portalTagline => 'أدر مطاعمك وطلباتك ومبيعاتك من مكان واحد.';

  @override
  String get portalLoginTitle => 'الدخول إلى بوابة الشركاء';

  @override
  String get portalNotPartner =>
      'هذه البوابة مخصصة للمطاعم الشريكة. سجّل مطعمك أولًا في التطبيق.';

  @override
  String get navReports => 'التقارير';

  @override
  String get navInvoices => 'الفواتير';

  @override
  String get navMenu => 'إدارة القائمة';

  @override
  String get navHours => 'أوقات العمل';

  @override
  String get navReviews => 'التقييمات';

  @override
  String get navMarketing => 'التسويق';

  @override
  String get navNotifications => 'مركز الإشعارات';

  @override
  String get navTeam => 'الفريق';

  @override
  String get soon => 'قريبًا';

  @override
  String get comingSoonTitle => 'قريبًا';

  @override
  String get comingSoonBody =>
      'هذا القسم سيأتي في المرحلة القادمة. في الأثناء استعمل التطبيق.';

  @override
  String get outletsAll => 'كل الفروع';

  @override
  String outletsCount(int n, int total) {
    return '$n/$total فروع';
  }

  @override
  String get dashboardSubtitle => 'نظرة عامة على طلباتك وفروعك';

  @override
  String get ordersToday => 'طلبات اليوم';

  @override
  String get cancelledToday => 'ملغاة أو مرفوضة اليوم';

  @override
  String get closedOutletsNow => 'فروع مغلقة الآن';

  @override
  String get salesToday => 'مبيعات اليوم';

  @override
  String updatedAt(String time) {
    return 'آخر تحديث $time';
  }

  @override
  String get businessSummary => 'ملخص النشاط';

  @override
  String get thisWeek => 'هذا الأسبوع';

  @override
  String get lastWeek => 'الأسبوع الماضي';

  @override
  String get comparison => 'مقارنة';

  @override
  String get previousPeriod => 'الفترة السابقة';

  @override
  String get totalLabel => 'المجموع';

  @override
  String get cancelledLabel => 'ملغاة';

  @override
  String get waitingOrders => 'بانتظار ردك';

  @override
  String get noWaitingOrders => 'لا توجد طلبات في الانتظار.';

  @override
  String get ordersSubtitle => 'تفاصيل الطلبات في الوقت الحقيقي';

  @override
  String get placedAtCol => 'وقت الطلب';

  @override
  String acceptedIn(String time) {
    return 'قُبل خلال $time';
  }

  @override
  String get orderDetailsTitle => 'تفاصيل الطلب';

  @override
  String secondsShort(int n) {
    return '$n ث';
  }

  @override
  String get reportsSubtitle => 'حلّل أداءك';

  @override
  String get tabSales => 'المبيعات';

  @override
  String get tabOperations => 'العمليات';

  @override
  String get tabCustomers => 'الزبائن';

  @override
  String get previousMonth => 'الشهر الماضي';

  @override
  String get salesByDayHint =>
      'المبيعات والطلبات يوميًا: هل نشاطك في صعود أم هبوط؟';

  @override
  String get downloadReport => 'تحميل التقرير';

  @override
  String get salesByHour => 'المبيعات حسب الساعة';

  @override
  String get salesByHourHint =>
      'المبيعات حسب الساعة واليوم: ساعاتك الهادئة والمزدحمة.';

  @override
  String get avgResponse => 'متوسط وقت القبول';

  @override
  String get cancellationRate => 'نسبة الإلغاء';

  @override
  String get lostSales => 'مبيعات ضائعة';

  @override
  String get refusalReasons => 'الرفض والإلغاء حسب السبب';

  @override
  String get prepByDay => 'وقت التحضير حسب اليوم';

  @override
  String get newVsReturning => 'زبائن جدد مقابل زبائن عائدين';

  @override
  String get newVsReturningHint =>
      'نسبة الطلبات من زبائن جدد ومن زبائن يعودون.';

  @override
  String get ordersFromNew => 'طلبات من زبائن جدد';

  @override
  String get ordersFromReturning => 'طلبات من زبائن عائدين';

  @override
  String get moreReturningTitle => 'تريد زبائن أوفياء أكثر؟';

  @override
  String get moreReturningBody =>
      'يعود الزبائن للجودة والسرعة: اجعل أفضل أطباقك متوفرة، ورد بسرعة، وأعلن أوقات تحضير صادقة.';

  @override
  String get moreNewTitle => 'تريد زبائن جدد أكثر؟';

  @override
  String get moreNewBody =>
      'الصور الجميلة والأوصاف الكاملة تشجع على التجربة. لافتة في الصفحة الرئيسية (اطلبها من الإدارة) تعرّف بك للجميع.';

  @override
  String get topAreas => 'أهم الأحياء';

  @override
  String get uniqueCustomers => 'الزبائن';

  @override
  String get invoicesSubtitle => 'حمّل كشوف العمولة';

  @override
  String get noInvoices => 'لا توجد فواتير بعد';

  @override
  String get outletsSubtitle => 'مطاعمك وحالتها ودورك فيها';

  @override
  String get addOutlet => 'إضافة فرع';

  @override
  String get outletAdded => 'تمت إضافة الفرع. سيظهر بعد موافقة الإدارة.';

  @override
  String yourRole(String role) {
    return 'دورك: $role';
  }

  @override
  String get teamSubtitle => 'امنح فريقك حسابات خاصة بصلاحيات مناسبة';

  @override
  String get addMember => 'إضافة عضو';

  @override
  String get memberEmail => 'البريد الإلكتروني للحساب';

  @override
  String get memberEmailHint =>
      'يجب على الشخص أولًا إنشاء حساب في التطبيق بهذا البريد.';

  @override
  String get roleOwnerDesc => 'كل شيء، بما في ذلك الفريق وإغلاق الحساب';

  @override
  String get roleManagerDesc =>
      'الطلبات، القائمة، المعلومات، التقارير والفواتير';

  @override
  String get roleStaffDesc => 'الطلبات فقط: قبول، رفض، جاهز، استلام المال';

  @override
  String get removeMember => 'إزالة';

  @override
  String removeMemberConfirm(String name) {
    return 'إزالة $name من هذا الفرع؟';
  }

  @override
  String get memberAdded => 'تمت إضافة العضو';

  @override
  String get errUserNotFound =>
      'لا يوجد حساب بهذا البريد. اطلب منه التسجيل أولًا في التطبيق.';

  @override
  String get errOtherRole =>
      'هذا الحساب لسائق أو مدير ولا يمكنه الانضمام إلى مطعم.';

  @override
  String get errAlreadyMember => 'موجود بالفعل في الفريق.';

  @override
  String get errLastOwner => 'يجب أن يبقى للفرع مالك واحد على الأقل.';

  @override
  String get onlyOwnersTeam => 'المالكون فقط يمكنهم تعديل الفريق.';

  @override
  String get colName => 'الاسم';

  @override
  String get colEmail => 'البريد';

  @override
  String get colRole => 'الدور';

  @override
  String get colSince => 'منذ';

  @override
  String get portalStaffOnly =>
      'حسابك كموظف يعمل في التطبيق. اطلب من المالك صلاحية مسير لاستعمال البوابة.';

  @override
  String get errOptionsChanged => 'تغيّرت خيارات هذا الطبق. اخترها من جديد.';

  @override
  String chooseUpTo(int n) {
    return 'حتى $n اختيارات';
  }

  @override
  String get optionRequired => 'إجباري';

  @override
  String get outOfStock => 'نفدت الكمية';

  @override
  String opensTodayAt(String time) {
    return 'مغلق · يفتح اليوم على $time';
  }

  @override
  String opensTomorrowAt(String time) {
    return 'مغلق · يفتح غدًا على $time';
  }

  @override
  String opensOnAt(String day, String time) {
    return 'مغلق · يفتح $day على $time';
  }

  @override
  String get menuSubtitle => 'الأطباق والأسعار والصور والخيارات';

  @override
  String get addOptionGroup => 'إضافة مجموعة خيارات';

  @override
  String get editOptionGroup => 'تعديل مجموعة الخيارات';

  @override
  String get dishesTab => 'الأطباق';

  @override
  String get optionGroupsTab => 'مجموعات الخيارات';

  @override
  String get searchDishesHint => 'ابحث عن طبق…';

  @override
  String bulkDone(int n) {
    return 'تم تعديل $n أطباق';
  }

  @override
  String bulkDeleteConfirm(int n) {
    return 'حذف $n أطباق؟ هذا نهائي.';
  }

  @override
  String selectedCount(int n) {
    return '$n محدد';
  }

  @override
  String get bulkShow => 'إتاحة';

  @override
  String get bulkHide => 'إخفاء';

  @override
  String get bulkPrices => 'تعديل الأسعار';

  @override
  String get priceIncrease => 'زيادة';

  @override
  String get priceDecrease => 'تخفيض';

  @override
  String get pricesRounded => 'تُقرّب الأسعار الجديدة إلى 10 دج.';

  @override
  String get apply => 'تطبيق';

  @override
  String get uploadDishPhoto => 'إضافة صورة للطبق';

  @override
  String get photosSellHint => 'الأطباق ذات الصور الجميلة تُباع أكثر.';

  @override
  String get noOptionGroupsHint =>
      'أنشئ أولًا مجموعات خيارات (أحجام، إضافات) في تبويب مجموعات الخيارات.';

  @override
  String get optionGroupsPickHint => 'اختر الخيارات المعروضة مع هذا الطبق.';

  @override
  String get noOptionGroups =>
      'لا توجد مجموعات خيارات. أنشئ مثلًا «الحجم» (صغير، كبير) أو «إضافات» (جبن، بيض).';

  @override
  String get ruleRequiredOne => 'إجباري · اختيار واحد';

  @override
  String ruleRequiredRange(int min, int max) {
    return 'إجباري · من $min إلى $max';
  }

  @override
  String ruleOptionalUpTo(int max) {
    return 'اختياري · حتى $max';
  }

  @override
  String deleteGroupConfirm(String name) {
    return 'حذف المجموعة «$name»؟ ستُزال من كل الأطباق.';
  }

  @override
  String get free => 'مجاني';

  @override
  String get usedByNoDish => 'غير مستعمل في أي طبق';

  @override
  String usedBy(String names) {
    return 'مستعمل في: $names';
  }

  @override
  String get groupName => 'اسم المجموعة';

  @override
  String get groupNameHint => 'مثال: الحجم، الصلصة، الإضافات';

  @override
  String get requiredHint => 'يجب على الزبون الاختيار قبل الطلب';

  @override
  String get minChoices => 'أقل عدد اختيارات';

  @override
  String get maxChoices => 'أكثر عدد اختيارات';

  @override
  String get choices => 'الاختيارات';

  @override
  String get choiceNameHint => 'مثال: كبير';

  @override
  String get extraPriceHint => 'سعر إضافي';

  @override
  String get addChoice => 'إضافة اختيار';

  @override
  String get dishesUsingGroup => 'الأطباق التي تعرض هذه الخيارات';

  @override
  String get errGroupRule =>
      'يجب أن يكون عدد الاختيارات على الأقل مساويًا للحد الأدنى.';

  @override
  String get hoursSubtitle => 'أوقات العمل والعطل والأوقات الخاصة';

  @override
  String get weeklyHours => 'أوقات العمل';

  @override
  String get specialDays => 'العطل والأوقات الخاصة';

  @override
  String get openNowLabel => 'مفتوح الآن';

  @override
  String get closedNowLabel => 'مغلق الآن';

  @override
  String get switchOffHint => 'الطلبات متوقفة بالزر';

  @override
  String get takingOrders => 'يمكن للزبائن الطلب';

  @override
  String get ordersSwitch => 'استقبال الطلبات';

  @override
  String get weeklyHoursHint =>
      'لا يمكن للزبائن الطلب إلا في هذه الأوقات (والزر مفعل). بدون أوقات: مفتوح ما دام الزر مفعلًا.';

  @override
  String get closedAllDay => 'مغلق طوال اليوم';

  @override
  String get addHours => 'إضافة أوقات';

  @override
  String get copyToAllDays => 'نسخ لكل الأيام';

  @override
  String get specialDaysHint =>
      'العطل، العيد، رمضان… هذه التواريخ تعوض الأوقات العادية.';

  @override
  String get addSpecialDay => 'إضافة تاريخ';

  @override
  String get noSpecialDays => 'لا توجد تواريخ قادمة';

  @override
  String get pickDate => 'اختر التاريخ';

  @override
  String get opensLabel => 'يفتح';

  @override
  String get closesLabel => 'يغلق';

  @override
  String get specialDayNote => 'ملاحظة';

  @override
  String get specialDayNoteHint => 'مثال: عيد الفطر';

  @override
  String get rateDriverTitle => 'كيف كان التوصيل؟';

  @override
  String get rateFoodTitle => 'كيف كانت الوجبة؟';

  @override
  String get ratingWhatWrong => 'ما المشكلة؟';

  @override
  String get ratingCommentHint => 'أضف تعليقًا (اختياري)';

  @override
  String get ratingSubmit => 'إرسال تقييمي';

  @override
  String get ratingLater => 'لاحقًا';

  @override
  String get ratingThanks => 'شكرًا على تقييمك!';

  @override
  String get ratingWord1 => 'سيئ جدًا';

  @override
  String get ratingWord2 => 'سيئ';

  @override
  String get ratingWord3 => 'مقبول';

  @override
  String get ratingWord4 => 'جيد';

  @override
  String get ratingWord5 => 'ممتاز';

  @override
  String get errRatingClosed => 'انتهت مدة التقييم (7 أيام).';

  @override
  String get errRatingLocked => 'لا يمكن تعديل هذا التقييم بعد الآن.';

  @override
  String get rateFoodCard => 'قيّم الوجبة';

  @override
  String get rateDriverCard => 'قيّم التوصيل';

  @override
  String ratingDaysLeft(int n) {
    return 'متبقي $n أيام للتقييم';
  }

  @override
  String get ratingLastDay => 'آخر يوم للتقييم';

  @override
  String get yourRating => 'تقييمك';

  @override
  String get rateAction => 'قيّم';

  @override
  String get editRating => 'تعديل';

  @override
  String get ratingEditHint => 'قابل للتعديل لمدة 24 ساعة';

  @override
  String get ratingReplyFrom => 'رد المطعم';

  @override
  String get errAccountBlocked => 'حسابك موقوف. تواصل مع الدعم.';

  @override
  String get rsnCold => 'الأكل بارد';

  @override
  String get rsnMissingItem => 'صنف ناقص';

  @override
  String get rsnWrongOrder => 'طلب خاطئ';

  @override
  String get rsnSmallPortion => 'الكمية صغيرة';

  @override
  String get rsnBadTaste => 'الطعم سيئ';

  @override
  String get rsnBadPackaging => 'التغليف سيئ';

  @override
  String get rsnLate => 'متأخر';

  @override
  String get rsnRude => 'سلوك سيئ';

  @override
  String get rsnCareless => 'إهمال في التسليم';

  @override
  String get rsnNoContact => 'لا يرد على الهاتف';

  @override
  String get rsnWrongPlace => 'مكان خاطئ';

  @override
  String get rsnFakeOrder => 'طلب وهمي';

  @override
  String get rsnNoAnswer => 'لا يرد';

  @override
  String get rsnWrongAddress => 'عنوان غير صحيح';

  @override
  String get rsnRefusedToPay => 'رفض الدفع';

  @override
  String get rsnOther => 'أخرى';

  @override
  String get reviewsTitle => 'التقييمات';

  @override
  String get newRestaurant => 'جديد';

  @override
  String get noReviewsYet => 'لا توجد تقييمات بعد';

  @override
  String get restaurantReply => 'رد المطعم';

  @override
  String get seeMoreReviews => 'عرض المزيد';

  @override
  String ratingsCount(int n) {
    return '$n تقييمات';
  }

  @override
  String get reviewsSubtitle => 'ما يقوله زبائنك عن أطباقك';

  @override
  String get averageRating => 'متوسط التقييم';

  @override
  String get ratingDistribution => 'توزيع التقييمات';

  @override
  String get topComplaints => 'أكثر المشاكل ذكرًا';

  @override
  String get filterNeedsReply => 'بدون رد';

  @override
  String starsFilter(int n) {
    return '$n نجوم';
  }

  @override
  String get replyAction => 'رد';

  @override
  String get replyDialogHint => 'ردك علني ولا يمكن تعديله لاحقًا.';

  @override
  String get replyHint => 'شكرًا، نأمل رؤيتك مجددًا…';

  @override
  String get sendReply => 'نشر الرد';

  @override
  String get replyPublished => 'تم نشر الرد';

  @override
  String get flagReview => 'الإبلاغ عن هذا التقييم';

  @override
  String get flagReviewHint =>
      'اشرح السبب (إهانة، لا يخص طعامك، مطعم خاطئ…). ستقرر الإدارة.';

  @override
  String get flagSend => 'إرسال';

  @override
  String get flagSent => 'تم الإرسال إلى الإدارة';

  @override
  String get flagWaiting => 'بانتظار الإدارة';

  @override
  String get flagKept => 'أبقت الإدارة على هذا التقييم';

  @override
  String get errAlreadyReplied => 'هذا التقييم له رد بالفعل.';

  @override
  String get errAlreadyFlagged => 'تم الإبلاغ بالفعل.';

  @override
  String get noReviewsPeriod => 'لا توجد تقييمات في هذه الفترة';

  @override
  String reviewOrderRef(String code) {
    return 'الطلب #$code';
  }

  @override
  String get myRating => 'تقييمي';

  @override
  String get driverRatingHint => 'يظهر متوسطك بعد 5 تقييمات.';

  @override
  String get driverReasonsTitle => 'ما ذكره الزبائن';

  @override
  String get reportCustomer => 'الإبلاغ عن هذا الزبون';

  @override
  String get reportCustomerHint =>
      'الإدارة فقط ترى هذا البلاغ. لن يعرف الزبون.';

  @override
  String get reportNoteHint => 'تفاصيل (اختياري)';

  @override
  String get reportSend => 'إرسال';

  @override
  String get reportSent => 'تم إرسال البلاغ إلى الإدارة';

  @override
  String get reportedLabel => 'تم الإبلاغ';

  @override
  String get errAlreadyReported => 'لقد أبلغت عن هذا الطلب بالفعل.';

  @override
  String get errTooManyReports => 'عدد كبير من البلاغات اليوم.';

  @override
  String get errCustomerGone => 'لم يعد لهذا الزبون حساب.';

  @override
  String get navRatings => 'التقييمات';

  @override
  String get adminRatingsTitle => 'التقييمات والبلاغات';

  @override
  String get tabFlagged => 'تقييمات مُبلَّغ عنها';

  @override
  String get tabReports => 'بلاغات الزبائن';

  @override
  String get avg30d => 'آخر 30 يومًا';

  @override
  String get low30d => 'تقييمات ≤ 2 (30 يوم)';

  @override
  String get hideReview => 'إخفاء';

  @override
  String get keepReview => 'إبقاء';

  @override
  String get decisionHidden => 'مخفي';

  @override
  String get decisionKept => 'مُبقى';

  @override
  String get flaggedReason => 'سبب البلاغ';

  @override
  String get noFlagged => 'لا توجد تقييمات مُبلَّغ عنها';

  @override
  String get noReports => 'لا توجد بلاغات';

  @override
  String get reportOpen => 'قيد المعالجة';

  @override
  String get reportWarned => 'تم التنبيه';

  @override
  String get reportBlocked => 'محظور';

  @override
  String get reportDismissed => 'مُغلق';

  @override
  String get actionWarn => 'تنبيه';

  @override
  String get actionBlock => 'حظر الزبون';

  @override
  String get actionUnblock => 'إلغاء الحظر';

  @override
  String get actionDismiss => 'إغلاق دون إجراء';

  @override
  String get adminNoteHint => 'ملاحظة داخلية (اختياري)';

  @override
  String customerReportsCount(int n) {
    return '$n بلاغات عن هذا الزبون';
  }

  @override
  String get reportedByRestaurant => 'أبلغ عنه المطعم';

  @override
  String get reportedByDriver => 'أبلغ عنه السائق';

  @override
  String get customerBlockedNote => 'زبون محظور: لا يمكنه الطلب';

  @override
  String get rangeDaysSuffix => 'يومًا';

  @override
  String get riderReadyTitle => 'جاهز للانطلاق؟';

  @override
  String get riderReadySub => 'اتصل بالخدمة لتستقبل الطلبات';

  @override
  String get riderModeTitle => 'وصّل الطلبات من حولك';

  @override
  String get riderModeBody =>
      'استلم الطلبات من المطاعم القريبة ووصّلها. رسوم التوصيل لك.';

  @override
  String get startRiding => 'ابدأ';

  @override
  String get doneForToday => 'انتهيت لهذا اليوم';

  @override
  String get statDeliveries => 'التوصيلات';

  @override
  String get statEarnings => 'أرباح اليوم';

  @override
  String get jobsNearYou => 'طلبات قريبة منك';

  @override
  String get continueDelivery => 'متابعة التوصيل';

  @override
  String get stepToRestaurant => 'في الطريق إلى المطعم';

  @override
  String get stepReady => 'الطلب جاهز';

  @override
  String get stepReadySub => 'تحقق من كل صنف قبل الانطلاق';

  @override
  String get checkItems => 'تحقق من الأصناف';

  @override
  String get checkItemsTitle => 'تحقق من كل صنف';

  @override
  String get checkItemsHint => 'المس كل صنف بعد وضعه في الكيس.';

  @override
  String get headToCustomer => 'تم الاستلام، انطلق!';

  @override
  String get stepToCustomer => 'في الطريق إلى الزبون';

  @override
  String get stepArrived => 'لقد وصلت';

  @override
  String collectCash(String amount) {
    return 'استلم $amount';
  }

  @override
  String get statDistance => 'المسافة';

  @override
  String get statItems => 'الأصناف';

  @override
  String get statCash => 'للتحصيل';

  @override
  String wellDone(String name) {
    return 'أحسنت يا $name!';
  }

  @override
  String deliveryNumber(String code) {
    return 'التوصيل #$code';
  }

  @override
  String youEarned(String amount) {
    return '+$amount أرباح';
  }

  @override
  String get readyNextJob => 'جاهز للطلب التالي؟';

  @override
  String get nextJob => 'الطلب التالي';

  @override
  String get checkIn => 'وصلت إلى المطعم';

  @override
  String get atRestaurant => 'أنت في المطعم';

  @override
  String get missingItemCall => 'صنف ناقص أو خاطئ؟ اتصل بالمطعم';

  @override
  String get recenterMap => 'إعادة التمركز';

  @override
  String get followRider => 'تابع السائق';

  @override
  String riderUpdatedAt(String time) {
    return 'الموقع على الساعة $time';
  }

  @override
  String riderKmAway(String km) {
    return 'على بعد $km كم منك';
  }

  @override
  String get riderEditProfile => 'تعديل ملفي';

  @override
  String get riderEditHint => 'الاسم، الهاتف، المركبة والصورة';

  @override
  String riderSince(String date) {
    return 'سائق منذ $date';
  }

  @override
  String get levelRookie => 'مبتدئ';

  @override
  String get levelPro => 'محترف';

  @override
  String get levelExpert => 'خبير';

  @override
  String get levelLegend => 'أسطورة';

  @override
  String levelLabel(String level) {
    return 'مستوى $level';
  }

  @override
  String levelNext(int n, String level) {
    return 'باقي $n توصيلة لتصبح $level';
  }

  @override
  String levelNeedsRating(String stars, String level) {
    return 'حافظ على $stars نجوم على الأقل لتصبح $level';
  }

  @override
  String get levelTop => 'وصلت لأعلى مستوى، أحسنت!';

  @override
  String get statTotalDeliveries => 'توصيلات';

  @override
  String get statTotalEarned => 'الأرباح';

  @override
  String get statRating => 'التقييم';

  @override
  String get ratingDetails => 'عرض التفاصيل';

  @override
  String get allTime => 'منذ البداية';

  @override
  String fiveStarStreak(int n) {
    return '$n تقييمات بـ5 نجوم متتالية';
  }

  @override
  String get coachTitle => 'نصائح للتحسن';

  @override
  String get coachLate => 'اختر طلبات قريبة منك وانطلق فور جاهزية الطلب.';

  @override
  String get coachRude => 'تحية وابتسامة تصنعان الفرق.';

  @override
  String get coachCareless => 'حافظ على الكيس مستويًا والمشروبات واقفة.';

  @override
  String get coachNoContact => 'اتصل بالزبون قبل وصولك بدقيقتين.';

  @override
  String get coachWrongPlace =>
      'تحقق من الموقع على الخريطة والطابق قبل الانطلاق.';

  @override
  String get coachAllGood => 'لا توجد أي مشكلة. واصل هكذا!';

  @override
  String get ratingPrivateNote =>
      'يقيّم الزبائن التوصيل بشكل خاص: ترى الأرقام فقط، دون معرفة من قيّم.';

  @override
  String get sectionPreferences => 'التفضيلات';

  @override
  String get dangerZone => 'منطقة حساسة';

  @override
  String get riderDeleteTitle => 'حذف حساب السائق';

  @override
  String get riderDeleteBody =>
      'سيتم حذف ملفك وصورتك وتقييمك. تبقى الطلبات السابقة لحسابات المطاعم دون اسمك. هذا الإجراء نهائي.';

  @override
  String get riderDeleteCheckNoDelivery => 'لا يوجد توصيل جارٍ';

  @override
  String get riderDeleteCheckCash => 'تم تسليم كل الأموال للمطاعم';

  @override
  String get riderDeleteConfirm => 'أفهم أن هذا نهائي';

  @override
  String get errRiderNameInvalid => 'أدخل اسمك (من 2 إلى 60 حرفًا)';

  @override
  String get errRiderCashPending => 'سلّم أولًا أموال الطلبات إلى المطاعم.';

  @override
  String get goToCheckout => 'متابعة الطلب';

  @override
  String get orderSummary => 'ملخص الطلب';

  @override
  String get promoCode => 'رمز الخصم';

  @override
  String get promoHint => 'أدخل الرمز';

  @override
  String get applyPromo => 'تطبيق';

  @override
  String get removePromo => 'إزالة';

  @override
  String promoApplied(String code) {
    return 'تم تطبيق الرمز $code';
  }

  @override
  String get discount => 'الخصم';

  @override
  String taxLine(String rate) {
    return 'الضريبة ($rate)';
  }

  @override
  String get paymentMethod => 'طريقة الدفع';

  @override
  String get payCashHint => 'ادفع للسائق عند الاستلام';

  @override
  String get payCard => 'بطاقة CIB / الذهبية';

  @override
  String get payCcp => 'CCP / بريدي موب';

  @override
  String get comingSoon => 'قريبًا';

  @override
  String placeOrderTotal(String amount) {
    return 'اطلب · $amount';
  }

  @override
  String get payOnDeliveryNote => 'لا تدفع إلا عند الاستلام.';

  @override
  String youSave(String amount) {
    return 'وفّرت $amount';
  }

  @override
  String get errPromoInvalid => 'رمز غير صالح';

  @override
  String get errPromoNotHere => 'هذا الرمز غير صالح لهذا المطعم';

  @override
  String get errPromoNotStarted => 'هذا الرمز غير مفعّل بعد';

  @override
  String get errPromoExpired => 'انتهت صلاحية هذا الرمز';

  @override
  String get errPromoMinOrder => 'لم يتم بلوغ الحد الأدنى للطلب';

  @override
  String get errPromoUsedUp => 'نفدت استخدامات هذا الرمز';

  @override
  String get errPromoAlreadyUsed => 'استخدمت هذا الرمز من قبل';

  @override
  String get errPaymentUnavailable => 'طريقة الدفع هذه ستتوفر قريبًا';

  @override
  String get navPromos => 'رموز الخصم';

  @override
  String get promoNew => 'رمز جديد';

  @override
  String get promoEdit => 'تعديل الرمز';

  @override
  String get promoKindPercent => 'نسبة مئوية';

  @override
  String get promoKindAmount => 'مبلغ ثابت';

  @override
  String get promoValuePercent => 'الخصم (%)';

  @override
  String get promoValueAmount => 'الخصم (دج)';

  @override
  String get promoMaxDiscount => 'أقصى خصم (دج)';

  @override
  String get promoMinOrder => 'الحد الأدنى للطلب (دج)';

  @override
  String get promoMaxUses => 'أقصى عدد استخدامات';

  @override
  String get promoPerCustomer => 'الحد لكل زبون';

  @override
  String get promoEnds => 'ينتهي في';

  @override
  String get promoNoEnd => 'بدون تاريخ انتهاء';

  @override
  String get promoRestaurant => 'المطعم';

  @override
  String get promoAllRestaurants => 'كل المطاعم';

  @override
  String get promoFundedBy => 'يتحمّله';

  @override
  String get fundedPlatform => 'المنصة';

  @override
  String get fundedRestaurant => 'المطعم';

  @override
  String promoUses(int n) {
    return '$n استخدامات';
  }

  @override
  String promoGiven(String amount) {
    return '$amount خصومات';
  }

  @override
  String get promoActive => 'نشط';

  @override
  String get promoInactive => 'معطّل';

  @override
  String get promoNote => 'ملاحظة داخلية';

  @override
  String promoMin(String amount) {
    return 'ابتداءً من $amount';
  }

  @override
  String get errPromoCode => 'الرمز: من 3 إلى 20 حرفًا أو رقمًا';

  @override
  String get errPromoTaken => 'هذا الرمز موجود مسبقًا';

  @override
  String get errPromoValue => 'تحقق من القيم (النسبة من 1 إلى 90)';

  @override
  String get noPromos => 'لا توجد رموز بعد';

  @override
  String get amountDue => 'المبلغ المستحق';

  @override
  String get taxCollected => 'الضريبة المحصلة';

  @override
  String get platformDiscounts => 'خصومات تتحملها المنصة';

  @override
  String get taxLabel => 'الضريبة';

  @override
  String get copy => 'نسخ';

  @override
  String get copied => 'تم النسخ';

  @override
  String get qrTitle => 'رمز QR للمطعم';

  @override
  String get qrHint => 'ملصق للطباعة، عدد المسح';

  @override
  String get qrScanToOrder => 'امسح الرمز للطلب';

  @override
  String get qrDownloadPoster => 'تحميل الملصق (PDF)';

  @override
  String get qrCopyLink => 'نسخ الرابط';

  @override
  String get qrStatsTitle => 'مسح رمز QR الخاص بك';

  @override
  String get qrScans30 => 'مرات المسح (30 يومًا)';

  @override
  String get qrPeople => 'أشخاص';

  @override
  String get qrOrdersAfter => 'طلبات بعد المسح';

  @override
  String qrScansTotal(int total, int app, int web) {
    return '$total مسح إجمالًا · $app بالتطبيق · $web بالكاميرا';
  }

  @override
  String get qrTip =>
      'ألصق الملصق على الواجهة والصندوق والطاولات، وضعه في أكياس التوصيل. المسح يفتح صفحتك مباشرة في foodfennec.';

  @override
  String get scanTitle => 'مسح رمز QR';

  @override
  String get scanHint => 'وجّه الكاميرا نحو رمز QR لمطعم foodfennec';

  @override
  String get scanNotOurs => 'هذا الرمز ليس رمز foodfennec';

  @override
  String get scanCameraDenied => 'اسمح باستخدام الكاميرا من الإعدادات للمسح.';

  @override
  String get scanCameraError => 'تعذر فتح الكاميرا.';

  @override
  String get qrLinkSetting => 'رابط رموز QR';

  @override
  String get qrLinkLabel => 'عنوان الموقع';

  @override
  String get qrLinkHelp =>
      'رموز QR تفتح هذا العنوان + /r/اسم-المطعم. اضبط نطاقك الحقيقي قبل طباعة الملصقات. ماسح التطبيق يعمل مهما كان النطاق.';

  @override
  String get errQrLink => 'عنوان غير صالح (مثال https://foodfennec.com)';

  @override
  String get wilaya => 'الولاية';

  @override
  String get chooseWilaya => 'اختر ولايتك';

  @override
  String get errWilaya => 'اختر ولايتك';

  @override
  String get commune => 'البلدية';

  @override
  String get communeHint => 'مثال: باب الزوار';

  @override
  String get errCommune => 'أدخل بلديتك';

  @override
  String get birthDate => 'تاريخ الميلاد';

  @override
  String get chooseDate => 'اختر التاريخ';

  @override
  String get errBirthDate => 'تاريخ ميلاد غير صالح (13 سنة على الأقل)';

  @override
  String get gender => 'الجنس';

  @override
  String get genderMale => 'ذكر';

  @override
  String get genderFemale => 'أنثى';

  @override
  String get howDidYouHear => 'كيف تعرفت على foodfennec؟';

  @override
  String get refFriend => 'صديق';

  @override
  String get refSocial => 'مواقع التواصل';

  @override
  String get refSearch => 'بحث في Google';

  @override
  String get refRestaurant => 'مطعم';

  @override
  String get refAd => 'إعلان';

  @override
  String get refOther => 'أخرى';

  @override
  String get completeProfileTitle => 'أكمل ملفك الشخصي';

  @override
  String get completeProfileBody => '30 ثانية لتصلك عروض تناسبك.';

  @override
  String get completeProfileAction => 'أكمل';

  @override
  String get completeProfilePrivacy =>
      'تبقى هذه المعلومات خاصة: تساعدنا على تحسين foodfennec.';

  @override
  String get later => 'لاحقًا';

  @override
  String get thanksProfile => 'شكرًا! تم تحديث ملفك.';

  @override
  String get cancelOrderTitle => 'إلغاء الطلب؟';

  @override
  String get cancelRequestTitle => 'طلب الإلغاء';

  @override
  String get cancelFreeExplain =>
      'لم يقبل المطعم الطلب بعد: الإلغاء فوري ومجاني.';

  @override
  String get cancelRequestExplain =>
      'المطعم يحضّر طلبك بالفعل. سيصله طلبك ويقرر: إذا بدأ التحضير يمكنه الرفض.';

  @override
  String get cancelWhy => 'لماذا؟';

  @override
  String get cancelReasonChangedMind => 'غيّرت رأيي';

  @override
  String get cancelReasonTooLong => 'الانتظار طويل';

  @override
  String get cancelReasonWrongAddress => 'عنوان خاطئ';

  @override
  String get cancelReasonWrongItems => 'خطأ في الطلب';

  @override
  String get cancelReasonDuplicate => 'طلب مكرر';

  @override
  String get cancelReasonOther => 'سبب آخر';

  @override
  String get cancelNoteHint => 'كلمة للمطعم (اختياري)';

  @override
  String get sendCancelRequest => 'إرسال الطلب';

  @override
  String get cancelRequestSent => 'تم إرسال طلبك: سيرد المطعم قريبًا.';

  @override
  String get cancelRequestPending => 'تم إرسال طلب الإلغاء. سيرد المطعم.';

  @override
  String get cancelRequestRefused =>
      'رفض المطعم الإلغاء: طلبك قيد التحضير ويستمر.';

  @override
  String get cancelRequestExpired => 'فات وقت الإلغاء: استلم السائق الطلب.';

  @override
  String cancelledByYou(String reason) {
    return 'أُلغي بطلب منك · $reason';
  }

  @override
  String get errCancelAlreadyRequested => 'طلبت الإلغاء من قبل';

  @override
  String get errCancelRequestRefused => 'رفض المطعم الإلغاء من قبل';

  @override
  String get customerWantsCancel => 'الزبون يطلب الإلغاء';

  @override
  String get cancelRequestOwnerHint => 'اقبل إذا لم يبدأ التحضير.';

  @override
  String get acceptCancel => 'قبول الإلغاء';

  @override
  String get refuseCancel => 'رفض';

  @override
  String get cancelAcceptedMsg => 'أُلغي الطلب بطلب الزبون';

  @override
  String get cancelRefusedMsg => 'تم رفض الإلغاء: الطلب مستمر';

  @override
  String get accountSuspendedTitle => 'الحساب موقوف';

  @override
  String accountSuspendedUntil(String date) {
    return 'يمكنك استخدام foodfennec مجددًا في $date.';
  }

  @override
  String get accountBannedTitle => 'الحساب محظور';

  @override
  String get accountBannedBody =>
      'تم حظر حسابك. تواصل معنا إذا كنت تعتقد أن هناك خطأ.';

  @override
  String get sanctionReasonTitle => 'السبب';

  @override
  String get contactSupport => 'اتصل بالدعم';

  @override
  String get warningTitle => 'تنبيه';

  @override
  String get warningBody => 'إذا تكرر ذلك، قد يتم إيقاف حسابك.';

  @override
  String get understood => 'فهمت';

  @override
  String get errAccountSuspended => 'حسابك موقوف';

  @override
  String get sanctionFakeOrders => 'طلبات وهمية';

  @override
  String get sanctionNoShow => 'غياب عند التوصيل';

  @override
  String get sanctionRefusedToPay => 'رفض الدفع';

  @override
  String get sanctionAbuse => 'سلوك غير لائق';

  @override
  String get sanctionFraud => 'احتيال';

  @override
  String get sanctionTooManyCancellations => 'كثرة الإلغاءات';

  @override
  String get sanctionUnsafeDriving => 'قيادة خطيرة';

  @override
  String get sanctionCashNotReturned => 'عدم تسليم المال للمطعم';

  @override
  String get sanctionOther => 'مخالفة القواعد';

  @override
  String get sanctionWarning => 'تنبيه';

  @override
  String get sanctionSuspension => 'إيقاف';

  @override
  String get sanctionBan => 'حظر';

  @override
  String get suspendedPill => 'موقوف';

  @override
  String get bannedPill => 'محظور';

  @override
  String get warnAction => 'تنبيه';

  @override
  String get suspendAction => 'إيقاف';

  @override
  String get banAction => 'حظر';

  @override
  String get liftAction => 'رفع';

  @override
  String get removeAction => 'إزالة';

  @override
  String get warnTitle => 'إرسال تنبيه';

  @override
  String get suspendTitle => 'إيقاف الحساب';

  @override
  String get banTitle => 'حظر الحساب';

  @override
  String get warnExplain =>
      'سيراه الشخص مرة عند فتح التطبيق، ويمكنه مواصلة استخدامه.';

  @override
  String get suspendExplain =>
      'لا طلبات (زبون) ولا توصيلات (سائق) حتى النهاية.';

  @override
  String get banExplain => 'محظور حتى ترفع الحظر.';

  @override
  String get suspendFor => 'المدة';

  @override
  String daysCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n يومًا',
      few: '$n أيام',
      two: 'يومان',
      one: 'يوم',
    );
    return '$_temp0';
  }

  @override
  String get messageToUser => 'رسالة للشخص';

  @override
  String get messageToUserHint => 'مثال: يرجى الطلب فقط إذا كنت متاحًا.';

  @override
  String get adminNoteLabel => 'ملاحظة داخلية (المشرف)';

  @override
  String get sanctionHistory => 'السجل';

  @override
  String get noSanctions => 'لا توجد عقوبات';

  @override
  String get sanctionsTitle => 'العقوبات';

  @override
  String get sanctionLifted => 'تم رفع العقوبة';

  @override
  String untilDate(String date) {
    return 'حتى $date';
  }

  @override
  String liftedOn(String date) {
    return 'رُفعت في $date';
  }

  @override
  String get seen => 'شوهد';

  @override
  String get allCustomers => 'الكل';

  @override
  String watchlistTab(int n) {
    return 'للمراقبة ($n)';
  }

  @override
  String get watchlistHelp =>
      'زبائن ألغوا (أو طلبوا الإلغاء) 3 مرات أو أكثر خلال 30 يومًا.';

  @override
  String get watchlistEmpty => 'لا أحد للمراقبة';

  @override
  String cancels30d(int n) {
    return '$n إلغاءات في 30 يومًا';
  }

  @override
  String openReports(int n) {
    return '$n بلاغات';
  }

  @override
  String get statCustomers => 'الزبائن';

  @override
  String get statNew7d => 'جدد (7 أيام)';

  @override
  String statActive7d(int today) {
    return 'نشطون 7 أيام · $today اليوم';
  }

  @override
  String get statOrdered => 'طلبوا من قبل';

  @override
  String get statProfileDone => 'أكملوا الملف';

  @override
  String get ageGroups => 'العمر';

  @override
  String get heardFrom => 'تعرّف عبر';

  @override
  String get platformLabel => 'المنصة';

  @override
  String get unknownValue => 'غير محدد';

  @override
  String get ageLabel => 'العمر';

  @override
  String get memberSince => 'مسجل منذ';

  @override
  String get deviceAndActivity => 'الجهاز والنشاط';

  @override
  String get lastSeen => 'آخر زيارة';

  @override
  String get activeDays30 => 'أيام النشاط (30 يومًا)';

  @override
  String get deviceLabel => 'الجهاز';

  @override
  String get ordersTotal => 'الطلبات';

  @override
  String get cancels30dLabel => 'إلغاءات (30 يومًا)';

  @override
  String get spentLabel => 'أنفق';

  @override
  String get lastOrder => 'آخر طلب';
}
