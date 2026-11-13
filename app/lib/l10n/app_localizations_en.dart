// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'foodfennec';

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
  String get registerRestaurantSubtitle => 'Join foodfennec and receive orders';

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

  @override
  String get appearance => 'Appearance';

  @override
  String get themeSystem => 'Auto (like the phone)';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get insights => 'Insights';

  @override
  String get todayTitle => 'Today';

  @override
  String get compareYesterday => 'Compared with yesterday at the same time';

  @override
  String get kpiSales => 'Sales';

  @override
  String get kpiOrders => 'Orders';

  @override
  String get kpiAvgBasket => 'Average basket';

  @override
  String get kpiPrep => 'Avg. preparation';

  @override
  String get kpiAcceptance => 'Acceptance rate';

  @override
  String get kpiNet => 'Net after commission';

  @override
  String minutesShort(int n) {
    return '$n min';
  }

  @override
  String get last7Days => 'Last 7 days';

  @override
  String get seeInsights => 'See insights';

  @override
  String get shortcuts => 'Shortcuts';

  @override
  String get ordersTable => 'Orders table';

  @override
  String get liveOrders => 'Live orders';

  @override
  String dishesNoPhoto(int n) {
    return '$n dishes without a photo: photos sell';
  }

  @override
  String dishesUnavailable(int n) {
    return '$n dishes unavailable';
  }

  @override
  String get menuHealthGood => 'Your menu looks great!';

  @override
  String get rangeYesterday => 'Yesterday';

  @override
  String get range7 => '7 days';

  @override
  String get range30 => '30 days';

  @override
  String get range90 => '90 days';

  @override
  String get rangeMonth => 'This month';

  @override
  String get rangeCustom => 'Dates…';

  @override
  String get filterAll => 'All';

  @override
  String get filterInProgress => 'In progress';

  @override
  String get searchOrdersHint => 'Code, customer, dish…';

  @override
  String get exportCsv => 'Export CSV';

  @override
  String get csvReady => 'CSV file ready';

  @override
  String get noOrdersPeriod => 'No orders in this period';

  @override
  String get tableTotals => 'Selection total';

  @override
  String get csvCode => 'Code';

  @override
  String get csvDate => 'Date';

  @override
  String get csvTime => 'Time';

  @override
  String get csvStatus => 'Status';

  @override
  String get csvCustomer => 'Customer';

  @override
  String get csvArea => 'Area';

  @override
  String get csvItems => 'Items';

  @override
  String get csvItemCount => 'Item count';

  @override
  String get csvFood => 'Food (DA)';

  @override
  String get csvDeliveryFee => 'Delivery (DA)';

  @override
  String get csvTotal => 'Total (DA)';

  @override
  String get csvCommission => 'Commission (DA)';

  @override
  String get csvNet => 'Net (DA)';

  @override
  String get csvDriver => 'Driver';

  @override
  String get csvPrepMinutes => 'Prep (min)';

  @override
  String get csvReason => 'Reason';

  @override
  String comparedPrevious(int n) {
    return 'Compared with the previous $n days';
  }

  @override
  String get salesChartTitle => 'Sales per day';

  @override
  String get tapBarHint => 'Tap a bar to see its value';

  @override
  String get hoursChartTitle => 'Busiest hours';

  @override
  String get weekdayChartTitle => 'Days of the week';

  @override
  String get topDishesTitle => 'Best sellers';

  @override
  String get outcomesTitle => 'Order outcomes';

  @override
  String soldTimes(int n) {
    return '$n sold';
  }

  @override
  String get tipsTitle => 'Tips to sell more';

  @override
  String tipSalesUp(int n) {
    return 'Sales are up $n% on the previous period. Keep it up!';
  }

  @override
  String tipSalesDown(int n) {
    return 'Sales are down $n%. Check your opening hours and add photos to your dishes.';
  }

  @override
  String tipRefusals(int n, String amount) {
    return '$n orders refused or unanswered: $amount in lost sales. Close the restaurant when you can\'t serve.';
  }

  @override
  String tipSlowResponse(int n) {
    return 'You take $n min on average to accept. Customers are waiting, and an unanswered order is refused automatically.';
  }

  @override
  String tipSlowPrep(int n, int announced) {
    return 'Preparation takes $n min but you announce $announced min. Update it in your profile or speed up.';
  }

  @override
  String tipPeakHour(String hour, int share) {
    return 'Rush hour: $hour ($share% of orders). Get ingredients ready before it.';
  }

  @override
  String tipTopDish(String dish, int share) {
    return '\"$dish\" makes $share% of your sales. Keep it always available, with a great photo.';
  }

  @override
  String tipQuietDay(String day) {
    return '$day is your quietest day: a good time for an offer or a new dish.';
  }

  @override
  String get tipNoOrders =>
      'No orders in this period yet. Open at meal times and complete your menu with photos.';

  @override
  String get myBusiness => 'My business';

  @override
  String get accountApproved => 'Approved';

  @override
  String get accountPending => 'Pending';

  @override
  String get deleteRestaurantConfirm =>
      'Your account will be deleted and your restaurant removed from the app. Your orders and statements stay archived for accounting. This cannot be undone.';

  @override
  String get errDeleteCashPending =>
      'First confirm the money received from drivers.';

  @override
  String get errDeleteUnpaidCommission =>
      'Some commission is still unpaid. Contact the admin.';

  @override
  String get restaurantDetailsHint =>
      'Photos, address, phone, preparation time';

  @override
  String get outlets => 'Outlets';

  @override
  String get roleOwner => 'Owner';

  @override
  String get roleManager => 'Manager';

  @override
  String get roleStaff => 'Staff';

  @override
  String get csvOutlet => 'Outlet';

  @override
  String get portalTitle => 'Partner portal';

  @override
  String get portalTagline =>
      'Manage your restaurants, orders and sales in one place.';

  @override
  String get portalLoginTitle => 'Sign in to your partner portal';

  @override
  String get portalNotPartner =>
      'This portal is for restaurant partners. Register your restaurant in the app first.';

  @override
  String get navReports => 'Reports';

  @override
  String get navInvoices => 'Invoices';

  @override
  String get navMenu => 'Menu management';

  @override
  String get navHours => 'Opening times';

  @override
  String get navReviews => 'Ratings and reviews';

  @override
  String get navMarketing => 'Marketing';

  @override
  String get navNotifications => 'Notification centre';

  @override
  String get navTeam => 'Team';

  @override
  String get soon => 'Soon';

  @override
  String get comingSoonTitle => 'Coming soon';

  @override
  String get comingSoonBody =>
      'This section arrives in the next step. Meanwhile, use the app.';

  @override
  String get outletsAll => 'All outlets';

  @override
  String outletsCount(int n, int total) {
    return '$n/$total outlets';
  }

  @override
  String get dashboardSubtitle => 'An overview of your orders and outlets';

  @override
  String get ordersToday => 'Orders today';

  @override
  String get cancelledToday => 'Cancelled or refused today';

  @override
  String get closedOutletsNow => 'Outlets closed now';

  @override
  String get salesToday => 'Sales today';

  @override
  String updatedAt(String time) {
    return 'Updated at $time';
  }

  @override
  String get businessSummary => 'Business summary';

  @override
  String get thisWeek => 'This week';

  @override
  String get lastWeek => 'Last week';

  @override
  String get comparison => 'Comparison';

  @override
  String get previousPeriod => 'Previous period';

  @override
  String get totalLabel => 'Total';

  @override
  String get cancelledLabel => 'Cancelled';

  @override
  String get waitingOrders => 'Waiting for your answer';

  @override
  String get noWaitingOrders => 'No order is waiting.';

  @override
  String get ordersSubtitle => 'View real-time order details';

  @override
  String get placedAtCol => 'Placed at';

  @override
  String acceptedIn(String time) {
    return 'Accepted in $time';
  }

  @override
  String get orderDetailsTitle => 'Order details';

  @override
  String secondsShort(int n) {
    return '$n s';
  }

  @override
  String get reportsSubtitle => 'Analyze your performance with these insights';

  @override
  String get tabSales => 'Sales';

  @override
  String get tabOperations => 'Operations';

  @override
  String get tabCustomers => 'Customers';

  @override
  String get previousMonth => 'Previous month';

  @override
  String get salesByDayHint =>
      'Sales and orders per day: is your business trending up or down?';

  @override
  String get downloadReport => 'Download report';

  @override
  String get salesByHour => 'Sales by hour';

  @override
  String get salesByHourHint =>
      'Sales by hour and day of the week: your quiet and busy hours.';

  @override
  String get avgResponse => 'Avg. time to accept';

  @override
  String get cancellationRate => 'Cancellation rate';

  @override
  String get lostSales => 'Lost sales';

  @override
  String get refusalReasons => 'Refusals and cancellations by reason';

  @override
  String get prepByDay => 'Preparation time by day';

  @override
  String get newVsReturning => 'New vs returning customers';

  @override
  String get newVsReturningHint =>
      'Share of orders from first-time and returning customers.';

  @override
  String get ordersFromNew => 'Orders from new customers';

  @override
  String get ordersFromReturning => 'Orders from returning customers';

  @override
  String get moreReturningTitle => 'Looking for more returning customers?';

  @override
  String get moreReturningBody =>
      'Customers come back for quality and speed: keep your best dishes available, answer fast and announce honest preparation times.';

  @override
  String get moreNewTitle => 'Looking for more new customers?';

  @override
  String get moreNewBody =>
      'Great photos and full descriptions make people try you. A home banner (ask the admin) shows you to everyone.';

  @override
  String get topAreas => 'Top neighbourhoods';

  @override
  String get uniqueCustomers => 'Customers';

  @override
  String get invoicesSubtitle => 'Download your commission statements';

  @override
  String get noInvoices => 'No invoices yet';

  @override
  String get outletsSubtitle => 'Your restaurants, their status and your role';

  @override
  String get addOutlet => 'Add outlet';

  @override
  String get outletAdded =>
      'Outlet added. It will be visible after the admin approves it.';

  @override
  String yourRole(String role) {
    return 'Your role: $role';
  }

  @override
  String get teamSubtitle =>
      'Give your team their own login, with the right access';

  @override
  String get addMember => 'Add member';

  @override
  String get memberEmail => 'Account email';

  @override
  String get memberEmailHint =>
      'The person must first create an account in the app with this email.';

  @override
  String get roleOwnerDesc =>
      'Everything, including the team and closing the account';

  @override
  String get roleManagerDesc => 'Orders, menu, details, reports and invoices';

  @override
  String get roleStaffDesc =>
      'Orders only: accept, refuse, ready, cash received';

  @override
  String get removeMember => 'Remove';

  @override
  String removeMemberConfirm(String name) {
    return 'Remove $name from this outlet?';
  }

  @override
  String get memberAdded => 'Member added';

  @override
  String get errUserNotFound =>
      'No account with this email. Ask them to sign up in the app first.';

  @override
  String get errOtherRole =>
      'This account is a driver or admin and can\'t join a restaurant.';

  @override
  String get errAlreadyMember => 'Already in the team.';

  @override
  String get errLastOwner => 'An outlet needs at least one owner.';

  @override
  String get onlyOwnersTeam => 'Only owners can change the team.';

  @override
  String get colName => 'Name';

  @override
  String get colEmail => 'Email';

  @override
  String get colRole => 'Role';

  @override
  String get colSince => 'Since';

  @override
  String get portalStaffOnly =>
      'Your staff access works in the app. Ask an owner for manager access to use the portal.';

  @override
  String get errOptionsChanged =>
      'This dish\'s options changed. Please choose them again.';

  @override
  String chooseUpTo(int n) {
    return 'Choose up to $n';
  }

  @override
  String get optionRequired => 'Required';

  @override
  String get outOfStock => 'Out of stock';

  @override
  String opensTodayAt(String time) {
    return 'Closed · opens today at $time';
  }

  @override
  String opensTomorrowAt(String time) {
    return 'Closed · opens tomorrow at $time';
  }

  @override
  String opensOnAt(String day, String time) {
    return 'Closed · opens $day at $time';
  }

  @override
  String get menuSubtitle => 'Dishes, prices, photos and options';

  @override
  String get addOptionGroup => 'Add option group';

  @override
  String get editOptionGroup => 'Edit option group';

  @override
  String get dishesTab => 'Dishes';

  @override
  String get optionGroupsTab => 'Option groups';

  @override
  String get searchDishesHint => 'Search a dish…';

  @override
  String bulkDone(int n) {
    return '$n dishes updated';
  }

  @override
  String bulkDeleteConfirm(int n) {
    return 'Delete $n dishes? This cannot be undone.';
  }

  @override
  String selectedCount(int n) {
    return '$n selected';
  }

  @override
  String get bulkShow => 'Make available';

  @override
  String get bulkHide => 'Hide';

  @override
  String get bulkPrices => 'Change prices';

  @override
  String get priceIncrease => 'Increase';

  @override
  String get priceDecrease => 'Decrease';

  @override
  String get pricesRounded => 'New prices are rounded to 10 DA.';

  @override
  String get apply => 'Apply';

  @override
  String get uploadDishPhoto => 'Upload a dish photo';

  @override
  String get photosSellHint => 'Dishes with a good photo sell better.';

  @override
  String get noOptionGroupsHint =>
      'First create option groups (sizes, extras) in the Option groups tab.';

  @override
  String get optionGroupsPickHint =>
      'Choose the options offered with this dish.';

  @override
  String get noOptionGroups =>
      'No option groups yet. Create for example \"Size\" (Small, Large) or \"Extras\" (Cheese, Egg).';

  @override
  String get ruleRequiredOne => 'Required · choose 1';

  @override
  String ruleRequiredRange(int min, int max) {
    return 'Required · choose $min to $max';
  }

  @override
  String ruleOptionalUpTo(int max) {
    return 'Optional · up to $max';
  }

  @override
  String deleteGroupConfirm(String name) {
    return 'Delete the group \"$name\"? It is removed from every dish.';
  }

  @override
  String get free => 'Free';

  @override
  String get usedByNoDish => 'Not used by any dish';

  @override
  String usedBy(String names) {
    return 'Used by: $names';
  }

  @override
  String get groupName => 'Group name';

  @override
  String get groupNameHint => 'e.g. Size, Sauce, Extras';

  @override
  String get requiredHint => 'The customer must choose before ordering';

  @override
  String get minChoices => 'Minimum choices';

  @override
  String get maxChoices => 'Maximum choices';

  @override
  String get choices => 'Choices';

  @override
  String get choiceNameHint => 'e.g. Large';

  @override
  String get extraPriceHint => 'Extra price';

  @override
  String get addChoice => 'Add choice';

  @override
  String get dishesUsingGroup => 'Dishes offering these options';

  @override
  String get errGroupRule => 'Add at least as many choices as the minimum.';

  @override
  String get hoursSubtitle => 'Your hours, holidays and special hours';

  @override
  String get weeklyHours => 'Opening times';

  @override
  String get specialDays => 'Holidays and special hours';

  @override
  String get openNowLabel => 'Open now';

  @override
  String get closedNowLabel => 'Closed now';

  @override
  String get switchOffHint => 'Orders turned off with the switch';

  @override
  String get takingOrders => 'Customers can order';

  @override
  String get ordersSwitch => 'Take orders';

  @override
  String get weeklyHoursHint =>
      'Customers can only order during these hours (and while the switch is on). No hours set: open whenever the switch is on.';

  @override
  String get closedAllDay => 'Closed all day';

  @override
  String get addHours => 'Add hours';

  @override
  String get copyToAllDays => 'Copy to every day';

  @override
  String get specialDaysHint =>
      'Holidays, Eid, Ramadan… These dates replace the usual hours.';

  @override
  String get addSpecialDay => 'Add a date';

  @override
  String get noSpecialDays => 'No upcoming dates';

  @override
  String get pickDate => 'Pick the date';

  @override
  String get opensLabel => 'Opens';

  @override
  String get closesLabel => 'Closes';

  @override
  String get specialDayNote => 'Note';

  @override
  String get specialDayNoteHint => 'e.g. Eid al-Fitr';

  @override
  String get rateDriverTitle => 'How was the delivery?';

  @override
  String get rateFoodTitle => 'How was the food?';

  @override
  String get ratingWhatWrong => 'What went wrong?';

  @override
  String get ratingCommentHint => 'Add a comment (optional)';

  @override
  String get ratingSubmit => 'Send my rating';

  @override
  String get ratingLater => 'Later';

  @override
  String get ratingThanks => 'Thanks for your rating!';

  @override
  String get ratingWord1 => 'Very bad';

  @override
  String get ratingWord2 => 'Bad';

  @override
  String get ratingWord3 => 'Okay';

  @override
  String get ratingWord4 => 'Good';

  @override
  String get ratingWord5 => 'Excellent';

  @override
  String get errRatingClosed => 'The rating period (7 days) is over.';

  @override
  String get errRatingLocked => 'This rating can no longer be changed.';

  @override
  String get rateFoodCard => 'Rate the food';

  @override
  String get rateDriverCard => 'Rate the delivery';

  @override
  String ratingDaysLeft(int n) {
    return '$n days left to rate';
  }

  @override
  String get ratingLastDay => 'Last day to rate';

  @override
  String get yourRating => 'Your rating';

  @override
  String get rateAction => 'Rate';

  @override
  String get editRating => 'Edit';

  @override
  String get ratingEditHint => 'You can change it for 24 hours';

  @override
  String get ratingReplyFrom => 'Restaurant reply';

  @override
  String get errAccountBlocked =>
      'Your account is suspended. Please contact support.';

  @override
  String get rsnCold => 'Cold food';

  @override
  String get rsnMissingItem => 'Missing item';

  @override
  String get rsnWrongOrder => 'Wrong order';

  @override
  String get rsnSmallPortion => 'Small portion';

  @override
  String get rsnBadTaste => 'Bad taste';

  @override
  String get rsnBadPackaging => 'Bad packaging';

  @override
  String get rsnLate => 'Late';

  @override
  String get rsnRude => 'Rude';

  @override
  String get rsnCareless => 'Careless handling';

  @override
  String get rsnNoContact => 'Didn\'t answer the phone';

  @override
  String get rsnWrongPlace => 'Went to the wrong place';

  @override
  String get rsnFakeOrder => 'Fake order';

  @override
  String get rsnNoAnswer => 'Does not answer';

  @override
  String get rsnWrongAddress => 'Wrong address';

  @override
  String get rsnRefusedToPay => 'Refused to pay';

  @override
  String get rsnOther => 'Other';

  @override
  String get reviewsTitle => 'Reviews';

  @override
  String get newRestaurant => 'New';

  @override
  String get noReviewsYet => 'No reviews yet';

  @override
  String get restaurantReply => 'Reply from the restaurant';

  @override
  String get seeMoreReviews => 'See more reviews';

  @override
  String ratingsCount(int n) {
    return '$n ratings';
  }

  @override
  String get reviewsSubtitle => 'What customers say about your food';

  @override
  String get averageRating => 'Average rating';

  @override
  String get ratingDistribution => 'Rating distribution';

  @override
  String get topComplaints => 'Most common complaints';

  @override
  String get filterNeedsReply => 'No reply yet';

  @override
  String starsFilter(int n) {
    return '$n stars';
  }

  @override
  String get replyAction => 'Reply';

  @override
  String get replyDialogHint =>
      'Your reply is public and cannot be edited afterwards.';

  @override
  String get replyHint => 'Thank you, we hope to see you again…';

  @override
  String get sendReply => 'Publish reply';

  @override
  String get replyPublished => 'Reply published';

  @override
  String get flagReview => 'Report this review';

  @override
  String get flagReviewHint =>
      'Explain why (insult, not about your food, wrong restaurant…). The admin will decide.';

  @override
  String get flagSend => 'Send';

  @override
  String get flagSent => 'Sent to the admin';

  @override
  String get flagWaiting => 'Waiting for the admin';

  @override
  String get flagKept => 'The admin kept this review';

  @override
  String get errAlreadyReplied => 'This review already has a reply.';

  @override
  String get errAlreadyFlagged => 'Already reported.';

  @override
  String get noReviewsPeriod => 'No reviews in this period';

  @override
  String reviewOrderRef(String code) {
    return 'Order #$code';
  }

  @override
  String get myRating => 'My rating';

  @override
  String get driverRatingHint => 'Your average appears after 5 ratings.';

  @override
  String get driverReasonsTitle => 'What customers mentioned';

  @override
  String get reportCustomer => 'Report this customer';

  @override
  String get reportCustomerHint =>
      'Only the admin sees this. The customer is not told.';

  @override
  String get reportNoteHint => 'Details (optional)';

  @override
  String get reportSend => 'Send';

  @override
  String get reportSent => 'Report sent to the admin';

  @override
  String get reportedLabel => 'Reported';

  @override
  String get errAlreadyReported => 'You already reported this order.';

  @override
  String get errTooManyReports => 'Too many reports today.';

  @override
  String get errCustomerGone => 'This customer no longer has an account.';

  @override
  String get navRatings => 'Ratings';

  @override
  String get adminRatingsTitle => 'Ratings and reports';

  @override
  String get tabFlagged => 'Flagged reviews';

  @override
  String get tabReports => 'Customer reports';

  @override
  String get avg30d => 'Last 30 days';

  @override
  String get low30d => 'Ratings ≤ 2 (30 d)';

  @override
  String get hideReview => 'Hide';

  @override
  String get keepReview => 'Keep';

  @override
  String get decisionHidden => 'Hidden';

  @override
  String get decisionKept => 'Kept';

  @override
  String get flaggedReason => 'Reason reported';

  @override
  String get noFlagged => 'No flagged reviews';

  @override
  String get noReports => 'No reports';

  @override
  String get reportOpen => 'Open';

  @override
  String get reportWarned => 'Warned';

  @override
  String get reportBlocked => 'Blocked';

  @override
  String get reportDismissed => 'Dismissed';

  @override
  String get actionWarn => 'Warn';

  @override
  String get actionBlock => 'Block customer';

  @override
  String get actionUnblock => 'Unblock';

  @override
  String get actionDismiss => 'Dismiss';

  @override
  String get adminNoteHint => 'Internal note (optional)';

  @override
  String customerReportsCount(int n) {
    return '$n reports about this customer';
  }

  @override
  String get reportedByRestaurant => 'Reported by the restaurant';

  @override
  String get reportedByDriver => 'Reported by the driver';

  @override
  String get customerBlockedNote => 'Customer blocked: cannot order';

  @override
  String get rangeDaysSuffix => 'days';

  @override
  String get riderReadyTitle => 'Ready to ride?';

  @override
  String get riderReadySub => 'Go online to get delivery jobs';

  @override
  String get riderModeTitle => 'Deliver around you';

  @override
  String get riderModeBody =>
      'Pick up orders from nearby restaurants and deliver them. You keep the delivery fee.';

  @override
  String get startRiding => 'Start riding';

  @override
  String get doneForToday => 'I\'m done for the day';

  @override
  String get statDeliveries => 'Deliveries';

  @override
  String get statEarnings => 'Today\'s earnings';

  @override
  String get jobsNearYou => 'Jobs near you';

  @override
  String get continueDelivery => 'Continue delivery';

  @override
  String get stepToRestaurant => 'Head to the restaurant';

  @override
  String get stepReady => 'The order is ready';

  @override
  String get stepReadySub => 'Check each item before you leave';

  @override
  String get checkItems => 'Check the items';

  @override
  String get checkItemsTitle => 'Check each item';

  @override
  String get checkItemsHint => 'Tap each item once it is in the bag.';

  @override
  String get headToCustomer => 'Picked up, let’s go!';

  @override
  String get stepToCustomer => 'On the way to the customer';

  @override
  String get stepArrived => 'You have arrived';

  @override
  String collectCash(String amount) {
    return 'Collect $amount';
  }

  @override
  String get statDistance => 'Distance';

  @override
  String get statItems => 'Items';

  @override
  String get statCash => 'To collect';

  @override
  String wellDone(String name) {
    return 'Well done $name!';
  }

  @override
  String deliveryNumber(String code) {
    return 'Delivery #$code';
  }

  @override
  String youEarned(String amount) {
    return '+$amount earned';
  }

  @override
  String get readyNextJob => 'Ready for your next job?';

  @override
  String get nextJob => 'Next job';

  @override
  String get checkIn => 'I\'m at the restaurant';

  @override
  String get atRestaurant => 'You\'re at the restaurant';

  @override
  String get missingItemCall => 'Missing or wrong item? Call the restaurant';

  @override
  String get recenterMap => 'Re-centre';

  @override
  String get followRider => 'Follow your rider';

  @override
  String riderUpdatedAt(String time) {
    return 'Position at $time';
  }

  @override
  String riderKmAway(String km) {
    return '$km km from you';
  }

  @override
  String get riderEditProfile => 'Edit my profile';

  @override
  String get riderEditHint => 'Name, phone, vehicle and photo';

  @override
  String riderSince(String date) {
    return 'Rider since $date';
  }

  @override
  String get levelRookie => 'Rookie';

  @override
  String get levelPro => 'Pro';

  @override
  String get levelExpert => 'Expert';

  @override
  String get levelLegend => 'Legend';

  @override
  String levelLabel(String level) {
    return '$level level';
  }

  @override
  String levelNext(int n, String level) {
    return '$n more deliveries to become $level';
  }

  @override
  String levelNeedsRating(String stars, String level) {
    return 'Keep at least $stars stars to become $level';
  }

  @override
  String get levelTop => 'Top level reached, well done!';

  @override
  String get statTotalDeliveries => 'Deliveries';

  @override
  String get statTotalEarned => 'Earned';

  @override
  String get statRating => 'Rating';

  @override
  String get ratingDetails => 'See details';

  @override
  String get allTime => 'All time';

  @override
  String fiveStarStreak(int n) {
    return '$n five-star ratings in a row';
  }

  @override
  String get coachTitle => 'Tips to improve';

  @override
  String get coachLate =>
      'Take jobs close to you and leave as soon as the order is ready.';

  @override
  String get coachRude => 'A greeting and a smile change everything.';

  @override
  String get coachCareless => 'Keep the bag flat and drinks upright.';

  @override
  String get coachNoContact => 'Call the customer 2 minutes before you arrive.';

  @override
  String get coachWrongPlace =>
      'Check the map pin and the floor before you leave.';

  @override
  String get coachAllGood => 'No problems reported. Keep it up!';

  @override
  String get ratingPrivateNote =>
      'Customers rate the delivery privately: you see the numbers, never who rated.';

  @override
  String get sectionPreferences => 'Preferences';

  @override
  String get dangerZone => 'Danger zone';

  @override
  String get riderDeleteTitle => 'Delete my rider account';

  @override
  String get riderDeleteBody =>
      'Your profile, photo and rating are erased. Past orders stay for the restaurants’ accounts, without your name. This is final.';

  @override
  String get riderDeleteCheckNoDelivery => 'No delivery in progress';

  @override
  String get riderDeleteCheckCash => 'All money handed to restaurants';

  @override
  String get riderDeleteConfirm => 'I understand this is final';

  @override
  String get errRiderNameInvalid => 'Enter your name (2–60 characters)';

  @override
  String get errRiderCashPending =>
      'First hand the food money to the restaurants.';

  @override
  String get goToCheckout => 'Go to checkout';

  @override
  String get orderSummary => 'Order summary';

  @override
  String get promoCode => 'Promo code';

  @override
  String get promoHint => 'Enter your code';

  @override
  String get applyPromo => 'Apply';

  @override
  String get removePromo => 'Remove';

  @override
  String promoApplied(String code) {
    return 'Code $code applied';
  }

  @override
  String get discount => 'Discount';

  @override
  String taxLine(String rate) {
    return 'Tax ($rate)';
  }

  @override
  String get paymentMethod => 'Payment method';

  @override
  String get payCashHint => 'Pay the rider when it arrives';

  @override
  String get payCard => 'CIB / Edahabia card';

  @override
  String get payCcp => 'CCP / BaridiMob';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String placeOrderTotal(String amount) {
    return 'Place order · $amount';
  }

  @override
  String get payOnDeliveryNote => 'You only pay on delivery.';

  @override
  String youSave(String amount) {
    return 'You save $amount';
  }

  @override
  String get errPromoInvalid => 'Invalid code';

  @override
  String get errPromoNotHere => 'This code is not valid for this restaurant';

  @override
  String get errPromoNotStarted => 'This code is not active yet';

  @override
  String get errPromoExpired => 'This code has expired';

  @override
  String get errPromoMinOrder => 'Minimum order amount not reached';

  @override
  String get errPromoUsedUp => 'This code has been used up';

  @override
  String get errPromoAlreadyUsed => 'You already used this code';

  @override
  String get errPaymentUnavailable => 'This payment method is coming soon';

  @override
  String get navPromos => 'Promo codes';

  @override
  String get promoNew => 'New code';

  @override
  String get promoEdit => 'Edit code';

  @override
  String get promoKindPercent => 'Percentage';

  @override
  String get promoKindAmount => 'Fixed amount';

  @override
  String get promoValuePercent => 'Discount (%)';

  @override
  String get promoValueAmount => 'Discount (DA)';

  @override
  String get promoMaxDiscount => 'Max discount (DA)';

  @override
  String get promoMinOrder => 'Minimum order (DA)';

  @override
  String get promoMaxUses => 'Max uses (total)';

  @override
  String get promoPerCustomer => 'Max per customer';

  @override
  String get promoEnds => 'Expires on';

  @override
  String get promoNoEnd => 'No end date';

  @override
  String get promoRestaurant => 'Restaurant';

  @override
  String get promoAllRestaurants => 'All restaurants';

  @override
  String get promoFundedBy => 'Paid by';

  @override
  String get fundedPlatform => 'The platform';

  @override
  String get fundedRestaurant => 'The restaurant';

  @override
  String promoUses(int n) {
    return '$n uses';
  }

  @override
  String promoGiven(String amount) {
    return '$amount given';
  }

  @override
  String get promoActive => 'Active';

  @override
  String get promoInactive => 'Off';

  @override
  String get promoNote => 'Internal note';

  @override
  String promoMin(String amount) {
    return 'from $amount';
  }

  @override
  String get errPromoCode => 'Code: 3–20 letters or digits';

  @override
  String get errPromoTaken => 'This code already exists';

  @override
  String get errPromoValue => 'Check the values (percentage 1–90)';

  @override
  String get noPromos => 'No codes yet';

  @override
  String get amountDue => 'Amount due';

  @override
  String get taxCollected => 'Tax collected';

  @override
  String get platformDiscounts => 'Discounts paid by the platform';

  @override
  String get taxLabel => 'Tax';

  @override
  String get copy => 'Copy';

  @override
  String get copied => 'Copied';

  @override
  String get qrTitle => 'Restaurant QR code';

  @override
  String get qrHint => 'Printable poster, scans';

  @override
  String get qrScanToOrder => 'Scan to order';

  @override
  String get qrDownloadPoster => 'Download the poster (PDF)';

  @override
  String get qrCopyLink => 'Copy link';

  @override
  String get qrStatsTitle => 'Scans of your QR code';

  @override
  String get qrScans30 => 'Scans (30 days)';

  @override
  String get qrPeople => 'People';

  @override
  String get qrOrdersAfter => 'Orders after a scan';

  @override
  String qrScansTotal(int total, int app, int web) {
    return '$total scans in total · $app in the app · $web with the camera';
  }

  @override
  String get qrTip =>
      'Stick the poster on the window, the counter and the tables, and put it in delivery bags. A scan opens your page straight in foodfennec.';

  @override
  String get scanTitle => 'Scan a QR code';

  @override
  String get scanHint => 'Point at a foodfennec restaurant’s QR code';

  @override
  String get scanNotOurs => 'This is not a foodfennec QR code';

  @override
  String get scanCameraDenied => 'Allow the camera in your settings to scan.';

  @override
  String get scanCameraError => 'Couldn’t open the camera.';

  @override
  String get qrLinkSetting => 'QR code link';

  @override
  String get qrLinkLabel => 'Website address';

  @override
  String get qrLinkHelp =>
      'QR codes open this address + /r/restaurant-name. Set your real domain before printing posters. The in-app scanner works whatever the domain.';

  @override
  String get errQrLink => 'Invalid address (e.g. https://foodfennec.com)';

  @override
  String get wilaya => 'Wilaya';

  @override
  String get chooseWilaya => 'Choose your wilaya';

  @override
  String get errWilaya => 'Choose your wilaya';

  @override
  String get commune => 'Commune';

  @override
  String get communeHint => 'e.g. Bab Ezzouar';

  @override
  String get errCommune => 'Enter your commune';

  @override
  String get birthDate => 'Date of birth';

  @override
  String get chooseDate => 'Choose a date';

  @override
  String get errBirthDate => 'Invalid date of birth (13 or older)';

  @override
  String get gender => 'Gender';

  @override
  String get genderMale => 'Male';

  @override
  String get genderFemale => 'Female';

  @override
  String get howDidYouHear => 'How did you hear about foodfennec?';

  @override
  String get refFriend => 'A friend';

  @override
  String get refSocial => 'Social media';

  @override
  String get refSearch => 'Google search';

  @override
  String get refRestaurant => 'A restaurant';

  @override
  String get refAd => 'An ad';

  @override
  String get refOther => 'Other';

  @override
  String get completeProfileTitle => 'Complete your profile';

  @override
  String get completeProfileBody => '30 seconds to get offers made for you.';

  @override
  String get completeProfileAction => 'Complete';

  @override
  String get completeProfilePrivacy =>
      'This stays private: it helps us improve foodfennec.';

  @override
  String get later => 'Later';

  @override
  String get thanksProfile => 'Thanks! Profile updated.';

  @override
  String get cancelOrderTitle => 'Cancel the order?';

  @override
  String get cancelRequestTitle => 'Ask to cancel';

  @override
  String get cancelFreeExplain =>
      'The restaurant hasn’t accepted yet: cancelling is immediate and free.';

  @override
  String get cancelRequestExplain =>
      'The restaurant is already preparing your order. It gets your request and decides: if cooking has started, it can refuse.';

  @override
  String get cancelWhy => 'Why?';

  @override
  String get cancelReasonChangedMind => 'I changed my mind';

  @override
  String get cancelReasonTooLong => 'It’s taking too long';

  @override
  String get cancelReasonWrongAddress => 'Wrong address';

  @override
  String get cancelReasonWrongItems => 'Mistake in my order';

  @override
  String get cancelReasonDuplicate => 'Duplicate order';

  @override
  String get cancelReasonOther => 'Other reason';

  @override
  String get cancelNoteHint => 'A note for the restaurant (optional)';

  @override
  String get sendCancelRequest => 'Send request';

  @override
  String get cancelRequestSent => 'Request sent: the restaurant will answer.';

  @override
  String get cancelRequestPending =>
      'Cancellation requested. The restaurant will answer.';

  @override
  String get cancelRequestRefused =>
      'The restaurant refused: your order is already being prepared and goes on.';

  @override
  String get cancelRequestExpired =>
      'Too late to cancel: the rider already picked it up.';

  @override
  String cancelledByYou(String reason) {
    return 'Cancelled at your request · $reason';
  }

  @override
  String get errCancelAlreadyRequested => 'You already asked to cancel';

  @override
  String get errCancelRequestRefused =>
      'The restaurant already refused to cancel';

  @override
  String get customerWantsCancel => 'The customer asks to cancel';

  @override
  String get cancelRequestOwnerHint => 'Accept if cooking hasn’t started.';

  @override
  String get acceptCancel => 'Accept cancellation';

  @override
  String get refuseCancel => 'Refuse';

  @override
  String get cancelAcceptedMsg => 'Order cancelled at the customer’s request';

  @override
  String get cancelRefusedMsg => 'Cancellation refused: the order goes on';

  @override
  String get accountSuspendedTitle => 'Account suspended';

  @override
  String accountSuspendedUntil(String date) {
    return 'You can use foodfennec again on $date.';
  }

  @override
  String get accountBannedTitle => 'Account blocked';

  @override
  String get accountBannedBody =>
      'Your account was blocked. Contact us if you think this is a mistake.';

  @override
  String get sanctionReasonTitle => 'Reason';

  @override
  String get contactSupport => 'Contact support';

  @override
  String get warningTitle => 'Warning';

  @override
  String get warningBody =>
      'If it happens again, your account may be suspended.';

  @override
  String get understood => 'I understand';

  @override
  String get errAccountSuspended => 'Your account is suspended';

  @override
  String get sanctionFakeOrders => 'Fake orders';

  @override
  String get sanctionNoShow => 'Not there at delivery';

  @override
  String get sanctionRefusedToPay => 'Refused to pay';

  @override
  String get sanctionAbuse => 'Disrespectful behaviour';

  @override
  String get sanctionFraud => 'Fraud';

  @override
  String get sanctionTooManyCancellations => 'Too many cancellations';

  @override
  String get sanctionUnsafeDriving => 'Unsafe driving';

  @override
  String get sanctionCashNotReturned => 'Cash not handed to the restaurant';

  @override
  String get sanctionOther => 'Breaking the rules';

  @override
  String get sanctionWarning => 'Warning';

  @override
  String get sanctionSuspension => 'Suspension';

  @override
  String get sanctionBan => 'Ban';

  @override
  String get suspendedPill => 'Suspended';

  @override
  String get bannedPill => 'Banned';

  @override
  String get warnAction => 'Warn';

  @override
  String get suspendAction => 'Suspend';

  @override
  String get banAction => 'Ban';

  @override
  String get liftAction => 'Lift';

  @override
  String get removeAction => 'Remove';

  @override
  String get warnTitle => 'Send a warning';

  @override
  String get suspendTitle => 'Suspend the account';

  @override
  String get banTitle => 'Ban the account';

  @override
  String get warnExplain =>
      'They see it once when opening the app and can keep using it.';

  @override
  String get suspendExplain =>
      'No orders (customer) or deliveries (rider) until it ends.';

  @override
  String get banExplain => 'Blocked until you lift it.';

  @override
  String get suspendFor => 'Duration';

  @override
  String daysCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get messageToUser => 'Message to the person';

  @override
  String get messageToUserHint =>
      'e.g. Please only order when you are available.';

  @override
  String get adminNoteLabel => 'Internal note (admin)';

  @override
  String get sanctionHistory => 'History';

  @override
  String get noSanctions => 'No sanctions';

  @override
  String get sanctionsTitle => 'Sanctions';

  @override
  String get sanctionLifted => 'Sanction lifted';

  @override
  String untilDate(String date) {
    return 'until $date';
  }

  @override
  String liftedOn(String date) {
    return 'lifted on $date';
  }

  @override
  String get seen => 'seen';

  @override
  String get allCustomers => 'All';

  @override
  String watchlistTab(int n) {
    return 'Watchlist ($n)';
  }

  @override
  String get watchlistHelp =>
      'Customers who cancelled (or asked to) 3 times or more in 30 days.';

  @override
  String get watchlistEmpty => 'Nobody to watch';

  @override
  String cancels30d(int n) {
    return '$n cancellations in 30 days';
  }

  @override
  String openReports(int n) {
    return '$n reports';
  }

  @override
  String get statCustomers => 'Customers';

  @override
  String get statNew7d => 'New (7 days)';

  @override
  String statActive7d(int today) {
    return 'Active 7 days · $today today';
  }

  @override
  String get statOrdered => 'Have ordered';

  @override
  String get statProfileDone => 'Profile completed';

  @override
  String get ageGroups => 'Age';

  @override
  String get heardFrom => 'Heard from';

  @override
  String get platformLabel => 'Platform';

  @override
  String get unknownValue => 'Not given';

  @override
  String get ageLabel => 'Age';

  @override
  String get memberSince => 'Signed up';

  @override
  String get deviceAndActivity => 'Device and activity';

  @override
  String get lastSeen => 'Last seen';

  @override
  String get activeDays30 => 'Active days (30 d)';

  @override
  String get deviceLabel => 'Device';

  @override
  String get ordersTotal => 'Orders';

  @override
  String get cancels30dLabel => 'Cancellations (30 d)';

  @override
  String get spentLabel => 'Spent';

  @override
  String get lastOrder => 'Last order';
}
