import 'package:food_app/features/legal/consent_repository.dart';

/// Everything accepted by default (so other tests aren't stopped by the
/// consent screen); set [acceptedDocs] to test it.
class FakeConsentRepository implements ConsentRepository {
  Set<String>? acceptedDocs = {'terms', 'privacy', 'partner', 'rider'};
  final calls = <String>[];

  @override
  Future<Set<String>?> accepted(String version) async => acceptedDocs;

  @override
  Future<void> accept(List<String> documents, String version) async {
    calls.add('${documents.join(',')}@$version');
    acceptedDocs = {...?acceptedDocs, ...documents};
  }
}
