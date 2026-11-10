// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Food App';

  @override
  String get language => 'Language';

  @override
  String get langAr => 'العربية';

  @override
  String get langFr => 'Français';

  @override
  String get langEn => 'English';

  @override
  String get back => 'Back';

  @override
  String get addToCart => 'Add to cart';

  @override
  String get cart => 'Cart';

  @override
  String get checkout => 'Checkout';

  @override
  String get placeOrder => 'Place order';

  @override
  String get total => 'Total';

  @override
  String get subtotal => 'Subtotal';

  @override
  String get deliveryFee => 'Delivery';

  @override
  String get freeDelivery => 'Free';

  @override
  String minutes(int count) {
    return '$count min';
  }

  @override
  String get open => 'Open';

  @override
  String get closed => 'Closed';

  @override
  String get fullName => 'Full name';

  @override
  String get phone => 'Phone';

  @override
  String get address => 'Address';

  @override
  String get area => 'Neighbourhood / commune';

  @override
  String get notes => 'Notes';

  @override
  String get optional => 'optional';

  @override
  String get cashOnDelivery => 'Cash on delivery';

  @override
  String get otherRestaurants => 'Other restaurants';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get logIn => 'Log in';

  @override
  String get logInSubtitle => 'Please sign in to your existing account';

  @override
  String get accept => 'Accept';

  @override
  String get reject => 'Reject';

  @override
  String get ready => 'Ready';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get statusPlaced => 'Order sent';

  @override
  String get statusAccepted => 'Accepted by restaurant';

  @override
  String get statusReady => 'Ready';

  @override
  String get statusPickedUp => 'On the way';

  @override
  String get statusDelivered => 'Delivered';

  @override
  String get statusRejected => 'Rejected';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get runningOrders => 'Running orders';

  @override
  String get orderRequests => 'Order requests';

  @override
  String itemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
      zero: 'No items',
    );
    return '$_temp0';
  }

  @override
  String get componentGallery => 'Component gallery';

  @override
  String get onb1Title => 'All your favorites';

  @override
  String get onb1Body =>
      'Get all your loved foods in one place. You just place the order, we do the rest.';

  @override
  String get onb2Title => 'The best restaurants';

  @override
  String get onb2Body =>
      'Restaurants near you and their full menus, in seconds.';

  @override
  String get onb3Title => 'Pay cash on delivery';

  @override
  String get onb3Body => 'No card needed: pay cash when your order arrives.';

  @override
  String get next => 'Next';

  @override
  String get skip => 'Skip';

  @override
  String get getStarted => 'Get started';

  @override
  String get logInTitle => 'Log In';

  @override
  String get logInSubtitleLong => 'Please sign in to your existing account';

  @override
  String get signUpTitle => 'Sign Up';

  @override
  String get signUpSubtitle => 'Please sign up to get started';

  @override
  String get signUp => 'Sign up';

  @override
  String get name => 'Name';

  @override
  String get namePlaceholder => 'John Doe';

  @override
  String get emailPlaceholder => 'example@gmail.com';

  @override
  String get retypePassword => 'Re-type password';

  @override
  String get rememberMe => 'Remember me';

  @override
  String get forgotPassword => 'Forgot password';

  @override
  String get noAccount => 'Don\'t have an account?';

  @override
  String get haveAccount => 'Already have an account?';

  @override
  String get verificationTitle => 'Verification';

  @override
  String get codeSentTo => 'We have sent a code to your email';

  @override
  String get code => 'Code';

  @override
  String get resend => 'Resend';

  @override
  String resendIn(int seconds) {
    return 'in ${seconds}s';
  }

  @override
  String get verify => 'Verify';

  @override
  String get codeResent => 'A new code was sent';

  @override
  String get forgotPasswordTitle => 'Forgot Password';

  @override
  String get forgotPasswordSubtitle => 'Enter your email to receive a code';

  @override
  String get sendCode => 'Send code';

  @override
  String get newPasswordTitle => 'New Password';

  @override
  String get newPasswordSubtitle => 'Choose a new password';

  @override
  String get newPassword => 'New password';

  @override
  String get passwordUpdated => 'Password updated';

  @override
  String get logOut => 'Log out';

  @override
  String hello(String name) {
    return 'Hello, $name';
  }

  @override
  String get homeComingSoon => 'Restaurants come in the next step.';

  @override
  String get errNameRequired => 'Enter your name (2–80 characters)';

  @override
  String get errEmailInvalid => 'Invalid email address';

  @override
  String get errPasswordShort => 'At least 8 characters';

  @override
  String get errPasswordMismatch => 'Passwords don\'t match';

  @override
  String get errCodeIncomplete => 'Enter the 6-digit code';

  @override
  String get errInvalidCredentials => 'Wrong email or password';

  @override
  String get errUserExists => 'An account with this email already exists';

  @override
  String get errCodeInvalid => 'Wrong or expired code';

  @override
  String get errTooManyRequests => 'Too many attempts, try again in a moment';

  @override
  String get errWeakPassword => 'Password is too weak';

  @override
  String get errNetwork => 'No connection. Check your network.';

  @override
  String get errGeneric => 'Something went wrong, try again';

  @override
  String get errBackendMissing => 'Server not configured (env.json)';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get errEmailSend =>
      'We couldn\'t send the code email to this address. Try again later.';

  @override
  String get errServer => 'The server had a problem. Try again in a moment.';

  @override
  String get deliverTo => 'Deliver to';

  @override
  String get chooseAddress => 'Choose an address';

  @override
  String greetingMorning(String name) {
    return 'Hey $name, good morning!';
  }

  @override
  String greetingAfternoon(String name) {
    return 'Hey $name, good afternoon!';
  }

  @override
  String greetingEvening(String name) {
    return 'Hey $name, good evening!';
  }

  @override
  String get searchHint => 'Search dishes, restaurants';

  @override
  String get allCategories => 'All categories';

  @override
  String get seeAll => 'See all';

  @override
  String get openRestaurants => 'Open restaurants';

  @override
  String get all => 'All';

  @override
  String fromPrice(String price) {
    return 'From $price';
  }

  @override
  String kmAway(String km) {
    return '$km km';
  }

  @override
  String get recentKeywords => 'Recent keywords';

  @override
  String get suggestedRestaurants => 'Suggested restaurants';

  @override
  String noResults(String query) {
    return 'No results for “$query”';
  }

  @override
  String get dishes => 'Dishes';

  @override
  String get restaurantsTitle => 'Restaurants';

  @override
  String get restaurant => 'Restaurant';

  @override
  String get details => 'Details';

  @override
  String popularIn(String category) {
    return 'Popular $category';
  }

  @override
  String get addedToCart => 'Added to cart';

  @override
  String cartOtherRestaurant(String name) {
    return 'Your cart has items from $name. Start a new cart?';
  }

  @override
  String get newCart => 'New cart';

  @override
  String get unavailable => 'Unavailable';

  @override
  String get restaurantNotFound => 'Restaurant not found';

  @override
  String get restaurantClosedNote => 'This restaurant is closed right now';

  @override
  String get retry => 'Retry';

  @override
  String get loadError => 'Couldn\'t load. Check your connection.';

  @override
  String get accessLocation => 'Access location';

  @override
  String get locationExplain =>
      'FOOD WILL ACCESS YOUR LOCATION ONLY WHILE USING THE APP';

  @override
  String get notNow => 'Not now';

  @override
  String get locationDenied => 'Location access denied';

  @override
  String get profile => 'Profile';

  @override
  String get personalInfo => 'Personal info';

  @override
  String get addresses => 'Addresses';

  @override
  String get edit => 'Edit';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get saved => 'Saved';

  @override
  String get changePhoto => 'Change photo';

  @override
  String get phoneOptionalHint => '0550 12 34 56';

  @override
  String get errPhoneInvalid => 'Invalid number (05, 06 or 07 + 8 digits)';

  @override
  String get addNewAddress => 'Add new address';

  @override
  String get editAddress => 'Edit address';

  @override
  String get saveLocation => 'Save location';

  @override
  String get labelAs => 'Label as';

  @override
  String get labelHome => 'Home';

  @override
  String get labelWork => 'Work';

  @override
  String get labelOther => 'Other';

  @override
  String get addressDetails => 'Building, floor, door';

  @override
  String get addressHint => 'Street, neighbourhood…';

  @override
  String get areaHint => 'Kouba, Hydra, Bab Ezzouar…';

  @override
  String get setDefault => 'Set as default';

  @override
  String get defaultTag => 'Default';

  @override
  String get delete => 'Delete';

  @override
  String get deleteAddressConfirm => 'Delete this address?';

  @override
  String get noAddresses => 'No saved address yet';

  @override
  String get moveMapHint => 'Move the map to place the pin';

  @override
  String get useMyLocation => 'My location';

  @override
  String get errAddressRequired => 'Enter the address (at least 3 characters)';

  @override
  String get errAddressLimit => 'You can save up to 10 addresses';

  @override
  String get search => 'Search';

  @override
  String get cartEmpty => 'Your cart is empty';

  @override
  String get checkoutNextStep => 'Checkout comes in the next step.';

  @override
  String get ownRestaurant => 'Own a restaurant?';

  @override
  String get registerIt => 'Register it';

  @override
  String get registerRestaurantTitle => 'Your restaurant';

  @override
  String get registerRestaurantSubtitle => 'Join Food and receive orders';

  @override
  String get yourAccount => 'Your account';

  @override
  String get restaurantSection => 'The restaurant';

  @override
  String get restaurantName => 'Restaurant name';

  @override
  String get restaurantPhone => 'Restaurant phone';

  @override
  String get prepTime => 'Preparation time (min)';

  @override
  String get errRestaurantPhone =>
      'Invalid number (e.g. 0550123456 or 021234567)';

  @override
  String get errPrepTime => 'Between 5 and 120 minutes';

  @override
  String get pendingApprovalTitle => 'Waiting for approval';

  @override
  String get pendingApprovalBody =>
      'We\'re reviewing your restaurant. Prepare your menu meanwhile: customers will see it once it\'s approved.';

  @override
  String get openForOrders => 'Open for orders';

  @override
  String get closedForOrders => 'Closed';

  @override
  String get openSwitchHint => 'Customers can order while this is on';

  @override
  String get cantOpenPending => 'You can open once your restaurant is approved';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get menu => 'Menu';

  @override
  String get orders => 'Orders';

  @override
  String get myMenu => 'My menu';

  @override
  String totalItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dishes',
      one: '1 dish',
      zero: 'No dishes',
    );
    return '$_temp0';
  }

  @override
  String get addItem => 'Add new item';

  @override
  String get editItem => 'Edit item';

  @override
  String get reset => 'Reset';

  @override
  String get itemName => 'Item name';

  @override
  String get itemNameHint => 'Pizza Margherita';

  @override
  String get uploadPhoto => 'Upload photo';

  @override
  String get add => 'Add';

  @override
  String get price => 'Price (DA)';

  @override
  String get priceHint => '650';

  @override
  String get errPrice => 'Price between 10 and 100,000 DA';

  @override
  String get category => 'Category';

  @override
  String get noCategory => 'None';

  @override
  String get available => 'Available';

  @override
  String get itemDetails => 'Details';

  @override
  String get itemDetailsHint => 'Ingredients, size…';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get deleteItemConfirm => 'Delete this dish?';

  @override
  String get emptyMenu => 'Your menu is empty. Add your first dish.';

  @override
  String get ordersComingSoon => 'Live orders arrive in the next step.';

  @override
  String get restaurantProfile => 'Restaurant profile';

  @override
  String get coverPhoto => 'Cover photo';

  @override
  String get logo => 'Logo';

  @override
  String get description => 'Description';

  @override
  String get descriptionHint => 'Wood-fired pizzas, tacos…';

  @override
  String get restaurantLocation => 'Location on the map';

  @override
  String get errPhotoTooLarge => 'Photo too large (max 3 MB)';

  @override
  String dishesAvailable(int available, int total) {
    return '$available of $total available';
  }

  @override
  String get seeMenu => 'See menu';

  @override
  String get registrationDone => 'Restaurant registered';

  @override
  String get admin => 'Admin';

  @override
  String get receipts => 'Receipts';

  @override
  String get settings => 'Settings';

  @override
  String get customers => 'Customers';

  @override
  String get periodToday => 'Today';

  @override
  String get periodLast7 => '7 days';

  @override
  String get periodThisMonth => 'This month';

  @override
  String get periodLastMonth => 'Last month';

  @override
  String get periodCustom => 'Custom';

  @override
  String get previousHalfMonth => 'Previous half-month';

  @override
  String get statDelivered => 'Delivered orders';

  @override
  String get statSales => 'Food sales';

  @override
  String get statDeliveryFees => 'Delivery fees';

  @override
  String get statCommission => 'Commission earned';

  @override
  String get statCancelled => 'Cancelled / rejected';

  @override
  String get statActive => 'In progress';

  @override
  String get statPending => 'Restaurants to approve';

  @override
  String get statActiveRestaurants => 'Active restaurants';

  @override
  String get statUnbilled => 'Commission not billed yet';

  @override
  String get byRestaurant => 'By restaurant';

  @override
  String get filterPending => 'To approve';

  @override
  String get filterActive => 'Active';

  @override
  String get filterInactive => 'Deactivated';

  @override
  String get approve => 'Approve';

  @override
  String get deactivate => 'Deactivate';

  @override
  String get reactivate => 'Reactivate';

  @override
  String get commissionRate => 'Commission rate';

  @override
  String defaultRate(String rate) {
    return 'Default ($rate)';
  }

  @override
  String get useDefault => 'Use default';

  @override
  String get errRate => 'Between 0 and 50%';

  @override
  String get owner => 'Owner';

  @override
  String toBill(String amount) {
    return 'To bill: $amount';
  }

  @override
  String deliveredCount(int count) {
    return '$count delivered';
  }

  @override
  String get noRestaurants => 'No restaurants';

  @override
  String get newReceipt => 'New receipt';

  @override
  String get receiptPeriod => 'Period';

  @override
  String receiptPreview(int count, String food) {
    return '$count delivered orders · sales $food';
  }

  @override
  String get commissionDue => 'Commission due';

  @override
  String get generateReceipt => 'Generate receipt';

  @override
  String get noOrdersToBill => 'No delivered orders to bill in this period';

  @override
  String get periodNotFinished => 'Choose a period that has ended';

  @override
  String get statusPaid => 'Paid';

  @override
  String get statusUnpaid => 'Unpaid';

  @override
  String get markPaid => 'Mark as paid';

  @override
  String get markUnpaid => 'Mark as unpaid';

  @override
  String get downloadPdf => 'Download PDF';

  @override
  String get printPdf => 'Print';

  @override
  String get cancelReceipt => 'Cancel receipt';

  @override
  String get cancelReceiptConfirm =>
      'Cancel this receipt? Its orders can be billed again.';

  @override
  String get noReceipts => 'No receipts yet';

  @override
  String get allRestaurants => 'All restaurants';

  @override
  String get allStatuses => 'All statuses';

  @override
  String get noOrders => 'No orders';

  @override
  String get loadMore => 'Load more';

  @override
  String get itemsTitle => 'Items';

  @override
  String get defaultCommission => 'Default commission (%)';

  @override
  String get deliveryFeeDa => 'Delivery fee (DA)';

  @override
  String get errDeliveryFee => 'Between 0 and 5,000 DA';

  @override
  String get businessInfo => 'Your details (printed on receipts)';

  @override
  String get businessName => 'Business name';

  @override
  String get businessPhone => 'Phone';

  @override
  String get businessEmail => 'Email';

  @override
  String get businessAddress => 'Address';

  @override
  String get businessTaxId => 'Tax ID';

  @override
  String get searchCustomers => 'Name, email or phone';

  @override
  String ordersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count orders',
      one: '1 order',
      zero: 'No orders',
    );
    return '$_temp0';
  }

  @override
  String get restaurantFilter => 'Restaurant';

  @override
  String get statusFilter => 'Status';

  @override
  String issuedOn(String date) {
    return 'Issued $date';
  }

  @override
  String get deliveryAddress => 'Delivery address';

  @override
  String get breakdown => 'Breakdown';

  @override
  String get addDeliveryAddress => 'Add a delivery address';

  @override
  String get deliveryDetails => 'Delivery details';

  @override
  String get phoneForDriver =>
      'The restaurant and the driver will call you on this number.';

  @override
  String get notesHint => 'E.g. no onions, 2nd floor';

  @override
  String get orderPlacedTitle => 'Order placed!';

  @override
  String orderPlacedBody(String total) {
    return 'The restaurant will confirm your order. You will pay $total in cash on delivery.';
  }

  @override
  String get trackOrder => 'Track order';

  @override
  String get backToHome => 'Back to home';

  @override
  String get myOrders => 'My orders';

  @override
  String get ongoingOrders => 'Ongoing';

  @override
  String get orderHistory => 'History';

  @override
  String get noOngoingOrders => 'No ongoing orders';

  @override
  String get noPastOrders => 'No past orders';

  @override
  String orderNumber(String code) {
    return 'Order #$code';
  }

  @override
  String orderedAt(String date) {
    return 'Ordered on $date';
  }

  @override
  String get cancelOrder => 'Cancel order';

  @override
  String get cancelOrderConfirm => 'Cancel this order?';

  @override
  String get keepOrder => 'No, keep it';

  @override
  String get orderCancelledMsg => 'Order cancelled';

  @override
  String rejectReasonLabel(String reason) {
    return 'Reason: $reason';
  }

  @override
  String get payInCash => 'To pay in cash';

  @override
  String get orderItems => 'Your order';

  @override
  String get callRestaurant => 'Call the restaurant';

  @override
  String get errRestaurantClosed => 'This restaurant is closed right now.';

  @override
  String get errRestaurantUnavailable =>
      'This restaurant is no longer available.';

  @override
  String get errItemUnavailable =>
      'A dish is no longer available. Your cart was updated.';

  @override
  String get errPricesChanged =>
      'Prices changed. Your cart was updated, please check the total.';

  @override
  String get errTooManyActiveOrders =>
      'You already have 3 ongoing orders. Wait until one is delivered.';

  @override
  String get errTooManyOrders =>
      'Too many orders in a short time. Try again later.';

  @override
  String get errAddressGone =>
      'This address no longer exists. Choose another one.';

  @override
  String get errCannotCancel =>
      'The restaurant already accepted this order, it can no longer be cancelled.';

  @override
  String tabNewOrders(int count) {
    return 'New ($count)';
  }

  @override
  String tabInProgress(int count) {
    return 'In progress ($count)';
  }

  @override
  String get markReady => 'Ready';

  @override
  String get waitingDriver => 'Waiting for driver';

  @override
  String get rejectOrderTitle => 'Reject order';

  @override
  String get cancelOrderTitleOwner => 'Cancel order';

  @override
  String get reasonLabel => 'Reason (shown to the customer)';

  @override
  String get reasonBusy => 'Too busy right now';

  @override
  String get reasonItemOut => 'A dish is no longer available';

  @override
  String get reasonClosing => 'We are closing soon';

  @override
  String get reasonUnreachable => 'Customer unreachable';

  @override
  String get errReasonRequired => 'Please give a reason.';

  @override
  String get errOrderChanged =>
      'This order changed in the meantime. The list is up to date.';

  @override
  String get enableSoundAlerts =>
      'Tap here to turn on the sound alert for new orders';

  @override
  String get soundOn => 'Sound alert on';

  @override
  String get soundOff => 'Sound alert off';

  @override
  String minutesAgo(int count) {
    return '$count min ago';
  }

  @override
  String get justNow => 'just now';

  @override
  String get noNewOrders => 'No new orders';

  @override
  String get noOrdersInProgress => 'No orders in progress';

  @override
  String get customer => 'Customer';

  @override
  String get orderAcceptedMsg => 'Order accepted';

  @override
  String get orderReadyMsg => 'Order ready, waiting for the driver';

  @override
  String get orderRejectedMsg => 'Order rejected';

  @override
  String newOrderBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new orders to accept',
      one: '1 new order to accept',
    );
    return '$_temp0';
  }

  @override
  String get deliverWithUs => 'Deliver with us?';

  @override
  String get joinAsDriver => 'Join';

  @override
  String get registerDriverTitle => 'Become a driver';

  @override
  String get registerDriverSubtitle => 'Deliver orders near you';

  @override
  String get driverSection => 'Driver';

  @override
  String get driverPhone => 'Phone (mobile)';

  @override
  String get vehicle => 'Vehicle';

  @override
  String get vehicleMoto => 'Motorbike';

  @override
  String get vehicleCar => 'Car';

  @override
  String get vehicleBike => 'Bicycle';

  @override
  String get driverRegistered =>
      'Registration sent. An admin will approve your account.';

  @override
  String get driverPendingTitle => 'Waiting for approval';

  @override
  String get driverPendingBody =>
      'The admin must approve your account before you can deliver.';

  @override
  String get onlineLabel => 'Online';

  @override
  String get offlineLabel => 'Offline';

  @override
  String get youAreOnline => 'You receive new orders.';

  @override
  String get youAreOffline => 'Go online to receive orders.';

  @override
  String get availableOrders => 'Available orders';

  @override
  String get noAvailableOrders =>
      'No orders right now. The list updates by itself.';

  @override
  String get takeOrder => 'Take it';

  @override
  String get orderTaken => 'It\'s yours! Head to the restaurant.';

  @override
  String get errAlreadyTaken => 'Another driver took it first.';

  @override
  String get errDriverBusy => 'Finish your current delivery first.';

  @override
  String get errNotOnline => 'Go online first.';

  @override
  String get errNotApproved => 'Your account is not approved yet.';

  @override
  String get currentDelivery => 'Current delivery';

  @override
  String get pickupAt => 'Pick up at';

  @override
  String get dropOffAt => 'Deliver to';

  @override
  String get cashToCollect => 'Cash to collect';

  @override
  String get yourFee => 'Your fee';

  @override
  String get handToRestaurant => 'Hand to the restaurant';

  @override
  String get waitRestaurant =>
      'The restaurant is preparing the order. Wait until it is ready.';

  @override
  String get markPickedUp => 'Picked up';

  @override
  String get markDelivered => 'Delivered & paid';

  @override
  String confirmDelivered(String total) {
    return 'Confirm delivery? The customer paid you $total.';
  }

  @override
  String get confirm => 'Confirm';

  @override
  String get releaseOrder => 'Give it back';

  @override
  String get releaseConfirm => 'Give this order back to the other drivers?';

  @override
  String get callAction => 'Call';

  @override
  String get directions => 'Directions';

  @override
  String get deliveredMsg => 'Delivery done. Thank you!';

  @override
  String get pickedUpMsg => 'On the way to the customer';

  @override
  String get cancelledByRestaurant => 'The restaurant cancelled this order.';

  @override
  String todaySummary(int count, String amount) {
    return 'Today: $count deliveries · $amount';
  }

  @override
  String get driversTitle => 'Drivers';

  @override
  String get noDrivers => 'No drivers';

  @override
  String currentOrderCode(String code) {
    return 'Current order: #$code';
  }

  @override
  String get yourDriver => 'Your driver';

  @override
  String driverLabel(String name) {
    return 'Driver: $name';
  }

  @override
  String get myDeliveries => 'My deliveries';

  @override
  String get noDeliveries => 'No deliveries yet';

  @override
  String get driverApproved => 'Account approved';

  @override
  String get proofTitle => 'Delivery photo';

  @override
  String get proofHint =>
      'Take a photo of the order handed to the customer (or at their door). It is the proof if there is a dispute.';

  @override
  String get takePhoto => 'Take the photo';

  @override
  String get retakePhoto => 'Retake';

  @override
  String get errPhotoRequired =>
      'The photo is required to confirm the delivery.';

  @override
  String get errCashOverdue =>
      'You have had money to hand over for too long. The restaurant must confirm it before you can take new orders.';

  @override
  String get cashBlockedTitle => 'New orders blocked';

  @override
  String get moneyToHand => 'Money to give to restaurants';

  @override
  String moneyToHandTotal(String amount) {
    return 'Total to give: $amount';
  }

  @override
  String get iGaveMoney => 'I gave the money';

  @override
  String get waitingRestaurantConfirm =>
      'Waiting for the restaurant to confirm';

  @override
  String get cashHandedMsg => 'Noted. The restaurant must confirm it.';

  @override
  String get cashToReceive => 'Money to receive from drivers';

  @override
  String get confirmReceived => 'Received';

  @override
  String confirmReceivedQ(String amount, String name) {
    return 'Confirm you received $amount from $name?';
  }

  @override
  String get cashConfirmedMsg => 'Receipt confirmed';

  @override
  String get driverSaysHanded => 'The driver says it was handed over';

  @override
  String get proofOfDelivery => 'Proof of delivery';

  @override
  String cashOwedLine(String amount, int count) {
    return 'Owes $amount ($count orders)';
  }

  @override
  String get cashBlockedPill => 'Blocked';

  @override
  String get cashStatusConfirmed => 'Money received by the restaurant';

  @override
  String get cashStatusHanded => 'Money handed by the driver, to confirm';

  @override
  String get cashStatusPending => 'Money not yet given to the restaurant';

  @override
  String deliveredOnTime(String date) {
    return 'Delivered $date';
  }

  @override
  String get cashHoursSetting =>
      'Block a driver after (hours without handover)';

  @override
  String get errCashHours => 'Between 1 and 168 hours';

  @override
  String get downloadReceipt => 'Download receipt';

  @override
  String get printAction => 'Print';

  @override
  String get receiptOrderTitle => 'Order receipt';

  @override
  String get receiptOrderNo => 'Order';

  @override
  String get receiptDate => 'Date';

  @override
  String get receiptDeliveredOn => 'Delivered on';

  @override
  String get receiptCustomer => 'Customer';

  @override
  String get receiptItem => 'Item';

  @override
  String get receiptQty => 'Qty';

  @override
  String get receiptUnit => 'Unit price';

  @override
  String get receiptAmount => 'Amount';

  @override
  String get receiptPaidCash => 'Paid in cash on delivery';

  @override
  String get receiptDeliveredBy => 'Delivered by';

  @override
  String get receiptTotalPaid => 'Total paid';

  @override
  String get receiptFooter =>
      'Amounts in Algerian dinars (DA). Document generated by the app.';

  @override
  String get receiptPage => 'Page';

  @override
  String get taxIdShort => 'Tax ID';

  @override
  String get driverStatementTitle => 'Driver statement';

  @override
  String get downloadStatement => 'Download statement';

  @override
  String get periodThisWeek => 'This week';

  @override
  String get periodLastWeek => 'Last week';

  @override
  String get stDeliveries => 'Deliveries';

  @override
  String get stCollected => 'Collected';

  @override
  String get stToRestaurant => 'To restaurant';

  @override
  String get stFee => 'Fee';

  @override
  String get stMoney => 'Money';

  @override
  String get stConfirmed => 'Handed';

  @override
  String get stOpen => 'To give';

  @override
  String get stTotalCollected => 'Total collected';

  @override
  String get stTotalToRestaurants => 'Total due to restaurants';

  @override
  String get stStillToGive => 'Still to give';

  @override
  String get stEarned => 'Your earnings';

  @override
  String get stDriver => 'Driver';

  @override
  String get noDeliveriesInPeriod => 'No deliveries in this period';

  @override
  String get myStatements => 'My commission statements';

  @override
  String get chooseFromGallery => 'Choose from gallery';

  @override
  String get errCamera =>
      'Couldn\'t open the camera. Allow the camera in settings, or choose a photo from the gallery.';

  @override
  String get reasonNoAnswer => 'The restaurant didn\'t answer in time';

  @override
  String get autoRejectSetting =>
      'Auto-reject if the restaurant doesn\'t answer (minutes)';

  @override
  String get errAutoReject => 'Between 3 and 60 minutes';

  @override
  String get deleteAccount => 'Delete my account';

  @override
  String get deleteAccountConfirm =>
      'Permanently delete your account? Your addresses and photo are erased. Past orders stay anonymous for accounting.';

  @override
  String get accountDeleted => 'Account deleted';

  @override
  String get errDeleteActiveOrders =>
      'You have an order in progress. Try again once it is delivered.';

  @override
  String get errDeleteNotCustomer =>
      'Restaurant and driver accounts are closed by the admin. Please contact them.';

  @override
  String get locationServiceOff => 'Your phone\'s location is turned off.';

  @override
  String get locationBlocked =>
      'Location is blocked for this app. Allow it in settings.';

  @override
  String get locationUnavailable =>
      'Couldn\'t find your position. Try outside, or search your address on the map.';

  @override
  String get turnOn => 'Turn on';

  @override
  String get openSettings => 'Settings';

  @override
  String get searchAddressHint => 'Search an address or area…';

  @override
  String get navHome => 'Home';

  @override
  String get navAccount => 'Account';

  @override
  String get viewProfile => 'View profile';

  @override
  String get general => 'General';

  @override
  String get helpCenter => 'Help center';

  @override
  String get supportSoon => 'The support number will be available soon.';

  @override
  String get becomePartner => 'Register my restaurant';

  @override
  String get becomeDriver => 'Become a driver';

  @override
  String get termsTitle => 'Terms & privacy';

  @override
  String get appVersion => 'Version';

  @override
  String get promoCashTitle => 'Pay on delivery';

  @override
  String get promoCashBody =>
      'In cash, when your order arrives. No card needed.';

  @override
  String promoFeeTitle(String fee) {
    return 'Delivery $fee';
  }

  @override
  String get promoFeeBody => 'The same price everywhere in town.';

  @override
  String get promoDiscover => 'Open now · Order →';

  @override
  String get termsOrdersTitle => 'Orders and payment';

  @override
  String get termsOrdersBody =>
      'Prices are the restaurant\'s at the time of ordering. You pay in cash on delivery (food + delivery fee). An order can be cancelled until the restaurant accepts it.';

  @override
  String get termsDataTitle => 'Your data';

  @override
  String get termsDataBody =>
      'We use your name, phone and address only to deliver your orders. The restaurant and the driver see them for your order. A photo is taken at delivery as proof.';

  @override
  String get termsDeleteTitle => 'Deleting your account';

  @override
  String get termsDeleteBody =>
      'Account → Delete my account. Your addresses and photo are erased; past orders stay anonymous for accounting.';

  @override
  String get openNowTitle => 'Open now';

  @override
  String get homeBanners => 'Home banners';

  @override
  String get addBanner => 'Add banner';

  @override
  String get noBanners =>
      'No banners yet. Add pictures (ads, news): they slide at the top of the customer home.';

  @override
  String get bannerSizeHint => 'Recommended wide format: 1200 × 500 pixels.';

  @override
  String get choosePicture => 'Choose a picture';

  @override
  String get bannerTitle => 'Title';

  @override
  String get bannerOpens => 'When tapped, open';

  @override
  String get bannerNoLink => 'Nothing (picture only)';

  @override
  String get deleteBannerConfirm => 'Delete this banner?';

  @override
  String get moveUp => 'Move up';

  @override
  String get moveDown => 'Move down';
}
