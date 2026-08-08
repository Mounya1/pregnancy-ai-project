import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/emergency_contact.dart';
import 'local_storage_service.dart';

/// The emergency contact list, kept sorted so the most urgent number is
/// always first regardless of the order things were added in.
class EmergencyController extends ChangeNotifier {
  EmergencyController(this._storage);

  final LocalStorageService _storage;

  List<EmergencyContact> _contacts = [];
  bool _loaded = false;

  bool get isLoaded => _loaded;
  bool get isEmpty => _loaded && _contacts.isEmpty;

  /// Ambulance, hospital, midwife, doctor, then people - and alphabetical
  /// only as a tiebreak within a kind.
  List<EmergencyContact> get contacts {
    final sorted = [..._contacts]..sort((a, b) {
        final byKind =
            contactKindPriority(a.kind).compareTo(contactKindPriority(b.kind));
        return byKind != 0 ? byKind : a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    return List.unmodifiable(sorted);
  }

  Future<void> load() async {
    _contacts = await _storage.loadEmergencyContacts();
    _loaded = true;
    notifyListeners();
  }

  Future<void> save(EmergencyContact contact) async {
    final index = _contacts.indexWhere((c) => c.id == contact.id);
    if (index >= 0) {
      _contacts[index] = contact;
    } else {
      _contacts.add(contact);
    }
    await _persist();
  }

  Future<void> remove(EmergencyContact contact) async {
    _contacts.removeWhere((c) => c.id == contact.id);
    await _persist();
  }

  /// Opens the dialler with the number filled in, rather than placing the
  /// call. One more tap, but it means a mis-tap in a panic does not silently
  /// ring an ambulance.
  Future<bool> dial(String phone) async {
    // Strip only the characters a dialler cannot use. Digits, +, *, # and
    // pause characters all survive, because extensions matter.
    final cleaned = phone.replaceAll(RegExp(r'[^0-9+*#,;]'), '');
    if (cleaned.isEmpty) return false;

    try {
      return await launchUrl(Uri(scheme: 'tel', path: cleaned));
    } catch (_) {
      return false;
    }
  }

  Future<void> _persist() async {
    notifyListeners();
    await _storage.saveEmergencyContacts(_contacts);
  }
}
