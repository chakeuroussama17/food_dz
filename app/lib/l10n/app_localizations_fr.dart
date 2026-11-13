// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'foodfennec';

  @override
  String get language => 'Langue';

  @override
  String get langAr => 'العربية';

  @override
  String get langFr => 'Français';

  @override
  String get langEn => 'English';

  @override
  String get back => 'Retour';

  @override
  String get addToCart => 'Ajouter au panier';

  @override
  String get cart => 'Panier';

  @override
  String get checkout => 'Commander';

  @override
  String get placeOrder => 'Passer la commande';

  @override
  String get total => 'Total';

  @override
  String get subtotal => 'Sous-total';

  @override
  String get deliveryFee => 'Livraison';

  @override
  String get freeDelivery => 'Gratuit';

  @override
  String minutes(int count) {
    return '$count min';
  }

  @override
  String get open => 'Ouvert';

  @override
  String get closed => 'Fermé';

  @override
  String get fullName => 'Nom complet';

  @override
  String get phone => 'Téléphone';

  @override
  String get address => 'Adresse';

  @override
  String get area => 'Quartier / commune';

  @override
  String get notes => 'Remarques';

  @override
  String get optional => 'facultatif';

  @override
  String get cashOnDelivery => 'Paiement à la livraison';

  @override
  String get otherRestaurants => 'Autres restaurants';

  @override
  String get email => 'E-mail';

  @override
  String get password => 'Mot de passe';

  @override
  String get logIn => 'Se connecter';

  @override
  String get logInSubtitle => 'Connectez-vous à votre compte';

  @override
  String get accept => 'Accepter';

  @override
  String get reject => 'Refuser';

  @override
  String get ready => 'Prêt';

  @override
  String get cancel => 'Annuler';

  @override
  String get save => 'Enregistrer';

  @override
  String get statusPlaced => 'Commande envoyée';

  @override
  String get statusAccepted => 'Acceptée par le restaurant';

  @override
  String get statusReady => 'Prête';

  @override
  String get statusPickedUp => 'En route';

  @override
  String get statusDelivered => 'Livrée';

  @override
  String get statusRejected => 'Refusée';

  @override
  String get statusCancelled => 'Annulée';

  @override
  String get runningOrders => 'Commandes en cours';

  @override
  String get orderRequests => 'Nouvelles demandes';

  @override
  String itemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count articles',
      one: '1 article',
      zero: 'Aucun article',
    );
    return '$_temp0';
  }

  @override
  String get componentGallery => 'Galerie des composants';

  @override
  String get onb1Title => 'Tous vos plats préférés';

  @override
  String get onb1Body =>
      'Tous vos plats préférés au même endroit. Vous commandez, on s\'occupe du reste.';

  @override
  String get onb2Title => 'Les meilleurs restaurants';

  @override
  String get onb2Body =>
      'Les restaurants de votre quartier, tout leur menu, en quelques secondes.';

  @override
  String get onb3Title => 'Paiement à la livraison';

  @override
  String get onb3Body =>
      'Pas besoin de carte : payez en espèces à l\'arrivée de votre commande.';

  @override
  String get next => 'Suivant';

  @override
  String get skip => 'Passer';

  @override
  String get getStarted => 'Commencer';

  @override
  String get logInTitle => 'Connexion';

  @override
  String get logInSubtitleLong => 'Connectez-vous à votre compte';

  @override
  String get signUpTitle => 'Inscription';

  @override
  String get signUpSubtitle => 'Inscrivez-vous pour commencer';

  @override
  String get signUp => 'S\'inscrire';

  @override
  String get name => 'Nom';

  @override
  String get namePlaceholder => 'Karim Benali';

  @override
  String get emailPlaceholder => 'exemple@gmail.com';

  @override
  String get retypePassword => 'Confirmer le mot de passe';

  @override
  String get rememberMe => 'Se souvenir de moi';

  @override
  String get forgotPassword => 'Mot de passe oublié';

  @override
  String get noAccount => 'Pas encore de compte ?';

  @override
  String get haveAccount => 'Déjà un compte ?';

  @override
  String get verificationTitle => 'Vérification';

  @override
  String get codeSentTo => 'Nous avons envoyé un code à';

  @override
  String get code => 'Code';

  @override
  String get resend => 'Renvoyer';

  @override
  String resendIn(int seconds) {
    return 'dans $seconds s';
  }

  @override
  String get verify => 'Vérifier';

  @override
  String get codeResent => 'Nouveau code envoyé';

  @override
  String get forgotPasswordTitle => 'Mot de passe oublié';

  @override
  String get forgotPasswordSubtitle =>
      'Entrez votre e-mail pour recevoir un code';

  @override
  String get sendCode => 'Envoyer le code';

  @override
  String get newPasswordTitle => 'Nouveau mot de passe';

  @override
  String get newPasswordSubtitle => 'Choisissez un nouveau mot de passe';

  @override
  String get newPassword => 'Nouveau mot de passe';

  @override
  String get passwordUpdated => 'Mot de passe modifié';

  @override
  String get logOut => 'Se déconnecter';

  @override
  String hello(String name) {
    return 'Bonjour, $name';
  }

  @override
  String get homeComingSoon => 'Les restaurants arrivent à la prochaine étape.';

  @override
  String get errNameRequired => 'Entrez votre nom (2 à 80 caractères)';

  @override
  String get errEmailInvalid => 'Adresse e-mail invalide';

  @override
  String get errPasswordShort => '8 caractères minimum';

  @override
  String get errPasswordMismatch => 'Les mots de passe ne correspondent pas';

  @override
  String get errCodeIncomplete => 'Entrez le code à 6 chiffres';

  @override
  String get errInvalidCredentials => 'E-mail ou mot de passe incorrect';

  @override
  String get errUserExists => 'Un compte existe déjà avec cet e-mail';

  @override
  String get errCodeInvalid => 'Code incorrect ou expiré';

  @override
  String get errTooManyRequests =>
      'Trop de tentatives, réessayez dans un moment';

  @override
  String get errWeakPassword => 'Mot de passe trop faible';

  @override
  String get errNetwork => 'Pas de connexion. Vérifiez votre réseau.';

  @override
  String get errGeneric => 'Une erreur est survenue, réessayez';

  @override
  String get errBackendMissing => 'Serveur non configuré (env.json)';

  @override
  String get showPassword => 'Afficher le mot de passe';

  @override
  String get hidePassword => 'Masquer le mot de passe';

  @override
  String get errEmailSend =>
      'Impossible d\'envoyer l\'e-mail de code à cette adresse. Réessayez plus tard.';

  @override
  String get errServer =>
      'Le serveur a rencontré un problème. Réessayez dans un instant.';

  @override
  String get deliverTo => 'Livrer à';

  @override
  String get chooseAddress => 'Choisir une adresse';

  @override
  String greetingMorning(String name) {
    return 'Bonjour $name !';
  }

  @override
  String greetingAfternoon(String name) {
    return 'Bon après-midi $name !';
  }

  @override
  String greetingEvening(String name) {
    return 'Bonsoir $name !';
  }

  @override
  String get searchHint => 'Rechercher plats, restaurants';

  @override
  String get allCategories => 'Toutes les catégories';

  @override
  String get seeAll => 'Tout voir';

  @override
  String get openRestaurants => 'Restaurants';

  @override
  String get all => 'Tout';

  @override
  String fromPrice(String price) {
    return 'Dès $price';
  }

  @override
  String kmAway(String km) {
    return '$km km';
  }

  @override
  String get recentKeywords => 'Recherches récentes';

  @override
  String get suggestedRestaurants => 'Restaurants suggérés';

  @override
  String noResults(String query) {
    return 'Aucun résultat pour « $query »';
  }

  @override
  String get dishes => 'Plats';

  @override
  String get restaurantsTitle => 'Restaurants';

  @override
  String get restaurant => 'Restaurant';

  @override
  String get details => 'Détails';

  @override
  String popularIn(String category) {
    return '$category populaires';
  }

  @override
  String get addedToCart => 'Ajouté au panier';

  @override
  String cartOtherRestaurant(String name) {
    return 'Votre panier contient des articles de $name. Commencer un nouveau panier ?';
  }

  @override
  String get newCart => 'Nouveau panier';

  @override
  String get unavailable => 'Indisponible';

  @override
  String get restaurantNotFound => 'Restaurant introuvable';

  @override
  String get restaurantClosedNote => 'Ce restaurant est fermé pour le moment';

  @override
  String get retry => 'Réessayer';

  @override
  String get loadError => 'Chargement impossible. Vérifiez votre connexion.';

  @override
  String get accessLocation => 'Accéder à la position';

  @override
  String get locationExplain =>
      'FOOD UTILISE VOTRE POSITION UNIQUEMENT PENDANT L\'UTILISATION DE L\'APPLICATION';

  @override
  String get notNow => 'Plus tard';

  @override
  String get locationDenied => 'Accès à la position refusé';

  @override
  String get profile => 'Profil';

  @override
  String get personalInfo => 'Informations personnelles';

  @override
  String get addresses => 'Adresses';

  @override
  String get edit => 'Modifier';

  @override
  String get editProfile => 'Modifier le profil';

  @override
  String get saved => 'Enregistré';

  @override
  String get changePhoto => 'Changer la photo';

  @override
  String get phoneOptionalHint => '0550 12 34 56';

  @override
  String get errPhoneInvalid => 'Numéro invalide (05, 06 ou 07 + 8 chiffres)';

  @override
  String get addNewAddress => 'Ajouter une adresse';

  @override
  String get editAddress => 'Modifier l\'adresse';

  @override
  String get saveLocation => 'Enregistrer l\'adresse';

  @override
  String get labelAs => 'Type';

  @override
  String get labelHome => 'Maison';

  @override
  String get labelWork => 'Travail';

  @override
  String get labelOther => 'Autre';

  @override
  String get addressDetails => 'Bâtiment, étage, porte';

  @override
  String get addressHint => 'Cité 200 logements, rue…';

  @override
  String get areaHint => 'Kouba, Hydra, Bab Ezzouar…';

  @override
  String get setDefault => 'Définir par défaut';

  @override
  String get defaultTag => 'Par défaut';

  @override
  String get delete => 'Supprimer';

  @override
  String get deleteAddressConfirm => 'Supprimer cette adresse ?';

  @override
  String get noAddresses => 'Aucune adresse enregistrée';

  @override
  String get moveMapHint => 'Déplacez la carte pour placer le repère';

  @override
  String get useMyLocation => 'Ma position';

  @override
  String get errAddressRequired => 'Entrez l\'adresse (3 caractères minimum)';

  @override
  String get errAddressLimit =>
      'Vous pouvez enregistrer 10 adresses au maximum';

  @override
  String get search => 'Rechercher';

  @override
  String get cartEmpty => 'Votre panier est vide';

  @override
  String get checkoutNextStep =>
      'La commande sera disponible à la prochaine étape.';

  @override
  String get ownRestaurant => 'Vous avez un restaurant ?';

  @override
  String get registerIt => 'Inscrivez-le';

  @override
  String get registerRestaurantTitle => 'Votre restaurant';

  @override
  String get registerRestaurantSubtitle =>
      'Rejoignez foodfennec et recevez des commandes';

  @override
  String get yourAccount => 'Votre compte';

  @override
  String get restaurantSection => 'Le restaurant';

  @override
  String get restaurantName => 'Nom du restaurant';

  @override
  String get restaurantPhone => 'Téléphone du restaurant';

  @override
  String get prepTime => 'Temps de préparation (min)';

  @override
  String get errRestaurantPhone =>
      'Numéro invalide (ex. 0550123456 ou 021234567)';

  @override
  String get errPrepTime => 'Entre 5 et 120 minutes';

  @override
  String get pendingApprovalTitle => 'En attente de validation';

  @override
  String get pendingApprovalBody =>
      'Nous vérifions votre restaurant. Préparez votre menu en attendant : les clients le verront dès la validation.';

  @override
  String get openForOrders => 'Ouvert aux commandes';

  @override
  String get closedForOrders => 'Fermé';

  @override
  String get openSwitchHint =>
      'Les clients peuvent commander quand c\'est activé';

  @override
  String get cantOpenPending => 'Vous pourrez ouvrir après la validation';

  @override
  String get dashboard => 'Tableau de bord';

  @override
  String get menu => 'Menu';

  @override
  String get orders => 'Commandes';

  @override
  String get myMenu => 'Mon menu';

  @override
  String totalItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count plats',
      one: '1 plat',
      zero: 'Aucun plat',
    );
    return '$_temp0';
  }

  @override
  String get addItem => 'Ajouter un plat';

  @override
  String get editItem => 'Modifier le plat';

  @override
  String get reset => 'Réinitialiser';

  @override
  String get itemName => 'Nom du plat';

  @override
  String get itemNameHint => 'Pizza Margherita';

  @override
  String get uploadPhoto => 'Photo';

  @override
  String get add => 'Ajouter';

  @override
  String get price => 'Prix (DA)';

  @override
  String get priceHint => '650';

  @override
  String get errPrice => 'Prix entre 10 et 100 000 DA';

  @override
  String get category => 'Catégorie';

  @override
  String get noCategory => 'Aucune';

  @override
  String get available => 'Disponible';

  @override
  String get itemDetails => 'Description';

  @override
  String get itemDetailsHint => 'Ingrédients, taille…';

  @override
  String get saveChanges => 'Enregistrer';

  @override
  String get deleteItemConfirm => 'Supprimer ce plat ?';

  @override
  String get emptyMenu => 'Votre menu est vide. Ajoutez votre premier plat.';

  @override
  String get ordersComingSoon =>
      'Les commandes en direct arrivent à la prochaine étape.';

  @override
  String get restaurantProfile => 'Profil du restaurant';

  @override
  String get coverPhoto => 'Photo de couverture';

  @override
  String get logo => 'Logo';

  @override
  String get description => 'Description';

  @override
  String get descriptionHint => 'Pizzas au feu de bois, tacos…';

  @override
  String get restaurantLocation => 'Position sur la carte';

  @override
  String get errPhotoTooLarge => 'Photo trop lourde (3 Mo max)';

  @override
  String dishesAvailable(int available, int total) {
    return '$available sur $total disponibles';
  }

  @override
  String get seeMenu => 'Voir le menu';

  @override
  String get registrationDone => 'Restaurant enregistré';

  @override
  String get admin => 'Administration';

  @override
  String get receipts => 'Relevés';

  @override
  String get settings => 'Paramètres';

  @override
  String get customers => 'Clients';

  @override
  String get periodToday => 'Aujourd\'hui';

  @override
  String get periodLast7 => '7 jours';

  @override
  String get periodThisMonth => 'Ce mois';

  @override
  String get periodLastMonth => 'Mois dernier';

  @override
  String get periodCustom => 'Personnalisé';

  @override
  String get previousHalfMonth => 'Quinzaine précédente';

  @override
  String get statDelivered => 'Commandes livrées';

  @override
  String get statSales => 'Ventes (repas)';

  @override
  String get statDeliveryFees => 'Frais de livraison';

  @override
  String get statCommission => 'Commission gagnée';

  @override
  String get statCancelled => 'Annulées / refusées';

  @override
  String get statActive => 'En cours';

  @override
  String get statPending => 'Restaurants à valider';

  @override
  String get statActiveRestaurants => 'Restaurants actifs';

  @override
  String get statUnbilled => 'Commission non facturée';

  @override
  String get byRestaurant => 'Par restaurant';

  @override
  String get filterPending => 'À valider';

  @override
  String get filterActive => 'Actifs';

  @override
  String get filterInactive => 'Désactivés';

  @override
  String get approve => 'Valider';

  @override
  String get deactivate => 'Désactiver';

  @override
  String get reactivate => 'Réactiver';

  @override
  String get commissionRate => 'Taux de commission';

  @override
  String defaultRate(String rate) {
    return 'Par défaut ($rate)';
  }

  @override
  String get useDefault => 'Taux par défaut';

  @override
  String get errRate => 'Entre 0 et 50 %';

  @override
  String get owner => 'Gérant';

  @override
  String toBill(String amount) {
    return 'À facturer : $amount';
  }

  @override
  String deliveredCount(int count) {
    return '$count livrées';
  }

  @override
  String get noRestaurants => 'Aucun restaurant';

  @override
  String get newReceipt => 'Nouveau relevé';

  @override
  String get receiptPeriod => 'Période';

  @override
  String receiptPreview(int count, String food) {
    return '$count commandes livrées · ventes $food';
  }

  @override
  String get commissionDue => 'Commission due';

  @override
  String get generateReceipt => 'Générer le relevé';

  @override
  String get noOrdersToBill =>
      'Aucune commande livrée à facturer sur cette période';

  @override
  String get periodNotFinished => 'Choisissez une période terminée';

  @override
  String get statusPaid => 'Payé';

  @override
  String get statusUnpaid => 'Non payé';

  @override
  String get markPaid => 'Marquer payé';

  @override
  String get markUnpaid => 'Marquer non payé';

  @override
  String get downloadPdf => 'Télécharger le PDF';

  @override
  String get printPdf => 'Imprimer';

  @override
  String get cancelReceipt => 'Annuler le relevé';

  @override
  String get cancelReceiptConfirm =>
      'Annuler ce relevé ? Ses commandes pourront être refacturées.';

  @override
  String get noReceipts => 'Aucun relevé pour l\'instant';

  @override
  String get allRestaurants => 'Tous les restaurants';

  @override
  String get allStatuses => 'Tous les statuts';

  @override
  String get noOrders => 'Aucune commande';

  @override
  String get loadMore => 'Voir plus';

  @override
  String get itemsTitle => 'Articles';

  @override
  String get defaultCommission => 'Commission par défaut (%)';

  @override
  String get deliveryFeeDa => 'Frais de livraison (DA)';

  @override
  String get errDeliveryFee => 'Entre 0 et 5 000 DA';

  @override
  String get businessInfo => 'Vos informations (imprimées sur les relevés)';

  @override
  String get businessName => 'Nom commercial';

  @override
  String get businessPhone => 'Téléphone';

  @override
  String get businessEmail => 'E-mail';

  @override
  String get businessAddress => 'Adresse';

  @override
  String get businessTaxId => 'NIF';

  @override
  String get searchCustomers => 'Nom, e-mail ou téléphone';

  @override
  String ordersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commandes',
      one: '1 commande',
      zero: 'Aucune commande',
    );
    return '$_temp0';
  }

  @override
  String get restaurantFilter => 'Restaurant';

  @override
  String get statusFilter => 'Statut';

  @override
  String issuedOn(String date) {
    return 'Émis le $date';
  }

  @override
  String get deliveryAddress => 'Adresse de livraison';

  @override
  String get breakdown => 'Détail';

  @override
  String get addDeliveryAddress => 'Ajouter une adresse de livraison';

  @override
  String get deliveryDetails => 'Détails de livraison';

  @override
  String get phoneForDriver =>
      'Le restaurant et le livreur vous appelleront sur ce numéro.';

  @override
  String get notesHint => 'Ex. : sans oignons, 2e étage';

  @override
  String get orderPlacedTitle => 'Commande envoyée !';

  @override
  String orderPlacedBody(String total) {
    return 'Le restaurant va confirmer votre commande. Vous paierez $total en espèces à la livraison.';
  }

  @override
  String get trackOrder => 'Suivre la commande';

  @override
  String get backToHome => 'Retour à l\'accueil';

  @override
  String get myOrders => 'Mes commandes';

  @override
  String get ongoingOrders => 'En cours';

  @override
  String get orderHistory => 'Historique';

  @override
  String get noOngoingOrders => 'Aucune commande en cours';

  @override
  String get noPastOrders => 'Aucune commande passée';

  @override
  String orderNumber(String code) {
    return 'Commande #$code';
  }

  @override
  String orderedAt(String date) {
    return 'Commandée le $date';
  }

  @override
  String get cancelOrder => 'Annuler la commande';

  @override
  String get cancelOrderConfirm => 'Annuler cette commande ?';

  @override
  String get keepOrder => 'Non, garder';

  @override
  String get orderCancelledMsg => 'Commande annulée';

  @override
  String rejectReasonLabel(String reason) {
    return 'Motif : $reason';
  }

  @override
  String get payInCash => 'À payer en espèces';

  @override
  String get orderItems => 'Votre commande';

  @override
  String get callRestaurant => 'Appeler le restaurant';

  @override
  String get errRestaurantClosed => 'Ce restaurant est fermé pour le moment.';

  @override
  String get errRestaurantUnavailable =>
      'Ce restaurant n\'est plus disponible.';

  @override
  String get errItemUnavailable =>
      'Un plat n\'est plus disponible. Votre panier a été mis à jour.';

  @override
  String get errPricesChanged =>
      'Les prix ont changé. Votre panier a été mis à jour, vérifiez le total.';

  @override
  String get errTooManyActiveOrders =>
      'Vous avez déjà 3 commandes en cours. Attendez qu\'une soit livrée.';

  @override
  String get errTooManyOrders =>
      'Trop de commandes en peu de temps. Réessayez plus tard.';

  @override
  String get errAddressGone =>
      'Cette adresse n\'existe plus. Choisissez-en une autre.';

  @override
  String get errCannotCancel =>
      'Le restaurant a déjà accepté la commande, elle ne peut plus être annulée.';

  @override
  String tabNewOrders(int count) {
    return 'Nouvelles ($count)';
  }

  @override
  String tabInProgress(int count) {
    return 'En cours ($count)';
  }

  @override
  String get markReady => 'Prête';

  @override
  String get waitingDriver => 'En attente du livreur';

  @override
  String get rejectOrderTitle => 'Refuser la commande';

  @override
  String get cancelOrderTitleOwner => 'Annuler la commande';

  @override
  String get reasonLabel => 'Motif (visible par le client)';

  @override
  String get reasonBusy => 'Trop de commandes en ce moment';

  @override
  String get reasonItemOut => 'Un plat n\'est plus disponible';

  @override
  String get reasonClosing => 'Nous fermons bientôt';

  @override
  String get reasonUnreachable => 'Client injoignable';

  @override
  String get errReasonRequired => 'Indiquez un motif.';

  @override
  String get errOrderChanged =>
      'Cette commande a changé entre-temps. La liste est à jour.';

  @override
  String get enableSoundAlerts =>
      'Touchez ici pour activer l\'alerte sonore des nouvelles commandes';

  @override
  String get soundOn => 'Alerte sonore activée';

  @override
  String get soundOff => 'Alerte sonore coupée';

  @override
  String minutesAgo(int count) {
    return 'il y a $count min';
  }

  @override
  String get justNow => 'à l\'instant';

  @override
  String get noNewOrders => 'Aucune nouvelle commande';

  @override
  String get noOrdersInProgress => 'Aucune commande en cours';

  @override
  String get customer => 'Client';

  @override
  String get orderAcceptedMsg => 'Commande acceptée';

  @override
  String get orderReadyMsg => 'Commande prête, en attente du livreur';

  @override
  String get orderRejectedMsg => 'Commande refusée';

  @override
  String newOrderBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nouvelles commandes à accepter',
      one: '1 nouvelle commande à accepter',
    );
    return '$_temp0';
  }

  @override
  String get deliverWithUs => 'Vous êtes livreur ?';

  @override
  String get joinAsDriver => 'Rejoignez-nous';

  @override
  String get registerDriverTitle => 'Devenir livreur';

  @override
  String get registerDriverSubtitle => 'Livrez des commandes près de chez vous';

  @override
  String get driverSection => 'Livreur';

  @override
  String get driverPhone => 'Téléphone (mobile)';

  @override
  String get vehicle => 'Véhicule';

  @override
  String get vehicleMoto => 'Moto';

  @override
  String get vehicleCar => 'Voiture';

  @override
  String get vehicleBike => 'Vélo';

  @override
  String get driverRegistered =>
      'Inscription envoyée. Un administrateur va valider votre compte.';

  @override
  String get driverPendingTitle => 'En attente de validation';

  @override
  String get driverPendingBody =>
      'L\'administrateur doit valider votre compte avant que vous puissiez livrer.';

  @override
  String get onlineLabel => 'En ligne';

  @override
  String get offlineLabel => 'Hors ligne';

  @override
  String get youAreOnline => 'Vous recevez les nouvelles commandes.';

  @override
  String get youAreOffline => 'Passez en ligne pour recevoir des commandes.';

  @override
  String get availableOrders => 'Commandes disponibles';

  @override
  String get noAvailableOrders =>
      'Aucune commande pour le moment. La liste se met à jour toute seule.';

  @override
  String get takeOrder => 'Je la prends';

  @override
  String get orderTaken => 'Commande à vous ! Allez au restaurant.';

  @override
  String get errAlreadyTaken => 'Un autre livreur l\'a prise avant vous.';

  @override
  String get errDriverBusy => 'Terminez d\'abord votre livraison en cours.';

  @override
  String get errNotOnline => 'Passez en ligne d\'abord.';

  @override
  String get errNotApproved => 'Votre compte n\'est pas encore validé.';

  @override
  String get currentDelivery => 'Livraison en cours';

  @override
  String get pickupAt => 'Récupérer chez';

  @override
  String get dropOffAt => 'Livrer à';

  @override
  String get cashToCollect => 'À encaisser';

  @override
  String get yourFee => 'Votre gain';

  @override
  String get handToRestaurant => 'À remettre au restaurant';

  @override
  String get waitRestaurant =>
      'Le restaurant prépare la commande. Attendez qu\'elle soit prête.';

  @override
  String get markPickedUp => 'Commande récupérée';

  @override
  String get markDelivered => 'Livrée et payée';

  @override
  String confirmDelivered(String total) {
    return 'Confirmer la livraison ? Le client vous a payé $total.';
  }

  @override
  String get confirm => 'Confirmer';

  @override
  String get releaseOrder => 'Rendre la commande';

  @override
  String get releaseConfirm => 'Rendre cette commande aux autres livreurs ?';

  @override
  String get callAction => 'Appeler';

  @override
  String get directions => 'Itinéraire';

  @override
  String get deliveredMsg => 'Livraison terminée. Merci !';

  @override
  String get pickedUpMsg => 'En route vers le client';

  @override
  String get cancelledByRestaurant => 'Le restaurant a annulé cette commande.';

  @override
  String todaySummary(int count, String amount) {
    return 'Aujourd\'hui : $count livraisons · $amount';
  }

  @override
  String get driversTitle => 'Livreurs';

  @override
  String get noDrivers => 'Aucun livreur';

  @override
  String currentOrderCode(String code) {
    return 'Commande en cours : #$code';
  }

  @override
  String get yourDriver => 'Votre livreur';

  @override
  String driverLabel(String name) {
    return 'Livreur : $name';
  }

  @override
  String get myDeliveries => 'Mes livraisons';

  @override
  String get noDeliveries => 'Aucune livraison';

  @override
  String get driverApproved => 'Compte validé';

  @override
  String get proofTitle => 'Photo de livraison';

  @override
  String get proofHint =>
      'Prenez en photo la commande remise au client (ou devant sa porte). Elle sert de preuve en cas de litige.';

  @override
  String get takePhoto => 'Prendre la photo';

  @override
  String get retakePhoto => 'Reprendre';

  @override
  String get errPhotoRequired =>
      'La photo est obligatoire pour confirmer la livraison.';

  @override
  String get errCashOverdue =>
      'Vous avez de l\'argent à remettre depuis trop longtemps. Le restaurant doit confirmer la réception avant que vous preniez de nouvelles commandes.';

  @override
  String get cashBlockedTitle => 'Nouvelles commandes bloquées';

  @override
  String get moneyToHand => 'Argent à remettre aux restaurants';

  @override
  String moneyToHandTotal(String amount) {
    return 'Total à remettre : $amount';
  }

  @override
  String get iGaveMoney => 'J\'ai remis l\'argent';

  @override
  String get waitingRestaurantConfirm =>
      'En attente de confirmation du restaurant';

  @override
  String get cashHandedMsg =>
      'Noté. Le restaurant doit confirmer la réception.';

  @override
  String get cashToReceive => 'Argent à recevoir des livreurs';

  @override
  String get confirmReceived => 'Reçu';

  @override
  String confirmReceivedQ(String amount, String name) {
    return 'Confirmer avoir reçu $amount de $name ?';
  }

  @override
  String get cashConfirmedMsg => 'Réception confirmée';

  @override
  String get driverSaysHanded => 'Le livreur dit l\'avoir remis';

  @override
  String get proofOfDelivery => 'Preuve de livraison';

  @override
  String cashOwedLine(String amount, int count) {
    return 'Doit $amount ($count commandes)';
  }

  @override
  String get cashBlockedPill => 'Bloqué';

  @override
  String get cashStatusConfirmed => 'Argent reçu par le restaurant';

  @override
  String get cashStatusHanded => 'Argent remis par le livreur, à confirmer';

  @override
  String get cashStatusPending => 'Argent pas encore remis au restaurant';

  @override
  String deliveredOnTime(String date) {
    return 'Livrée $date';
  }

  @override
  String get cashHoursSetting =>
      'Bloquer un livreur après (heures sans remise)';

  @override
  String get errCashHours => 'Entre 1 et 168 heures';

  @override
  String get downloadReceipt => 'Télécharger le reçu';

  @override
  String get printAction => 'Imprimer';

  @override
  String get receiptOrderTitle => 'Reçu de commande';

  @override
  String get receiptOrderNo => 'Commande';

  @override
  String get receiptDate => 'Date';

  @override
  String get receiptDeliveredOn => 'Livrée le';

  @override
  String get receiptCustomer => 'Client';

  @override
  String get receiptItem => 'Article';

  @override
  String get receiptQty => 'Qté';

  @override
  String get receiptUnit => 'Prix unitaire';

  @override
  String get receiptAmount => 'Montant';

  @override
  String get receiptPaidCash => 'Payé en espèces à la livraison';

  @override
  String get receiptDeliveredBy => 'Livré par';

  @override
  String get receiptTotalPaid => 'Total payé';

  @override
  String get receiptFooter =>
      'Montants en dinars algériens (DA). Document généré par l\'application.';

  @override
  String get receiptPage => 'Page';

  @override
  String get taxIdShort => 'NIF';

  @override
  String get driverStatementTitle => 'Relevé du livreur';

  @override
  String get downloadStatement => 'Télécharger le relevé';

  @override
  String get periodThisWeek => 'Cette semaine';

  @override
  String get periodLastWeek => 'Semaine dernière';

  @override
  String get stDeliveries => 'Livraisons';

  @override
  String get stCollected => 'Encaissé';

  @override
  String get stToRestaurant => 'Au restaurant';

  @override
  String get stFee => 'Gain';

  @override
  String get stMoney => 'Argent';

  @override
  String get stConfirmed => 'Remis';

  @override
  String get stOpen => 'À remettre';

  @override
  String get stTotalCollected => 'Total encaissé';

  @override
  String get stTotalToRestaurants => 'Total dû aux restaurants';

  @override
  String get stStillToGive => 'Reste à remettre';

  @override
  String get stEarned => 'Vos gains';

  @override
  String get stDriver => 'Livreur';

  @override
  String get noDeliveriesInPeriod => 'Aucune livraison sur cette période';

  @override
  String get myStatements => 'Mes relevés de commission';

  @override
  String get chooseFromGallery => 'Choisir dans la galerie';

  @override
  String get errCamera =>
      'Impossible d\'ouvrir l\'appareil photo. Autorisez la caméra dans les réglages, ou choisissez une photo dans la galerie.';

  @override
  String get reasonNoAnswer => 'Le restaurant n\'a pas répondu à temps';

  @override
  String get autoRejectSetting =>
      'Refus automatique si le restaurant ne répond pas (minutes)';

  @override
  String get errAutoReject => 'Entre 3 et 60 minutes';

  @override
  String get deleteAccount => 'Supprimer mon compte';

  @override
  String get deleteAccountConfirm =>
      'Supprimer définitivement votre compte ? Vos adresses et votre photo seront effacées. Vos anciennes commandes restent anonymes pour la comptabilité.';

  @override
  String get accountDeleted => 'Compte supprimé';

  @override
  String get errDeleteActiveOrders =>
      'Vous avez une commande en cours. Réessayez quand elle est livrée.';

  @override
  String get errDeleteNotCustomer =>
      'Les comptes restaurant et livreur sont fermés par l\'administrateur. Contactez-le.';

  @override
  String get locationServiceOff =>
      'La localisation du téléphone est désactivée.';

  @override
  String get locationBlocked =>
      'Localisation refusée pour cette application. Autorisez-la dans les réglages.';

  @override
  String get locationUnavailable =>
      'Position introuvable. Réessayez dehors ou cherchez votre adresse sur la carte.';

  @override
  String get turnOn => 'Activer';

  @override
  String get openSettings => 'Réglages';

  @override
  String get searchAddressHint => 'Chercher une adresse, un quartier…';

  @override
  String get navHome => 'Accueil';

  @override
  String get navAccount => 'Compte';

  @override
  String get viewProfile => 'Voir le profil';

  @override
  String get general => 'Général';

  @override
  String get helpCenter => 'Centre d\'aide';

  @override
  String get supportSoon =>
      'Le numéro du service client sera bientôt disponible.';

  @override
  String get becomePartner => 'Inscrire mon restaurant';

  @override
  String get becomeDriver => 'Devenir livreur';

  @override
  String get termsTitle => 'Conditions et confidentialité';

  @override
  String get appVersion => 'Version';

  @override
  String get promoCashTitle => 'Payez à la livraison';

  @override
  String get promoCashBody =>
      'En espèces, à l\'arrivée de votre commande. Sans carte.';

  @override
  String promoFeeTitle(String fee) {
    return 'Livraison $fee';
  }

  @override
  String get promoFeeBody => 'Le même prix partout en ville.';

  @override
  String get promoDiscover => 'Ouvert maintenant · Commandez →';

  @override
  String get termsOrdersTitle => 'Commandes et paiement';

  @override
  String get termsOrdersBody =>
      'Les prix sont ceux du restaurant au moment de la commande. Vous payez en espèces à la livraison (plats + frais de livraison). Une commande peut être annulée tant que le restaurant ne l\'a pas acceptée.';

  @override
  String get termsDataTitle => 'Vos données';

  @override
  String get termsDataBody =>
      'Nous utilisons votre nom, téléphone et adresse uniquement pour livrer vos commandes. Le restaurant et le livreur les voient pour votre commande. Une photo de remise est prise à la livraison comme preuve.';

  @override
  String get termsDeleteTitle => 'Supprimer votre compte';

  @override
  String get termsDeleteBody =>
      'Compte → Supprimer mon compte. Vos adresses et votre photo sont effacées ; vos anciennes commandes restent anonymes pour la comptabilité.';

  @override
  String get openNowTitle => 'Ouverts maintenant';

  @override
  String get homeBanners => 'Bannières de l\'accueil';

  @override
  String get addBanner => 'Ajouter une bannière';

  @override
  String get noBanners =>
      'Aucune bannière. Ajoutez des images (pubs, nouveautés) : elles défilent en haut de l\'accueil des clients.';

  @override
  String get bannerSizeHint => 'Format large conseillé : 1200 × 500 pixels.';

  @override
  String get choosePicture => 'Choisir une image';

  @override
  String get bannerTitle => 'Titre';

  @override
  String get bannerOpens => 'Au toucher, ouvrir';

  @override
  String get bannerNoLink => 'Rien (image seule)';

  @override
  String get deleteBannerConfirm => 'Supprimer cette bannière ?';

  @override
  String get moveUp => 'Monter';

  @override
  String get moveDown => 'Descendre';

  @override
  String get appearance => 'Apparence';

  @override
  String get themeSystem => 'Auto (comme le téléphone)';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get insights => 'Tendances';

  @override
  String get todayTitle => 'Aujourd\'hui';

  @override
  String get compareYesterday => 'Comparé à hier à la même heure';

  @override
  String get kpiSales => 'Ventes';

  @override
  String get kpiOrders => 'Commandes';

  @override
  String get kpiAvgBasket => 'Panier moyen';

  @override
  String get kpiPrep => 'Préparation moy.';

  @override
  String get kpiAcceptance => 'Taux d\'acceptation';

  @override
  String get kpiNet => 'Net après commission';

  @override
  String minutesShort(int n) {
    return '$n min';
  }

  @override
  String get last7Days => '7 derniers jours';

  @override
  String get seeInsights => 'Voir les tendances';

  @override
  String get shortcuts => 'Raccourcis';

  @override
  String get ordersTable => 'Tableau des commandes';

  @override
  String get liveOrders => 'Commandes en direct';

  @override
  String dishesNoPhoto(int n) {
    return '$n plats sans photo : les photos font vendre';
  }

  @override
  String dishesUnavailable(int n) {
    return '$n plats indisponibles';
  }

  @override
  String get menuHealthGood => 'Menu complet, bravo !';

  @override
  String get rangeYesterday => 'Hier';

  @override
  String get range7 => '7 jours';

  @override
  String get range30 => '30 jours';

  @override
  String get range90 => '90 jours';

  @override
  String get rangeMonth => 'Ce mois';

  @override
  String get rangeCustom => 'Dates…';

  @override
  String get filterAll => 'Toutes';

  @override
  String get filterInProgress => 'En cours';

  @override
  String get searchOrdersHint => 'Code, client, plat…';

  @override
  String get exportCsv => 'Exporter CSV';

  @override
  String get csvReady => 'Fichier CSV prêt';

  @override
  String get noOrdersPeriod => 'Aucune commande sur cette période';

  @override
  String get tableTotals => 'Total de la sélection';

  @override
  String get csvCode => 'Code';

  @override
  String get csvDate => 'Date';

  @override
  String get csvTime => 'Heure';

  @override
  String get csvStatus => 'Statut';

  @override
  String get csvCustomer => 'Client';

  @override
  String get csvArea => 'Quartier';

  @override
  String get csvItems => 'Articles';

  @override
  String get csvItemCount => 'Nb articles';

  @override
  String get csvFood => 'Plats (DA)';

  @override
  String get csvDeliveryFee => 'Livraison (DA)';

  @override
  String get csvTotal => 'Total (DA)';

  @override
  String get csvCommission => 'Commission (DA)';

  @override
  String get csvNet => 'Net (DA)';

  @override
  String get csvDriver => 'Livreur';

  @override
  String get csvPrepMinutes => 'Préparation (min)';

  @override
  String get csvReason => 'Motif';

  @override
  String comparedPrevious(int n) {
    return 'Comparé aux $n jours précédents';
  }

  @override
  String get salesChartTitle => 'Ventes par jour';

  @override
  String get tapBarHint => 'Touchez une barre pour voir le détail';

  @override
  String get hoursChartTitle => 'Heures de pointe';

  @override
  String get weekdayChartTitle => 'Jours de la semaine';

  @override
  String get topDishesTitle => 'Plats les plus vendus';

  @override
  String get outcomesTitle => 'Issue des commandes';

  @override
  String soldTimes(int n) {
    return '$n vendus';
  }

  @override
  String get tipsTitle => 'Conseils pour vendre plus';

  @override
  String tipSalesUp(int n) {
    return 'Vos ventes ont augmenté de $n% par rapport à la période précédente. Continuez !';
  }

  @override
  String tipSalesDown(int n) {
    return 'Ventes en baisse de $n%. Vérifiez vos heures d\'ouverture et ajoutez des photos à vos plats.';
  }

  @override
  String tipRefusals(int n, String amount) {
    return '$n commandes refusées ou sans réponse : $amount de ventes perdues. Fermez le restaurant quand vous ne pouvez pas servir.';
  }

  @override
  String tipSlowResponse(int n) {
    return 'Vous mettez $n min en moyenne pour accepter. Les clients attendent, et une commande sans réponse est refusée automatiquement.';
  }

  @override
  String tipSlowPrep(int n, int announced) {
    return 'La préparation prend $n min, vous annoncez $announced min. Mettez à jour le temps dans votre profil ou accélérez.';
  }

  @override
  String tipPeakHour(String hour, int share) {
    return 'Heure de pointe : $hour ($share% des commandes). Préparez vos ingrédients avant.';
  }

  @override
  String tipTopDish(String dish, int share) {
    return '« $dish » fait $share% de vos ventes. Gardez-le toujours disponible, avec une belle photo.';
  }

  @override
  String tipQuietDay(String day) {
    return '$day est votre jour le plus calme : bon moment pour une offre ou un nouveau plat.';
  }

  @override
  String get tipNoOrders =>
      'Pas encore de commandes sur cette période. Ouvrez aux heures des repas et complétez votre menu avec des photos.';

  @override
  String get myBusiness => 'Mon activité';

  @override
  String get accountApproved => 'Approuvé';

  @override
  String get accountPending => 'En attente';

  @override
  String get deleteRestaurantConfirm =>
      'Votre compte sera supprimé et votre restaurant retiré de l\'application. Vos commandes et relevés restent archivés pour la comptabilité. Cette action est définitive.';

  @override
  String get errDeleteCashPending =>
      'Confirmez d\'abord l\'argent reçu des livreurs.';

  @override
  String get errDeleteUnpaidCommission =>
      'Des commissions restent à régler. Contactez l\'administrateur.';

  @override
  String get restaurantDetailsHint =>
      'Photos, adresse, téléphone, temps de préparation';

  @override
  String get outlets => 'Points de vente';

  @override
  String get roleOwner => 'Propriétaire';

  @override
  String get roleManager => 'Gérant';

  @override
  String get roleStaff => 'Employé';

  @override
  String get csvOutlet => 'Point de vente';

  @override
  String get portalTitle => 'Portail partenaire';

  @override
  String get portalTagline =>
      'Gérez vos restaurants, commandes et ventes au même endroit.';

  @override
  String get portalLoginTitle => 'Connexion au portail partenaire';

  @override
  String get portalNotPartner =>
      'Ce portail est réservé aux restaurants partenaires. Inscrivez d\'abord votre restaurant dans l\'application.';

  @override
  String get navReports => 'Rapports';

  @override
  String get navInvoices => 'Factures';

  @override
  String get navMenu => 'Gestion du menu';

  @override
  String get navHours => 'Horaires d\'ouverture';

  @override
  String get navReviews => 'Avis et notes';

  @override
  String get navMarketing => 'Marketing';

  @override
  String get navNotifications => 'Centre de notifications';

  @override
  String get navTeam => 'Équipe';

  @override
  String get soon => 'Bientôt';

  @override
  String get comingSoonTitle => 'Bientôt disponible';

  @override
  String get comingSoonBody =>
      'Cette section arrive à la prochaine étape. En attendant, utilisez l\'application.';

  @override
  String get outletsAll => 'Tous les points de vente';

  @override
  String outletsCount(int n, int total) {
    return '$n/$total points de vente';
  }

  @override
  String get dashboardSubtitle =>
      'Vue d\'ensemble de vos commandes et de vos points de vente';

  @override
  String get ordersToday => 'Commandes aujourd\'hui';

  @override
  String get cancelledToday => 'Annulées ou refusées aujourd\'hui';

  @override
  String get closedOutletsNow => 'Points de vente fermés';

  @override
  String get salesToday => 'Ventes aujourd\'hui';

  @override
  String updatedAt(String time) {
    return 'Mis à jour à $time';
  }

  @override
  String get businessSummary => 'Résumé de l’activité';

  @override
  String get thisWeek => 'Cette semaine';

  @override
  String get lastWeek => 'Semaine dernière';

  @override
  String get comparison => 'Comparaison';

  @override
  String get previousPeriod => 'Période précédente';

  @override
  String get totalLabel => 'Total';

  @override
  String get cancelledLabel => 'Annulées';

  @override
  String get waitingOrders => 'En attente de votre réponse';

  @override
  String get noWaitingOrders => 'Aucune commande en attente.';

  @override
  String get ordersSubtitle => 'Détails des commandes en temps réel';

  @override
  String get placedAtCol => 'Passée le';

  @override
  String acceptedIn(String time) {
    return 'Acceptée en $time';
  }

  @override
  String get orderDetailsTitle => 'Détails de la commande';

  @override
  String secondsShort(int n) {
    return '$n s';
  }

  @override
  String get reportsSubtitle => 'Analysez vos performances';

  @override
  String get tabSales => 'Ventes';

  @override
  String get tabOperations => 'Opérations';

  @override
  String get tabCustomers => 'Clients';

  @override
  String get previousMonth => 'Mois précédent';

  @override
  String get salesByDayHint =>
      'Ventes et commandes par jour : votre activité monte-t-elle ou baisse-t-elle ?';

  @override
  String get downloadReport => 'Télécharger le rapport';

  @override
  String get salesByHour => 'Ventes par heure';

  @override
  String get salesByHourHint =>
      'Ventes par heure et jour de la semaine : vos heures calmes et chargées.';

  @override
  String get avgResponse => 'Temps moyen d\'acceptation';

  @override
  String get cancellationRate => 'Taux d\'annulation';

  @override
  String get lostSales => 'Ventes perdues';

  @override
  String get refusalReasons => 'Refus et annulations par motif';

  @override
  String get prepByDay => 'Temps de préparation par jour';

  @override
  String get newVsReturning => 'Nouveaux vs clients fidèles';

  @override
  String get newVsReturningHint =>
      'Part des commandes venant de nouveaux clients et de clients qui reviennent.';

  @override
  String get ordersFromNew => 'Commandes de nouveaux clients';

  @override
  String get ordersFromReturning => 'Commandes de clients fidèles';

  @override
  String get moreReturningTitle => 'Plus de clients fidèles ?';

  @override
  String get moreReturningBody =>
      'Les clients reviennent pour la qualité et la rapidité : gardez vos meilleurs plats disponibles, répondez vite et annoncez des temps de préparation honnêtes.';

  @override
  String get moreNewTitle => 'Plus de nouveaux clients ?';

  @override
  String get moreNewBody =>
      'De belles photos et des descriptions complètes donnent envie d\'essayer. Une bannière sur l\'accueil (demandez à l\'administrateur) vous montre à tous.';

  @override
  String get topAreas => 'Quartiers principaux';

  @override
  String get uniqueCustomers => 'Clients';

  @override
  String get invoicesSubtitle => 'Téléchargez vos relevés de commission';

  @override
  String get noInvoices => 'Aucune facture pour le moment';

  @override
  String get outletsSubtitle => 'Vos restaurants, leur statut et votre rôle';

  @override
  String get addOutlet => 'Ajouter un point de vente';

  @override
  String get outletAdded =>
      'Point de vente ajouté. Il sera visible après validation par l\'administrateur.';

  @override
  String yourRole(String role) {
    return 'Votre rôle : $role';
  }

  @override
  String get teamSubtitle =>
      'Donnez à votre équipe son propre accès, avec les bons droits';

  @override
  String get addMember => 'Ajouter un membre';

  @override
  String get memberEmail => 'E-mail du compte';

  @override
  String get memberEmailHint =>
      'La personne doit d\'abord créer un compte dans l\'application avec cet e-mail.';

  @override
  String get roleOwnerDesc =>
      'Tout, y compris l\'équipe et la fermeture du compte';

  @override
  String get roleManagerDesc =>
      'Commandes, menu, informations, rapports et factures';

  @override
  String get roleStaffDesc =>
      'Commandes uniquement : accepter, refuser, prête, argent reçu';

  @override
  String get removeMember => 'Retirer';

  @override
  String removeMemberConfirm(String name) {
    return 'Retirer $name de ce point de vente ?';
  }

  @override
  String get memberAdded => 'Membre ajouté';

  @override
  String get errUserNotFound =>
      'Aucun compte avec cet e-mail. Demandez-lui de s\'inscrire d\'abord dans l\'application.';

  @override
  String get errOtherRole =>
      'Ce compte est livreur ou administrateur et ne peut pas rejoindre un restaurant.';

  @override
  String get errAlreadyMember => 'Déjà dans l\'équipe.';

  @override
  String get errLastOwner =>
      'Un point de vente doit garder au moins un propriétaire.';

  @override
  String get onlyOwnersTeam =>
      'Seuls les propriétaires peuvent modifier l\'équipe.';

  @override
  String get colName => 'Nom';

  @override
  String get colEmail => 'E-mail';

  @override
  String get colRole => 'Rôle';

  @override
  String get colSince => 'Depuis';

  @override
  String get portalStaffOnly =>
      'Votre accès employé fonctionne dans l\'application. Demandez à un propriétaire un accès gérant pour utiliser le portail.';

  @override
  String get errOptionsChanged =>
      'Les options de ce plat ont changé. Choisissez-les à nouveau.';

  @override
  String chooseUpTo(int n) {
    return 'Jusqu\'à $n au choix';
  }

  @override
  String get optionRequired => 'Obligatoire';

  @override
  String get outOfStock => 'Épuisé';

  @override
  String opensTodayAt(String time) {
    return 'Fermé · ouvre aujourd\'hui à $time';
  }

  @override
  String opensTomorrowAt(String time) {
    return 'Fermé · ouvre demain à $time';
  }

  @override
  String opensOnAt(String day, String time) {
    return 'Fermé · ouvre $day à $time';
  }

  @override
  String get menuSubtitle => 'Plats, prix, photos et options de vos plats';

  @override
  String get addOptionGroup => 'Ajouter un groupe d\'options';

  @override
  String get editOptionGroup => 'Modifier le groupe d\'options';

  @override
  String get dishesTab => 'Plats';

  @override
  String get optionGroupsTab => 'Groupes d\'options';

  @override
  String get searchDishesHint => 'Rechercher un plat…';

  @override
  String bulkDone(int n) {
    return '$n plats modifiés';
  }

  @override
  String bulkDeleteConfirm(int n) {
    return 'Supprimer $n plats ? Cette action est définitive.';
  }

  @override
  String selectedCount(int n) {
    return '$n sélectionnés';
  }

  @override
  String get bulkShow => 'Rendre disponible';

  @override
  String get bulkHide => 'Masquer';

  @override
  String get bulkPrices => 'Modifier les prix';

  @override
  String get priceIncrease => 'Augmenter';

  @override
  String get priceDecrease => 'Baisser';

  @override
  String get pricesRounded => 'Les nouveaux prix sont arrondis à 10 DA.';

  @override
  String get apply => 'Appliquer';

  @override
  String get uploadDishPhoto => 'Ajouter une photo du plat';

  @override
  String get photosSellHint =>
      'Les plats avec une belle photo se vendent mieux.';

  @override
  String get noOptionGroupsHint =>
      'Créez d\'abord des groupes d\'options (tailles, suppléments) dans l\'onglet Groupes d\'options.';

  @override
  String get optionGroupsPickHint =>
      'Choisissez les options proposées avec ce plat.';

  @override
  String get noOptionGroups =>
      'Aucun groupe d\'options. Créez par exemple « Taille » (Petite, Grande) ou « Suppléments » (Fromage, Œuf).';

  @override
  String get ruleRequiredOne => 'Obligatoire · 1 choix';

  @override
  String ruleRequiredRange(int min, int max) {
    return 'Obligatoire · $min à $max choix';
  }

  @override
  String ruleOptionalUpTo(int max) {
    return 'Facultatif · jusqu\'à $max';
  }

  @override
  String deleteGroupConfirm(String name) {
    return 'Supprimer le groupe « $name » ? Il sera retiré de tous les plats.';
  }

  @override
  String get free => 'Gratuit';

  @override
  String get usedByNoDish => 'Utilisé par aucun plat';

  @override
  String usedBy(String names) {
    return 'Utilisé par : $names';
  }

  @override
  String get groupName => 'Nom du groupe';

  @override
  String get groupNameHint => 'ex. Taille, Sauce, Suppléments';

  @override
  String get requiredHint => 'Le client doit choisir avant de commander';

  @override
  String get minChoices => 'Minimum de choix';

  @override
  String get maxChoices => 'Maximum de choix';

  @override
  String get choices => 'Choix';

  @override
  String get choiceNameHint => 'ex. Grande';

  @override
  String get extraPriceHint => 'Supplément';

  @override
  String get addChoice => 'Ajouter un choix';

  @override
  String get dishesUsingGroup => 'Plats proposant ces options';

  @override
  String get errGroupRule => 'Il faut au moins autant de choix que le minimum.';

  @override
  String get hoursSubtitle => 'Vos horaires, jours fériés et horaires spéciaux';

  @override
  String get weeklyHours => 'Horaires d\'ouverture';

  @override
  String get specialDays => 'Jours fériés et horaires spéciaux';

  @override
  String get openNowLabel => 'Ouvert maintenant';

  @override
  String get closedNowLabel => 'Fermé maintenant';

  @override
  String get switchOffHint => 'Commandes désactivées par l\'interrupteur';

  @override
  String get takingOrders => 'Les clients peuvent commander';

  @override
  String get ordersSwitch => 'Recevoir des commandes';

  @override
  String get weeklyHoursHint =>
      'Les clients ne peuvent commander que pendant ces heures (et quand l\'interrupteur est activé). Sans horaires : ouvert dès que l\'interrupteur est activé.';

  @override
  String get closedAllDay => 'Fermé toute la journée';

  @override
  String get addHours => 'Ajouter des heures';

  @override
  String get copyToAllDays => 'Copier sur tous les jours';

  @override
  String get specialDaysHint =>
      'Jours fériés, Aïd, Ramadan… Ces dates remplacent les horaires habituels.';

  @override
  String get addSpecialDay => 'Ajouter une date';

  @override
  String get noSpecialDays => 'Aucune date à venir';

  @override
  String get pickDate => 'Choisir la date';

  @override
  String get opensLabel => 'Ouvre';

  @override
  String get closesLabel => 'Ferme';

  @override
  String get specialDayNote => 'Note';

  @override
  String get specialDayNoteHint => 'ex. Aïd el-Fitr';

  @override
  String get rateDriverTitle => 'Comment était la livraison ?';

  @override
  String get rateFoodTitle => 'Comment était le repas ?';

  @override
  String get ratingWhatWrong => 'Qu\'est-ce qui n\'allait pas ?';

  @override
  String get ratingCommentHint => 'Ajouter un commentaire (facultatif)';

  @override
  String get ratingSubmit => 'Envoyer ma note';

  @override
  String get ratingLater => 'Plus tard';

  @override
  String get ratingThanks => 'Merci pour votre avis !';

  @override
  String get ratingWord1 => 'Très mauvais';

  @override
  String get ratingWord2 => 'Mauvais';

  @override
  String get ratingWord3 => 'Moyen';

  @override
  String get ratingWord4 => 'Bien';

  @override
  String get ratingWord5 => 'Excellent';

  @override
  String get errRatingClosed =>
      'La période de notation (7 jours) est terminée.';

  @override
  String get errRatingLocked => 'Cette note ne peut plus être modifiée.';

  @override
  String get rateFoodCard => 'Notez le repas';

  @override
  String get rateDriverCard => 'Notez la livraison';

  @override
  String ratingDaysLeft(int n) {
    return 'Encore $n jours pour noter';
  }

  @override
  String get ratingLastDay => 'Dernier jour pour noter';

  @override
  String get yourRating => 'Votre note';

  @override
  String get rateAction => 'Noter';

  @override
  String get editRating => 'Modifier';

  @override
  String get ratingEditHint => 'Modifiable pendant 24 h';

  @override
  String get ratingReplyFrom => 'Réponse du restaurant';

  @override
  String get errAccountBlocked =>
      'Votre compte est suspendu. Contactez le support.';

  @override
  String get rsnCold => 'Plat froid';

  @override
  String get rsnMissingItem => 'Article manquant';

  @override
  String get rsnWrongOrder => 'Mauvaise commande';

  @override
  String get rsnSmallPortion => 'Portion trop petite';

  @override
  String get rsnBadTaste => 'Mauvais goût';

  @override
  String get rsnBadPackaging => 'Emballage abîmé';

  @override
  String get rsnLate => 'En retard';

  @override
  String get rsnRude => 'Impoli';

  @override
  String get rsnCareless => 'Manipulation négligée';

  @override
  String get rsnNoContact => 'Injoignable';

  @override
  String get rsnWrongPlace => 'Mauvaise adresse';

  @override
  String get rsnFakeOrder => 'Fausse commande';

  @override
  String get rsnNoAnswer => 'Ne répond pas';

  @override
  String get rsnWrongAddress => 'Adresse incorrecte';

  @override
  String get rsnRefusedToPay => 'A refusé de payer';

  @override
  String get rsnOther => 'Autre';

  @override
  String get reviewsTitle => 'Avis';

  @override
  String get newRestaurant => 'Nouveau';

  @override
  String get noReviewsYet => 'Pas encore d’avis';

  @override
  String get restaurantReply => 'Réponse du restaurant';

  @override
  String get seeMoreReviews => 'Voir plus d\'avis';

  @override
  String ratingsCount(int n) {
    return '$n notes';
  }

  @override
  String get reviewsSubtitle => 'Ce que disent vos clients de vos plats';

  @override
  String get averageRating => 'Note moyenne';

  @override
  String get ratingDistribution => 'Répartition des notes';

  @override
  String get topComplaints => 'Problèmes les plus cités';

  @override
  String get filterNeedsReply => 'Sans réponse';

  @override
  String starsFilter(int n) {
    return '$n étoiles';
  }

  @override
  String get replyAction => 'Répondre';

  @override
  String get replyDialogHint =>
      'Votre réponse est publique et ne pourra plus être modifiée.';

  @override
  String get replyHint => 'Merci, nous espérons vous revoir…';

  @override
  String get sendReply => 'Publier la réponse';

  @override
  String get replyPublished => 'Réponse publiée';

  @override
  String get flagReview => 'Signaler cet avis';

  @override
  String get flagReviewHint =>
      'Expliquez pourquoi (insulte, ne concerne pas votre cuisine, mauvais restaurant…). L\'administrateur décidera.';

  @override
  String get flagSend => 'Envoyer';

  @override
  String get flagSent => 'Envoyé à l\'administrateur';

  @override
  String get flagWaiting => 'En attente de l\'administrateur';

  @override
  String get flagKept => 'L\'administrateur a conservé cet avis';

  @override
  String get errAlreadyReplied => 'Cet avis a déjà une réponse.';

  @override
  String get errAlreadyFlagged => 'Déjà signalé.';

  @override
  String get noReviewsPeriod => 'Aucun avis sur cette période';

  @override
  String reviewOrderRef(String code) {
    return 'Commande #$code';
  }

  @override
  String get myRating => 'Ma note';

  @override
  String get driverRatingHint => 'Votre moyenne apparaît après 5 notes.';

  @override
  String get driverReasonsTitle => 'Ce que les clients ont signalé';

  @override
  String get reportCustomer => 'Signaler ce client';

  @override
  String get reportCustomerHint =>
      'Seul l\'administrateur voit ce signalement. Le client n\'est pas prévenu.';

  @override
  String get reportNoteHint => 'Détails (facultatif)';

  @override
  String get reportSend => 'Envoyer';

  @override
  String get reportSent => 'Signalement envoyé à l\'administrateur';

  @override
  String get reportedLabel => 'Signalé';

  @override
  String get errAlreadyReported => 'Vous avez déjà signalé cette commande.';

  @override
  String get errTooManyReports => 'Trop de signalements aujourd\'hui.';

  @override
  String get errCustomerGone => 'Ce client n\'a plus de compte.';

  @override
  String get navRatings => 'Avis';

  @override
  String get adminRatingsTitle => 'Avis et signalements';

  @override
  String get tabFlagged => 'Avis signalés';

  @override
  String get tabReports => 'Signalements clients';

  @override
  String get avg30d => '30 derniers jours';

  @override
  String get low30d => 'Notes ≤ 2 (30 j)';

  @override
  String get hideReview => 'Masquer';

  @override
  String get keepReview => 'Conserver';

  @override
  String get decisionHidden => 'Masqué';

  @override
  String get decisionKept => 'Conservé';

  @override
  String get flaggedReason => 'Motif du signalement';

  @override
  String get noFlagged => 'Aucun avis signalé';

  @override
  String get noReports => 'Aucun signalement';

  @override
  String get reportOpen => 'À traiter';

  @override
  String get reportWarned => 'Averti';

  @override
  String get reportBlocked => 'Bloqué';

  @override
  String get reportDismissed => 'Classé';

  @override
  String get actionWarn => 'Avertir';

  @override
  String get actionBlock => 'Bloquer le client';

  @override
  String get actionUnblock => 'Débloquer';

  @override
  String get actionDismiss => 'Classer sans suite';

  @override
  String get adminNoteHint => 'Note interne (facultatif)';

  @override
  String customerReportsCount(int n) {
    return '$n signalements pour ce client';
  }

  @override
  String get reportedByRestaurant => 'Signalé par le restaurant';

  @override
  String get reportedByDriver => 'Signalé par le livreur';

  @override
  String get customerBlockedNote => 'Client bloqué : ne peut plus commander';

  @override
  String get rangeDaysSuffix => 'jours';

  @override
  String get riderReadyTitle => 'Prêt à rouler ?';

  @override
  String get riderReadySub => 'Passez en ligne pour recevoir des courses';

  @override
  String get riderModeTitle => 'Livrer autour de vous';

  @override
  String get riderModeBody =>
      'Récupérez les commandes des restaurants proches et livrez-les. Les frais de livraison sont pour vous.';

  @override
  String get startRiding => 'Commencer';

  @override
  String get doneForToday => 'J\'arrête pour aujourd\'hui';

  @override
  String get statDeliveries => 'Courses';

  @override
  String get statEarnings => 'Gains du jour';

  @override
  String get jobsNearYou => 'Courses autour de vous';

  @override
  String get continueDelivery => 'Continuer la course';

  @override
  String get stepToRestaurant => 'En route vers le restaurant';

  @override
  String get stepReady => 'La commande est prête';

  @override
  String get stepReadySub => 'Vérifiez chaque article avant de partir';

  @override
  String get checkItems => 'Vérifier les articles';

  @override
  String get checkItemsTitle => 'Vérifiez chaque article';

  @override
  String get checkItemsHint =>
      'Touchez chaque article une fois qu’il est dans le sac.';

  @override
  String get headToCustomer => 'Récupérée, en route !';

  @override
  String get stepToCustomer => 'En route vers le client';

  @override
  String get stepArrived => 'Vous êtes arrivé';

  @override
  String collectCash(String amount) {
    return 'Encaissez $amount';
  }

  @override
  String get statDistance => 'Distance';

  @override
  String get statItems => 'Articles';

  @override
  String get statCash => 'À encaisser';

  @override
  String wellDone(String name) {
    return 'Bravo $name !';
  }

  @override
  String deliveryNumber(String code) {
    return 'Livraison #$code';
  }

  @override
  String youEarned(String amount) {
    return '+$amount gagnés';
  }

  @override
  String get readyNextJob => 'Prêt pour la prochaine course ?';

  @override
  String get nextJob => 'Course suivante';

  @override
  String get checkIn => 'Je suis au restaurant';

  @override
  String get atRestaurant => 'Vous êtes au restaurant';

  @override
  String get missingItemCall =>
      'Article manquant ou erroné ? Appelez le restaurant';

  @override
  String get recenterMap => 'Recentrer';

  @override
  String get followRider => 'Suivez votre livreur';

  @override
  String riderUpdatedAt(String time) {
    return 'Position à $time';
  }

  @override
  String riderKmAway(String km) {
    return 'À $km km de chez vous';
  }

  @override
  String get riderEditProfile => 'Modifier mon profil';

  @override
  String get riderEditHint => 'Nom, téléphone, véhicule et photo';

  @override
  String riderSince(String date) {
    return 'Livreur depuis $date';
  }

  @override
  String get levelRookie => 'Débutant';

  @override
  String get levelPro => 'Pro';

  @override
  String get levelExpert => 'Expert';

  @override
  String get levelLegend => 'Légende';

  @override
  String levelLabel(String level) {
    return 'Niveau $level';
  }

  @override
  String levelNext(int n, String level) {
    return 'Encore $n livraisons pour devenir $level';
  }

  @override
  String levelNeedsRating(String stars, String level) {
    return 'Gardez au moins $stars étoiles pour devenir $level';
  }

  @override
  String get levelTop => 'Niveau maximum atteint, bravo !';

  @override
  String get statTotalDeliveries => 'Livraisons';

  @override
  String get statTotalEarned => 'Gagnés';

  @override
  String get statRating => 'Note';

  @override
  String get ratingDetails => 'Voir le détail';

  @override
  String get allTime => 'Depuis le début';

  @override
  String fiveStarStreak(int n) {
    return '$n notes 5 étoiles d’affilée';
  }

  @override
  String get coachTitle => 'Conseils pour progresser';

  @override
  String get coachLate =>
      'Prenez des courses proches de vous et partez dès que la commande est prête.';

  @override
  String get coachRude => 'Un bonjour et un sourire changent tout.';

  @override
  String get coachCareless => 'Gardez le sac à plat et les boissons debout.';

  @override
  String get coachNoContact => 'Appelez le client 2 minutes avant d’arriver.';

  @override
  String get coachWrongPlace =>
      'Vérifiez le point sur la carte et l’étage avant de partir.';

  @override
  String get coachAllGood => 'Aucun problème signalé. Continuez comme ça !';

  @override
  String get ratingPrivateNote =>
      'Les clients notent la livraison en privé : vous voyez les chiffres, jamais qui a noté.';

  @override
  String get sectionPreferences => 'Préférences';

  @override
  String get dangerZone => 'Zone sensible';

  @override
  String get riderDeleteTitle => 'Supprimer mon compte livreur';

  @override
  String get riderDeleteBody =>
      'Votre profil, votre photo et votre note seront supprimés. Les commandes passées restent pour la comptabilité des restaurants, sans votre nom. C’est définitif.';

  @override
  String get riderDeleteCheckNoDelivery => 'Aucune livraison en cours';

  @override
  String get riderDeleteCheckCash => 'Tout l’argent remis aux restaurants';

  @override
  String get riderDeleteConfirm => 'Je comprends, c’est définitif';

  @override
  String get errRiderNameInvalid => 'Entrez votre nom (2 à 60 caractères)';

  @override
  String get errRiderCashPending =>
      'Remettez d’abord l’argent des repas aux restaurants.';

  @override
  String get goToCheckout => 'Passer à la caisse';

  @override
  String get orderSummary => 'Récapitulatif';

  @override
  String get promoCode => 'Code promo';

  @override
  String get promoHint => 'Entrez votre code';

  @override
  String get applyPromo => 'Appliquer';

  @override
  String get removePromo => 'Retirer';

  @override
  String promoApplied(String code) {
    return 'Code $code appliqué';
  }

  @override
  String get discount => 'Réduction';

  @override
  String taxLine(String rate) {
    return 'Taxe ($rate)';
  }

  @override
  String get paymentMethod => 'Mode de paiement';

  @override
  String get payCashHint => 'Payez le livreur à la réception';

  @override
  String get payCard => 'Carte CIB / Edahabia';

  @override
  String get payCcp => 'CCP / BaridiMob';

  @override
  String get comingSoon => 'Bientôt';

  @override
  String placeOrderTotal(String amount) {
    return 'Commander · $amount';
  }

  @override
  String get payOnDeliveryNote => 'Vous ne payez qu’à la livraison.';

  @override
  String youSave(String amount) {
    return 'Vous économisez $amount';
  }

  @override
  String get errPromoInvalid => 'Code invalide';

  @override
  String get errPromoNotHere => 'Ce code n’est pas valable pour ce restaurant';

  @override
  String get errPromoNotStarted => 'Ce code n’est pas encore actif';

  @override
  String get errPromoExpired => 'Ce code a expiré';

  @override
  String get errPromoMinOrder =>
      'Le montant minimum de commande n’est pas atteint';

  @override
  String get errPromoUsedUp => 'Ce code a atteint sa limite';

  @override
  String get errPromoAlreadyUsed => 'Vous avez déjà utilisé ce code';

  @override
  String get errPaymentUnavailable => 'Ce mode de paiement arrive bientôt';

  @override
  String get navPromos => 'Codes promo';

  @override
  String get promoNew => 'Nouveau code';

  @override
  String get promoEdit => 'Modifier le code';

  @override
  String get promoKindPercent => 'Pourcentage';

  @override
  String get promoKindAmount => 'Montant fixe';

  @override
  String get promoValuePercent => 'Réduction (%)';

  @override
  String get promoValueAmount => 'Réduction (DA)';

  @override
  String get promoMaxDiscount => 'Réduction max (DA)';

  @override
  String get promoMinOrder => 'Commande minimum (DA)';

  @override
  String get promoMaxUses => 'Utilisations max (total)';

  @override
  String get promoPerCustomer => 'Max par client';

  @override
  String get promoEnds => 'Expire le';

  @override
  String get promoNoEnd => 'Sans date de fin';

  @override
  String get promoRestaurant => 'Restaurant';

  @override
  String get promoAllRestaurants => 'Tous les restaurants';

  @override
  String get promoFundedBy => 'Payé par';

  @override
  String get fundedPlatform => 'La plateforme';

  @override
  String get fundedRestaurant => 'Le restaurant';

  @override
  String promoUses(int n) {
    return '$n utilisations';
  }

  @override
  String promoGiven(String amount) {
    return '$amount offerts';
  }

  @override
  String get promoActive => 'Actif';

  @override
  String get promoInactive => 'Désactivé';

  @override
  String get promoNote => 'Note interne';

  @override
  String promoMin(String amount) {
    return 'dès $amount';
  }

  @override
  String get errPromoCode => 'Code : 3 à 20 lettres ou chiffres';

  @override
  String get errPromoTaken => 'Ce code existe déjà';

  @override
  String get errPromoValue => 'Vérifiez les valeurs (pourcentage 1 à 90)';

  @override
  String get noPromos => 'Aucun code pour le moment';

  @override
  String get amountDue => 'Montant dû';

  @override
  String get taxCollected => 'Taxe collectée';

  @override
  String get platformDiscounts => 'Réductions payées par la plateforme';

  @override
  String get taxLabel => 'Taxe';

  @override
  String get copy => 'Copier';

  @override
  String get copied => 'Copié';

  @override
  String get qrTitle => 'QR code du restaurant';

  @override
  String get qrHint => 'Affiche à imprimer, scans';

  @override
  String get qrScanToOrder => 'Scannez pour commander';

  @override
  String get qrDownloadPoster => 'Télécharger l’affiche (PDF)';

  @override
  String get qrCopyLink => 'Copier le lien';

  @override
  String get qrStatsTitle => 'Scans de votre QR code';

  @override
  String get qrScans30 => 'Scans (30 jours)';

  @override
  String get qrPeople => 'Personnes';

  @override
  String get qrOrdersAfter => 'Commandes après un scan';

  @override
  String qrScansTotal(int total, int app, int web) {
    return '$total scans au total · $app avec l’app · $web avec l’appareil photo';
  }

  @override
  String get qrTip =>
      'Collez l’affiche sur la vitrine, la caisse et les tables, et mettez-la dans les sacs de livraison. Un scan ouvre directement votre page dans foodfennec.';

  @override
  String get scanTitle => 'Scanner un QR code';

  @override
  String get scanHint => 'Visez le QR code d’un restaurant foodfennec';

  @override
  String get scanNotOurs => 'Ce QR code n’est pas un code foodfennec';

  @override
  String get scanCameraDenied =>
      'Autorisez l’appareil photo dans les réglages pour scanner.';

  @override
  String get scanCameraError => 'Impossible d’ouvrir l’appareil photo.';

  @override
  String get qrLinkSetting => 'Lien des QR codes';

  @override
  String get qrLinkLabel => 'Adresse du site';

  @override
  String get qrLinkHelp =>
      'Les QR codes ouvrent cette adresse + /r/nom-du-restaurant. Réglez votre vrai domaine avant d’imprimer les affiches. Le scanner de l’app fonctionne quel que soit le domaine.';

  @override
  String get errQrLink => 'Adresse invalide (ex. https://foodfennec.com)';

  @override
  String get wilaya => 'Wilaya';

  @override
  String get chooseWilaya => 'Choisissez votre wilaya';

  @override
  String get errWilaya => 'Choisissez votre wilaya';

  @override
  String get commune => 'Commune';

  @override
  String get communeHint => 'Ex. Bab Ezzouar';

  @override
  String get errCommune => 'Indiquez votre commune';

  @override
  String get birthDate => 'Date de naissance';

  @override
  String get chooseDate => 'Choisir une date';

  @override
  String get errBirthDate => 'Date de naissance invalide (13 ans minimum)';

  @override
  String get gender => 'Genre';

  @override
  String get genderMale => 'Homme';

  @override
  String get genderFemale => 'Femme';

  @override
  String get howDidYouHear => 'Comment avez-vous connu foodfennec ?';

  @override
  String get refFriend => 'Un ami';

  @override
  String get refSocial => 'Réseaux sociaux';

  @override
  String get refSearch => 'Recherche Google';

  @override
  String get refRestaurant => 'Un restaurant';

  @override
  String get refAd => 'Publicité';

  @override
  String get refOther => 'Autre';

  @override
  String get completeProfileTitle => 'Complétez votre profil';

  @override
  String get completeProfileBody =>
      '30 secondes pour recevoir des offres qui vous ressemblent.';

  @override
  String get completeProfileAction => 'Compléter';

  @override
  String get completeProfilePrivacy =>
      'Ces informations restent privées : elles nous aident à améliorer foodfennec.';

  @override
  String get later => 'Plus tard';

  @override
  String get thanksProfile => 'Merci ! Profil mis à jour.';

  @override
  String get cancelOrderTitle => 'Annuler la commande ?';

  @override
  String get cancelRequestTitle => 'Demander l’annulation';

  @override
  String get cancelFreeExplain =>
      'Le restaurant n’a pas encore accepté : l’annulation est immédiate et gratuite.';

  @override
  String get cancelRequestExplain =>
      'Le restaurant prépare déjà votre commande. Il recevra votre demande et décidera : si la cuisine a commencé, il peut refuser.';

  @override
  String get cancelWhy => 'Pourquoi ?';

  @override
  String get cancelReasonChangedMind => 'J’ai changé d’avis';

  @override
  String get cancelReasonTooLong => 'C’est trop long';

  @override
  String get cancelReasonWrongAddress => 'Mauvaise adresse';

  @override
  String get cancelReasonWrongItems => 'Erreur dans la commande';

  @override
  String get cancelReasonDuplicate => 'Commande en double';

  @override
  String get cancelReasonOther => 'Autre raison';

  @override
  String get cancelNoteHint => 'Un mot pour le restaurant (facultatif)';

  @override
  String get sendCancelRequest => 'Envoyer la demande';

  @override
  String get cancelRequestSent =>
      'Demande envoyée : le restaurant va répondre.';

  @override
  String get cancelRequestPending =>
      'Demande d’annulation envoyée. Le restaurant va répondre.';

  @override
  String get cancelRequestRefused =>
      'Le restaurant a refusé l’annulation : votre commande est déjà en préparation et continue.';

  @override
  String get cancelRequestExpired =>
      'Trop tard pour annuler : le livreur a déjà récupéré la commande.';

  @override
  String cancelledByYou(String reason) {
    return 'Annulée à votre demande · $reason';
  }

  @override
  String get errCancelAlreadyRequested => 'Vous avez déjà demandé l’annulation';

  @override
  String get errCancelRequestRefused =>
      'Le restaurant a déjà refusé l’annulation';

  @override
  String get customerWantsCancel => 'Le client demande l’annulation';

  @override
  String get cancelRequestOwnerHint =>
      'Acceptez si la cuisine n’a pas commencé.';

  @override
  String get acceptCancel => 'Accepter l’annulation';

  @override
  String get refuseCancel => 'Refuser';

  @override
  String get cancelAcceptedMsg => 'Commande annulée à la demande du client';

  @override
  String get cancelRefusedMsg => 'Annulation refusée : la commande continue';

  @override
  String get accountSuspendedTitle => 'Compte suspendu';

  @override
  String accountSuspendedUntil(String date) {
    return 'Vous pourrez de nouveau utiliser foodfennec le $date.';
  }

  @override
  String get accountBannedTitle => 'Compte bloqué';

  @override
  String get accountBannedBody =>
      'Votre compte a été bloqué. Contactez-nous si vous pensez que c’est une erreur.';

  @override
  String get sanctionReasonTitle => 'Motif';

  @override
  String get contactSupport => 'Contacter le support';

  @override
  String get warningTitle => 'Avertissement';

  @override
  String get warningBody =>
      'Si cela se reproduit, votre compte pourra être suspendu.';

  @override
  String get understood => 'J’ai compris';

  @override
  String get errAccountSuspended => 'Votre compte est suspendu';

  @override
  String get sanctionFakeOrders => 'Fausses commandes';

  @override
  String get sanctionNoShow => 'Absent à la livraison';

  @override
  String get sanctionRefusedToPay => 'Refus de payer';

  @override
  String get sanctionAbuse => 'Comportement irrespectueux';

  @override
  String get sanctionFraud => 'Fraude';

  @override
  String get sanctionTooManyCancellations => 'Trop d’annulations';

  @override
  String get sanctionUnsafeDriving => 'Conduite dangereuse';

  @override
  String get sanctionCashNotReturned => 'Argent non remis au restaurant';

  @override
  String get sanctionOther => 'Non-respect des règles';

  @override
  String get sanctionWarning => 'Avertissement';

  @override
  String get sanctionSuspension => 'Suspension';

  @override
  String get sanctionBan => 'Blocage';

  @override
  String get suspendedPill => 'Suspendu';

  @override
  String get bannedPill => 'Bloqué';

  @override
  String get warnAction => 'Avertir';

  @override
  String get suspendAction => 'Suspendre';

  @override
  String get banAction => 'Bloquer';

  @override
  String get liftAction => 'Lever';

  @override
  String get removeAction => 'Retirer';

  @override
  String get warnTitle => 'Envoyer un avertissement';

  @override
  String get suspendTitle => 'Suspendre le compte';

  @override
  String get banTitle => 'Bloquer le compte';

  @override
  String get warnExplain =>
      'La personne le verra une fois en ouvrant l’app. Elle peut continuer à l’utiliser.';

  @override
  String get suspendExplain =>
      'Plus de commandes (client) ni de livraisons (livreur) jusqu’à la fin.';

  @override
  String get banExplain => 'Bloqué jusqu’à ce que vous leviez le blocage.';

  @override
  String get suspendFor => 'Durée';

  @override
  String daysCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n jours',
      one: '1 jour',
    );
    return '$_temp0';
  }

  @override
  String get messageToUser => 'Message à la personne';

  @override
  String get messageToUserHint =>
      'Ex. Merci de ne commander que si vous êtes disponible.';

  @override
  String get adminNoteLabel => 'Note interne (admin)';

  @override
  String get sanctionHistory => 'Historique';

  @override
  String get noSanctions => 'Aucune sanction';

  @override
  String get sanctionsTitle => 'Sanctions';

  @override
  String get sanctionLifted => 'Sanction levée';

  @override
  String untilDate(String date) {
    return 'jusqu’au $date';
  }

  @override
  String liftedOn(String date) {
    return 'levée le $date';
  }

  @override
  String get seen => 'vu';

  @override
  String get allCustomers => 'Tous';

  @override
  String watchlistTab(int n) {
    return 'À surveiller ($n)';
  }

  @override
  String get watchlistHelp =>
      'Clients ayant annulé (ou demandé à annuler) 3 fois ou plus en 30 jours.';

  @override
  String get watchlistEmpty => 'Personne à surveiller';

  @override
  String cancels30d(int n) {
    return '$n annulations en 30 j';
  }

  @override
  String openReports(int n) {
    return '$n signalements';
  }

  @override
  String get statCustomers => 'Clients';

  @override
  String get statNew7d => 'Nouveaux (7 jours)';

  @override
  String statActive7d(int today) {
    return 'Actifs 7 j · $today aujourd’hui';
  }

  @override
  String get statOrdered => 'Ont déjà commandé';

  @override
  String get statProfileDone => 'Profil complété';

  @override
  String get ageGroups => 'Âge';

  @override
  String get heardFrom => 'Connu via';

  @override
  String get platformLabel => 'Plateforme';

  @override
  String get unknownValue => 'Non renseigné';

  @override
  String get ageLabel => 'Âge';

  @override
  String get memberSince => 'Inscrit le';

  @override
  String get deviceAndActivity => 'Appareil et activité';

  @override
  String get lastSeen => 'Dernière visite';

  @override
  String get activeDays30 => 'Jours actifs (30 j)';

  @override
  String get deviceLabel => 'Appareil';

  @override
  String get ordersTotal => 'Commandes';

  @override
  String get cancels30dLabel => 'Annulations (30 j)';

  @override
  String get spentLabel => 'Dépensé';

  @override
  String get lastOrder => 'Dernière commande';
}
