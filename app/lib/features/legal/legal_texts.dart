/// The legal documents shown in the app and on the website (`/legal/<id>`).
///
/// DRAFT written for the founder: have it checked by an Algerian lawyer
/// before launch. When the text changes in a way users must accept again,
/// change [kLegalVersion] (everyone is asked again on the next start).
library;

/// Date of the current version (yyyy-mm-dd), stored with each acceptance.
const kLegalVersion = '2026-11-20';

/// terms, privacy, partner (restaurants), rider (riders).
const legalDocIds = ['terms', 'privacy', 'partner', 'rider'];

/// Documents a role must accept.
List<String> requiredDocs(String role) => switch (role) {
  'restaurant' => const ['terms', 'privacy', 'partner'],
  'driver' => const ['terms', 'privacy', 'rider'],
  'admin' => const [],
  _ => const ['terms', 'privacy'],
};

class LegalDoc {
  const LegalDoc(this.id, this.title, this.intro, this.sections);
  final String id;
  final String title;
  final String intro;
  final List<(String, String)> sections;
}

LegalDoc legalDoc(String id, String lang) {
  final docs = switch (lang) {
    'ar' => _ar,
    'en' => _en,
    _ => _fr,
  };
  return docs[id] ?? docs['terms']!;
}

// ---------------------------------------------------------------- French --
const _fr = {
  'terms': LegalDoc(
    'terms',
    'Conditions générales d’utilisation',
    'En créant un compte ou en utilisant foodfennec, vous acceptez les présentes conditions. Si vous ne les acceptez pas, n’utilisez pas le service.',
    [
      (
        '1. Ce qu’est foodfennec',
        'foodfennec est une plateforme technique qui met en relation des clients, des restaurants partenaires et des livreurs indépendants. foodfennec ne prépare pas les repas, ne les vend pas et n’est pas l’employeur des livreurs. Chaque commande est un contrat entre le client et le restaurant ; la livraison est assurée par un livreur indépendant.',
      ),
      (
        '2. Votre compte',
        'Vous devez avoir au moins 13 ans (et l’accord d’un parent si vous êtes mineur). Les informations que vous donnez doivent être exactes. Vous êtes responsable de votre mot de passe et de tout ce qui est fait avec votre compte. Un compte est personnel : ne le prêtez pas.',
      ),
      (
        '3. Commandes, prix et paiement',
        'Les plats, prix, disponibilités et horaires sont fixés par chaque restaurant. Le total affiché avant de commander comprend les plats, l’éventuelle réduction, la taxe de service et les frais de livraison. Le paiement se fait en espèces à la livraison. Vérifiez votre commande à la réception.',
      ),
      (
        '4. Annulation',
        'Avant que le restaurant accepte, vous pouvez annuler librement. Ensuite, vous pouvez seulement demander l’annulation : le restaurant décide (si la cuisine a commencé, il peut refuser). Une commande récupérée par le livreur ne peut plus être annulée. Les annulations répétées peuvent entraîner une sanction.',
      ),
      (
        '5. Règles de bonne conduite',
        'Il est interdit de : passer de fausses commandes, être absent ou refuser de payer à la livraison, insulter, menacer ou harceler quiconque, frauder (codes promo, faux comptes), publier des avis faux ou injurieux, ou détourner l’application. foodfennec peut avertir, suspendre ou bloquer un compte, avec un motif, en cas de manquement.',
      ),
      (
        '6. Responsabilités',
        'Le restaurant est seul responsable de la préparation, de la qualité, de l’hygiène, de la composition (allergènes compris) et de la conformité de ses plats. Le livreur est seul responsable de sa conduite, du respect du code de la route, de son véhicule et de ses assurances. Chaque utilisateur est responsable de ses propres actes et de ses publications.',
      ),
      (
        '7. Limitation de responsabilité',
        'foodfennec fournit l’application « en l’état » et fait de son mieux pour qu’elle fonctionne. Dans toute la mesure permise par la loi algérienne, foodfennec n’est pas responsable des dommages causés par les actes, fautes ou omissions des restaurants, des livreurs ou des clients, ni des retards, pannes, interruptions, pertes de données ou d’un usage contraire aux présentes conditions. Rien dans ces conditions ne prive le consommateur des droits que la loi lui garantit.',
      ),
      (
        '8. Indemnisation',
        'Si votre comportement ou un usage contraire à ces conditions cause un dommage ou une réclamation contre foodfennec, vous vous engagez à en supporter les conséquences.',
      ),
      (
        '9. Avis et contenus',
        'Vos avis doivent être honnêtes et respectueux. En les publiant, vous autorisez foodfennec à les afficher dans le service. foodfennec peut masquer un contenu illicite, injurieux ou trompeur.',
      ),
      (
        '10. Propriété',
        'La marque foodfennec, le logo et l’application appartiennent à leur exploitant. Les noms, logos et photos des restaurants appartiennent aux restaurants.',
      ),
      (
        '11. Suppression du compte',
        'Vous pouvez supprimer votre compte à tout moment depuis l’application (Compte → Supprimer mon compte), sauf pendant une commande en cours. foodfennec peut fermer un compte qui enfreint ces conditions.',
      ),
      (
        '12. Modifications et droit applicable',
        'Ces conditions peuvent évoluer ; en cas de changement important, l’application vous demandera de les accepter à nouveau. Elles sont soumises au droit algérien. En cas de litige, une solution amiable sera recherchée en premier.',
      ),
    ],
  ),
  'privacy': LegalDoc(
    'privacy',
    'Politique de confidentialité',
    'foodfennec traite vos données personnelles conformément à la loi n° 18-07 du 10 juin 2018 relative à la protection des personnes physiques dans le traitement des données à caractère personnel. En créant un compte, vous consentez aux traitements décrits ici.',
    [
      (
        '1. Données collectées',
        'Compte : nom, e-mail, téléphone, photo (facultative), wilaya et commune. Profil (facultatif) : date de naissance, genre, comment vous avez connu foodfennec. Commandes : plats, montants, adresses et point sur la carte, notes, historique, annulations, avis. Appareil : type de téléphone, système, version de l’application, langue, dates de connexion. Livreurs : position GPS pendant une livraison, photo de livraison. Restaurants : informations de l’établissement et de l’équipe.',
      ),
      (
        '2. Pourquoi',
        'Pour créer et sécuriser votre compte ; transmettre et livrer les commandes ; permettre au client de suivre son livreur ; calculer les montants, commissions et reçus ; envoyer les notifications ; prévenir la fraude et les abus ; améliorer le service grâce à des statistiques (âge, wilaya, utilisation) ; vous proposer des offres adaptées.',
      ),
      (
        '3. Qui voit vos données',
        'Le restaurant de votre commande et le livreur qui la prend voient votre nom, votre téléphone et l’adresse de livraison, uniquement pour cette commande. Le client voit le prénom et le téléphone du livreur pendant la livraison. L’administrateur de foodfennec accède aux données nécessaires à la gestion du service. Vos données ne sont jamais vendues.',
      ),
      (
        '4. Prestataires et hébergement',
        'Les données sont hébergées par nos prestataires techniques (base de données Supabase, notifications Firebase, cartes OpenStreetMap), qui peuvent être situés hors d’Algérie. foodfennec veille à ce que ces transferts respectent la loi applicable.',
      ),
      (
        '5. Autorisations du téléphone',
        'Position : afficher les restaurants proches et votre adresse ; pour les livreurs, obligatoire pour être en ligne, calculer les distances et permettre le suivi de la livraison (uniquement quand l’application est ouverte). Appareil photo : photo de profil, photos des plats, photo de livraison, scan des QR codes. Photos : choisir une image. Notifications : suivi des commandes. Vous pouvez retirer une autorisation à tout moment dans les réglages du téléphone ; certaines fonctions ne marcheront plus.',
      ),
      (
        '6. Durée de conservation',
        'Les données du compte sont conservées tant que le compte existe. La position du livreur n’est gardée que pendant la livraison (10 minutes maximum après le dernier point). Les commandes et reçus sont conservés pour les obligations comptables, sans lien avec votre compte après sa suppression.',
      ),
      (
        '7. Vos droits',
        'Vous pouvez accéder à vos données, les corriger (Compte → Modifier le profil), vous opposer à leur utilisation à des fins d’offres, et supprimer votre compte depuis l’application. Pour toute demande, contactez-nous via Compte → Centre d’aide. Vous pouvez aussi saisir l’Autorité nationale de protection des données à caractère personnel (ANPDP).',
      ),
      (
        '8. Sécurité',
        'Les échanges sont chiffrés (HTTPS) et l’accès aux données est limité par des règles strictes : chacun ne voit que ce qui le concerne. Aucun système n’étant infaillible, gardez votre mot de passe secret.',
      ),
      (
        '9. Mineurs',
        'Le service n’est pas destiné aux enfants de moins de 13 ans.',
      ),
    ],
  ),
  'partner': LegalDoc(
    'partner',
    'Conditions des restaurants partenaires',
    'Ces conditions s’ajoutent aux conditions générales pour tout restaurant inscrit sur foodfennec.',
    [
      (
        '1. Inscription',
        'Le restaurant déclare exercer légalement (registre du commerce, autorisations et règles d’hygiène en vigueur). Le compte reste inactif jusqu’à la validation par foodfennec, qui peut refuser ou désactiver un restaurant.',
      ),
      (
        '2. Plats et informations',
        'Le restaurant est seul responsable de ses plats : qualité, hygiène, fraîcheur, quantités, composition et allergènes, ainsi que de l’exactitude de son menu, de ses prix, photos et horaires. Il met à jour les plats indisponibles.',
      ),
      (
        '3. Commandes',
        'Le restaurant répond rapidement (une commande sans réponse est refusée automatiquement), prépare la commande telle qu’affichée et la remet au livreur bien emballée. Il répond aux demandes d’annulation des clients.',
      ),
      (
        '4. Argent',
        'Le livreur remet au restaurant le montant des plats (après réduction, taxe comprise) ; le restaurant confirme la réception dans l’application. foodfennec émet des relevés de commission ; le montant dû est payé dans les délais indiqués. Les réductions financées par le restaurant sont déduites selon le code promo.',
      ),
      (
        '5. Responsabilité',
        'Le restaurant répond seul des dommages causés par ses plats (intoxication, allergie, erreur de commande) et de ses employés. foodfennec n’est pas responsable de l’activité du restaurant.',
      ),
      (
        '6. Fin',
        'Le restaurant peut fermer son compte depuis l’application après avoir réglé les commandes et montants en cours. foodfennec peut suspendre un restaurant en cas de manquement.',
      ),
    ],
  ),
  'rider': LegalDoc(
    'rider',
    'Conditions des livreurs',
    'Ces conditions s’ajoutent aux conditions générales pour toute personne qui livre avec foodfennec.',
    [
      (
        '1. Statut',
        'Le livreur est un prestataire indépendant, libre de se connecter quand il le souhaite et de choisir ses courses. Il n’est pas salarié de foodfennec. Il garde les frais de livraison des commandes qu’il effectue.',
      ),
      (
        '2. Véhicule, permis et assurance',
        'Le livreur est seul responsable de son véhicule, de son permis, de ses papiers et de ses assurances, ainsi que du respect du code de la route. foodfennec n’est pas responsable des accidents, amendes ou dommages survenus pendant une course.',
      ),
      (
        '3. Localisation',
        'Être en ligne nécessite la localisation du téléphone. Elle sert à afficher la distance des restaurants et, pendant une livraison, à permettre au client et au restaurant de suivre la course. Elle n’est pas suivie hors des livraisons.',
      ),
      (
        '4. Argent liquide',
        'Le livreur encaisse le client et remet au restaurant le montant des plats dans le délai indiqué dans l’application. Un retard bloque la prise de nouvelles courses ; un détournement entraîne la suspension du compte et peut donner lieu à des poursuites.',
      ),
      (
        '5. Comportement',
        'Le livreur est poli, transporte les commandes avec soin, sans les ouvrir, et prend la photo de livraison. Toute fraude, violence ou conduite dangereuse entraîne une sanction.',
      ),
    ],
  ),
};

// --------------------------------------------------------------- English --
const _en = {
  'terms': LegalDoc(
    'terms',
    'Terms of use',
    'By creating an account or using foodfennec, you accept these terms. If you do not accept them, do not use the service.',
    [
      (
        '1. What foodfennec is',
        'foodfennec is a technical platform that connects customers, partner restaurants and independent riders. foodfennec does not prepare or sell the meals and does not employ the riders. Each order is a contract between the customer and the restaurant; delivery is done by an independent rider.',
      ),
      (
        '2. Your account',
        'You must be at least 13 (with a parent’s consent if you are a minor). The information you give must be true. You are responsible for your password and for everything done with your account. An account is personal: do not lend it.',
      ),
      (
        '3. Orders, prices and payment',
        'Dishes, prices, availability and hours are set by each restaurant. The total shown before you order includes the dishes, any discount, the service tax and the delivery fee. You pay in cash on delivery. Check your order when you receive it.',
      ),
      (
        '4. Cancelling',
        'Before the restaurant accepts, you can cancel freely. After that you can only ask to cancel: the restaurant decides (if cooking has started, it can refuse). An order picked up by the rider can no longer be cancelled. Repeated cancellations can lead to a sanction.',
      ),
      (
        '5. Rules of conduct',
        'It is forbidden to place fake orders, be absent or refuse to pay at delivery, insult, threaten or harass anyone, commit fraud (promo codes, fake accounts), post false or abusive reviews, or misuse the app. foodfennec may warn, suspend or block an account, with a reason, when the rules are broken.',
      ),
      (
        '6. Responsibilities',
        'The restaurant alone is responsible for the preparation, quality, hygiene, ingredients (including allergens) and compliance of its dishes. The rider alone is responsible for their driving, traffic rules, vehicle and insurance. Each user is responsible for their own actions and posts.',
      ),
      (
        '7. Limitation of liability',
        'foodfennec provides the app “as is” and does its best to keep it working. To the fullest extent allowed by Algerian law, foodfennec is not liable for damage caused by the acts, faults or omissions of restaurants, riders or customers, nor for delays, outages, interruptions, data loss or use contrary to these terms. Nothing in these terms removes the rights that the law guarantees to consumers.',
      ),
      (
        '8. Indemnity',
        'If your behaviour or a use contrary to these terms causes damage or a claim against foodfennec, you agree to bear the consequences.',
      ),
      (
        '9. Reviews and content',
        'Your reviews must be honest and respectful. By posting them, you allow foodfennec to show them in the service. foodfennec may hide unlawful, abusive or misleading content.',
      ),
      (
        '10. Ownership',
        'The foodfennec brand, logo and app belong to their operator. Restaurant names, logos and photos belong to the restaurants.',
      ),
      (
        '11. Deleting your account',
        'You can delete your account at any time in the app (Account → Delete my account), except during an order in progress. foodfennec may close an account that breaks these terms.',
      ),
      (
        '12. Changes and governing law',
        'These terms may change; after an important change, the app will ask you to accept them again. They are governed by Algerian law. In a dispute, an amicable solution is sought first.',
      ),
    ],
  ),
  'privacy': LegalDoc(
    'privacy',
    'Privacy policy',
    'foodfennec processes your personal data in line with Algerian Law No. 18-07 of 10 June 2018 on the protection of individuals in the processing of personal data. By creating an account, you consent to the processing described here.',
    [
      (
        '1. Data we collect',
        'Account: name, email, phone, photo (optional), wilaya and commune. Profile (optional): date of birth, gender, how you heard about foodfennec. Orders: dishes, amounts, addresses and map point, notes, history, cancellations, reviews. Device: phone model, system, app version, language, sign-in dates. Riders: GPS position during a delivery, delivery photo. Restaurants: business and team details.',
      ),
      (
        '2. Why',
        'To create and secure your account; send and deliver orders; let the customer follow the rider; compute amounts, commissions and receipts; send notifications; prevent fraud and abuse; improve the service with statistics (age, wilaya, usage); offer you relevant deals.',
      ),
      (
        '3. Who sees your data',
        'The restaurant of your order and the rider who takes it see your name, phone and delivery address, only for that order. The customer sees the rider’s first name and phone during the delivery. The foodfennec administrator can access the data needed to run the service. Your data is never sold.',
      ),
      (
        '4. Providers and hosting',
        'Data is hosted by our technical providers (Supabase database, Firebase notifications, OpenStreetMap maps), which may be located outside Algeria. foodfennec makes sure these transfers follow the applicable law.',
      ),
      (
        '5. Phone permissions',
        'Location: show nearby restaurants and your address; for riders, required to go online, compute distances and let customers follow the delivery (only while the app is open). Camera: profile photo, dish photos, delivery photo, QR code scanning. Photos: choose a picture. Notifications: order updates. You can withdraw a permission at any time in the phone settings; some features will stop working.',
      ),
      (
        '6. How long we keep it',
        'Account data is kept as long as the account exists. The rider’s position is kept only during the delivery (at most 10 minutes after the last point). Orders and receipts are kept for accounting obligations, no longer linked to your account once it is deleted.',
      ),
      (
        '7. Your rights',
        'You can access and correct your data (Account → Edit profile), object to its use for offers, and delete your account in the app. For any request, contact us via Account → Help center. You can also contact the national personal data protection authority (ANPDP).',
      ),
      (
        '8. Security',
        'Connections are encrypted (HTTPS) and access to data is limited by strict rules: everyone only sees what concerns them. No system is perfect: keep your password secret.',
      ),
      ('9. Children', 'The service is not meant for children under 13.'),
    ],
  ),
  'partner': LegalDoc(
    'partner',
    'Partner restaurant terms',
    'These terms add to the terms of use for every restaurant registered on foodfennec.',
    [
      (
        '1. Registration',
        'The restaurant declares that it operates legally (trade register, permits and hygiene rules in force). The account stays inactive until foodfennec approves it; foodfennec may refuse or deactivate a restaurant.',
      ),
      (
        '2. Dishes and information',
        'The restaurant alone is responsible for its dishes: quality, hygiene, freshness, quantities, ingredients and allergens, and for the accuracy of its menu, prices, photos and hours. It marks unavailable dishes.',
      ),
      (
        '3. Orders',
        'The restaurant answers quickly (an unanswered order is rejected automatically), prepares the order as shown and hands it to the rider well packed. It answers customers’ cancellation requests.',
      ),
      (
        '4. Money',
        'The rider hands the restaurant the food amount (after discount, tax included); the restaurant confirms receipt in the app. foodfennec issues commission statements; the amount due is paid within the stated time. Discounts paid by the restaurant are deducted according to the promo code.',
      ),
      (
        '5. Liability',
        'The restaurant alone is liable for damage caused by its dishes (food poisoning, allergy, wrong order) and by its staff. foodfennec is not liable for the restaurant’s business.',
      ),
      (
        '6. Ending',
        'The restaurant can close its account in the app once current orders and amounts are settled. foodfennec may suspend a restaurant that breaks these terms.',
      ),
    ],
  ),
  'rider': LegalDoc(
    'rider',
    'Rider terms',
    'These terms add to the terms of use for everyone who delivers with foodfennec.',
    [
      (
        '1. Status',
        'The rider is an independent provider, free to go online when they want and to choose their jobs. They are not employed by foodfennec. They keep the delivery fee of the orders they deliver.',
      ),
      (
        '2. Vehicle, licence and insurance',
        'The rider alone is responsible for their vehicle, licence, papers and insurance, and for following traffic rules. foodfennec is not liable for accidents, fines or damage during a job.',
      ),
      (
        '3. Location',
        'Going online needs the phone’s location. It is used to show how far restaurants are and, during a delivery, to let the customer and the restaurant follow it. It is not tracked outside deliveries.',
      ),
      (
        '4. Cash',
        'The rider collects from the customer and hands the food amount to the restaurant within the time shown in the app. Being late blocks new jobs; keeping the money leads to suspension and may lead to legal action.',
      ),
      (
        '5. Conduct',
        'The rider is polite, carries orders with care without opening them, and takes the delivery photo. Fraud, violence or dangerous driving lead to a sanction.',
      ),
    ],
  ),
};

// ---------------------------------------------------------------- Arabic --
const _ar = {
  'terms': LegalDoc(
    'terms',
    'شروط الاستخدام',
    'بإنشاء حساب أو استخدام foodfennec، فإنك توافق على هذه الشروط. إذا لم توافق عليها، فلا تستخدم الخدمة.',
    [
      (
        '1. ما هو foodfennec',
        'foodfennec منصة تقنية تربط بين الزبائن والمطاعم الشريكة والسائقين المستقلين. لا يحضّر foodfennec الوجبات ولا يبيعها، ولا يُعدّ صاحب عمل للسائقين. كل طلب هو عقد بين الزبون والمطعم، ويتولى التوصيل سائق مستقل.',
      ),
      (
        '2. حسابك',
        'يجب أن يكون عمرك 13 سنة على الأقل (مع موافقة الولي إذا كنت قاصرًا). يجب أن تكون المعلومات التي تقدمها صحيحة. أنت مسؤول عن كلمة المرور وعن كل ما يُفعل بحسابك. الحساب شخصي: لا تعره لغيرك.',
      ),
      (
        '3. الطلبات والأسعار والدفع',
        'يحدد كل مطعم أطباقه وأسعاره وتوفرها وأوقات عمله. يشمل المجموع المعروض قبل الطلب الأطباق والخصم إن وُجد وضريبة الخدمة ورسوم التوصيل. يتم الدفع نقدًا عند الاستلام. تحقق من طلبك عند استلامه.',
      ),
      (
        '4. الإلغاء',
        'قبل أن يقبل المطعم الطلب، يمكنك الإلغاء بحرية. بعد ذلك يمكنك فقط طلب الإلغاء، والمطعم يقرر (يمكنه الرفض إذا بدأ التحضير). لا يمكن إلغاء طلب استلمه السائق. قد يؤدي تكرار الإلغاء إلى عقوبة.',
      ),
      (
        '5. قواعد السلوك',
        'يُمنع تقديم طلبات وهمية، أو الغياب أو رفض الدفع عند التوصيل، أو السب أو التهديد أو التحرش بأي شخص، أو الاحتيال (رموز الخصم، حسابات مزيفة)، أو نشر تقييمات كاذبة أو مسيئة، أو إساءة استخدام التطبيق. يمكن لـ foodfennec تنبيه الحساب أو إيقافه أو حظره مع ذكر السبب عند المخالفة.',
      ),
      (
        '6. المسؤوليات',
        'المطعم وحده مسؤول عن تحضير أطباقه وجودتها ونظافتها ومكوناتها (بما فيها مسببات الحساسية) ومطابقتها. السائق وحده مسؤول عن قيادته واحترام قانون المرور ومركبته وتأمينه. كل مستخدم مسؤول عن أفعاله ومنشوراته.',
      ),
      (
        '7. حدود المسؤولية',
        'يقدم foodfennec التطبيق «كما هو» ويبذل جهده ليعمل جيدًا. في حدود ما يسمح به القانون الجزائري، لا يتحمل foodfennec مسؤولية الأضرار الناتجة عن أفعال أو أخطاء أو تقصير المطاعم أو السائقين أو الزبائن، ولا عن التأخير أو الأعطال أو الانقطاع أو فقدان البيانات أو الاستعمال المخالف لهذه الشروط. لا شيء في هذه الشروط يسلب المستهلك الحقوق التي يضمنها له القانون.',
      ),
      (
        '8. التعويض',
        'إذا تسبب سلوكك أو استعمال مخالف لهذه الشروط في ضرر أو مطالبة ضد foodfennec، فإنك تتحمل العواقب.',
      ),
      (
        '9. التقييمات والمحتوى',
        'يجب أن تكون تقييماتك صادقة ومحترمة. بنشرها تسمح لـ foodfennec بعرضها في الخدمة. يمكن لـ foodfennec إخفاء أي محتوى غير قانوني أو مسيء أو مضلل.',
      ),
      (
        '10. الملكية',
        'علامة foodfennec وشعارها والتطبيق ملك لمشغلها. أسماء المطاعم وشعاراتها وصورها ملك للمطاعم.',
      ),
      (
        '11. حذف الحساب',
        'يمكنك حذف حسابك في أي وقت من التطبيق (الحساب ← حذف حسابي)، إلا أثناء طلب جارٍ. يمكن لـ foodfennec إغلاق حساب يخالف هذه الشروط.',
      ),
      (
        '12. التعديلات والقانون المطبق',
        'قد تتغير هذه الشروط؛ عند تغيير مهم سيطلب منك التطبيق قبولها من جديد. تخضع هذه الشروط للقانون الجزائري، ويُسعى أولًا إلى حل ودي لأي نزاع.',
      ),
    ],
  ),
  'privacy': LegalDoc(
    'privacy',
    'سياسة الخصوصية',
    'يعالج foodfennec بياناتك الشخصية وفقًا للقانون رقم 18-07 المؤرخ في 10 يونيو 2018 المتعلق بحماية الأشخاص الطبيعيين في مجال معالجة المعطيات ذات الطابع الشخصي. بإنشاء حساب، فإنك توافق على المعالجات الموضحة هنا.',
    [
      (
        '1. البيانات التي نجمعها',
        'الحساب: الاسم، البريد الإلكتروني، الهاتف، الصورة (اختيارية)، الولاية والبلدية. الملف (اختياري): تاريخ الميلاد، الجنس، كيف تعرفت على foodfennec. الطلبات: الأطباق، المبالغ، العناوين ونقطة الخريطة، الملاحظات، السجل، الإلغاءات، التقييمات. الجهاز: نوع الهاتف، النظام، إصدار التطبيق، اللغة، أوقات الدخول. السائقون: موقع GPS أثناء التوصيل وصورة التسليم. المطاعم: معلومات المحل والفريق.',
      ),
      (
        '2. لماذا',
        'لإنشاء حسابك وحمايته؛ إرسال الطلبات وتوصيلها؛ تمكين الزبون من متابعة السائق؛ حساب المبالغ والعمولات والإيصالات؛ إرسال الإشعارات؛ منع الاحتيال والتجاوزات؛ تحسين الخدمة بالإحصاءات (العمر، الولاية، الاستخدام)؛ تقديم عروض تناسبك.',
      ),
      (
        '3. من يرى بياناتك',
        'يرى مطعم طلبك والسائق الذي يتولاه اسمك وهاتفك وعنوان التوصيل، لهذا الطلب فقط. يرى الزبون اسم السائق وهاتفه أثناء التوصيل. يطلع مشرف foodfennec على البيانات اللازمة لتسيير الخدمة. لا تُباع بياناتك أبدًا.',
      ),
      (
        '4. مقدمو الخدمات والاستضافة',
        'تُستضاف البيانات لدى مقدمي خدمات تقنية (قاعدة بيانات Supabase، إشعارات Firebase، خرائط OpenStreetMap) قد يكونون خارج الجزائر. يحرص foodfennec على أن تحترم هذه التحويلات القانون المعمول به.',
      ),
      (
        '5. أذونات الهاتف',
        'الموقع: عرض المطاعم القريبة وعنوانك؛ وللسائقين هو إلزامي للاتصال وحساب المسافات وتمكين متابعة التوصيل (فقط والتطبيق مفتوح). الكاميرا: صورة الملف، صور الأطباق، صورة التسليم، مسح رموز QR. الصور: اختيار صورة. الإشعارات: متابعة الطلبات. يمكنك سحب أي إذن في أي وقت من إعدادات الهاتف، وقد تتوقف بعض الوظائف.',
      ),
      (
        '6. مدة الحفظ',
        'تُحفظ بيانات الحساب ما دام الحساب موجودًا. لا يُحفظ موقع السائق إلا أثناء التوصيل (10 دقائق على الأكثر بعد آخر نقطة). تُحفظ الطلبات والإيصالات للالتزامات المحاسبية دون ربطها بحسابك بعد حذفه.',
      ),
      (
        '7. حقوقك',
        'يمكنك الاطلاع على بياناتك وتصحيحها (الحساب ← تعديل الملف)، والاعتراض على استعمالها للعروض، وحذف حسابك من التطبيق. لأي طلب تواصل معنا عبر الحساب ← مركز المساعدة. يمكنك أيضًا اللجوء إلى السلطة الوطنية لحماية المعطيات ذات الطابع الشخصي.',
      ),
      (
        '8. الأمان',
        'الاتصالات مشفرة (HTTPS) والوصول إلى البيانات محدود بقواعد صارمة: كل شخص يرى ما يخصه فقط. لا يوجد نظام مثالي، فاحفظ كلمة المرور سرًا.',
      ),
      ('9. القاصرون', 'الخدمة غير موجهة للأطفال دون 13 سنة.'),
    ],
  ),
  'partner': LegalDoc(
    'partner',
    'شروط المطاعم الشريكة',
    'تضاف هذه الشروط إلى شروط الاستخدام لكل مطعم مسجل في foodfennec.',
    [
      (
        '1. التسجيل',
        'يصرح المطعم بأنه يمارس نشاطه قانونيًا (السجل التجاري، التراخيص وقواعد النظافة السارية). يبقى الحساب غير مفعل حتى يوافق عليه foodfennec، الذي يمكنه رفض مطعم أو إيقافه.',
      ),
      (
        '2. الأطباق والمعلومات',
        'المطعم وحده مسؤول عن أطباقه: الجودة والنظافة والطزاجة والكميات والمكونات ومسببات الحساسية، وعن صحة قائمته وأسعاره وصوره وأوقاته. يحدّث الأطباق غير المتوفرة.',
      ),
      (
        '3. الطلبات',
        'يرد المطعم بسرعة (الطلب الذي لا يُرد عليه يُرفض تلقائيًا)، ويحضّر الطلب كما هو معروض ويسلمه للسائق مغلفًا جيدًا. ويرد على طلبات إلغاء الزبائن.',
      ),
      (
        '4. المال',
        'يسلم السائق للمطعم مبلغ الأطباق (بعد الخصم، شاملًا الضريبة) ويؤكد المطعم الاستلام في التطبيق. يصدر foodfennec كشوف العمولة ويُدفع المبلغ المستحق في الآجال المحددة. تُخصم التخفيضات التي يتحملها المطعم حسب رمز الخصم.',
      ),
      (
        '5. المسؤولية',
        'المطعم وحده مسؤول عن الأضرار الناتجة عن أطباقه (تسمم، حساسية، خطأ في الطلب) وعن عماله. لا يتحمل foodfennec مسؤولية نشاط المطعم.',
      ),
      (
        '6. الإنهاء',
        'يمكن للمطعم إغلاق حسابه من التطبيق بعد تسوية الطلبات والمبالغ الجارية. يمكن لـ foodfennec إيقاف مطعم يخالف هذه الشروط.',
      ),
    ],
  ),
  'rider': LegalDoc(
    'rider',
    'شروط السائقين',
    'تضاف هذه الشروط إلى شروط الاستخدام لكل من يوصّل مع foodfennec.',
    [
      (
        '1. الصفة',
        'السائق مقدم خدمة مستقل، حر في الاتصال متى شاء واختيار التوصيلات. ليس أجيرًا لدى foodfennec، ويحتفظ برسوم توصيل الطلبات التي ينجزها.',
      ),
      (
        '2. المركبة والرخصة والتأمين',
        'السائق وحده مسؤول عن مركبته ورخصته ووثائقه وتأمينه واحترام قانون المرور. لا يتحمل foodfennec مسؤولية الحوادث أو المخالفات أو الأضرار أثناء التوصيل.',
      ),
      (
        '3. الموقع',
        'الاتصال يتطلب موقع الهاتف. يُستعمل لعرض بُعد المطاعم، وأثناء التوصيل لتمكين الزبون والمطعم من متابعته. لا يُتتبع خارج التوصيلات.',
      ),
      (
        '4. النقود',
        'يحصّل السائق المبلغ من الزبون ويسلم مبلغ الأطباق للمطعم في الأجل المبين في التطبيق. التأخير يمنع أخذ توصيلات جديدة، والاحتفاظ بالمال يؤدي إلى إيقاف الحساب وقد يعرّض للمتابعة القضائية.',
      ),
      (
        '5. السلوك',
        'يكون السائق مهذبًا، وينقل الطلبات بعناية دون فتحها، ويلتقط صورة التسليم. الاحتيال أو العنف أو القيادة الخطيرة تؤدي إلى عقوبة.',
      ),
    ],
  ),
};
