// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'Food App';

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
  String get registerRestaurantSubtitle => 'انضم إلى Food واستقبل الطلبات';

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
}
