import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @appName.
  ///
  /// In fr, this message translates to:
  /// **'Food App'**
  String get appName;

  /// No description provided for @language.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get language;

  /// No description provided for @langAr.
  ///
  /// In fr, this message translates to:
  /// **'العربية'**
  String get langAr;

  /// No description provided for @langFr.
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get langFr;

  /// No description provided for @langEn.
  ///
  /// In fr, this message translates to:
  /// **'English'**
  String get langEn;

  /// No description provided for @back.
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get back;

  /// No description provided for @addToCart.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter au panier'**
  String get addToCart;

  /// No description provided for @cart.
  ///
  /// In fr, this message translates to:
  /// **'Panier'**
  String get cart;

  /// No description provided for @checkout.
  ///
  /// In fr, this message translates to:
  /// **'Commander'**
  String get checkout;

  /// No description provided for @placeOrder.
  ///
  /// In fr, this message translates to:
  /// **'Passer la commande'**
  String get placeOrder;

  /// No description provided for @total.
  ///
  /// In fr, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @subtotal.
  ///
  /// In fr, this message translates to:
  /// **'Sous-total'**
  String get subtotal;

  /// No description provided for @deliveryFee.
  ///
  /// In fr, this message translates to:
  /// **'Livraison'**
  String get deliveryFee;

  /// No description provided for @freeDelivery.
  ///
  /// In fr, this message translates to:
  /// **'Gratuit'**
  String get freeDelivery;

  /// No description provided for @minutes.
  ///
  /// In fr, this message translates to:
  /// **'{count} min'**
  String minutes(int count);

  /// No description provided for @open.
  ///
  /// In fr, this message translates to:
  /// **'Ouvert'**
  String get open;

  /// No description provided for @closed.
  ///
  /// In fr, this message translates to:
  /// **'Fermé'**
  String get closed;

  /// No description provided for @fullName.
  ///
  /// In fr, this message translates to:
  /// **'Nom complet'**
  String get fullName;

  /// No description provided for @phone.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone'**
  String get phone;

  /// No description provided for @address.
  ///
  /// In fr, this message translates to:
  /// **'Adresse'**
  String get address;

  /// No description provided for @area.
  ///
  /// In fr, this message translates to:
  /// **'Quartier / commune'**
  String get area;

  /// No description provided for @notes.
  ///
  /// In fr, this message translates to:
  /// **'Remarques'**
  String get notes;

  /// No description provided for @optional.
  ///
  /// In fr, this message translates to:
  /// **'facultatif'**
  String get optional;

  /// No description provided for @cashOnDelivery.
  ///
  /// In fr, this message translates to:
  /// **'Paiement à la livraison'**
  String get cashOnDelivery;

  /// No description provided for @otherRestaurants.
  ///
  /// In fr, this message translates to:
  /// **'Autres restaurants'**
  String get otherRestaurants;

  /// No description provided for @email.
  ///
  /// In fr, this message translates to:
  /// **'E-mail'**
  String get email;

  /// No description provided for @password.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get password;

  /// No description provided for @logIn.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get logIn;

  /// No description provided for @logInSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Connectez-vous à votre compte'**
  String get logInSubtitle;

  /// No description provided for @accept.
  ///
  /// In fr, this message translates to:
  /// **'Accepter'**
  String get accept;

  /// No description provided for @reject.
  ///
  /// In fr, this message translates to:
  /// **'Refuser'**
  String get reject;

  /// No description provided for @ready.
  ///
  /// In fr, this message translates to:
  /// **'Prêt'**
  String get ready;

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get save;

  /// No description provided for @statusPlaced.
  ///
  /// In fr, this message translates to:
  /// **'Commande envoyée'**
  String get statusPlaced;

  /// No description provided for @statusAccepted.
  ///
  /// In fr, this message translates to:
  /// **'Acceptée par le restaurant'**
  String get statusAccepted;

  /// No description provided for @statusReady.
  ///
  /// In fr, this message translates to:
  /// **'Prête'**
  String get statusReady;

  /// No description provided for @statusPickedUp.
  ///
  /// In fr, this message translates to:
  /// **'En route'**
  String get statusPickedUp;

  /// No description provided for @statusDelivered.
  ///
  /// In fr, this message translates to:
  /// **'Livrée'**
  String get statusDelivered;

  /// No description provided for @statusRejected.
  ///
  /// In fr, this message translates to:
  /// **'Refusée'**
  String get statusRejected;

  /// No description provided for @statusCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Annulée'**
  String get statusCancelled;

  /// No description provided for @runningOrders.
  ///
  /// In fr, this message translates to:
  /// **'Commandes en cours'**
  String get runningOrders;

  /// No description provided for @orderRequests.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelles demandes'**
  String get orderRequests;

  /// No description provided for @itemCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucun article} =1{1 article} other{{count} articles}}'**
  String itemCount(int count);

  /// No description provided for @componentGallery.
  ///
  /// In fr, this message translates to:
  /// **'Galerie des composants'**
  String get componentGallery;

  /// No description provided for @onb1Title.
  ///
  /// In fr, this message translates to:
  /// **'Tous vos plats préférés'**
  String get onb1Title;

  /// No description provided for @onb1Body.
  ///
  /// In fr, this message translates to:
  /// **'Tous vos plats préférés au même endroit. Vous commandez, on s\'occupe du reste.'**
  String get onb1Body;

  /// No description provided for @onb2Title.
  ///
  /// In fr, this message translates to:
  /// **'Les meilleurs restaurants'**
  String get onb2Title;

  /// No description provided for @onb2Body.
  ///
  /// In fr, this message translates to:
  /// **'Les restaurants de votre quartier, tout leur menu, en quelques secondes.'**
  String get onb2Body;

  /// No description provided for @onb3Title.
  ///
  /// In fr, this message translates to:
  /// **'Paiement à la livraison'**
  String get onb3Title;

  /// No description provided for @onb3Body.
  ///
  /// In fr, this message translates to:
  /// **'Pas besoin de carte : payez en espèces à l\'arrivée de votre commande.'**
  String get onb3Body;

  /// No description provided for @next.
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get next;

  /// No description provided for @skip.
  ///
  /// In fr, this message translates to:
  /// **'Passer'**
  String get skip;

  /// No description provided for @getStarted.
  ///
  /// In fr, this message translates to:
  /// **'Commencer'**
  String get getStarted;

  /// No description provided for @logInTitle.
  ///
  /// In fr, this message translates to:
  /// **'Connexion'**
  String get logInTitle;

  /// No description provided for @logInSubtitleLong.
  ///
  /// In fr, this message translates to:
  /// **'Connectez-vous à votre compte'**
  String get logInSubtitleLong;

  /// No description provided for @signUpTitle.
  ///
  /// In fr, this message translates to:
  /// **'Inscription'**
  String get signUpTitle;

  /// No description provided for @signUpSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Inscrivez-vous pour commencer'**
  String get signUpSubtitle;

  /// No description provided for @signUp.
  ///
  /// In fr, this message translates to:
  /// **'S\'inscrire'**
  String get signUp;

  /// No description provided for @name.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get name;

  /// No description provided for @namePlaceholder.
  ///
  /// In fr, this message translates to:
  /// **'Karim Benali'**
  String get namePlaceholder;

  /// No description provided for @emailPlaceholder.
  ///
  /// In fr, this message translates to:
  /// **'exemple@gmail.com'**
  String get emailPlaceholder;

  /// No description provided for @retypePassword.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le mot de passe'**
  String get retypePassword;

  /// No description provided for @rememberMe.
  ///
  /// In fr, this message translates to:
  /// **'Se souvenir de moi'**
  String get rememberMe;

  /// No description provided for @forgotPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié'**
  String get forgotPassword;

  /// No description provided for @noAccount.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de compte ?'**
  String get noAccount;

  /// No description provided for @haveAccount.
  ///
  /// In fr, this message translates to:
  /// **'Déjà un compte ?'**
  String get haveAccount;

  /// No description provided for @verificationTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vérification'**
  String get verificationTitle;

  /// No description provided for @codeSentTo.
  ///
  /// In fr, this message translates to:
  /// **'Nous avons envoyé un code à'**
  String get codeSentTo;

  /// No description provided for @code.
  ///
  /// In fr, this message translates to:
  /// **'Code'**
  String get code;

  /// No description provided for @resend.
  ///
  /// In fr, this message translates to:
  /// **'Renvoyer'**
  String get resend;

  /// No description provided for @resendIn.
  ///
  /// In fr, this message translates to:
  /// **'dans {seconds} s'**
  String resendIn(int seconds);

  /// No description provided for @verify.
  ///
  /// In fr, this message translates to:
  /// **'Vérifier'**
  String get verify;

  /// No description provided for @codeResent.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau code envoyé'**
  String get codeResent;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Entrez votre e-mail pour recevoir un code'**
  String get forgotPasswordSubtitle;

  /// No description provided for @sendCode.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer le code'**
  String get sendCode;

  /// No description provided for @newPasswordTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau mot de passe'**
  String get newPasswordTitle;

  /// No description provided for @newPasswordSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez un nouveau mot de passe'**
  String get newPasswordSubtitle;

  /// No description provided for @newPassword.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau mot de passe'**
  String get newPassword;

  /// No description provided for @passwordUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe modifié'**
  String get passwordUpdated;

  /// No description provided for @logOut.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get logOut;

  /// No description provided for @hello.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour, {name}'**
  String hello(String name);

  /// No description provided for @homeComingSoon.
  ///
  /// In fr, this message translates to:
  /// **'Les restaurants arrivent à la prochaine étape.'**
  String get homeComingSoon;

  /// No description provided for @errNameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Entrez votre nom (2 à 80 caractères)'**
  String get errNameRequired;

  /// No description provided for @errEmailInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Adresse e-mail invalide'**
  String get errEmailInvalid;

  /// No description provided for @errPasswordShort.
  ///
  /// In fr, this message translates to:
  /// **'8 caractères minimum'**
  String get errPasswordShort;

  /// No description provided for @errPasswordMismatch.
  ///
  /// In fr, this message translates to:
  /// **'Les mots de passe ne correspondent pas'**
  String get errPasswordMismatch;

  /// No description provided for @errCodeIncomplete.
  ///
  /// In fr, this message translates to:
  /// **'Entrez le code à 6 chiffres'**
  String get errCodeIncomplete;

  /// No description provided for @errInvalidCredentials.
  ///
  /// In fr, this message translates to:
  /// **'E-mail ou mot de passe incorrect'**
  String get errInvalidCredentials;

  /// No description provided for @errUserExists.
  ///
  /// In fr, this message translates to:
  /// **'Un compte existe déjà avec cet e-mail'**
  String get errUserExists;

  /// No description provided for @errCodeInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Code incorrect ou expiré'**
  String get errCodeInvalid;

  /// No description provided for @errTooManyRequests.
  ///
  /// In fr, this message translates to:
  /// **'Trop de tentatives, réessayez dans un moment'**
  String get errTooManyRequests;

  /// No description provided for @errWeakPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe trop faible'**
  String get errWeakPassword;

  /// No description provided for @errNetwork.
  ///
  /// In fr, this message translates to:
  /// **'Pas de connexion. Vérifiez votre réseau.'**
  String get errNetwork;

  /// No description provided for @errGeneric.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue, réessayez'**
  String get errGeneric;

  /// No description provided for @errBackendMissing.
  ///
  /// In fr, this message translates to:
  /// **'Serveur non configuré (env.json)'**
  String get errBackendMissing;

  /// No description provided for @showPassword.
  ///
  /// In fr, this message translates to:
  /// **'Afficher le mot de passe'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In fr, this message translates to:
  /// **'Masquer le mot de passe'**
  String get hidePassword;

  /// No description provided for @errEmailSend.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'envoyer l\'e-mail de code à cette adresse. Réessayez plus tard.'**
  String get errEmailSend;

  /// No description provided for @errServer.
  ///
  /// In fr, this message translates to:
  /// **'Le serveur a rencontré un problème. Réessayez dans un instant.'**
  String get errServer;

  /// No description provided for @deliverTo.
  ///
  /// In fr, this message translates to:
  /// **'Livrer à'**
  String get deliverTo;

  /// No description provided for @chooseAddress.
  ///
  /// In fr, this message translates to:
  /// **'Choisir une adresse'**
  String get chooseAddress;

  /// No description provided for @greetingMorning.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour {name} !'**
  String greetingMorning(String name);

  /// No description provided for @greetingAfternoon.
  ///
  /// In fr, this message translates to:
  /// **'Bon après-midi {name} !'**
  String greetingAfternoon(String name);

  /// No description provided for @greetingEvening.
  ///
  /// In fr, this message translates to:
  /// **'Bonsoir {name} !'**
  String greetingEvening(String name);

  /// No description provided for @searchHint.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher plats, restaurants'**
  String get searchHint;

  /// No description provided for @allCategories.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les catégories'**
  String get allCategories;

  /// No description provided for @seeAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout voir'**
  String get seeAll;

  /// No description provided for @openRestaurants.
  ///
  /// In fr, this message translates to:
  /// **'Restaurants'**
  String get openRestaurants;

  /// No description provided for @all.
  ///
  /// In fr, this message translates to:
  /// **'Tout'**
  String get all;

  /// No description provided for @fromPrice.
  ///
  /// In fr, this message translates to:
  /// **'Dès {price}'**
  String fromPrice(String price);

  /// No description provided for @kmAway.
  ///
  /// In fr, this message translates to:
  /// **'{km} km'**
  String kmAway(String km);

  /// No description provided for @recentKeywords.
  ///
  /// In fr, this message translates to:
  /// **'Recherches récentes'**
  String get recentKeywords;

  /// No description provided for @suggestedRestaurants.
  ///
  /// In fr, this message translates to:
  /// **'Restaurants suggérés'**
  String get suggestedRestaurants;

  /// No description provided for @noResults.
  ///
  /// In fr, this message translates to:
  /// **'Aucun résultat pour « {query} »'**
  String noResults(String query);

  /// No description provided for @dishes.
  ///
  /// In fr, this message translates to:
  /// **'Plats'**
  String get dishes;

  /// No description provided for @restaurantsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Restaurants'**
  String get restaurantsTitle;

  /// No description provided for @restaurant.
  ///
  /// In fr, this message translates to:
  /// **'Restaurant'**
  String get restaurant;

  /// No description provided for @details.
  ///
  /// In fr, this message translates to:
  /// **'Détails'**
  String get details;

  /// No description provided for @popularIn.
  ///
  /// In fr, this message translates to:
  /// **'{category} populaires'**
  String popularIn(String category);

  /// No description provided for @addedToCart.
  ///
  /// In fr, this message translates to:
  /// **'Ajouté au panier'**
  String get addedToCart;

  /// No description provided for @cartOtherRestaurant.
  ///
  /// In fr, this message translates to:
  /// **'Votre panier contient des articles de {name}. Commencer un nouveau panier ?'**
  String cartOtherRestaurant(String name);

  /// No description provided for @newCart.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau panier'**
  String get newCart;

  /// No description provided for @unavailable.
  ///
  /// In fr, this message translates to:
  /// **'Indisponible'**
  String get unavailable;

  /// No description provided for @restaurantNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Restaurant introuvable'**
  String get restaurantNotFound;

  /// No description provided for @restaurantClosedNote.
  ///
  /// In fr, this message translates to:
  /// **'Ce restaurant est fermé pour le moment'**
  String get restaurantClosedNote;

  /// No description provided for @retry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get retry;

  /// No description provided for @loadError.
  ///
  /// In fr, this message translates to:
  /// **'Chargement impossible. Vérifiez votre connexion.'**
  String get loadError;

  /// No description provided for @accessLocation.
  ///
  /// In fr, this message translates to:
  /// **'Accéder à la position'**
  String get accessLocation;

  /// No description provided for @locationExplain.
  ///
  /// In fr, this message translates to:
  /// **'FOOD UTILISE VOTRE POSITION UNIQUEMENT PENDANT L\'UTILISATION DE L\'APPLICATION'**
  String get locationExplain;

  /// No description provided for @notNow.
  ///
  /// In fr, this message translates to:
  /// **'Plus tard'**
  String get notNow;

  /// No description provided for @locationDenied.
  ///
  /// In fr, this message translates to:
  /// **'Accès à la position refusé'**
  String get locationDenied;

  /// No description provided for @profile.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get profile;

  /// No description provided for @personalInfo.
  ///
  /// In fr, this message translates to:
  /// **'Informations personnelles'**
  String get personalInfo;

  /// No description provided for @addresses.
  ///
  /// In fr, this message translates to:
  /// **'Adresses'**
  String get addresses;

  /// No description provided for @edit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get edit;

  /// No description provided for @editProfile.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le profil'**
  String get editProfile;

  /// No description provided for @saved.
  ///
  /// In fr, this message translates to:
  /// **'Enregistré'**
  String get saved;

  /// No description provided for @changePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Changer la photo'**
  String get changePhoto;

  /// No description provided for @phoneOptionalHint.
  ///
  /// In fr, this message translates to:
  /// **'0550 12 34 56'**
  String get phoneOptionalHint;

  /// No description provided for @errPhoneInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Numéro invalide (05, 06 ou 07 + 8 chiffres)'**
  String get errPhoneInvalid;

  /// No description provided for @addNewAddress.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une adresse'**
  String get addNewAddress;

  /// No description provided for @editAddress.
  ///
  /// In fr, this message translates to:
  /// **'Modifier l\'adresse'**
  String get editAddress;

  /// No description provided for @saveLocation.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer l\'adresse'**
  String get saveLocation;

  /// No description provided for @labelAs.
  ///
  /// In fr, this message translates to:
  /// **'Type'**
  String get labelAs;

  /// No description provided for @labelHome.
  ///
  /// In fr, this message translates to:
  /// **'Maison'**
  String get labelHome;

  /// No description provided for @labelWork.
  ///
  /// In fr, this message translates to:
  /// **'Travail'**
  String get labelWork;

  /// No description provided for @labelOther.
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get labelOther;

  /// No description provided for @addressDetails.
  ///
  /// In fr, this message translates to:
  /// **'Bâtiment, étage, porte'**
  String get addressDetails;

  /// No description provided for @addressHint.
  ///
  /// In fr, this message translates to:
  /// **'Cité 200 logements, rue…'**
  String get addressHint;

  /// No description provided for @areaHint.
  ///
  /// In fr, this message translates to:
  /// **'Kouba, Hydra, Bab Ezzouar…'**
  String get areaHint;

  /// No description provided for @setDefault.
  ///
  /// In fr, this message translates to:
  /// **'Définir par défaut'**
  String get setDefault;

  /// No description provided for @defaultTag.
  ///
  /// In fr, this message translates to:
  /// **'Par défaut'**
  String get defaultTag;

  /// No description provided for @delete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get delete;

  /// No description provided for @deleteAddressConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer cette adresse ?'**
  String get deleteAddressConfirm;

  /// No description provided for @noAddresses.
  ///
  /// In fr, this message translates to:
  /// **'Aucune adresse enregistrée'**
  String get noAddresses;

  /// No description provided for @moveMapHint.
  ///
  /// In fr, this message translates to:
  /// **'Déplacez la carte pour placer le repère'**
  String get moveMapHint;

  /// No description provided for @useMyLocation.
  ///
  /// In fr, this message translates to:
  /// **'Ma position'**
  String get useMyLocation;

  /// No description provided for @errAddressRequired.
  ///
  /// In fr, this message translates to:
  /// **'Entrez l\'adresse (3 caractères minimum)'**
  String get errAddressRequired;

  /// No description provided for @errAddressLimit.
  ///
  /// In fr, this message translates to:
  /// **'Vous pouvez enregistrer 10 adresses au maximum'**
  String get errAddressLimit;

  /// No description provided for @search.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher'**
  String get search;

  /// No description provided for @cartEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Votre panier est vide'**
  String get cartEmpty;

  /// No description provided for @checkoutNextStep.
  ///
  /// In fr, this message translates to:
  /// **'La commande sera disponible à la prochaine étape.'**
  String get checkoutNextStep;

  /// No description provided for @ownRestaurant.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez un restaurant ?'**
  String get ownRestaurant;

  /// No description provided for @registerIt.
  ///
  /// In fr, this message translates to:
  /// **'Inscrivez-le'**
  String get registerIt;

  /// No description provided for @registerRestaurantTitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre restaurant'**
  String get registerRestaurantTitle;

  /// No description provided for @registerRestaurantSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Rejoignez Food et recevez des commandes'**
  String get registerRestaurantSubtitle;

  /// No description provided for @yourAccount.
  ///
  /// In fr, this message translates to:
  /// **'Votre compte'**
  String get yourAccount;

  /// No description provided for @restaurantSection.
  ///
  /// In fr, this message translates to:
  /// **'Le restaurant'**
  String get restaurantSection;

  /// No description provided for @restaurantName.
  ///
  /// In fr, this message translates to:
  /// **'Nom du restaurant'**
  String get restaurantName;

  /// No description provided for @restaurantPhone.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone du restaurant'**
  String get restaurantPhone;

  /// No description provided for @prepTime.
  ///
  /// In fr, this message translates to:
  /// **'Temps de préparation (min)'**
  String get prepTime;

  /// No description provided for @errRestaurantPhone.
  ///
  /// In fr, this message translates to:
  /// **'Numéro invalide (ex. 0550123456 ou 021234567)'**
  String get errRestaurantPhone;

  /// No description provided for @errPrepTime.
  ///
  /// In fr, this message translates to:
  /// **'Entre 5 et 120 minutes'**
  String get errPrepTime;

  /// No description provided for @pendingApprovalTitle.
  ///
  /// In fr, this message translates to:
  /// **'En attente de validation'**
  String get pendingApprovalTitle;

  /// No description provided for @pendingApprovalBody.
  ///
  /// In fr, this message translates to:
  /// **'Nous vérifions votre restaurant. Préparez votre menu en attendant : les clients le verront dès la validation.'**
  String get pendingApprovalBody;

  /// No description provided for @openForOrders.
  ///
  /// In fr, this message translates to:
  /// **'Ouvert aux commandes'**
  String get openForOrders;

  /// No description provided for @closedForOrders.
  ///
  /// In fr, this message translates to:
  /// **'Fermé'**
  String get closedForOrders;

  /// No description provided for @openSwitchHint.
  ///
  /// In fr, this message translates to:
  /// **'Les clients peuvent commander quand c\'est activé'**
  String get openSwitchHint;

  /// No description provided for @cantOpenPending.
  ///
  /// In fr, this message translates to:
  /// **'Vous pourrez ouvrir après la validation'**
  String get cantOpenPending;

  /// No description provided for @dashboard.
  ///
  /// In fr, this message translates to:
  /// **'Tableau de bord'**
  String get dashboard;

  /// No description provided for @menu.
  ///
  /// In fr, this message translates to:
  /// **'Menu'**
  String get menu;

  /// No description provided for @orders.
  ///
  /// In fr, this message translates to:
  /// **'Commandes'**
  String get orders;

  /// No description provided for @myMenu.
  ///
  /// In fr, this message translates to:
  /// **'Mon menu'**
  String get myMenu;

  /// No description provided for @totalItems.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucun plat} =1{1 plat} other{{count} plats}}'**
  String totalItems(int count);

  /// No description provided for @addItem.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un plat'**
  String get addItem;

  /// No description provided for @editItem.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le plat'**
  String get editItem;

  /// No description provided for @reset.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser'**
  String get reset;

  /// No description provided for @itemName.
  ///
  /// In fr, this message translates to:
  /// **'Nom du plat'**
  String get itemName;

  /// No description provided for @itemNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Pizza Margherita'**
  String get itemNameHint;

  /// No description provided for @uploadPhoto.
  ///
  /// In fr, this message translates to:
  /// **'Photo'**
  String get uploadPhoto;

  /// No description provided for @add.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get add;

  /// No description provided for @price.
  ///
  /// In fr, this message translates to:
  /// **'Prix (DA)'**
  String get price;

  /// No description provided for @priceHint.
  ///
  /// In fr, this message translates to:
  /// **'650'**
  String get priceHint;

  /// No description provided for @errPrice.
  ///
  /// In fr, this message translates to:
  /// **'Prix entre 10 et 100 000 DA'**
  String get errPrice;

  /// No description provided for @category.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie'**
  String get category;

  /// No description provided for @noCategory.
  ///
  /// In fr, this message translates to:
  /// **'Aucune'**
  String get noCategory;

  /// No description provided for @available.
  ///
  /// In fr, this message translates to:
  /// **'Disponible'**
  String get available;

  /// No description provided for @itemDetails.
  ///
  /// In fr, this message translates to:
  /// **'Description'**
  String get itemDetails;

  /// No description provided for @itemDetailsHint.
  ///
  /// In fr, this message translates to:
  /// **'Ingrédients, taille…'**
  String get itemDetailsHint;

  /// No description provided for @saveChanges.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get saveChanges;

  /// No description provided for @deleteItemConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer ce plat ?'**
  String get deleteItemConfirm;

  /// No description provided for @emptyMenu.
  ///
  /// In fr, this message translates to:
  /// **'Votre menu est vide. Ajoutez votre premier plat.'**
  String get emptyMenu;

  /// No description provided for @ordersComingSoon.
  ///
  /// In fr, this message translates to:
  /// **'Les commandes en direct arrivent à la prochaine étape.'**
  String get ordersComingSoon;

  /// No description provided for @restaurantProfile.
  ///
  /// In fr, this message translates to:
  /// **'Profil du restaurant'**
  String get restaurantProfile;

  /// No description provided for @coverPhoto.
  ///
  /// In fr, this message translates to:
  /// **'Photo de couverture'**
  String get coverPhoto;

  /// No description provided for @logo.
  ///
  /// In fr, this message translates to:
  /// **'Logo'**
  String get logo;

  /// No description provided for @description.
  ///
  /// In fr, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @descriptionHint.
  ///
  /// In fr, this message translates to:
  /// **'Pizzas au feu de bois, tacos…'**
  String get descriptionHint;

  /// No description provided for @restaurantLocation.
  ///
  /// In fr, this message translates to:
  /// **'Position sur la carte'**
  String get restaurantLocation;

  /// No description provided for @errPhotoTooLarge.
  ///
  /// In fr, this message translates to:
  /// **'Photo trop lourde (3 Mo max)'**
  String get errPhotoTooLarge;

  /// No description provided for @dishesAvailable.
  ///
  /// In fr, this message translates to:
  /// **'{available} sur {total} disponibles'**
  String dishesAvailable(int available, int total);

  /// No description provided for @seeMenu.
  ///
  /// In fr, this message translates to:
  /// **'Voir le menu'**
  String get seeMenu;

  /// No description provided for @registrationDone.
  ///
  /// In fr, this message translates to:
  /// **'Restaurant enregistré'**
  String get registrationDone;

  /// No description provided for @admin.
  ///
  /// In fr, this message translates to:
  /// **'Administration'**
  String get admin;

  /// No description provided for @receipts.
  ///
  /// In fr, this message translates to:
  /// **'Relevés'**
  String get receipts;

  /// No description provided for @settings.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get settings;

  /// No description provided for @customers.
  ///
  /// In fr, this message translates to:
  /// **'Clients'**
  String get customers;

  /// No description provided for @periodToday.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get periodToday;

  /// No description provided for @periodLast7.
  ///
  /// In fr, this message translates to:
  /// **'7 jours'**
  String get periodLast7;

  /// No description provided for @periodThisMonth.
  ///
  /// In fr, this message translates to:
  /// **'Ce mois'**
  String get periodThisMonth;

  /// No description provided for @periodLastMonth.
  ///
  /// In fr, this message translates to:
  /// **'Mois dernier'**
  String get periodLastMonth;

  /// No description provided for @periodCustom.
  ///
  /// In fr, this message translates to:
  /// **'Personnalisé'**
  String get periodCustom;

  /// No description provided for @previousHalfMonth.
  ///
  /// In fr, this message translates to:
  /// **'Quinzaine précédente'**
  String get previousHalfMonth;

  /// No description provided for @statDelivered.
  ///
  /// In fr, this message translates to:
  /// **'Commandes livrées'**
  String get statDelivered;

  /// No description provided for @statSales.
  ///
  /// In fr, this message translates to:
  /// **'Ventes (repas)'**
  String get statSales;

  /// No description provided for @statDeliveryFees.
  ///
  /// In fr, this message translates to:
  /// **'Frais de livraison'**
  String get statDeliveryFees;

  /// No description provided for @statCommission.
  ///
  /// In fr, this message translates to:
  /// **'Commission gagnée'**
  String get statCommission;

  /// No description provided for @statCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Annulées / refusées'**
  String get statCancelled;

  /// No description provided for @statActive.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get statActive;

  /// No description provided for @statPending.
  ///
  /// In fr, this message translates to:
  /// **'Restaurants à valider'**
  String get statPending;

  /// No description provided for @statActiveRestaurants.
  ///
  /// In fr, this message translates to:
  /// **'Restaurants actifs'**
  String get statActiveRestaurants;

  /// No description provided for @statUnbilled.
  ///
  /// In fr, this message translates to:
  /// **'Commission non facturée'**
  String get statUnbilled;

  /// No description provided for @byRestaurant.
  ///
  /// In fr, this message translates to:
  /// **'Par restaurant'**
  String get byRestaurant;

  /// No description provided for @filterPending.
  ///
  /// In fr, this message translates to:
  /// **'À valider'**
  String get filterPending;

  /// No description provided for @filterActive.
  ///
  /// In fr, this message translates to:
  /// **'Actifs'**
  String get filterActive;

  /// No description provided for @filterInactive.
  ///
  /// In fr, this message translates to:
  /// **'Désactivés'**
  String get filterInactive;

  /// No description provided for @approve.
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get approve;

  /// No description provided for @deactivate.
  ///
  /// In fr, this message translates to:
  /// **'Désactiver'**
  String get deactivate;

  /// No description provided for @reactivate.
  ///
  /// In fr, this message translates to:
  /// **'Réactiver'**
  String get reactivate;

  /// No description provided for @commissionRate.
  ///
  /// In fr, this message translates to:
  /// **'Taux de commission'**
  String get commissionRate;

  /// No description provided for @defaultRate.
  ///
  /// In fr, this message translates to:
  /// **'Par défaut ({rate})'**
  String defaultRate(String rate);

  /// No description provided for @useDefault.
  ///
  /// In fr, this message translates to:
  /// **'Taux par défaut'**
  String get useDefault;

  /// No description provided for @errRate.
  ///
  /// In fr, this message translates to:
  /// **'Entre 0 et 50 %'**
  String get errRate;

  /// No description provided for @owner.
  ///
  /// In fr, this message translates to:
  /// **'Gérant'**
  String get owner;

  /// No description provided for @toBill.
  ///
  /// In fr, this message translates to:
  /// **'À facturer : {amount}'**
  String toBill(String amount);

  /// No description provided for @deliveredCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} livrées'**
  String deliveredCount(int count);

  /// No description provided for @noRestaurants.
  ///
  /// In fr, this message translates to:
  /// **'Aucun restaurant'**
  String get noRestaurants;

  /// No description provided for @newReceipt.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau relevé'**
  String get newReceipt;

  /// No description provided for @receiptPeriod.
  ///
  /// In fr, this message translates to:
  /// **'Période'**
  String get receiptPeriod;

  /// No description provided for @receiptPreview.
  ///
  /// In fr, this message translates to:
  /// **'{count} commandes livrées · ventes {food}'**
  String receiptPreview(int count, String food);

  /// No description provided for @commissionDue.
  ///
  /// In fr, this message translates to:
  /// **'Commission due'**
  String get commissionDue;

  /// No description provided for @generateReceipt.
  ///
  /// In fr, this message translates to:
  /// **'Générer le relevé'**
  String get generateReceipt;

  /// No description provided for @noOrdersToBill.
  ///
  /// In fr, this message translates to:
  /// **'Aucune commande livrée à facturer sur cette période'**
  String get noOrdersToBill;

  /// No description provided for @periodNotFinished.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez une période terminée'**
  String get periodNotFinished;

  /// No description provided for @statusPaid.
  ///
  /// In fr, this message translates to:
  /// **'Payé'**
  String get statusPaid;

  /// No description provided for @statusUnpaid.
  ///
  /// In fr, this message translates to:
  /// **'Non payé'**
  String get statusUnpaid;

  /// No description provided for @markPaid.
  ///
  /// In fr, this message translates to:
  /// **'Marquer payé'**
  String get markPaid;

  /// No description provided for @markUnpaid.
  ///
  /// In fr, this message translates to:
  /// **'Marquer non payé'**
  String get markUnpaid;

  /// No description provided for @downloadPdf.
  ///
  /// In fr, this message translates to:
  /// **'Télécharger le PDF'**
  String get downloadPdf;

  /// No description provided for @printPdf.
  ///
  /// In fr, this message translates to:
  /// **'Imprimer'**
  String get printPdf;

  /// No description provided for @cancelReceipt.
  ///
  /// In fr, this message translates to:
  /// **'Annuler le relevé'**
  String get cancelReceipt;

  /// No description provided for @cancelReceiptConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Annuler ce relevé ? Ses commandes pourront être refacturées.'**
  String get cancelReceiptConfirm;

  /// No description provided for @noReceipts.
  ///
  /// In fr, this message translates to:
  /// **'Aucun relevé pour l\'instant'**
  String get noReceipts;

  /// No description provided for @allRestaurants.
  ///
  /// In fr, this message translates to:
  /// **'Tous les restaurants'**
  String get allRestaurants;

  /// No description provided for @allStatuses.
  ///
  /// In fr, this message translates to:
  /// **'Tous les statuts'**
  String get allStatuses;

  /// No description provided for @noOrders.
  ///
  /// In fr, this message translates to:
  /// **'Aucune commande'**
  String get noOrders;

  /// No description provided for @loadMore.
  ///
  /// In fr, this message translates to:
  /// **'Voir plus'**
  String get loadMore;

  /// No description provided for @itemsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Articles'**
  String get itemsTitle;

  /// No description provided for @defaultCommission.
  ///
  /// In fr, this message translates to:
  /// **'Commission par défaut (%)'**
  String get defaultCommission;

  /// No description provided for @deliveryFeeDa.
  ///
  /// In fr, this message translates to:
  /// **'Frais de livraison (DA)'**
  String get deliveryFeeDa;

  /// No description provided for @errDeliveryFee.
  ///
  /// In fr, this message translates to:
  /// **'Entre 0 et 5 000 DA'**
  String get errDeliveryFee;

  /// No description provided for @businessInfo.
  ///
  /// In fr, this message translates to:
  /// **'Vos informations (imprimées sur les relevés)'**
  String get businessInfo;

  /// No description provided for @businessName.
  ///
  /// In fr, this message translates to:
  /// **'Nom commercial'**
  String get businessName;

  /// No description provided for @businessPhone.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone'**
  String get businessPhone;

  /// No description provided for @businessEmail.
  ///
  /// In fr, this message translates to:
  /// **'E-mail'**
  String get businessEmail;

  /// No description provided for @businessAddress.
  ///
  /// In fr, this message translates to:
  /// **'Adresse'**
  String get businessAddress;

  /// No description provided for @businessTaxId.
  ///
  /// In fr, this message translates to:
  /// **'NIF'**
  String get businessTaxId;

  /// No description provided for @searchCustomers.
  ///
  /// In fr, this message translates to:
  /// **'Nom, e-mail ou téléphone'**
  String get searchCustomers;

  /// No description provided for @ordersCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucune commande} =1{1 commande} other{{count} commandes}}'**
  String ordersCount(int count);

  /// No description provided for @restaurantFilter.
  ///
  /// In fr, this message translates to:
  /// **'Restaurant'**
  String get restaurantFilter;

  /// No description provided for @statusFilter.
  ///
  /// In fr, this message translates to:
  /// **'Statut'**
  String get statusFilter;

  /// No description provided for @issuedOn.
  ///
  /// In fr, this message translates to:
  /// **'Émis le {date}'**
  String issuedOn(String date);

  /// No description provided for @deliveryAddress.
  ///
  /// In fr, this message translates to:
  /// **'Adresse de livraison'**
  String get deliveryAddress;

  /// No description provided for @breakdown.
  ///
  /// In fr, this message translates to:
  /// **'Détail'**
  String get breakdown;

  /// No description provided for @addDeliveryAddress.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une adresse de livraison'**
  String get addDeliveryAddress;

  /// No description provided for @deliveryDetails.
  ///
  /// In fr, this message translates to:
  /// **'Détails de livraison'**
  String get deliveryDetails;

  /// No description provided for @phoneForDriver.
  ///
  /// In fr, this message translates to:
  /// **'Le restaurant et le livreur vous appelleront sur ce numéro.'**
  String get phoneForDriver;

  /// No description provided for @notesHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex. : sans oignons, 2e étage'**
  String get notesHint;

  /// No description provided for @orderPlacedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Commande envoyée !'**
  String get orderPlacedTitle;

  /// No description provided for @orderPlacedBody.
  ///
  /// In fr, this message translates to:
  /// **'Le restaurant va confirmer votre commande. Vous paierez {total} en espèces à la livraison.'**
  String orderPlacedBody(String total);

  /// No description provided for @trackOrder.
  ///
  /// In fr, this message translates to:
  /// **'Suivre la commande'**
  String get trackOrder;

  /// No description provided for @backToHome.
  ///
  /// In fr, this message translates to:
  /// **'Retour à l\'accueil'**
  String get backToHome;

  /// No description provided for @myOrders.
  ///
  /// In fr, this message translates to:
  /// **'Mes commandes'**
  String get myOrders;

  /// No description provided for @ongoingOrders.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get ongoingOrders;

  /// No description provided for @orderHistory.
  ///
  /// In fr, this message translates to:
  /// **'Historique'**
  String get orderHistory;

  /// No description provided for @noOngoingOrders.
  ///
  /// In fr, this message translates to:
  /// **'Aucune commande en cours'**
  String get noOngoingOrders;

  /// No description provided for @noPastOrders.
  ///
  /// In fr, this message translates to:
  /// **'Aucune commande passée'**
  String get noPastOrders;

  /// No description provided for @orderNumber.
  ///
  /// In fr, this message translates to:
  /// **'Commande #{code}'**
  String orderNumber(String code);

  /// No description provided for @orderedAt.
  ///
  /// In fr, this message translates to:
  /// **'Commandée le {date}'**
  String orderedAt(String date);

  /// No description provided for @cancelOrder.
  ///
  /// In fr, this message translates to:
  /// **'Annuler la commande'**
  String get cancelOrder;

  /// No description provided for @cancelOrderConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Annuler cette commande ?'**
  String get cancelOrderConfirm;

  /// No description provided for @keepOrder.
  ///
  /// In fr, this message translates to:
  /// **'Non, garder'**
  String get keepOrder;

  /// No description provided for @orderCancelledMsg.
  ///
  /// In fr, this message translates to:
  /// **'Commande annulée'**
  String get orderCancelledMsg;

  /// No description provided for @rejectReasonLabel.
  ///
  /// In fr, this message translates to:
  /// **'Motif : {reason}'**
  String rejectReasonLabel(String reason);

  /// No description provided for @payInCash.
  ///
  /// In fr, this message translates to:
  /// **'À payer en espèces'**
  String get payInCash;

  /// No description provided for @orderItems.
  ///
  /// In fr, this message translates to:
  /// **'Votre commande'**
  String get orderItems;

  /// No description provided for @callRestaurant.
  ///
  /// In fr, this message translates to:
  /// **'Appeler le restaurant'**
  String get callRestaurant;

  /// No description provided for @errRestaurantClosed.
  ///
  /// In fr, this message translates to:
  /// **'Ce restaurant est fermé pour le moment.'**
  String get errRestaurantClosed;

  /// No description provided for @errRestaurantUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Ce restaurant n\'est plus disponible.'**
  String get errRestaurantUnavailable;

  /// No description provided for @errItemUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Un plat n\'est plus disponible. Votre panier a été mis à jour.'**
  String get errItemUnavailable;

  /// No description provided for @errPricesChanged.
  ///
  /// In fr, this message translates to:
  /// **'Les prix ont changé. Votre panier a été mis à jour, vérifiez le total.'**
  String get errPricesChanged;

  /// No description provided for @errTooManyActiveOrders.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez déjà 3 commandes en cours. Attendez qu\'une soit livrée.'**
  String get errTooManyActiveOrders;

  /// No description provided for @errTooManyOrders.
  ///
  /// In fr, this message translates to:
  /// **'Trop de commandes en peu de temps. Réessayez plus tard.'**
  String get errTooManyOrders;

  /// No description provided for @errAddressGone.
  ///
  /// In fr, this message translates to:
  /// **'Cette adresse n\'existe plus. Choisissez-en une autre.'**
  String get errAddressGone;

  /// No description provided for @errCannotCancel.
  ///
  /// In fr, this message translates to:
  /// **'Le restaurant a déjà accepté la commande, elle ne peut plus être annulée.'**
  String get errCannotCancel;

  /// No description provided for @tabNewOrders.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelles ({count})'**
  String tabNewOrders(int count);

  /// No description provided for @tabInProgress.
  ///
  /// In fr, this message translates to:
  /// **'En cours ({count})'**
  String tabInProgress(int count);

  /// No description provided for @markReady.
  ///
  /// In fr, this message translates to:
  /// **'Prête'**
  String get markReady;

  /// No description provided for @waitingDriver.
  ///
  /// In fr, this message translates to:
  /// **'En attente du livreur'**
  String get waitingDriver;

  /// No description provided for @rejectOrderTitle.
  ///
  /// In fr, this message translates to:
  /// **'Refuser la commande'**
  String get rejectOrderTitle;

  /// No description provided for @cancelOrderTitleOwner.
  ///
  /// In fr, this message translates to:
  /// **'Annuler la commande'**
  String get cancelOrderTitleOwner;

  /// No description provided for @reasonLabel.
  ///
  /// In fr, this message translates to:
  /// **'Motif (visible par le client)'**
  String get reasonLabel;

  /// No description provided for @reasonBusy.
  ///
  /// In fr, this message translates to:
  /// **'Trop de commandes en ce moment'**
  String get reasonBusy;

  /// No description provided for @reasonItemOut.
  ///
  /// In fr, this message translates to:
  /// **'Un plat n\'est plus disponible'**
  String get reasonItemOut;

  /// No description provided for @reasonClosing.
  ///
  /// In fr, this message translates to:
  /// **'Nous fermons bientôt'**
  String get reasonClosing;

  /// No description provided for @reasonUnreachable.
  ///
  /// In fr, this message translates to:
  /// **'Client injoignable'**
  String get reasonUnreachable;

  /// No description provided for @errReasonRequired.
  ///
  /// In fr, this message translates to:
  /// **'Indiquez un motif.'**
  String get errReasonRequired;

  /// No description provided for @errOrderChanged.
  ///
  /// In fr, this message translates to:
  /// **'Cette commande a changé entre-temps. La liste est à jour.'**
  String get errOrderChanged;

  /// No description provided for @enableSoundAlerts.
  ///
  /// In fr, this message translates to:
  /// **'Touchez ici pour activer l\'alerte sonore des nouvelles commandes'**
  String get enableSoundAlerts;

  /// No description provided for @soundOn.
  ///
  /// In fr, this message translates to:
  /// **'Alerte sonore activée'**
  String get soundOn;

  /// No description provided for @soundOff.
  ///
  /// In fr, this message translates to:
  /// **'Alerte sonore coupée'**
  String get soundOff;

  /// No description provided for @minutesAgo.
  ///
  /// In fr, this message translates to:
  /// **'il y a {count} min'**
  String minutesAgo(int count);

  /// No description provided for @justNow.
  ///
  /// In fr, this message translates to:
  /// **'à l\'instant'**
  String get justNow;

  /// No description provided for @noNewOrders.
  ///
  /// In fr, this message translates to:
  /// **'Aucune nouvelle commande'**
  String get noNewOrders;

  /// No description provided for @noOrdersInProgress.
  ///
  /// In fr, this message translates to:
  /// **'Aucune commande en cours'**
  String get noOrdersInProgress;

  /// No description provided for @customer.
  ///
  /// In fr, this message translates to:
  /// **'Client'**
  String get customer;

  /// No description provided for @orderAcceptedMsg.
  ///
  /// In fr, this message translates to:
  /// **'Commande acceptée'**
  String get orderAcceptedMsg;

  /// No description provided for @orderReadyMsg.
  ///
  /// In fr, this message translates to:
  /// **'Commande prête, en attente du livreur'**
  String get orderReadyMsg;

  /// No description provided for @orderRejectedMsg.
  ///
  /// In fr, this message translates to:
  /// **'Commande refusée'**
  String get orderRejectedMsg;

  /// No description provided for @newOrderBanner.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 nouvelle commande à accepter} other{{count} nouvelles commandes à accepter}}'**
  String newOrderBanner(int count);

  /// No description provided for @deliverWithUs.
  ///
  /// In fr, this message translates to:
  /// **'Vous êtes livreur ?'**
  String get deliverWithUs;

  /// No description provided for @joinAsDriver.
  ///
  /// In fr, this message translates to:
  /// **'Rejoignez-nous'**
  String get joinAsDriver;

  /// No description provided for @registerDriverTitle.
  ///
  /// In fr, this message translates to:
  /// **'Devenir livreur'**
  String get registerDriverTitle;

  /// No description provided for @registerDriverSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Livrez des commandes près de chez vous'**
  String get registerDriverSubtitle;

  /// No description provided for @driverSection.
  ///
  /// In fr, this message translates to:
  /// **'Livreur'**
  String get driverSection;

  /// No description provided for @driverPhone.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone (mobile)'**
  String get driverPhone;

  /// No description provided for @vehicle.
  ///
  /// In fr, this message translates to:
  /// **'Véhicule'**
  String get vehicle;

  /// No description provided for @vehicleMoto.
  ///
  /// In fr, this message translates to:
  /// **'Moto'**
  String get vehicleMoto;

  /// No description provided for @vehicleCar.
  ///
  /// In fr, this message translates to:
  /// **'Voiture'**
  String get vehicleCar;

  /// No description provided for @vehicleBike.
  ///
  /// In fr, this message translates to:
  /// **'Vélo'**
  String get vehicleBike;

  /// No description provided for @driverRegistered.
  ///
  /// In fr, this message translates to:
  /// **'Inscription envoyée. Un administrateur va valider votre compte.'**
  String get driverRegistered;

  /// No description provided for @driverPendingTitle.
  ///
  /// In fr, this message translates to:
  /// **'En attente de validation'**
  String get driverPendingTitle;

  /// No description provided for @driverPendingBody.
  ///
  /// In fr, this message translates to:
  /// **'L\'administrateur doit valider votre compte avant que vous puissiez livrer.'**
  String get driverPendingBody;

  /// No description provided for @onlineLabel.
  ///
  /// In fr, this message translates to:
  /// **'En ligne'**
  String get onlineLabel;

  /// No description provided for @offlineLabel.
  ///
  /// In fr, this message translates to:
  /// **'Hors ligne'**
  String get offlineLabel;

  /// No description provided for @youAreOnline.
  ///
  /// In fr, this message translates to:
  /// **'Vous recevez les nouvelles commandes.'**
  String get youAreOnline;

  /// No description provided for @youAreOffline.
  ///
  /// In fr, this message translates to:
  /// **'Passez en ligne pour recevoir des commandes.'**
  String get youAreOffline;

  /// No description provided for @availableOrders.
  ///
  /// In fr, this message translates to:
  /// **'Commandes disponibles'**
  String get availableOrders;

  /// No description provided for @noAvailableOrders.
  ///
  /// In fr, this message translates to:
  /// **'Aucune commande pour le moment. La liste se met à jour toute seule.'**
  String get noAvailableOrders;

  /// No description provided for @takeOrder.
  ///
  /// In fr, this message translates to:
  /// **'Je la prends'**
  String get takeOrder;

  /// No description provided for @orderTaken.
  ///
  /// In fr, this message translates to:
  /// **'Commande à vous ! Allez au restaurant.'**
  String get orderTaken;

  /// No description provided for @errAlreadyTaken.
  ///
  /// In fr, this message translates to:
  /// **'Un autre livreur l\'a prise avant vous.'**
  String get errAlreadyTaken;

  /// No description provided for @errDriverBusy.
  ///
  /// In fr, this message translates to:
  /// **'Terminez d\'abord votre livraison en cours.'**
  String get errDriverBusy;

  /// No description provided for @errNotOnline.
  ///
  /// In fr, this message translates to:
  /// **'Passez en ligne d\'abord.'**
  String get errNotOnline;

  /// No description provided for @errNotApproved.
  ///
  /// In fr, this message translates to:
  /// **'Votre compte n\'est pas encore validé.'**
  String get errNotApproved;

  /// No description provided for @currentDelivery.
  ///
  /// In fr, this message translates to:
  /// **'Livraison en cours'**
  String get currentDelivery;

  /// No description provided for @pickupAt.
  ///
  /// In fr, this message translates to:
  /// **'Récupérer chez'**
  String get pickupAt;

  /// No description provided for @dropOffAt.
  ///
  /// In fr, this message translates to:
  /// **'Livrer à'**
  String get dropOffAt;

  /// No description provided for @cashToCollect.
  ///
  /// In fr, this message translates to:
  /// **'À encaisser'**
  String get cashToCollect;

  /// No description provided for @yourFee.
  ///
  /// In fr, this message translates to:
  /// **'Votre gain'**
  String get yourFee;

  /// No description provided for @handToRestaurant.
  ///
  /// In fr, this message translates to:
  /// **'À remettre au restaurant'**
  String get handToRestaurant;

  /// No description provided for @waitRestaurant.
  ///
  /// In fr, this message translates to:
  /// **'Le restaurant prépare la commande. Attendez qu\'elle soit prête.'**
  String get waitRestaurant;

  /// No description provided for @markPickedUp.
  ///
  /// In fr, this message translates to:
  /// **'Commande récupérée'**
  String get markPickedUp;

  /// No description provided for @markDelivered.
  ///
  /// In fr, this message translates to:
  /// **'Livrée et payée'**
  String get markDelivered;

  /// No description provided for @confirmDelivered.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer la livraison ? Le client vous a payé {total}.'**
  String confirmDelivered(String total);

  /// No description provided for @confirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get confirm;

  /// No description provided for @releaseOrder.
  ///
  /// In fr, this message translates to:
  /// **'Rendre la commande'**
  String get releaseOrder;

  /// No description provided for @releaseConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Rendre cette commande aux autres livreurs ?'**
  String get releaseConfirm;

  /// No description provided for @callAction.
  ///
  /// In fr, this message translates to:
  /// **'Appeler'**
  String get callAction;

  /// No description provided for @directions.
  ///
  /// In fr, this message translates to:
  /// **'Itinéraire'**
  String get directions;

  /// No description provided for @deliveredMsg.
  ///
  /// In fr, this message translates to:
  /// **'Livraison terminée. Merci !'**
  String get deliveredMsg;

  /// No description provided for @pickedUpMsg.
  ///
  /// In fr, this message translates to:
  /// **'En route vers le client'**
  String get pickedUpMsg;

  /// No description provided for @cancelledByRestaurant.
  ///
  /// In fr, this message translates to:
  /// **'Le restaurant a annulé cette commande.'**
  String get cancelledByRestaurant;

  /// No description provided for @todaySummary.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui : {count} livraisons · {amount}'**
  String todaySummary(int count, String amount);

  /// No description provided for @driversTitle.
  ///
  /// In fr, this message translates to:
  /// **'Livreurs'**
  String get driversTitle;

  /// No description provided for @noDrivers.
  ///
  /// In fr, this message translates to:
  /// **'Aucun livreur'**
  String get noDrivers;

  /// No description provided for @currentOrderCode.
  ///
  /// In fr, this message translates to:
  /// **'Commande en cours : #{code}'**
  String currentOrderCode(String code);

  /// No description provided for @yourDriver.
  ///
  /// In fr, this message translates to:
  /// **'Votre livreur'**
  String get yourDriver;

  /// No description provided for @driverLabel.
  ///
  /// In fr, this message translates to:
  /// **'Livreur : {name}'**
  String driverLabel(String name);

  /// No description provided for @myDeliveries.
  ///
  /// In fr, this message translates to:
  /// **'Mes livraisons'**
  String get myDeliveries;

  /// No description provided for @noDeliveries.
  ///
  /// In fr, this message translates to:
  /// **'Aucune livraison'**
  String get noDeliveries;

  /// No description provided for @driverApproved.
  ///
  /// In fr, this message translates to:
  /// **'Compte validé'**
  String get driverApproved;

  /// No description provided for @proofTitle.
  ///
  /// In fr, this message translates to:
  /// **'Photo de livraison'**
  String get proofTitle;

  /// No description provided for @proofHint.
  ///
  /// In fr, this message translates to:
  /// **'Prenez en photo la commande remise au client (ou devant sa porte). Elle sert de preuve en cas de litige.'**
  String get proofHint;

  /// No description provided for @takePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Prendre la photo'**
  String get takePhoto;

  /// No description provided for @retakePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Reprendre'**
  String get retakePhoto;

  /// No description provided for @errPhotoRequired.
  ///
  /// In fr, this message translates to:
  /// **'La photo est obligatoire pour confirmer la livraison.'**
  String get errPhotoRequired;

  /// No description provided for @errCashOverdue.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez de l\'argent à remettre depuis trop longtemps. Le restaurant doit confirmer la réception avant que vous preniez de nouvelles commandes.'**
  String get errCashOverdue;

  /// No description provided for @cashBlockedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelles commandes bloquées'**
  String get cashBlockedTitle;

  /// No description provided for @moneyToHand.
  ///
  /// In fr, this message translates to:
  /// **'Argent à remettre aux restaurants'**
  String get moneyToHand;

  /// No description provided for @moneyToHandTotal.
  ///
  /// In fr, this message translates to:
  /// **'Total à remettre : {amount}'**
  String moneyToHandTotal(String amount);

  /// No description provided for @iGaveMoney.
  ///
  /// In fr, this message translates to:
  /// **'J\'ai remis l\'argent'**
  String get iGaveMoney;

  /// No description provided for @waitingRestaurantConfirm.
  ///
  /// In fr, this message translates to:
  /// **'En attente de confirmation du restaurant'**
  String get waitingRestaurantConfirm;

  /// No description provided for @cashHandedMsg.
  ///
  /// In fr, this message translates to:
  /// **'Noté. Le restaurant doit confirmer la réception.'**
  String get cashHandedMsg;

  /// No description provided for @cashToReceive.
  ///
  /// In fr, this message translates to:
  /// **'Argent à recevoir des livreurs'**
  String get cashToReceive;

  /// No description provided for @confirmReceived.
  ///
  /// In fr, this message translates to:
  /// **'Reçu'**
  String get confirmReceived;

  /// No description provided for @confirmReceivedQ.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer avoir reçu {amount} de {name} ?'**
  String confirmReceivedQ(String amount, String name);

  /// No description provided for @cashConfirmedMsg.
  ///
  /// In fr, this message translates to:
  /// **'Réception confirmée'**
  String get cashConfirmedMsg;

  /// No description provided for @driverSaysHanded.
  ///
  /// In fr, this message translates to:
  /// **'Le livreur dit l\'avoir remis'**
  String get driverSaysHanded;

  /// No description provided for @proofOfDelivery.
  ///
  /// In fr, this message translates to:
  /// **'Preuve de livraison'**
  String get proofOfDelivery;

  /// No description provided for @cashOwedLine.
  ///
  /// In fr, this message translates to:
  /// **'Doit {amount} ({count} commandes)'**
  String cashOwedLine(String amount, int count);

  /// No description provided for @cashBlockedPill.
  ///
  /// In fr, this message translates to:
  /// **'Bloqué'**
  String get cashBlockedPill;

  /// No description provided for @cashStatusConfirmed.
  ///
  /// In fr, this message translates to:
  /// **'Argent reçu par le restaurant'**
  String get cashStatusConfirmed;

  /// No description provided for @cashStatusHanded.
  ///
  /// In fr, this message translates to:
  /// **'Argent remis par le livreur, à confirmer'**
  String get cashStatusHanded;

  /// No description provided for @cashStatusPending.
  ///
  /// In fr, this message translates to:
  /// **'Argent pas encore remis au restaurant'**
  String get cashStatusPending;

  /// No description provided for @deliveredOnTime.
  ///
  /// In fr, this message translates to:
  /// **'Livrée {date}'**
  String deliveredOnTime(String date);

  /// No description provided for @cashHoursSetting.
  ///
  /// In fr, this message translates to:
  /// **'Bloquer un livreur après (heures sans remise)'**
  String get cashHoursSetting;

  /// No description provided for @errCashHours.
  ///
  /// In fr, this message translates to:
  /// **'Entre 1 et 168 heures'**
  String get errCashHours;

  /// No description provided for @downloadReceipt.
  ///
  /// In fr, this message translates to:
  /// **'Télécharger le reçu'**
  String get downloadReceipt;

  /// No description provided for @printAction.
  ///
  /// In fr, this message translates to:
  /// **'Imprimer'**
  String get printAction;

  /// No description provided for @receiptOrderTitle.
  ///
  /// In fr, this message translates to:
  /// **'Reçu de commande'**
  String get receiptOrderTitle;

  /// No description provided for @receiptOrderNo.
  ///
  /// In fr, this message translates to:
  /// **'Commande'**
  String get receiptOrderNo;

  /// No description provided for @receiptDate.
  ///
  /// In fr, this message translates to:
  /// **'Date'**
  String get receiptDate;

  /// No description provided for @receiptDeliveredOn.
  ///
  /// In fr, this message translates to:
  /// **'Livrée le'**
  String get receiptDeliveredOn;

  /// No description provided for @receiptCustomer.
  ///
  /// In fr, this message translates to:
  /// **'Client'**
  String get receiptCustomer;

  /// No description provided for @receiptItem.
  ///
  /// In fr, this message translates to:
  /// **'Article'**
  String get receiptItem;

  /// No description provided for @receiptQty.
  ///
  /// In fr, this message translates to:
  /// **'Qté'**
  String get receiptQty;

  /// No description provided for @receiptUnit.
  ///
  /// In fr, this message translates to:
  /// **'Prix unitaire'**
  String get receiptUnit;

  /// No description provided for @receiptAmount.
  ///
  /// In fr, this message translates to:
  /// **'Montant'**
  String get receiptAmount;

  /// No description provided for @receiptPaidCash.
  ///
  /// In fr, this message translates to:
  /// **'Payé en espèces à la livraison'**
  String get receiptPaidCash;

  /// No description provided for @receiptDeliveredBy.
  ///
  /// In fr, this message translates to:
  /// **'Livré par'**
  String get receiptDeliveredBy;

  /// No description provided for @receiptTotalPaid.
  ///
  /// In fr, this message translates to:
  /// **'Total payé'**
  String get receiptTotalPaid;

  /// No description provided for @receiptFooter.
  ///
  /// In fr, this message translates to:
  /// **'Montants en dinars algériens (DA). Document généré par l\'application.'**
  String get receiptFooter;

  /// No description provided for @receiptPage.
  ///
  /// In fr, this message translates to:
  /// **'Page'**
  String get receiptPage;

  /// No description provided for @taxIdShort.
  ///
  /// In fr, this message translates to:
  /// **'NIF'**
  String get taxIdShort;

  /// No description provided for @driverStatementTitle.
  ///
  /// In fr, this message translates to:
  /// **'Relevé du livreur'**
  String get driverStatementTitle;

  /// No description provided for @downloadStatement.
  ///
  /// In fr, this message translates to:
  /// **'Télécharger le relevé'**
  String get downloadStatement;

  /// No description provided for @periodThisWeek.
  ///
  /// In fr, this message translates to:
  /// **'Cette semaine'**
  String get periodThisWeek;

  /// No description provided for @periodLastWeek.
  ///
  /// In fr, this message translates to:
  /// **'Semaine dernière'**
  String get periodLastWeek;

  /// No description provided for @stDeliveries.
  ///
  /// In fr, this message translates to:
  /// **'Livraisons'**
  String get stDeliveries;

  /// No description provided for @stCollected.
  ///
  /// In fr, this message translates to:
  /// **'Encaissé'**
  String get stCollected;

  /// No description provided for @stToRestaurant.
  ///
  /// In fr, this message translates to:
  /// **'Au restaurant'**
  String get stToRestaurant;

  /// No description provided for @stFee.
  ///
  /// In fr, this message translates to:
  /// **'Gain'**
  String get stFee;

  /// No description provided for @stMoney.
  ///
  /// In fr, this message translates to:
  /// **'Argent'**
  String get stMoney;

  /// No description provided for @stConfirmed.
  ///
  /// In fr, this message translates to:
  /// **'Remis'**
  String get stConfirmed;

  /// No description provided for @stOpen.
  ///
  /// In fr, this message translates to:
  /// **'À remettre'**
  String get stOpen;

  /// No description provided for @stTotalCollected.
  ///
  /// In fr, this message translates to:
  /// **'Total encaissé'**
  String get stTotalCollected;

  /// No description provided for @stTotalToRestaurants.
  ///
  /// In fr, this message translates to:
  /// **'Total dû aux restaurants'**
  String get stTotalToRestaurants;

  /// No description provided for @stStillToGive.
  ///
  /// In fr, this message translates to:
  /// **'Reste à remettre'**
  String get stStillToGive;

  /// No description provided for @stEarned.
  ///
  /// In fr, this message translates to:
  /// **'Vos gains'**
  String get stEarned;

  /// No description provided for @stDriver.
  ///
  /// In fr, this message translates to:
  /// **'Livreur'**
  String get stDriver;

  /// No description provided for @noDeliveriesInPeriod.
  ///
  /// In fr, this message translates to:
  /// **'Aucune livraison sur cette période'**
  String get noDeliveriesInPeriod;

  /// No description provided for @myStatements.
  ///
  /// In fr, this message translates to:
  /// **'Mes relevés de commission'**
  String get myStatements;

  /// No description provided for @chooseFromGallery.
  ///
  /// In fr, this message translates to:
  /// **'Choisir dans la galerie'**
  String get chooseFromGallery;

  /// No description provided for @errCamera.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'ouvrir l\'appareil photo. Autorisez la caméra dans les réglages, ou choisissez une photo dans la galerie.'**
  String get errCamera;

  /// No description provided for @reasonNoAnswer.
  ///
  /// In fr, this message translates to:
  /// **'Le restaurant n\'a pas répondu à temps'**
  String get reasonNoAnswer;

  /// No description provided for @autoRejectSetting.
  ///
  /// In fr, this message translates to:
  /// **'Refus automatique si le restaurant ne répond pas (minutes)'**
  String get autoRejectSetting;

  /// No description provided for @errAutoReject.
  ///
  /// In fr, this message translates to:
  /// **'Entre 3 et 60 minutes'**
  String get errAutoReject;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
