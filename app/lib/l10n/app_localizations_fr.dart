// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'Food App';

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
      'Rejoignez Food et recevez des commandes';

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
}
