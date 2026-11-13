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
  /// **'foodfennec'**
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
  /// **'Rejoignez foodfennec et recevez des commandes'**
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

  /// No description provided for @deleteAccount.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer mon compte'**
  String get deleteAccount;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer définitivement votre compte ? Vos adresses et votre photo seront effacées. Vos anciennes commandes restent anonymes pour la comptabilité.'**
  String get deleteAccountConfirm;

  /// No description provided for @accountDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Compte supprimé'**
  String get accountDeleted;

  /// No description provided for @errDeleteActiveOrders.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez une commande en cours. Réessayez quand elle est livrée.'**
  String get errDeleteActiveOrders;

  /// No description provided for @errDeleteNotCustomer.
  ///
  /// In fr, this message translates to:
  /// **'Les comptes restaurant et livreur sont fermés par l\'administrateur. Contactez-le.'**
  String get errDeleteNotCustomer;

  /// No description provided for @locationServiceOff.
  ///
  /// In fr, this message translates to:
  /// **'La localisation du téléphone est désactivée.'**
  String get locationServiceOff;

  /// No description provided for @locationBlocked.
  ///
  /// In fr, this message translates to:
  /// **'Localisation refusée pour cette application. Autorisez-la dans les réglages.'**
  String get locationBlocked;

  /// No description provided for @locationUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Position introuvable. Réessayez dehors ou cherchez votre adresse sur la carte.'**
  String get locationUnavailable;

  /// No description provided for @turnOn.
  ///
  /// In fr, this message translates to:
  /// **'Activer'**
  String get turnOn;

  /// No description provided for @openSettings.
  ///
  /// In fr, this message translates to:
  /// **'Réglages'**
  String get openSettings;

  /// No description provided for @searchAddressHint.
  ///
  /// In fr, this message translates to:
  /// **'Chercher une adresse, un quartier…'**
  String get searchAddressHint;

  /// No description provided for @navHome.
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get navHome;

  /// No description provided for @navAccount.
  ///
  /// In fr, this message translates to:
  /// **'Compte'**
  String get navAccount;

  /// No description provided for @viewProfile.
  ///
  /// In fr, this message translates to:
  /// **'Voir le profil'**
  String get viewProfile;

  /// No description provided for @general.
  ///
  /// In fr, this message translates to:
  /// **'Général'**
  String get general;

  /// No description provided for @helpCenter.
  ///
  /// In fr, this message translates to:
  /// **'Centre d\'aide'**
  String get helpCenter;

  /// No description provided for @supportSoon.
  ///
  /// In fr, this message translates to:
  /// **'Le numéro du service client sera bientôt disponible.'**
  String get supportSoon;

  /// No description provided for @becomePartner.
  ///
  /// In fr, this message translates to:
  /// **'Inscrire mon restaurant'**
  String get becomePartner;

  /// No description provided for @becomeDriver.
  ///
  /// In fr, this message translates to:
  /// **'Devenir livreur'**
  String get becomeDriver;

  /// No description provided for @termsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Conditions et confidentialité'**
  String get termsTitle;

  /// No description provided for @appVersion.
  ///
  /// In fr, this message translates to:
  /// **'Version'**
  String get appVersion;

  /// No description provided for @promoCashTitle.
  ///
  /// In fr, this message translates to:
  /// **'Payez à la livraison'**
  String get promoCashTitle;

  /// No description provided for @promoCashBody.
  ///
  /// In fr, this message translates to:
  /// **'En espèces, à l\'arrivée de votre commande. Sans carte.'**
  String get promoCashBody;

  /// No description provided for @promoFeeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Livraison {fee}'**
  String promoFeeTitle(String fee);

  /// No description provided for @promoFeeBody.
  ///
  /// In fr, this message translates to:
  /// **'Le même prix partout en ville.'**
  String get promoFeeBody;

  /// No description provided for @promoDiscover.
  ///
  /// In fr, this message translates to:
  /// **'Ouvert maintenant · Commandez →'**
  String get promoDiscover;

  /// No description provided for @termsOrdersTitle.
  ///
  /// In fr, this message translates to:
  /// **'Commandes et paiement'**
  String get termsOrdersTitle;

  /// No description provided for @termsOrdersBody.
  ///
  /// In fr, this message translates to:
  /// **'Les prix sont ceux du restaurant au moment de la commande. Vous payez en espèces à la livraison (plats + frais de livraison). Une commande peut être annulée tant que le restaurant ne l\'a pas acceptée.'**
  String get termsOrdersBody;

  /// No description provided for @termsDataTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vos données'**
  String get termsDataTitle;

  /// No description provided for @termsDataBody.
  ///
  /// In fr, this message translates to:
  /// **'Nous utilisons votre nom, téléphone et adresse uniquement pour livrer vos commandes. Le restaurant et le livreur les voient pour votre commande. Une photo de remise est prise à la livraison comme preuve.'**
  String get termsDataBody;

  /// No description provided for @termsDeleteTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer votre compte'**
  String get termsDeleteTitle;

  /// No description provided for @termsDeleteBody.
  ///
  /// In fr, this message translates to:
  /// **'Compte → Supprimer mon compte. Vos adresses et votre photo sont effacées ; vos anciennes commandes restent anonymes pour la comptabilité.'**
  String get termsDeleteBody;

  /// No description provided for @openNowTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ouverts maintenant'**
  String get openNowTitle;

  /// No description provided for @homeBanners.
  ///
  /// In fr, this message translates to:
  /// **'Bannières de l\'accueil'**
  String get homeBanners;

  /// No description provided for @addBanner.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une bannière'**
  String get addBanner;

  /// No description provided for @noBanners.
  ///
  /// In fr, this message translates to:
  /// **'Aucune bannière. Ajoutez des images (pubs, nouveautés) : elles défilent en haut de l\'accueil des clients.'**
  String get noBanners;

  /// No description provided for @bannerSizeHint.
  ///
  /// In fr, this message translates to:
  /// **'Format large conseillé : 1200 × 500 pixels.'**
  String get bannerSizeHint;

  /// No description provided for @choosePicture.
  ///
  /// In fr, this message translates to:
  /// **'Choisir une image'**
  String get choosePicture;

  /// No description provided for @bannerTitle.
  ///
  /// In fr, this message translates to:
  /// **'Titre'**
  String get bannerTitle;

  /// No description provided for @bannerOpens.
  ///
  /// In fr, this message translates to:
  /// **'Au toucher, ouvrir'**
  String get bannerOpens;

  /// No description provided for @bannerNoLink.
  ///
  /// In fr, this message translates to:
  /// **'Rien (image seule)'**
  String get bannerNoLink;

  /// No description provided for @deleteBannerConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer cette bannière ?'**
  String get deleteBannerConfirm;

  /// No description provided for @moveUp.
  ///
  /// In fr, this message translates to:
  /// **'Monter'**
  String get moveUp;

  /// No description provided for @moveDown.
  ///
  /// In fr, this message translates to:
  /// **'Descendre'**
  String get moveDown;

  /// No description provided for @appearance.
  ///
  /// In fr, this message translates to:
  /// **'Apparence'**
  String get appearance;

  /// No description provided for @themeSystem.
  ///
  /// In fr, this message translates to:
  /// **'Auto (comme le téléphone)'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In fr, this message translates to:
  /// **'Clair'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In fr, this message translates to:
  /// **'Sombre'**
  String get themeDark;

  /// No description provided for @insights.
  ///
  /// In fr, this message translates to:
  /// **'Tendances'**
  String get insights;

  /// No description provided for @todayTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get todayTitle;

  /// No description provided for @compareYesterday.
  ///
  /// In fr, this message translates to:
  /// **'Comparé à hier à la même heure'**
  String get compareYesterday;

  /// No description provided for @kpiSales.
  ///
  /// In fr, this message translates to:
  /// **'Ventes'**
  String get kpiSales;

  /// No description provided for @kpiOrders.
  ///
  /// In fr, this message translates to:
  /// **'Commandes'**
  String get kpiOrders;

  /// No description provided for @kpiAvgBasket.
  ///
  /// In fr, this message translates to:
  /// **'Panier moyen'**
  String get kpiAvgBasket;

  /// No description provided for @kpiPrep.
  ///
  /// In fr, this message translates to:
  /// **'Préparation moy.'**
  String get kpiPrep;

  /// No description provided for @kpiAcceptance.
  ///
  /// In fr, this message translates to:
  /// **'Taux d\'acceptation'**
  String get kpiAcceptance;

  /// No description provided for @kpiNet.
  ///
  /// In fr, this message translates to:
  /// **'Net après commission'**
  String get kpiNet;

  /// No description provided for @minutesShort.
  ///
  /// In fr, this message translates to:
  /// **'{n} min'**
  String minutesShort(int n);

  /// No description provided for @last7Days.
  ///
  /// In fr, this message translates to:
  /// **'7 derniers jours'**
  String get last7Days;

  /// No description provided for @seeInsights.
  ///
  /// In fr, this message translates to:
  /// **'Voir les tendances'**
  String get seeInsights;

  /// No description provided for @shortcuts.
  ///
  /// In fr, this message translates to:
  /// **'Raccourcis'**
  String get shortcuts;

  /// No description provided for @ordersTable.
  ///
  /// In fr, this message translates to:
  /// **'Tableau des commandes'**
  String get ordersTable;

  /// No description provided for @liveOrders.
  ///
  /// In fr, this message translates to:
  /// **'Commandes en direct'**
  String get liveOrders;

  /// No description provided for @dishesNoPhoto.
  ///
  /// In fr, this message translates to:
  /// **'{n} plats sans photo : les photos font vendre'**
  String dishesNoPhoto(int n);

  /// No description provided for @dishesUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'{n} plats indisponibles'**
  String dishesUnavailable(int n);

  /// No description provided for @menuHealthGood.
  ///
  /// In fr, this message translates to:
  /// **'Menu complet, bravo !'**
  String get menuHealthGood;

  /// No description provided for @rangeYesterday.
  ///
  /// In fr, this message translates to:
  /// **'Hier'**
  String get rangeYesterday;

  /// No description provided for @range7.
  ///
  /// In fr, this message translates to:
  /// **'7 jours'**
  String get range7;

  /// No description provided for @range30.
  ///
  /// In fr, this message translates to:
  /// **'30 jours'**
  String get range30;

  /// No description provided for @range90.
  ///
  /// In fr, this message translates to:
  /// **'90 jours'**
  String get range90;

  /// No description provided for @rangeMonth.
  ///
  /// In fr, this message translates to:
  /// **'Ce mois'**
  String get rangeMonth;

  /// No description provided for @rangeCustom.
  ///
  /// In fr, this message translates to:
  /// **'Dates…'**
  String get rangeCustom;

  /// No description provided for @filterAll.
  ///
  /// In fr, this message translates to:
  /// **'Toutes'**
  String get filterAll;

  /// No description provided for @filterInProgress.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get filterInProgress;

  /// No description provided for @searchOrdersHint.
  ///
  /// In fr, this message translates to:
  /// **'Code, client, plat…'**
  String get searchOrdersHint;

  /// No description provided for @exportCsv.
  ///
  /// In fr, this message translates to:
  /// **'Exporter CSV'**
  String get exportCsv;

  /// No description provided for @csvReady.
  ///
  /// In fr, this message translates to:
  /// **'Fichier CSV prêt'**
  String get csvReady;

  /// No description provided for @noOrdersPeriod.
  ///
  /// In fr, this message translates to:
  /// **'Aucune commande sur cette période'**
  String get noOrdersPeriod;

  /// No description provided for @tableTotals.
  ///
  /// In fr, this message translates to:
  /// **'Total de la sélection'**
  String get tableTotals;

  /// No description provided for @csvCode.
  ///
  /// In fr, this message translates to:
  /// **'Code'**
  String get csvCode;

  /// No description provided for @csvDate.
  ///
  /// In fr, this message translates to:
  /// **'Date'**
  String get csvDate;

  /// No description provided for @csvTime.
  ///
  /// In fr, this message translates to:
  /// **'Heure'**
  String get csvTime;

  /// No description provided for @csvStatus.
  ///
  /// In fr, this message translates to:
  /// **'Statut'**
  String get csvStatus;

  /// No description provided for @csvCustomer.
  ///
  /// In fr, this message translates to:
  /// **'Client'**
  String get csvCustomer;

  /// No description provided for @csvArea.
  ///
  /// In fr, this message translates to:
  /// **'Quartier'**
  String get csvArea;

  /// No description provided for @csvItems.
  ///
  /// In fr, this message translates to:
  /// **'Articles'**
  String get csvItems;

  /// No description provided for @csvItemCount.
  ///
  /// In fr, this message translates to:
  /// **'Nb articles'**
  String get csvItemCount;

  /// No description provided for @csvFood.
  ///
  /// In fr, this message translates to:
  /// **'Plats (DA)'**
  String get csvFood;

  /// No description provided for @csvDeliveryFee.
  ///
  /// In fr, this message translates to:
  /// **'Livraison (DA)'**
  String get csvDeliveryFee;

  /// No description provided for @csvTotal.
  ///
  /// In fr, this message translates to:
  /// **'Total (DA)'**
  String get csvTotal;

  /// No description provided for @csvCommission.
  ///
  /// In fr, this message translates to:
  /// **'Commission (DA)'**
  String get csvCommission;

  /// No description provided for @csvNet.
  ///
  /// In fr, this message translates to:
  /// **'Net (DA)'**
  String get csvNet;

  /// No description provided for @csvDriver.
  ///
  /// In fr, this message translates to:
  /// **'Livreur'**
  String get csvDriver;

  /// No description provided for @csvPrepMinutes.
  ///
  /// In fr, this message translates to:
  /// **'Préparation (min)'**
  String get csvPrepMinutes;

  /// No description provided for @csvReason.
  ///
  /// In fr, this message translates to:
  /// **'Motif'**
  String get csvReason;

  /// No description provided for @comparedPrevious.
  ///
  /// In fr, this message translates to:
  /// **'Comparé aux {n} jours précédents'**
  String comparedPrevious(int n);

  /// No description provided for @salesChartTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ventes par jour'**
  String get salesChartTitle;

  /// No description provided for @tapBarHint.
  ///
  /// In fr, this message translates to:
  /// **'Touchez une barre pour voir le détail'**
  String get tapBarHint;

  /// No description provided for @hoursChartTitle.
  ///
  /// In fr, this message translates to:
  /// **'Heures de pointe'**
  String get hoursChartTitle;

  /// No description provided for @weekdayChartTitle.
  ///
  /// In fr, this message translates to:
  /// **'Jours de la semaine'**
  String get weekdayChartTitle;

  /// No description provided for @topDishesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Plats les plus vendus'**
  String get topDishesTitle;

  /// No description provided for @outcomesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Issue des commandes'**
  String get outcomesTitle;

  /// No description provided for @soldTimes.
  ///
  /// In fr, this message translates to:
  /// **'{n} vendus'**
  String soldTimes(int n);

  /// No description provided for @tipsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Conseils pour vendre plus'**
  String get tipsTitle;

  /// No description provided for @tipSalesUp.
  ///
  /// In fr, this message translates to:
  /// **'Vos ventes ont augmenté de {n}% par rapport à la période précédente. Continuez !'**
  String tipSalesUp(int n);

  /// No description provided for @tipSalesDown.
  ///
  /// In fr, this message translates to:
  /// **'Ventes en baisse de {n}%. Vérifiez vos heures d\'ouverture et ajoutez des photos à vos plats.'**
  String tipSalesDown(int n);

  /// No description provided for @tipRefusals.
  ///
  /// In fr, this message translates to:
  /// **'{n} commandes refusées ou sans réponse : {amount} de ventes perdues. Fermez le restaurant quand vous ne pouvez pas servir.'**
  String tipRefusals(int n, String amount);

  /// No description provided for @tipSlowResponse.
  ///
  /// In fr, this message translates to:
  /// **'Vous mettez {n} min en moyenne pour accepter. Les clients attendent, et une commande sans réponse est refusée automatiquement.'**
  String tipSlowResponse(int n);

  /// No description provided for @tipSlowPrep.
  ///
  /// In fr, this message translates to:
  /// **'La préparation prend {n} min, vous annoncez {announced} min. Mettez à jour le temps dans votre profil ou accélérez.'**
  String tipSlowPrep(int n, int announced);

  /// No description provided for @tipPeakHour.
  ///
  /// In fr, this message translates to:
  /// **'Heure de pointe : {hour} ({share}% des commandes). Préparez vos ingrédients avant.'**
  String tipPeakHour(String hour, int share);

  /// No description provided for @tipTopDish.
  ///
  /// In fr, this message translates to:
  /// **'« {dish} » fait {share}% de vos ventes. Gardez-le toujours disponible, avec une belle photo.'**
  String tipTopDish(String dish, int share);

  /// No description provided for @tipQuietDay.
  ///
  /// In fr, this message translates to:
  /// **'{day} est votre jour le plus calme : bon moment pour une offre ou un nouveau plat.'**
  String tipQuietDay(String day);

  /// No description provided for @tipNoOrders.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de commandes sur cette période. Ouvrez aux heures des repas et complétez votre menu avec des photos.'**
  String get tipNoOrders;

  /// No description provided for @myBusiness.
  ///
  /// In fr, this message translates to:
  /// **'Mon activité'**
  String get myBusiness;

  /// No description provided for @accountApproved.
  ///
  /// In fr, this message translates to:
  /// **'Approuvé'**
  String get accountApproved;

  /// No description provided for @accountPending.
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get accountPending;

  /// No description provided for @deleteRestaurantConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Votre compte sera supprimé et votre restaurant retiré de l\'application. Vos commandes et relevés restent archivés pour la comptabilité. Cette action est définitive.'**
  String get deleteRestaurantConfirm;

  /// No description provided for @errDeleteCashPending.
  ///
  /// In fr, this message translates to:
  /// **'Confirmez d\'abord l\'argent reçu des livreurs.'**
  String get errDeleteCashPending;

  /// No description provided for @errDeleteUnpaidCommission.
  ///
  /// In fr, this message translates to:
  /// **'Des commissions restent à régler. Contactez l\'administrateur.'**
  String get errDeleteUnpaidCommission;

  /// No description provided for @restaurantDetailsHint.
  ///
  /// In fr, this message translates to:
  /// **'Photos, adresse, téléphone, temps de préparation'**
  String get restaurantDetailsHint;

  /// No description provided for @outlets.
  ///
  /// In fr, this message translates to:
  /// **'Points de vente'**
  String get outlets;

  /// No description provided for @roleOwner.
  ///
  /// In fr, this message translates to:
  /// **'Propriétaire'**
  String get roleOwner;

  /// No description provided for @roleManager.
  ///
  /// In fr, this message translates to:
  /// **'Gérant'**
  String get roleManager;

  /// No description provided for @roleStaff.
  ///
  /// In fr, this message translates to:
  /// **'Employé'**
  String get roleStaff;

  /// No description provided for @csvOutlet.
  ///
  /// In fr, this message translates to:
  /// **'Point de vente'**
  String get csvOutlet;

  /// No description provided for @portalTitle.
  ///
  /// In fr, this message translates to:
  /// **'Portail partenaire'**
  String get portalTitle;

  /// No description provided for @portalTagline.
  ///
  /// In fr, this message translates to:
  /// **'Gérez vos restaurants, commandes et ventes au même endroit.'**
  String get portalTagline;

  /// No description provided for @portalLoginTitle.
  ///
  /// In fr, this message translates to:
  /// **'Connexion au portail partenaire'**
  String get portalLoginTitle;

  /// No description provided for @portalNotPartner.
  ///
  /// In fr, this message translates to:
  /// **'Ce portail est réservé aux restaurants partenaires. Inscrivez d\'abord votre restaurant dans l\'application.'**
  String get portalNotPartner;

  /// No description provided for @navReports.
  ///
  /// In fr, this message translates to:
  /// **'Rapports'**
  String get navReports;

  /// No description provided for @navInvoices.
  ///
  /// In fr, this message translates to:
  /// **'Factures'**
  String get navInvoices;

  /// No description provided for @navMenu.
  ///
  /// In fr, this message translates to:
  /// **'Gestion du menu'**
  String get navMenu;

  /// No description provided for @navHours.
  ///
  /// In fr, this message translates to:
  /// **'Horaires d\'ouverture'**
  String get navHours;

  /// No description provided for @navReviews.
  ///
  /// In fr, this message translates to:
  /// **'Avis et notes'**
  String get navReviews;

  /// No description provided for @navMarketing.
  ///
  /// In fr, this message translates to:
  /// **'Marketing'**
  String get navMarketing;

  /// No description provided for @navNotifications.
  ///
  /// In fr, this message translates to:
  /// **'Centre de notifications'**
  String get navNotifications;

  /// No description provided for @navTeam.
  ///
  /// In fr, this message translates to:
  /// **'Équipe'**
  String get navTeam;

  /// No description provided for @soon.
  ///
  /// In fr, this message translates to:
  /// **'Bientôt'**
  String get soon;

  /// No description provided for @comingSoonTitle.
  ///
  /// In fr, this message translates to:
  /// **'Bientôt disponible'**
  String get comingSoonTitle;

  /// No description provided for @comingSoonBody.
  ///
  /// In fr, this message translates to:
  /// **'Cette section arrive à la prochaine étape. En attendant, utilisez l\'application.'**
  String get comingSoonBody;

  /// No description provided for @outletsAll.
  ///
  /// In fr, this message translates to:
  /// **'Tous les points de vente'**
  String get outletsAll;

  /// No description provided for @outletsCount.
  ///
  /// In fr, this message translates to:
  /// **'{n}/{total} points de vente'**
  String outletsCount(int n, int total);

  /// No description provided for @dashboardSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Vue d\'ensemble de vos commandes et de vos points de vente'**
  String get dashboardSubtitle;

  /// No description provided for @ordersToday.
  ///
  /// In fr, this message translates to:
  /// **'Commandes aujourd\'hui'**
  String get ordersToday;

  /// No description provided for @cancelledToday.
  ///
  /// In fr, this message translates to:
  /// **'Annulées ou refusées aujourd\'hui'**
  String get cancelledToday;

  /// No description provided for @closedOutletsNow.
  ///
  /// In fr, this message translates to:
  /// **'Points de vente fermés'**
  String get closedOutletsNow;

  /// No description provided for @salesToday.
  ///
  /// In fr, this message translates to:
  /// **'Ventes aujourd\'hui'**
  String get salesToday;

  /// No description provided for @updatedAt.
  ///
  /// In fr, this message translates to:
  /// **'Mis à jour à {time}'**
  String updatedAt(String time);

  /// No description provided for @businessSummary.
  ///
  /// In fr, this message translates to:
  /// **'Résumé de l’activité'**
  String get businessSummary;

  /// No description provided for @thisWeek.
  ///
  /// In fr, this message translates to:
  /// **'Cette semaine'**
  String get thisWeek;

  /// No description provided for @lastWeek.
  ///
  /// In fr, this message translates to:
  /// **'Semaine dernière'**
  String get lastWeek;

  /// No description provided for @comparison.
  ///
  /// In fr, this message translates to:
  /// **'Comparaison'**
  String get comparison;

  /// No description provided for @previousPeriod.
  ///
  /// In fr, this message translates to:
  /// **'Période précédente'**
  String get previousPeriod;

  /// No description provided for @totalLabel.
  ///
  /// In fr, this message translates to:
  /// **'Total'**
  String get totalLabel;

  /// No description provided for @cancelledLabel.
  ///
  /// In fr, this message translates to:
  /// **'Annulées'**
  String get cancelledLabel;

  /// No description provided for @waitingOrders.
  ///
  /// In fr, this message translates to:
  /// **'En attente de votre réponse'**
  String get waitingOrders;

  /// No description provided for @noWaitingOrders.
  ///
  /// In fr, this message translates to:
  /// **'Aucune commande en attente.'**
  String get noWaitingOrders;

  /// No description provided for @ordersSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Détails des commandes en temps réel'**
  String get ordersSubtitle;

  /// No description provided for @placedAtCol.
  ///
  /// In fr, this message translates to:
  /// **'Passée le'**
  String get placedAtCol;

  /// No description provided for @acceptedIn.
  ///
  /// In fr, this message translates to:
  /// **'Acceptée en {time}'**
  String acceptedIn(String time);

  /// No description provided for @orderDetailsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Détails de la commande'**
  String get orderDetailsTitle;

  /// No description provided for @secondsShort.
  ///
  /// In fr, this message translates to:
  /// **'{n} s'**
  String secondsShort(int n);

  /// No description provided for @reportsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Analysez vos performances'**
  String get reportsSubtitle;

  /// No description provided for @tabSales.
  ///
  /// In fr, this message translates to:
  /// **'Ventes'**
  String get tabSales;

  /// No description provided for @tabOperations.
  ///
  /// In fr, this message translates to:
  /// **'Opérations'**
  String get tabOperations;

  /// No description provided for @tabCustomers.
  ///
  /// In fr, this message translates to:
  /// **'Clients'**
  String get tabCustomers;

  /// No description provided for @previousMonth.
  ///
  /// In fr, this message translates to:
  /// **'Mois précédent'**
  String get previousMonth;

  /// No description provided for @salesByDayHint.
  ///
  /// In fr, this message translates to:
  /// **'Ventes et commandes par jour : votre activité monte-t-elle ou baisse-t-elle ?'**
  String get salesByDayHint;

  /// No description provided for @downloadReport.
  ///
  /// In fr, this message translates to:
  /// **'Télécharger le rapport'**
  String get downloadReport;

  /// No description provided for @salesByHour.
  ///
  /// In fr, this message translates to:
  /// **'Ventes par heure'**
  String get salesByHour;

  /// No description provided for @salesByHourHint.
  ///
  /// In fr, this message translates to:
  /// **'Ventes par heure et jour de la semaine : vos heures calmes et chargées.'**
  String get salesByHourHint;

  /// No description provided for @avgResponse.
  ///
  /// In fr, this message translates to:
  /// **'Temps moyen d\'acceptation'**
  String get avgResponse;

  /// No description provided for @cancellationRate.
  ///
  /// In fr, this message translates to:
  /// **'Taux d\'annulation'**
  String get cancellationRate;

  /// No description provided for @lostSales.
  ///
  /// In fr, this message translates to:
  /// **'Ventes perdues'**
  String get lostSales;

  /// No description provided for @refusalReasons.
  ///
  /// In fr, this message translates to:
  /// **'Refus et annulations par motif'**
  String get refusalReasons;

  /// No description provided for @prepByDay.
  ///
  /// In fr, this message translates to:
  /// **'Temps de préparation par jour'**
  String get prepByDay;

  /// No description provided for @newVsReturning.
  ///
  /// In fr, this message translates to:
  /// **'Nouveaux vs clients fidèles'**
  String get newVsReturning;

  /// No description provided for @newVsReturningHint.
  ///
  /// In fr, this message translates to:
  /// **'Part des commandes venant de nouveaux clients et de clients qui reviennent.'**
  String get newVsReturningHint;

  /// No description provided for @ordersFromNew.
  ///
  /// In fr, this message translates to:
  /// **'Commandes de nouveaux clients'**
  String get ordersFromNew;

  /// No description provided for @ordersFromReturning.
  ///
  /// In fr, this message translates to:
  /// **'Commandes de clients fidèles'**
  String get ordersFromReturning;

  /// No description provided for @moreReturningTitle.
  ///
  /// In fr, this message translates to:
  /// **'Plus de clients fidèles ?'**
  String get moreReturningTitle;

  /// No description provided for @moreReturningBody.
  ///
  /// In fr, this message translates to:
  /// **'Les clients reviennent pour la qualité et la rapidité : gardez vos meilleurs plats disponibles, répondez vite et annoncez des temps de préparation honnêtes.'**
  String get moreReturningBody;

  /// No description provided for @moreNewTitle.
  ///
  /// In fr, this message translates to:
  /// **'Plus de nouveaux clients ?'**
  String get moreNewTitle;

  /// No description provided for @moreNewBody.
  ///
  /// In fr, this message translates to:
  /// **'De belles photos et des descriptions complètes donnent envie d\'essayer. Une bannière sur l\'accueil (demandez à l\'administrateur) vous montre à tous.'**
  String get moreNewBody;

  /// No description provided for @topAreas.
  ///
  /// In fr, this message translates to:
  /// **'Quartiers principaux'**
  String get topAreas;

  /// No description provided for @uniqueCustomers.
  ///
  /// In fr, this message translates to:
  /// **'Clients'**
  String get uniqueCustomers;

  /// No description provided for @invoicesSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Téléchargez vos relevés de commission'**
  String get invoicesSubtitle;

  /// No description provided for @noInvoices.
  ///
  /// In fr, this message translates to:
  /// **'Aucune facture pour le moment'**
  String get noInvoices;

  /// No description provided for @outletsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Vos restaurants, leur statut et votre rôle'**
  String get outletsSubtitle;

  /// No description provided for @addOutlet.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un point de vente'**
  String get addOutlet;

  /// No description provided for @outletAdded.
  ///
  /// In fr, this message translates to:
  /// **'Point de vente ajouté. Il sera visible après validation par l\'administrateur.'**
  String get outletAdded;

  /// No description provided for @yourRole.
  ///
  /// In fr, this message translates to:
  /// **'Votre rôle : {role}'**
  String yourRole(String role);

  /// No description provided for @teamSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Donnez à votre équipe son propre accès, avec les bons droits'**
  String get teamSubtitle;

  /// No description provided for @addMember.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un membre'**
  String get addMember;

  /// No description provided for @memberEmail.
  ///
  /// In fr, this message translates to:
  /// **'E-mail du compte'**
  String get memberEmail;

  /// No description provided for @memberEmailHint.
  ///
  /// In fr, this message translates to:
  /// **'La personne doit d\'abord créer un compte dans l\'application avec cet e-mail.'**
  String get memberEmailHint;

  /// No description provided for @roleOwnerDesc.
  ///
  /// In fr, this message translates to:
  /// **'Tout, y compris l\'équipe et la fermeture du compte'**
  String get roleOwnerDesc;

  /// No description provided for @roleManagerDesc.
  ///
  /// In fr, this message translates to:
  /// **'Commandes, menu, informations, rapports et factures'**
  String get roleManagerDesc;

  /// No description provided for @roleStaffDesc.
  ///
  /// In fr, this message translates to:
  /// **'Commandes uniquement : accepter, refuser, prête, argent reçu'**
  String get roleStaffDesc;

  /// No description provided for @removeMember.
  ///
  /// In fr, this message translates to:
  /// **'Retirer'**
  String get removeMember;

  /// No description provided for @removeMemberConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Retirer {name} de ce point de vente ?'**
  String removeMemberConfirm(String name);

  /// No description provided for @memberAdded.
  ///
  /// In fr, this message translates to:
  /// **'Membre ajouté'**
  String get memberAdded;

  /// No description provided for @errUserNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Aucun compte avec cet e-mail. Demandez-lui de s\'inscrire d\'abord dans l\'application.'**
  String get errUserNotFound;

  /// No description provided for @errOtherRole.
  ///
  /// In fr, this message translates to:
  /// **'Ce compte est livreur ou administrateur et ne peut pas rejoindre un restaurant.'**
  String get errOtherRole;

  /// No description provided for @errAlreadyMember.
  ///
  /// In fr, this message translates to:
  /// **'Déjà dans l\'équipe.'**
  String get errAlreadyMember;

  /// No description provided for @errLastOwner.
  ///
  /// In fr, this message translates to:
  /// **'Un point de vente doit garder au moins un propriétaire.'**
  String get errLastOwner;

  /// No description provided for @onlyOwnersTeam.
  ///
  /// In fr, this message translates to:
  /// **'Seuls les propriétaires peuvent modifier l\'équipe.'**
  String get onlyOwnersTeam;

  /// No description provided for @colName.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get colName;

  /// No description provided for @colEmail.
  ///
  /// In fr, this message translates to:
  /// **'E-mail'**
  String get colEmail;

  /// No description provided for @colRole.
  ///
  /// In fr, this message translates to:
  /// **'Rôle'**
  String get colRole;

  /// No description provided for @colSince.
  ///
  /// In fr, this message translates to:
  /// **'Depuis'**
  String get colSince;

  /// No description provided for @portalStaffOnly.
  ///
  /// In fr, this message translates to:
  /// **'Votre accès employé fonctionne dans l\'application. Demandez à un propriétaire un accès gérant pour utiliser le portail.'**
  String get portalStaffOnly;

  /// No description provided for @errOptionsChanged.
  ///
  /// In fr, this message translates to:
  /// **'Les options de ce plat ont changé. Choisissez-les à nouveau.'**
  String get errOptionsChanged;

  /// No description provided for @chooseUpTo.
  ///
  /// In fr, this message translates to:
  /// **'Jusqu\'à {n} au choix'**
  String chooseUpTo(int n);

  /// No description provided for @optionRequired.
  ///
  /// In fr, this message translates to:
  /// **'Obligatoire'**
  String get optionRequired;

  /// No description provided for @outOfStock.
  ///
  /// In fr, this message translates to:
  /// **'Épuisé'**
  String get outOfStock;

  /// No description provided for @opensTodayAt.
  ///
  /// In fr, this message translates to:
  /// **'Fermé · ouvre aujourd\'hui à {time}'**
  String opensTodayAt(String time);

  /// No description provided for @opensTomorrowAt.
  ///
  /// In fr, this message translates to:
  /// **'Fermé · ouvre demain à {time}'**
  String opensTomorrowAt(String time);

  /// No description provided for @opensOnAt.
  ///
  /// In fr, this message translates to:
  /// **'Fermé · ouvre {day} à {time}'**
  String opensOnAt(String day, String time);

  /// No description provided for @menuSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Plats, prix, photos et options de vos plats'**
  String get menuSubtitle;

  /// No description provided for @addOptionGroup.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un groupe d\'options'**
  String get addOptionGroup;

  /// No description provided for @editOptionGroup.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le groupe d\'options'**
  String get editOptionGroup;

  /// No description provided for @dishesTab.
  ///
  /// In fr, this message translates to:
  /// **'Plats'**
  String get dishesTab;

  /// No description provided for @optionGroupsTab.
  ///
  /// In fr, this message translates to:
  /// **'Groupes d\'options'**
  String get optionGroupsTab;

  /// No description provided for @searchDishesHint.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un plat…'**
  String get searchDishesHint;

  /// No description provided for @bulkDone.
  ///
  /// In fr, this message translates to:
  /// **'{n} plats modifiés'**
  String bulkDone(int n);

  /// No description provided for @bulkDeleteConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer {n} plats ? Cette action est définitive.'**
  String bulkDeleteConfirm(int n);

  /// No description provided for @selectedCount.
  ///
  /// In fr, this message translates to:
  /// **'{n} sélectionnés'**
  String selectedCount(int n);

  /// No description provided for @bulkShow.
  ///
  /// In fr, this message translates to:
  /// **'Rendre disponible'**
  String get bulkShow;

  /// No description provided for @bulkHide.
  ///
  /// In fr, this message translates to:
  /// **'Masquer'**
  String get bulkHide;

  /// No description provided for @bulkPrices.
  ///
  /// In fr, this message translates to:
  /// **'Modifier les prix'**
  String get bulkPrices;

  /// No description provided for @priceIncrease.
  ///
  /// In fr, this message translates to:
  /// **'Augmenter'**
  String get priceIncrease;

  /// No description provided for @priceDecrease.
  ///
  /// In fr, this message translates to:
  /// **'Baisser'**
  String get priceDecrease;

  /// No description provided for @pricesRounded.
  ///
  /// In fr, this message translates to:
  /// **'Les nouveaux prix sont arrondis à 10 DA.'**
  String get pricesRounded;

  /// No description provided for @apply.
  ///
  /// In fr, this message translates to:
  /// **'Appliquer'**
  String get apply;

  /// No description provided for @uploadDishPhoto.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une photo du plat'**
  String get uploadDishPhoto;

  /// No description provided for @photosSellHint.
  ///
  /// In fr, this message translates to:
  /// **'Les plats avec une belle photo se vendent mieux.'**
  String get photosSellHint;

  /// No description provided for @noOptionGroupsHint.
  ///
  /// In fr, this message translates to:
  /// **'Créez d\'abord des groupes d\'options (tailles, suppléments) dans l\'onglet Groupes d\'options.'**
  String get noOptionGroupsHint;

  /// No description provided for @optionGroupsPickHint.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez les options proposées avec ce plat.'**
  String get optionGroupsPickHint;

  /// No description provided for @noOptionGroups.
  ///
  /// In fr, this message translates to:
  /// **'Aucun groupe d\'options. Créez par exemple « Taille » (Petite, Grande) ou « Suppléments » (Fromage, Œuf).'**
  String get noOptionGroups;

  /// No description provided for @ruleRequiredOne.
  ///
  /// In fr, this message translates to:
  /// **'Obligatoire · 1 choix'**
  String get ruleRequiredOne;

  /// No description provided for @ruleRequiredRange.
  ///
  /// In fr, this message translates to:
  /// **'Obligatoire · {min} à {max} choix'**
  String ruleRequiredRange(int min, int max);

  /// No description provided for @ruleOptionalUpTo.
  ///
  /// In fr, this message translates to:
  /// **'Facultatif · jusqu\'à {max}'**
  String ruleOptionalUpTo(int max);

  /// No description provided for @deleteGroupConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le groupe « {name} » ? Il sera retiré de tous les plats.'**
  String deleteGroupConfirm(String name);

  /// No description provided for @free.
  ///
  /// In fr, this message translates to:
  /// **'Gratuit'**
  String get free;

  /// No description provided for @usedByNoDish.
  ///
  /// In fr, this message translates to:
  /// **'Utilisé par aucun plat'**
  String get usedByNoDish;

  /// No description provided for @usedBy.
  ///
  /// In fr, this message translates to:
  /// **'Utilisé par : {names}'**
  String usedBy(String names);

  /// No description provided for @groupName.
  ///
  /// In fr, this message translates to:
  /// **'Nom du groupe'**
  String get groupName;

  /// No description provided for @groupNameHint.
  ///
  /// In fr, this message translates to:
  /// **'ex. Taille, Sauce, Suppléments'**
  String get groupNameHint;

  /// No description provided for @requiredHint.
  ///
  /// In fr, this message translates to:
  /// **'Le client doit choisir avant de commander'**
  String get requiredHint;

  /// No description provided for @minChoices.
  ///
  /// In fr, this message translates to:
  /// **'Minimum de choix'**
  String get minChoices;

  /// No description provided for @maxChoices.
  ///
  /// In fr, this message translates to:
  /// **'Maximum de choix'**
  String get maxChoices;

  /// No description provided for @choices.
  ///
  /// In fr, this message translates to:
  /// **'Choix'**
  String get choices;

  /// No description provided for @choiceNameHint.
  ///
  /// In fr, this message translates to:
  /// **'ex. Grande'**
  String get choiceNameHint;

  /// No description provided for @extraPriceHint.
  ///
  /// In fr, this message translates to:
  /// **'Supplément'**
  String get extraPriceHint;

  /// No description provided for @addChoice.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un choix'**
  String get addChoice;

  /// No description provided for @dishesUsingGroup.
  ///
  /// In fr, this message translates to:
  /// **'Plats proposant ces options'**
  String get dishesUsingGroup;

  /// No description provided for @errGroupRule.
  ///
  /// In fr, this message translates to:
  /// **'Il faut au moins autant de choix que le minimum.'**
  String get errGroupRule;

  /// No description provided for @hoursSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Vos horaires, jours fériés et horaires spéciaux'**
  String get hoursSubtitle;

  /// No description provided for @weeklyHours.
  ///
  /// In fr, this message translates to:
  /// **'Horaires d\'ouverture'**
  String get weeklyHours;

  /// No description provided for @specialDays.
  ///
  /// In fr, this message translates to:
  /// **'Jours fériés et horaires spéciaux'**
  String get specialDays;

  /// No description provided for @openNowLabel.
  ///
  /// In fr, this message translates to:
  /// **'Ouvert maintenant'**
  String get openNowLabel;

  /// No description provided for @closedNowLabel.
  ///
  /// In fr, this message translates to:
  /// **'Fermé maintenant'**
  String get closedNowLabel;

  /// No description provided for @switchOffHint.
  ///
  /// In fr, this message translates to:
  /// **'Commandes désactivées par l\'interrupteur'**
  String get switchOffHint;

  /// No description provided for @takingOrders.
  ///
  /// In fr, this message translates to:
  /// **'Les clients peuvent commander'**
  String get takingOrders;

  /// No description provided for @ordersSwitch.
  ///
  /// In fr, this message translates to:
  /// **'Recevoir des commandes'**
  String get ordersSwitch;

  /// No description provided for @weeklyHoursHint.
  ///
  /// In fr, this message translates to:
  /// **'Les clients ne peuvent commander que pendant ces heures (et quand l\'interrupteur est activé). Sans horaires : ouvert dès que l\'interrupteur est activé.'**
  String get weeklyHoursHint;

  /// No description provided for @closedAllDay.
  ///
  /// In fr, this message translates to:
  /// **'Fermé toute la journée'**
  String get closedAllDay;

  /// No description provided for @addHours.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter des heures'**
  String get addHours;

  /// No description provided for @copyToAllDays.
  ///
  /// In fr, this message translates to:
  /// **'Copier sur tous les jours'**
  String get copyToAllDays;

  /// No description provided for @specialDaysHint.
  ///
  /// In fr, this message translates to:
  /// **'Jours fériés, Aïd, Ramadan… Ces dates remplacent les horaires habituels.'**
  String get specialDaysHint;

  /// No description provided for @addSpecialDay.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une date'**
  String get addSpecialDay;

  /// No description provided for @noSpecialDays.
  ///
  /// In fr, this message translates to:
  /// **'Aucune date à venir'**
  String get noSpecialDays;

  /// No description provided for @pickDate.
  ///
  /// In fr, this message translates to:
  /// **'Choisir la date'**
  String get pickDate;

  /// No description provided for @opensLabel.
  ///
  /// In fr, this message translates to:
  /// **'Ouvre'**
  String get opensLabel;

  /// No description provided for @closesLabel.
  ///
  /// In fr, this message translates to:
  /// **'Ferme'**
  String get closesLabel;

  /// No description provided for @specialDayNote.
  ///
  /// In fr, this message translates to:
  /// **'Note'**
  String get specialDayNote;

  /// No description provided for @specialDayNoteHint.
  ///
  /// In fr, this message translates to:
  /// **'ex. Aïd el-Fitr'**
  String get specialDayNoteHint;

  /// No description provided for @rateDriverTitle.
  ///
  /// In fr, this message translates to:
  /// **'Comment était la livraison ?'**
  String get rateDriverTitle;

  /// No description provided for @rateFoodTitle.
  ///
  /// In fr, this message translates to:
  /// **'Comment était le repas ?'**
  String get rateFoodTitle;

  /// No description provided for @ratingWhatWrong.
  ///
  /// In fr, this message translates to:
  /// **'Qu\'est-ce qui n\'allait pas ?'**
  String get ratingWhatWrong;

  /// No description provided for @ratingCommentHint.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un commentaire (facultatif)'**
  String get ratingCommentHint;

  /// No description provided for @ratingSubmit.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer ma note'**
  String get ratingSubmit;

  /// No description provided for @ratingLater.
  ///
  /// In fr, this message translates to:
  /// **'Plus tard'**
  String get ratingLater;

  /// No description provided for @ratingThanks.
  ///
  /// In fr, this message translates to:
  /// **'Merci pour votre avis !'**
  String get ratingThanks;

  /// No description provided for @ratingWord1.
  ///
  /// In fr, this message translates to:
  /// **'Très mauvais'**
  String get ratingWord1;

  /// No description provided for @ratingWord2.
  ///
  /// In fr, this message translates to:
  /// **'Mauvais'**
  String get ratingWord2;

  /// No description provided for @ratingWord3.
  ///
  /// In fr, this message translates to:
  /// **'Moyen'**
  String get ratingWord3;

  /// No description provided for @ratingWord4.
  ///
  /// In fr, this message translates to:
  /// **'Bien'**
  String get ratingWord4;

  /// No description provided for @ratingWord5.
  ///
  /// In fr, this message translates to:
  /// **'Excellent'**
  String get ratingWord5;

  /// No description provided for @errRatingClosed.
  ///
  /// In fr, this message translates to:
  /// **'La période de notation (7 jours) est terminée.'**
  String get errRatingClosed;

  /// No description provided for @errRatingLocked.
  ///
  /// In fr, this message translates to:
  /// **'Cette note ne peut plus être modifiée.'**
  String get errRatingLocked;

  /// No description provided for @rateFoodCard.
  ///
  /// In fr, this message translates to:
  /// **'Notez le repas'**
  String get rateFoodCard;

  /// No description provided for @rateDriverCard.
  ///
  /// In fr, this message translates to:
  /// **'Notez la livraison'**
  String get rateDriverCard;

  /// No description provided for @ratingDaysLeft.
  ///
  /// In fr, this message translates to:
  /// **'Encore {n} jours pour noter'**
  String ratingDaysLeft(int n);

  /// No description provided for @ratingLastDay.
  ///
  /// In fr, this message translates to:
  /// **'Dernier jour pour noter'**
  String get ratingLastDay;

  /// No description provided for @yourRating.
  ///
  /// In fr, this message translates to:
  /// **'Votre note'**
  String get yourRating;

  /// No description provided for @rateAction.
  ///
  /// In fr, this message translates to:
  /// **'Noter'**
  String get rateAction;

  /// No description provided for @editRating.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get editRating;

  /// No description provided for @ratingEditHint.
  ///
  /// In fr, this message translates to:
  /// **'Modifiable pendant 24 h'**
  String get ratingEditHint;

  /// No description provided for @ratingReplyFrom.
  ///
  /// In fr, this message translates to:
  /// **'Réponse du restaurant'**
  String get ratingReplyFrom;

  /// No description provided for @errAccountBlocked.
  ///
  /// In fr, this message translates to:
  /// **'Votre compte est suspendu. Contactez le support.'**
  String get errAccountBlocked;

  /// No description provided for @rsnCold.
  ///
  /// In fr, this message translates to:
  /// **'Plat froid'**
  String get rsnCold;

  /// No description provided for @rsnMissingItem.
  ///
  /// In fr, this message translates to:
  /// **'Article manquant'**
  String get rsnMissingItem;

  /// No description provided for @rsnWrongOrder.
  ///
  /// In fr, this message translates to:
  /// **'Mauvaise commande'**
  String get rsnWrongOrder;

  /// No description provided for @rsnSmallPortion.
  ///
  /// In fr, this message translates to:
  /// **'Portion trop petite'**
  String get rsnSmallPortion;

  /// No description provided for @rsnBadTaste.
  ///
  /// In fr, this message translates to:
  /// **'Mauvais goût'**
  String get rsnBadTaste;

  /// No description provided for @rsnBadPackaging.
  ///
  /// In fr, this message translates to:
  /// **'Emballage abîmé'**
  String get rsnBadPackaging;

  /// No description provided for @rsnLate.
  ///
  /// In fr, this message translates to:
  /// **'En retard'**
  String get rsnLate;

  /// No description provided for @rsnRude.
  ///
  /// In fr, this message translates to:
  /// **'Impoli'**
  String get rsnRude;

  /// No description provided for @rsnCareless.
  ///
  /// In fr, this message translates to:
  /// **'Manipulation négligée'**
  String get rsnCareless;

  /// No description provided for @rsnNoContact.
  ///
  /// In fr, this message translates to:
  /// **'Injoignable'**
  String get rsnNoContact;

  /// No description provided for @rsnWrongPlace.
  ///
  /// In fr, this message translates to:
  /// **'Mauvaise adresse'**
  String get rsnWrongPlace;

  /// No description provided for @rsnFakeOrder.
  ///
  /// In fr, this message translates to:
  /// **'Fausse commande'**
  String get rsnFakeOrder;

  /// No description provided for @rsnNoAnswer.
  ///
  /// In fr, this message translates to:
  /// **'Ne répond pas'**
  String get rsnNoAnswer;

  /// No description provided for @rsnWrongAddress.
  ///
  /// In fr, this message translates to:
  /// **'Adresse incorrecte'**
  String get rsnWrongAddress;

  /// No description provided for @rsnRefusedToPay.
  ///
  /// In fr, this message translates to:
  /// **'A refusé de payer'**
  String get rsnRefusedToPay;

  /// No description provided for @rsnOther.
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get rsnOther;

  /// No description provided for @reviewsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Avis'**
  String get reviewsTitle;

  /// No description provided for @newRestaurant.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau'**
  String get newRestaurant;

  /// No description provided for @noReviewsYet.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore d’avis'**
  String get noReviewsYet;

  /// No description provided for @restaurantReply.
  ///
  /// In fr, this message translates to:
  /// **'Réponse du restaurant'**
  String get restaurantReply;

  /// No description provided for @seeMoreReviews.
  ///
  /// In fr, this message translates to:
  /// **'Voir plus d\'avis'**
  String get seeMoreReviews;

  /// No description provided for @ratingsCount.
  ///
  /// In fr, this message translates to:
  /// **'{n} notes'**
  String ratingsCount(int n);

  /// No description provided for @reviewsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Ce que disent vos clients de vos plats'**
  String get reviewsSubtitle;

  /// No description provided for @averageRating.
  ///
  /// In fr, this message translates to:
  /// **'Note moyenne'**
  String get averageRating;

  /// No description provided for @ratingDistribution.
  ///
  /// In fr, this message translates to:
  /// **'Répartition des notes'**
  String get ratingDistribution;

  /// No description provided for @topComplaints.
  ///
  /// In fr, this message translates to:
  /// **'Problèmes les plus cités'**
  String get topComplaints;

  /// No description provided for @filterNeedsReply.
  ///
  /// In fr, this message translates to:
  /// **'Sans réponse'**
  String get filterNeedsReply;

  /// No description provided for @starsFilter.
  ///
  /// In fr, this message translates to:
  /// **'{n} étoiles'**
  String starsFilter(int n);

  /// No description provided for @replyAction.
  ///
  /// In fr, this message translates to:
  /// **'Répondre'**
  String get replyAction;

  /// No description provided for @replyDialogHint.
  ///
  /// In fr, this message translates to:
  /// **'Votre réponse est publique et ne pourra plus être modifiée.'**
  String get replyDialogHint;

  /// No description provided for @replyHint.
  ///
  /// In fr, this message translates to:
  /// **'Merci, nous espérons vous revoir…'**
  String get replyHint;

  /// No description provided for @sendReply.
  ///
  /// In fr, this message translates to:
  /// **'Publier la réponse'**
  String get sendReply;

  /// No description provided for @replyPublished.
  ///
  /// In fr, this message translates to:
  /// **'Réponse publiée'**
  String get replyPublished;

  /// No description provided for @flagReview.
  ///
  /// In fr, this message translates to:
  /// **'Signaler cet avis'**
  String get flagReview;

  /// No description provided for @flagReviewHint.
  ///
  /// In fr, this message translates to:
  /// **'Expliquez pourquoi (insulte, ne concerne pas votre cuisine, mauvais restaurant…). L\'administrateur décidera.'**
  String get flagReviewHint;

  /// No description provided for @flagSend.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer'**
  String get flagSend;

  /// No description provided for @flagSent.
  ///
  /// In fr, this message translates to:
  /// **'Envoyé à l\'administrateur'**
  String get flagSent;

  /// No description provided for @flagWaiting.
  ///
  /// In fr, this message translates to:
  /// **'En attente de l\'administrateur'**
  String get flagWaiting;

  /// No description provided for @flagKept.
  ///
  /// In fr, this message translates to:
  /// **'L\'administrateur a conservé cet avis'**
  String get flagKept;

  /// No description provided for @errAlreadyReplied.
  ///
  /// In fr, this message translates to:
  /// **'Cet avis a déjà une réponse.'**
  String get errAlreadyReplied;

  /// No description provided for @errAlreadyFlagged.
  ///
  /// In fr, this message translates to:
  /// **'Déjà signalé.'**
  String get errAlreadyFlagged;

  /// No description provided for @noReviewsPeriod.
  ///
  /// In fr, this message translates to:
  /// **'Aucun avis sur cette période'**
  String get noReviewsPeriod;

  /// No description provided for @reviewOrderRef.
  ///
  /// In fr, this message translates to:
  /// **'Commande #{code}'**
  String reviewOrderRef(String code);

  /// No description provided for @myRating.
  ///
  /// In fr, this message translates to:
  /// **'Ma note'**
  String get myRating;

  /// No description provided for @driverRatingHint.
  ///
  /// In fr, this message translates to:
  /// **'Votre moyenne apparaît après 5 notes.'**
  String get driverRatingHint;

  /// No description provided for @driverReasonsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ce que les clients ont signalé'**
  String get driverReasonsTitle;

  /// No description provided for @reportCustomer.
  ///
  /// In fr, this message translates to:
  /// **'Signaler ce client'**
  String get reportCustomer;

  /// No description provided for @reportCustomerHint.
  ///
  /// In fr, this message translates to:
  /// **'Seul l\'administrateur voit ce signalement. Le client n\'est pas prévenu.'**
  String get reportCustomerHint;

  /// No description provided for @reportNoteHint.
  ///
  /// In fr, this message translates to:
  /// **'Détails (facultatif)'**
  String get reportNoteHint;

  /// No description provided for @reportSend.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer'**
  String get reportSend;

  /// No description provided for @reportSent.
  ///
  /// In fr, this message translates to:
  /// **'Signalement envoyé à l\'administrateur'**
  String get reportSent;

  /// No description provided for @reportedLabel.
  ///
  /// In fr, this message translates to:
  /// **'Signalé'**
  String get reportedLabel;

  /// No description provided for @errAlreadyReported.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez déjà signalé cette commande.'**
  String get errAlreadyReported;

  /// No description provided for @errTooManyReports.
  ///
  /// In fr, this message translates to:
  /// **'Trop de signalements aujourd\'hui.'**
  String get errTooManyReports;

  /// No description provided for @errCustomerGone.
  ///
  /// In fr, this message translates to:
  /// **'Ce client n\'a plus de compte.'**
  String get errCustomerGone;

  /// No description provided for @navRatings.
  ///
  /// In fr, this message translates to:
  /// **'Avis'**
  String get navRatings;

  /// No description provided for @adminRatingsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Avis et signalements'**
  String get adminRatingsTitle;

  /// No description provided for @tabFlagged.
  ///
  /// In fr, this message translates to:
  /// **'Avis signalés'**
  String get tabFlagged;

  /// No description provided for @tabReports.
  ///
  /// In fr, this message translates to:
  /// **'Signalements clients'**
  String get tabReports;

  /// No description provided for @avg30d.
  ///
  /// In fr, this message translates to:
  /// **'30 derniers jours'**
  String get avg30d;

  /// No description provided for @low30d.
  ///
  /// In fr, this message translates to:
  /// **'Notes ≤ 2 (30 j)'**
  String get low30d;

  /// No description provided for @hideReview.
  ///
  /// In fr, this message translates to:
  /// **'Masquer'**
  String get hideReview;

  /// No description provided for @keepReview.
  ///
  /// In fr, this message translates to:
  /// **'Conserver'**
  String get keepReview;

  /// No description provided for @decisionHidden.
  ///
  /// In fr, this message translates to:
  /// **'Masqué'**
  String get decisionHidden;

  /// No description provided for @decisionKept.
  ///
  /// In fr, this message translates to:
  /// **'Conservé'**
  String get decisionKept;

  /// No description provided for @flaggedReason.
  ///
  /// In fr, this message translates to:
  /// **'Motif du signalement'**
  String get flaggedReason;

  /// No description provided for @noFlagged.
  ///
  /// In fr, this message translates to:
  /// **'Aucun avis signalé'**
  String get noFlagged;

  /// No description provided for @noReports.
  ///
  /// In fr, this message translates to:
  /// **'Aucun signalement'**
  String get noReports;

  /// No description provided for @reportOpen.
  ///
  /// In fr, this message translates to:
  /// **'À traiter'**
  String get reportOpen;

  /// No description provided for @reportWarned.
  ///
  /// In fr, this message translates to:
  /// **'Averti'**
  String get reportWarned;

  /// No description provided for @reportBlocked.
  ///
  /// In fr, this message translates to:
  /// **'Bloqué'**
  String get reportBlocked;

  /// No description provided for @reportDismissed.
  ///
  /// In fr, this message translates to:
  /// **'Classé'**
  String get reportDismissed;

  /// No description provided for @actionWarn.
  ///
  /// In fr, this message translates to:
  /// **'Avertir'**
  String get actionWarn;

  /// No description provided for @actionBlock.
  ///
  /// In fr, this message translates to:
  /// **'Bloquer le client'**
  String get actionBlock;

  /// No description provided for @actionUnblock.
  ///
  /// In fr, this message translates to:
  /// **'Débloquer'**
  String get actionUnblock;

  /// No description provided for @actionDismiss.
  ///
  /// In fr, this message translates to:
  /// **'Classer sans suite'**
  String get actionDismiss;

  /// No description provided for @adminNoteHint.
  ///
  /// In fr, this message translates to:
  /// **'Note interne (facultatif)'**
  String get adminNoteHint;

  /// No description provided for @customerReportsCount.
  ///
  /// In fr, this message translates to:
  /// **'{n} signalements pour ce client'**
  String customerReportsCount(int n);

  /// No description provided for @reportedByRestaurant.
  ///
  /// In fr, this message translates to:
  /// **'Signalé par le restaurant'**
  String get reportedByRestaurant;

  /// No description provided for @reportedByDriver.
  ///
  /// In fr, this message translates to:
  /// **'Signalé par le livreur'**
  String get reportedByDriver;

  /// No description provided for @customerBlockedNote.
  ///
  /// In fr, this message translates to:
  /// **'Client bloqué : ne peut plus commander'**
  String get customerBlockedNote;

  /// No description provided for @rangeDaysSuffix.
  ///
  /// In fr, this message translates to:
  /// **'jours'**
  String get rangeDaysSuffix;

  /// No description provided for @riderReadyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Prêt à rouler ?'**
  String get riderReadyTitle;

  /// No description provided for @riderReadySub.
  ///
  /// In fr, this message translates to:
  /// **'Passez en ligne pour recevoir des courses'**
  String get riderReadySub;

  /// No description provided for @riderModeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Livrer autour de vous'**
  String get riderModeTitle;

  /// No description provided for @riderModeBody.
  ///
  /// In fr, this message translates to:
  /// **'Récupérez les commandes des restaurants proches et livrez-les. Les frais de livraison sont pour vous.'**
  String get riderModeBody;

  /// No description provided for @startRiding.
  ///
  /// In fr, this message translates to:
  /// **'Commencer'**
  String get startRiding;

  /// No description provided for @doneForToday.
  ///
  /// In fr, this message translates to:
  /// **'J\'arrête pour aujourd\'hui'**
  String get doneForToday;

  /// No description provided for @statDeliveries.
  ///
  /// In fr, this message translates to:
  /// **'Courses'**
  String get statDeliveries;

  /// No description provided for @statEarnings.
  ///
  /// In fr, this message translates to:
  /// **'Gains du jour'**
  String get statEarnings;

  /// No description provided for @jobsNearYou.
  ///
  /// In fr, this message translates to:
  /// **'Courses autour de vous'**
  String get jobsNearYou;

  /// No description provided for @continueDelivery.
  ///
  /// In fr, this message translates to:
  /// **'Continuer la course'**
  String get continueDelivery;

  /// No description provided for @stepToRestaurant.
  ///
  /// In fr, this message translates to:
  /// **'En route vers le restaurant'**
  String get stepToRestaurant;

  /// No description provided for @stepReady.
  ///
  /// In fr, this message translates to:
  /// **'La commande est prête'**
  String get stepReady;

  /// No description provided for @stepReadySub.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez chaque article avant de partir'**
  String get stepReadySub;

  /// No description provided for @checkItems.
  ///
  /// In fr, this message translates to:
  /// **'Vérifier les articles'**
  String get checkItems;

  /// No description provided for @checkItemsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez chaque article'**
  String get checkItemsTitle;

  /// No description provided for @checkItemsHint.
  ///
  /// In fr, this message translates to:
  /// **'Touchez chaque article une fois qu’il est dans le sac.'**
  String get checkItemsHint;

  /// No description provided for @headToCustomer.
  ///
  /// In fr, this message translates to:
  /// **'Récupérée, en route !'**
  String get headToCustomer;

  /// No description provided for @stepToCustomer.
  ///
  /// In fr, this message translates to:
  /// **'En route vers le client'**
  String get stepToCustomer;

  /// No description provided for @stepArrived.
  ///
  /// In fr, this message translates to:
  /// **'Vous êtes arrivé'**
  String get stepArrived;

  /// No description provided for @collectCash.
  ///
  /// In fr, this message translates to:
  /// **'Encaissez {amount}'**
  String collectCash(String amount);

  /// No description provided for @statDistance.
  ///
  /// In fr, this message translates to:
  /// **'Distance'**
  String get statDistance;

  /// No description provided for @statItems.
  ///
  /// In fr, this message translates to:
  /// **'Articles'**
  String get statItems;

  /// No description provided for @statCash.
  ///
  /// In fr, this message translates to:
  /// **'À encaisser'**
  String get statCash;

  /// No description provided for @wellDone.
  ///
  /// In fr, this message translates to:
  /// **'Bravo {name} !'**
  String wellDone(String name);

  /// No description provided for @deliveryNumber.
  ///
  /// In fr, this message translates to:
  /// **'Livraison #{code}'**
  String deliveryNumber(String code);

  /// No description provided for @youEarned.
  ///
  /// In fr, this message translates to:
  /// **'+{amount} gagnés'**
  String youEarned(String amount);

  /// No description provided for @readyNextJob.
  ///
  /// In fr, this message translates to:
  /// **'Prêt pour la prochaine course ?'**
  String get readyNextJob;

  /// No description provided for @nextJob.
  ///
  /// In fr, this message translates to:
  /// **'Course suivante'**
  String get nextJob;

  /// No description provided for @checkIn.
  ///
  /// In fr, this message translates to:
  /// **'Je suis au restaurant'**
  String get checkIn;

  /// No description provided for @atRestaurant.
  ///
  /// In fr, this message translates to:
  /// **'Vous êtes au restaurant'**
  String get atRestaurant;

  /// No description provided for @missingItemCall.
  ///
  /// In fr, this message translates to:
  /// **'Article manquant ou erroné ? Appelez le restaurant'**
  String get missingItemCall;

  /// No description provided for @recenterMap.
  ///
  /// In fr, this message translates to:
  /// **'Recentrer'**
  String get recenterMap;

  /// No description provided for @followRider.
  ///
  /// In fr, this message translates to:
  /// **'Suivez votre livreur'**
  String get followRider;

  /// No description provided for @riderUpdatedAt.
  ///
  /// In fr, this message translates to:
  /// **'Position à {time}'**
  String riderUpdatedAt(String time);

  /// No description provided for @riderKmAway.
  ///
  /// In fr, this message translates to:
  /// **'À {km} km de chez vous'**
  String riderKmAway(String km);

  /// No description provided for @riderEditProfile.
  ///
  /// In fr, this message translates to:
  /// **'Modifier mon profil'**
  String get riderEditProfile;

  /// No description provided for @riderEditHint.
  ///
  /// In fr, this message translates to:
  /// **'Nom, téléphone, véhicule et photo'**
  String get riderEditHint;

  /// No description provided for @riderSince.
  ///
  /// In fr, this message translates to:
  /// **'Livreur depuis {date}'**
  String riderSince(String date);

  /// No description provided for @levelRookie.
  ///
  /// In fr, this message translates to:
  /// **'Débutant'**
  String get levelRookie;

  /// No description provided for @levelPro.
  ///
  /// In fr, this message translates to:
  /// **'Pro'**
  String get levelPro;

  /// No description provided for @levelExpert.
  ///
  /// In fr, this message translates to:
  /// **'Expert'**
  String get levelExpert;

  /// No description provided for @levelLegend.
  ///
  /// In fr, this message translates to:
  /// **'Légende'**
  String get levelLegend;

  /// No description provided for @levelLabel.
  ///
  /// In fr, this message translates to:
  /// **'Niveau {level}'**
  String levelLabel(String level);

  /// No description provided for @levelNext.
  ///
  /// In fr, this message translates to:
  /// **'Encore {n} livraisons pour devenir {level}'**
  String levelNext(int n, String level);

  /// No description provided for @levelNeedsRating.
  ///
  /// In fr, this message translates to:
  /// **'Gardez au moins {stars} étoiles pour devenir {level}'**
  String levelNeedsRating(String stars, String level);

  /// No description provided for @levelTop.
  ///
  /// In fr, this message translates to:
  /// **'Niveau maximum atteint, bravo !'**
  String get levelTop;

  /// No description provided for @statTotalDeliveries.
  ///
  /// In fr, this message translates to:
  /// **'Livraisons'**
  String get statTotalDeliveries;

  /// No description provided for @statTotalEarned.
  ///
  /// In fr, this message translates to:
  /// **'Gagnés'**
  String get statTotalEarned;

  /// No description provided for @statRating.
  ///
  /// In fr, this message translates to:
  /// **'Note'**
  String get statRating;

  /// No description provided for @ratingDetails.
  ///
  /// In fr, this message translates to:
  /// **'Voir le détail'**
  String get ratingDetails;

  /// No description provided for @allTime.
  ///
  /// In fr, this message translates to:
  /// **'Depuis le début'**
  String get allTime;

  /// No description provided for @fiveStarStreak.
  ///
  /// In fr, this message translates to:
  /// **'{n} notes 5 étoiles d’affilée'**
  String fiveStarStreak(int n);

  /// No description provided for @coachTitle.
  ///
  /// In fr, this message translates to:
  /// **'Conseils pour progresser'**
  String get coachTitle;

  /// No description provided for @coachLate.
  ///
  /// In fr, this message translates to:
  /// **'Prenez des courses proches de vous et partez dès que la commande est prête.'**
  String get coachLate;

  /// No description provided for @coachRude.
  ///
  /// In fr, this message translates to:
  /// **'Un bonjour et un sourire changent tout.'**
  String get coachRude;

  /// No description provided for @coachCareless.
  ///
  /// In fr, this message translates to:
  /// **'Gardez le sac à plat et les boissons debout.'**
  String get coachCareless;

  /// No description provided for @coachNoContact.
  ///
  /// In fr, this message translates to:
  /// **'Appelez le client 2 minutes avant d’arriver.'**
  String get coachNoContact;

  /// No description provided for @coachWrongPlace.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez le point sur la carte et l’étage avant de partir.'**
  String get coachWrongPlace;

  /// No description provided for @coachAllGood.
  ///
  /// In fr, this message translates to:
  /// **'Aucun problème signalé. Continuez comme ça !'**
  String get coachAllGood;

  /// No description provided for @ratingPrivateNote.
  ///
  /// In fr, this message translates to:
  /// **'Les clients notent la livraison en privé : vous voyez les chiffres, jamais qui a noté.'**
  String get ratingPrivateNote;

  /// No description provided for @sectionPreferences.
  ///
  /// In fr, this message translates to:
  /// **'Préférences'**
  String get sectionPreferences;

  /// No description provided for @dangerZone.
  ///
  /// In fr, this message translates to:
  /// **'Zone sensible'**
  String get dangerZone;

  /// No description provided for @riderDeleteTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer mon compte livreur'**
  String get riderDeleteTitle;

  /// No description provided for @riderDeleteBody.
  ///
  /// In fr, this message translates to:
  /// **'Votre profil, votre photo et votre note seront supprimés. Les commandes passées restent pour la comptabilité des restaurants, sans votre nom. C’est définitif.'**
  String get riderDeleteBody;

  /// No description provided for @riderDeleteCheckNoDelivery.
  ///
  /// In fr, this message translates to:
  /// **'Aucune livraison en cours'**
  String get riderDeleteCheckNoDelivery;

  /// No description provided for @riderDeleteCheckCash.
  ///
  /// In fr, this message translates to:
  /// **'Tout l’argent remis aux restaurants'**
  String get riderDeleteCheckCash;

  /// No description provided for @riderDeleteConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Je comprends, c’est définitif'**
  String get riderDeleteConfirm;

  /// No description provided for @errRiderNameInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Entrez votre nom (2 à 60 caractères)'**
  String get errRiderNameInvalid;

  /// No description provided for @errRiderCashPending.
  ///
  /// In fr, this message translates to:
  /// **'Remettez d’abord l’argent des repas aux restaurants.'**
  String get errRiderCashPending;

  /// No description provided for @goToCheckout.
  ///
  /// In fr, this message translates to:
  /// **'Passer à la caisse'**
  String get goToCheckout;

  /// No description provided for @orderSummary.
  ///
  /// In fr, this message translates to:
  /// **'Récapitulatif'**
  String get orderSummary;

  /// No description provided for @promoCode.
  ///
  /// In fr, this message translates to:
  /// **'Code promo'**
  String get promoCode;

  /// No description provided for @promoHint.
  ///
  /// In fr, this message translates to:
  /// **'Entrez votre code'**
  String get promoHint;

  /// No description provided for @applyPromo.
  ///
  /// In fr, this message translates to:
  /// **'Appliquer'**
  String get applyPromo;

  /// No description provided for @removePromo.
  ///
  /// In fr, this message translates to:
  /// **'Retirer'**
  String get removePromo;

  /// No description provided for @promoApplied.
  ///
  /// In fr, this message translates to:
  /// **'Code {code} appliqué'**
  String promoApplied(String code);

  /// No description provided for @discount.
  ///
  /// In fr, this message translates to:
  /// **'Réduction'**
  String get discount;

  /// No description provided for @taxLine.
  ///
  /// In fr, this message translates to:
  /// **'Taxe ({rate})'**
  String taxLine(String rate);

  /// No description provided for @paymentMethod.
  ///
  /// In fr, this message translates to:
  /// **'Mode de paiement'**
  String get paymentMethod;

  /// No description provided for @payCashHint.
  ///
  /// In fr, this message translates to:
  /// **'Payez le livreur à la réception'**
  String get payCashHint;

  /// No description provided for @payCard.
  ///
  /// In fr, this message translates to:
  /// **'Carte CIB / Edahabia'**
  String get payCard;

  /// No description provided for @payCcp.
  ///
  /// In fr, this message translates to:
  /// **'CCP / BaridiMob'**
  String get payCcp;

  /// No description provided for @comingSoon.
  ///
  /// In fr, this message translates to:
  /// **'Bientôt'**
  String get comingSoon;

  /// No description provided for @placeOrderTotal.
  ///
  /// In fr, this message translates to:
  /// **'Commander · {amount}'**
  String placeOrderTotal(String amount);

  /// No description provided for @payOnDeliveryNote.
  ///
  /// In fr, this message translates to:
  /// **'Vous ne payez qu’à la livraison.'**
  String get payOnDeliveryNote;

  /// No description provided for @youSave.
  ///
  /// In fr, this message translates to:
  /// **'Vous économisez {amount}'**
  String youSave(String amount);

  /// No description provided for @errPromoInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Code invalide'**
  String get errPromoInvalid;

  /// No description provided for @errPromoNotHere.
  ///
  /// In fr, this message translates to:
  /// **'Ce code n’est pas valable pour ce restaurant'**
  String get errPromoNotHere;

  /// No description provided for @errPromoNotStarted.
  ///
  /// In fr, this message translates to:
  /// **'Ce code n’est pas encore actif'**
  String get errPromoNotStarted;

  /// No description provided for @errPromoExpired.
  ///
  /// In fr, this message translates to:
  /// **'Ce code a expiré'**
  String get errPromoExpired;

  /// No description provided for @errPromoMinOrder.
  ///
  /// In fr, this message translates to:
  /// **'Le montant minimum de commande n’est pas atteint'**
  String get errPromoMinOrder;

  /// No description provided for @errPromoUsedUp.
  ///
  /// In fr, this message translates to:
  /// **'Ce code a atteint sa limite'**
  String get errPromoUsedUp;

  /// No description provided for @errPromoAlreadyUsed.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez déjà utilisé ce code'**
  String get errPromoAlreadyUsed;

  /// No description provided for @errPaymentUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Ce mode de paiement arrive bientôt'**
  String get errPaymentUnavailable;

  /// No description provided for @navPromos.
  ///
  /// In fr, this message translates to:
  /// **'Codes promo'**
  String get navPromos;

  /// No description provided for @promoNew.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau code'**
  String get promoNew;

  /// No description provided for @promoEdit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le code'**
  String get promoEdit;

  /// No description provided for @promoKindPercent.
  ///
  /// In fr, this message translates to:
  /// **'Pourcentage'**
  String get promoKindPercent;

  /// No description provided for @promoKindAmount.
  ///
  /// In fr, this message translates to:
  /// **'Montant fixe'**
  String get promoKindAmount;

  /// No description provided for @promoValuePercent.
  ///
  /// In fr, this message translates to:
  /// **'Réduction (%)'**
  String get promoValuePercent;

  /// No description provided for @promoValueAmount.
  ///
  /// In fr, this message translates to:
  /// **'Réduction (DA)'**
  String get promoValueAmount;

  /// No description provided for @promoMaxDiscount.
  ///
  /// In fr, this message translates to:
  /// **'Réduction max (DA)'**
  String get promoMaxDiscount;

  /// No description provided for @promoMinOrder.
  ///
  /// In fr, this message translates to:
  /// **'Commande minimum (DA)'**
  String get promoMinOrder;

  /// No description provided for @promoMaxUses.
  ///
  /// In fr, this message translates to:
  /// **'Utilisations max (total)'**
  String get promoMaxUses;

  /// No description provided for @promoPerCustomer.
  ///
  /// In fr, this message translates to:
  /// **'Max par client'**
  String get promoPerCustomer;

  /// No description provided for @promoEnds.
  ///
  /// In fr, this message translates to:
  /// **'Expire le'**
  String get promoEnds;

  /// No description provided for @promoNoEnd.
  ///
  /// In fr, this message translates to:
  /// **'Sans date de fin'**
  String get promoNoEnd;

  /// No description provided for @promoRestaurant.
  ///
  /// In fr, this message translates to:
  /// **'Restaurant'**
  String get promoRestaurant;

  /// No description provided for @promoAllRestaurants.
  ///
  /// In fr, this message translates to:
  /// **'Tous les restaurants'**
  String get promoAllRestaurants;

  /// No description provided for @promoFundedBy.
  ///
  /// In fr, this message translates to:
  /// **'Payé par'**
  String get promoFundedBy;

  /// No description provided for @fundedPlatform.
  ///
  /// In fr, this message translates to:
  /// **'La plateforme'**
  String get fundedPlatform;

  /// No description provided for @fundedRestaurant.
  ///
  /// In fr, this message translates to:
  /// **'Le restaurant'**
  String get fundedRestaurant;

  /// No description provided for @promoUses.
  ///
  /// In fr, this message translates to:
  /// **'{n} utilisations'**
  String promoUses(int n);

  /// No description provided for @promoGiven.
  ///
  /// In fr, this message translates to:
  /// **'{amount} offerts'**
  String promoGiven(String amount);

  /// No description provided for @promoActive.
  ///
  /// In fr, this message translates to:
  /// **'Actif'**
  String get promoActive;

  /// No description provided for @promoInactive.
  ///
  /// In fr, this message translates to:
  /// **'Désactivé'**
  String get promoInactive;

  /// No description provided for @promoNote.
  ///
  /// In fr, this message translates to:
  /// **'Note interne'**
  String get promoNote;

  /// No description provided for @promoMin.
  ///
  /// In fr, this message translates to:
  /// **'dès {amount}'**
  String promoMin(String amount);

  /// No description provided for @errPromoCode.
  ///
  /// In fr, this message translates to:
  /// **'Code : 3 à 20 lettres ou chiffres'**
  String get errPromoCode;

  /// No description provided for @errPromoTaken.
  ///
  /// In fr, this message translates to:
  /// **'Ce code existe déjà'**
  String get errPromoTaken;

  /// No description provided for @errPromoValue.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez les valeurs (pourcentage 1 à 90)'**
  String get errPromoValue;

  /// No description provided for @noPromos.
  ///
  /// In fr, this message translates to:
  /// **'Aucun code pour le moment'**
  String get noPromos;

  /// No description provided for @amountDue.
  ///
  /// In fr, this message translates to:
  /// **'Montant dû'**
  String get amountDue;

  /// No description provided for @taxCollected.
  ///
  /// In fr, this message translates to:
  /// **'Taxe collectée'**
  String get taxCollected;

  /// No description provided for @platformDiscounts.
  ///
  /// In fr, this message translates to:
  /// **'Réductions payées par la plateforme'**
  String get platformDiscounts;

  /// No description provided for @taxLabel.
  ///
  /// In fr, this message translates to:
  /// **'Taxe'**
  String get taxLabel;

  /// No description provided for @copy.
  ///
  /// In fr, this message translates to:
  /// **'Copier'**
  String get copy;

  /// No description provided for @copied.
  ///
  /// In fr, this message translates to:
  /// **'Copié'**
  String get copied;

  /// No description provided for @qrTitle.
  ///
  /// In fr, this message translates to:
  /// **'QR code du restaurant'**
  String get qrTitle;

  /// No description provided for @qrHint.
  ///
  /// In fr, this message translates to:
  /// **'Affiche à imprimer, scans'**
  String get qrHint;

  /// No description provided for @qrScanToOrder.
  ///
  /// In fr, this message translates to:
  /// **'Scannez pour commander'**
  String get qrScanToOrder;

  /// No description provided for @qrDownloadPoster.
  ///
  /// In fr, this message translates to:
  /// **'Télécharger l’affiche (PDF)'**
  String get qrDownloadPoster;

  /// No description provided for @qrCopyLink.
  ///
  /// In fr, this message translates to:
  /// **'Copier le lien'**
  String get qrCopyLink;

  /// No description provided for @qrStatsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Scans de votre QR code'**
  String get qrStatsTitle;

  /// No description provided for @qrScans30.
  ///
  /// In fr, this message translates to:
  /// **'Scans (30 jours)'**
  String get qrScans30;

  /// No description provided for @qrPeople.
  ///
  /// In fr, this message translates to:
  /// **'Personnes'**
  String get qrPeople;

  /// No description provided for @qrOrdersAfter.
  ///
  /// In fr, this message translates to:
  /// **'Commandes après un scan'**
  String get qrOrdersAfter;

  /// No description provided for @qrScansTotal.
  ///
  /// In fr, this message translates to:
  /// **'{total} scans au total · {app} avec l’app · {web} avec l’appareil photo'**
  String qrScansTotal(int total, int app, int web);

  /// No description provided for @qrTip.
  ///
  /// In fr, this message translates to:
  /// **'Collez l’affiche sur la vitrine, la caisse et les tables, et mettez-la dans les sacs de livraison. Un scan ouvre directement votre page dans foodfennec.'**
  String get qrTip;

  /// No description provided for @scanTitle.
  ///
  /// In fr, this message translates to:
  /// **'Scanner un QR code'**
  String get scanTitle;

  /// No description provided for @scanHint.
  ///
  /// In fr, this message translates to:
  /// **'Visez le QR code d’un restaurant foodfennec'**
  String get scanHint;

  /// No description provided for @scanNotOurs.
  ///
  /// In fr, this message translates to:
  /// **'Ce QR code n’est pas un code foodfennec'**
  String get scanNotOurs;

  /// No description provided for @scanCameraDenied.
  ///
  /// In fr, this message translates to:
  /// **'Autorisez l’appareil photo dans les réglages pour scanner.'**
  String get scanCameraDenied;

  /// No description provided for @scanCameraError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d’ouvrir l’appareil photo.'**
  String get scanCameraError;

  /// No description provided for @qrLinkSetting.
  ///
  /// In fr, this message translates to:
  /// **'Lien des QR codes'**
  String get qrLinkSetting;

  /// No description provided for @qrLinkLabel.
  ///
  /// In fr, this message translates to:
  /// **'Adresse du site'**
  String get qrLinkLabel;

  /// No description provided for @qrLinkHelp.
  ///
  /// In fr, this message translates to:
  /// **'Les QR codes ouvrent cette adresse + /r/nom-du-restaurant. Réglez votre vrai domaine avant d’imprimer les affiches. Le scanner de l’app fonctionne quel que soit le domaine.'**
  String get qrLinkHelp;

  /// No description provided for @errQrLink.
  ///
  /// In fr, this message translates to:
  /// **'Adresse invalide (ex. https://foodfennec.com)'**
  String get errQrLink;

  /// No description provided for @wilaya.
  ///
  /// In fr, this message translates to:
  /// **'Wilaya'**
  String get wilaya;

  /// No description provided for @chooseWilaya.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez votre wilaya'**
  String get chooseWilaya;

  /// No description provided for @errWilaya.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez votre wilaya'**
  String get errWilaya;

  /// No description provided for @commune.
  ///
  /// In fr, this message translates to:
  /// **'Commune'**
  String get commune;

  /// No description provided for @communeHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex. Bab Ezzouar'**
  String get communeHint;

  /// No description provided for @errCommune.
  ///
  /// In fr, this message translates to:
  /// **'Indiquez votre commune'**
  String get errCommune;

  /// No description provided for @birthDate.
  ///
  /// In fr, this message translates to:
  /// **'Date de naissance'**
  String get birthDate;

  /// No description provided for @chooseDate.
  ///
  /// In fr, this message translates to:
  /// **'Choisir une date'**
  String get chooseDate;

  /// No description provided for @errBirthDate.
  ///
  /// In fr, this message translates to:
  /// **'Date de naissance invalide (13 ans minimum)'**
  String get errBirthDate;

  /// No description provided for @gender.
  ///
  /// In fr, this message translates to:
  /// **'Genre'**
  String get gender;

  /// No description provided for @genderMale.
  ///
  /// In fr, this message translates to:
  /// **'Homme'**
  String get genderMale;

  /// No description provided for @genderFemale.
  ///
  /// In fr, this message translates to:
  /// **'Femme'**
  String get genderFemale;

  /// No description provided for @howDidYouHear.
  ///
  /// In fr, this message translates to:
  /// **'Comment avez-vous connu foodfennec ?'**
  String get howDidYouHear;

  /// No description provided for @refFriend.
  ///
  /// In fr, this message translates to:
  /// **'Un ami'**
  String get refFriend;

  /// No description provided for @refSocial.
  ///
  /// In fr, this message translates to:
  /// **'Réseaux sociaux'**
  String get refSocial;

  /// No description provided for @refSearch.
  ///
  /// In fr, this message translates to:
  /// **'Recherche Google'**
  String get refSearch;

  /// No description provided for @refRestaurant.
  ///
  /// In fr, this message translates to:
  /// **'Un restaurant'**
  String get refRestaurant;

  /// No description provided for @refAd.
  ///
  /// In fr, this message translates to:
  /// **'Publicité'**
  String get refAd;

  /// No description provided for @refOther.
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get refOther;

  /// No description provided for @completeProfileTitle.
  ///
  /// In fr, this message translates to:
  /// **'Complétez votre profil'**
  String get completeProfileTitle;

  /// No description provided for @completeProfileBody.
  ///
  /// In fr, this message translates to:
  /// **'30 secondes pour recevoir des offres qui vous ressemblent.'**
  String get completeProfileBody;

  /// No description provided for @completeProfileAction.
  ///
  /// In fr, this message translates to:
  /// **'Compléter'**
  String get completeProfileAction;

  /// No description provided for @completeProfilePrivacy.
  ///
  /// In fr, this message translates to:
  /// **'Ces informations restent privées : elles nous aident à améliorer foodfennec.'**
  String get completeProfilePrivacy;

  /// No description provided for @later.
  ///
  /// In fr, this message translates to:
  /// **'Plus tard'**
  String get later;

  /// No description provided for @thanksProfile.
  ///
  /// In fr, this message translates to:
  /// **'Merci ! Profil mis à jour.'**
  String get thanksProfile;

  /// No description provided for @cancelOrderTitle.
  ///
  /// In fr, this message translates to:
  /// **'Annuler la commande ?'**
  String get cancelOrderTitle;

  /// No description provided for @cancelRequestTitle.
  ///
  /// In fr, this message translates to:
  /// **'Demander l’annulation'**
  String get cancelRequestTitle;

  /// No description provided for @cancelFreeExplain.
  ///
  /// In fr, this message translates to:
  /// **'Le restaurant n’a pas encore accepté : l’annulation est immédiate et gratuite.'**
  String get cancelFreeExplain;

  /// No description provided for @cancelRequestExplain.
  ///
  /// In fr, this message translates to:
  /// **'Le restaurant prépare déjà votre commande. Il recevra votre demande et décidera : si la cuisine a commencé, il peut refuser.'**
  String get cancelRequestExplain;

  /// No description provided for @cancelWhy.
  ///
  /// In fr, this message translates to:
  /// **'Pourquoi ?'**
  String get cancelWhy;

  /// No description provided for @cancelReasonChangedMind.
  ///
  /// In fr, this message translates to:
  /// **'J’ai changé d’avis'**
  String get cancelReasonChangedMind;

  /// No description provided for @cancelReasonTooLong.
  ///
  /// In fr, this message translates to:
  /// **'C’est trop long'**
  String get cancelReasonTooLong;

  /// No description provided for @cancelReasonWrongAddress.
  ///
  /// In fr, this message translates to:
  /// **'Mauvaise adresse'**
  String get cancelReasonWrongAddress;

  /// No description provided for @cancelReasonWrongItems.
  ///
  /// In fr, this message translates to:
  /// **'Erreur dans la commande'**
  String get cancelReasonWrongItems;

  /// No description provided for @cancelReasonDuplicate.
  ///
  /// In fr, this message translates to:
  /// **'Commande en double'**
  String get cancelReasonDuplicate;

  /// No description provided for @cancelReasonOther.
  ///
  /// In fr, this message translates to:
  /// **'Autre raison'**
  String get cancelReasonOther;

  /// No description provided for @cancelNoteHint.
  ///
  /// In fr, this message translates to:
  /// **'Un mot pour le restaurant (facultatif)'**
  String get cancelNoteHint;

  /// No description provided for @sendCancelRequest.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer la demande'**
  String get sendCancelRequest;

  /// No description provided for @cancelRequestSent.
  ///
  /// In fr, this message translates to:
  /// **'Demande envoyée : le restaurant va répondre.'**
  String get cancelRequestSent;

  /// No description provided for @cancelRequestPending.
  ///
  /// In fr, this message translates to:
  /// **'Demande d’annulation envoyée. Le restaurant va répondre.'**
  String get cancelRequestPending;

  /// No description provided for @cancelRequestRefused.
  ///
  /// In fr, this message translates to:
  /// **'Le restaurant a refusé l’annulation : votre commande est déjà en préparation et continue.'**
  String get cancelRequestRefused;

  /// No description provided for @cancelRequestExpired.
  ///
  /// In fr, this message translates to:
  /// **'Trop tard pour annuler : le livreur a déjà récupéré la commande.'**
  String get cancelRequestExpired;

  /// No description provided for @cancelledByYou.
  ///
  /// In fr, this message translates to:
  /// **'Annulée à votre demande · {reason}'**
  String cancelledByYou(String reason);

  /// No description provided for @errCancelAlreadyRequested.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez déjà demandé l’annulation'**
  String get errCancelAlreadyRequested;

  /// No description provided for @errCancelRequestRefused.
  ///
  /// In fr, this message translates to:
  /// **'Le restaurant a déjà refusé l’annulation'**
  String get errCancelRequestRefused;

  /// No description provided for @customerWantsCancel.
  ///
  /// In fr, this message translates to:
  /// **'Le client demande l’annulation'**
  String get customerWantsCancel;

  /// No description provided for @cancelRequestOwnerHint.
  ///
  /// In fr, this message translates to:
  /// **'Acceptez si la cuisine n’a pas commencé.'**
  String get cancelRequestOwnerHint;

  /// No description provided for @acceptCancel.
  ///
  /// In fr, this message translates to:
  /// **'Accepter l’annulation'**
  String get acceptCancel;

  /// No description provided for @refuseCancel.
  ///
  /// In fr, this message translates to:
  /// **'Refuser'**
  String get refuseCancel;

  /// No description provided for @cancelAcceptedMsg.
  ///
  /// In fr, this message translates to:
  /// **'Commande annulée à la demande du client'**
  String get cancelAcceptedMsg;

  /// No description provided for @cancelRefusedMsg.
  ///
  /// In fr, this message translates to:
  /// **'Annulation refusée : la commande continue'**
  String get cancelRefusedMsg;

  /// No description provided for @accountSuspendedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Compte suspendu'**
  String get accountSuspendedTitle;

  /// No description provided for @accountSuspendedUntil.
  ///
  /// In fr, this message translates to:
  /// **'Vous pourrez de nouveau utiliser foodfennec le {date}.'**
  String accountSuspendedUntil(String date);

  /// No description provided for @accountBannedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Compte bloqué'**
  String get accountBannedTitle;

  /// No description provided for @accountBannedBody.
  ///
  /// In fr, this message translates to:
  /// **'Votre compte a été bloqué. Contactez-nous si vous pensez que c’est une erreur.'**
  String get accountBannedBody;

  /// No description provided for @sanctionReasonTitle.
  ///
  /// In fr, this message translates to:
  /// **'Motif'**
  String get sanctionReasonTitle;

  /// No description provided for @contactSupport.
  ///
  /// In fr, this message translates to:
  /// **'Contacter le support'**
  String get contactSupport;

  /// No description provided for @warningTitle.
  ///
  /// In fr, this message translates to:
  /// **'Avertissement'**
  String get warningTitle;

  /// No description provided for @warningBody.
  ///
  /// In fr, this message translates to:
  /// **'Si cela se reproduit, votre compte pourra être suspendu.'**
  String get warningBody;

  /// No description provided for @understood.
  ///
  /// In fr, this message translates to:
  /// **'J’ai compris'**
  String get understood;

  /// No description provided for @errAccountSuspended.
  ///
  /// In fr, this message translates to:
  /// **'Votre compte est suspendu'**
  String get errAccountSuspended;

  /// No description provided for @sanctionFakeOrders.
  ///
  /// In fr, this message translates to:
  /// **'Fausses commandes'**
  String get sanctionFakeOrders;

  /// No description provided for @sanctionNoShow.
  ///
  /// In fr, this message translates to:
  /// **'Absent à la livraison'**
  String get sanctionNoShow;

  /// No description provided for @sanctionRefusedToPay.
  ///
  /// In fr, this message translates to:
  /// **'Refus de payer'**
  String get sanctionRefusedToPay;

  /// No description provided for @sanctionAbuse.
  ///
  /// In fr, this message translates to:
  /// **'Comportement irrespectueux'**
  String get sanctionAbuse;

  /// No description provided for @sanctionFraud.
  ///
  /// In fr, this message translates to:
  /// **'Fraude'**
  String get sanctionFraud;

  /// No description provided for @sanctionTooManyCancellations.
  ///
  /// In fr, this message translates to:
  /// **'Trop d’annulations'**
  String get sanctionTooManyCancellations;

  /// No description provided for @sanctionUnsafeDriving.
  ///
  /// In fr, this message translates to:
  /// **'Conduite dangereuse'**
  String get sanctionUnsafeDriving;

  /// No description provided for @sanctionCashNotReturned.
  ///
  /// In fr, this message translates to:
  /// **'Argent non remis au restaurant'**
  String get sanctionCashNotReturned;

  /// No description provided for @sanctionOther.
  ///
  /// In fr, this message translates to:
  /// **'Non-respect des règles'**
  String get sanctionOther;

  /// No description provided for @sanctionWarning.
  ///
  /// In fr, this message translates to:
  /// **'Avertissement'**
  String get sanctionWarning;

  /// No description provided for @sanctionSuspension.
  ///
  /// In fr, this message translates to:
  /// **'Suspension'**
  String get sanctionSuspension;

  /// No description provided for @sanctionBan.
  ///
  /// In fr, this message translates to:
  /// **'Blocage'**
  String get sanctionBan;

  /// No description provided for @suspendedPill.
  ///
  /// In fr, this message translates to:
  /// **'Suspendu'**
  String get suspendedPill;

  /// No description provided for @bannedPill.
  ///
  /// In fr, this message translates to:
  /// **'Bloqué'**
  String get bannedPill;

  /// No description provided for @warnAction.
  ///
  /// In fr, this message translates to:
  /// **'Avertir'**
  String get warnAction;

  /// No description provided for @suspendAction.
  ///
  /// In fr, this message translates to:
  /// **'Suspendre'**
  String get suspendAction;

  /// No description provided for @banAction.
  ///
  /// In fr, this message translates to:
  /// **'Bloquer'**
  String get banAction;

  /// No description provided for @liftAction.
  ///
  /// In fr, this message translates to:
  /// **'Lever'**
  String get liftAction;

  /// No description provided for @removeAction.
  ///
  /// In fr, this message translates to:
  /// **'Retirer'**
  String get removeAction;

  /// No description provided for @warnTitle.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer un avertissement'**
  String get warnTitle;

  /// No description provided for @suspendTitle.
  ///
  /// In fr, this message translates to:
  /// **'Suspendre le compte'**
  String get suspendTitle;

  /// No description provided for @banTitle.
  ///
  /// In fr, this message translates to:
  /// **'Bloquer le compte'**
  String get banTitle;

  /// No description provided for @warnExplain.
  ///
  /// In fr, this message translates to:
  /// **'La personne le verra une fois en ouvrant l’app. Elle peut continuer à l’utiliser.'**
  String get warnExplain;

  /// No description provided for @suspendExplain.
  ///
  /// In fr, this message translates to:
  /// **'Plus de commandes (client) ni de livraisons (livreur) jusqu’à la fin.'**
  String get suspendExplain;

  /// No description provided for @banExplain.
  ///
  /// In fr, this message translates to:
  /// **'Bloqué jusqu’à ce que vous leviez le blocage.'**
  String get banExplain;

  /// No description provided for @suspendFor.
  ///
  /// In fr, this message translates to:
  /// **'Durée'**
  String get suspendFor;

  /// No description provided for @daysCount.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =1{1 jour} other{{n} jours}}'**
  String daysCount(int n);

  /// No description provided for @messageToUser.
  ///
  /// In fr, this message translates to:
  /// **'Message à la personne'**
  String get messageToUser;

  /// No description provided for @messageToUserHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex. Merci de ne commander que si vous êtes disponible.'**
  String get messageToUserHint;

  /// No description provided for @adminNoteLabel.
  ///
  /// In fr, this message translates to:
  /// **'Note interne (admin)'**
  String get adminNoteLabel;

  /// No description provided for @sanctionHistory.
  ///
  /// In fr, this message translates to:
  /// **'Historique'**
  String get sanctionHistory;

  /// No description provided for @noSanctions.
  ///
  /// In fr, this message translates to:
  /// **'Aucune sanction'**
  String get noSanctions;

  /// No description provided for @sanctionsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Sanctions'**
  String get sanctionsTitle;

  /// No description provided for @sanctionLifted.
  ///
  /// In fr, this message translates to:
  /// **'Sanction levée'**
  String get sanctionLifted;

  /// No description provided for @untilDate.
  ///
  /// In fr, this message translates to:
  /// **'jusqu’au {date}'**
  String untilDate(String date);

  /// No description provided for @liftedOn.
  ///
  /// In fr, this message translates to:
  /// **'levée le {date}'**
  String liftedOn(String date);

  /// No description provided for @seen.
  ///
  /// In fr, this message translates to:
  /// **'vu'**
  String get seen;

  /// No description provided for @allCustomers.
  ///
  /// In fr, this message translates to:
  /// **'Tous'**
  String get allCustomers;

  /// No description provided for @watchlistTab.
  ///
  /// In fr, this message translates to:
  /// **'À surveiller ({n})'**
  String watchlistTab(int n);

  /// No description provided for @watchlistHelp.
  ///
  /// In fr, this message translates to:
  /// **'Clients ayant annulé (ou demandé à annuler) 3 fois ou plus en 30 jours.'**
  String get watchlistHelp;

  /// No description provided for @watchlistEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Personne à surveiller'**
  String get watchlistEmpty;

  /// No description provided for @cancels30d.
  ///
  /// In fr, this message translates to:
  /// **'{n} annulations en 30 j'**
  String cancels30d(int n);

  /// No description provided for @openReports.
  ///
  /// In fr, this message translates to:
  /// **'{n} signalements'**
  String openReports(int n);

  /// No description provided for @statCustomers.
  ///
  /// In fr, this message translates to:
  /// **'Clients'**
  String get statCustomers;

  /// No description provided for @statNew7d.
  ///
  /// In fr, this message translates to:
  /// **'Nouveaux (7 jours)'**
  String get statNew7d;

  /// No description provided for @statActive7d.
  ///
  /// In fr, this message translates to:
  /// **'Actifs 7 j · {today} aujourd’hui'**
  String statActive7d(int today);

  /// No description provided for @statOrdered.
  ///
  /// In fr, this message translates to:
  /// **'Ont déjà commandé'**
  String get statOrdered;

  /// No description provided for @statProfileDone.
  ///
  /// In fr, this message translates to:
  /// **'Profil complété'**
  String get statProfileDone;

  /// No description provided for @ageGroups.
  ///
  /// In fr, this message translates to:
  /// **'Âge'**
  String get ageGroups;

  /// No description provided for @heardFrom.
  ///
  /// In fr, this message translates to:
  /// **'Connu via'**
  String get heardFrom;

  /// No description provided for @platformLabel.
  ///
  /// In fr, this message translates to:
  /// **'Plateforme'**
  String get platformLabel;

  /// No description provided for @unknownValue.
  ///
  /// In fr, this message translates to:
  /// **'Non renseigné'**
  String get unknownValue;

  /// No description provided for @ageLabel.
  ///
  /// In fr, this message translates to:
  /// **'Âge'**
  String get ageLabel;

  /// No description provided for @memberSince.
  ///
  /// In fr, this message translates to:
  /// **'Inscrit le'**
  String get memberSince;

  /// No description provided for @deviceAndActivity.
  ///
  /// In fr, this message translates to:
  /// **'Appareil et activité'**
  String get deviceAndActivity;

  /// No description provided for @lastSeen.
  ///
  /// In fr, this message translates to:
  /// **'Dernière visite'**
  String get lastSeen;

  /// No description provided for @activeDays30.
  ///
  /// In fr, this message translates to:
  /// **'Jours actifs (30 j)'**
  String get activeDays30;

  /// No description provided for @deviceLabel.
  ///
  /// In fr, this message translates to:
  /// **'Appareil'**
  String get deviceLabel;

  /// No description provided for @ordersTotal.
  ///
  /// In fr, this message translates to:
  /// **'Commandes'**
  String get ordersTotal;

  /// No description provided for @cancels30dLabel.
  ///
  /// In fr, this message translates to:
  /// **'Annulations (30 j)'**
  String get cancels30dLabel;

  /// No description provided for @spentLabel.
  ///
  /// In fr, this message translates to:
  /// **'Dépensé'**
  String get spentLabel;

  /// No description provided for @lastOrder.
  ///
  /// In fr, this message translates to:
  /// **'Dernière commande'**
  String get lastOrder;
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
