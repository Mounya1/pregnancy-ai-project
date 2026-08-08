import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/shopping.dart';
import '../models/shopping_region.dart';
import '../models/user_profile.dart';
import 'local_storage_service.dart';

/// Region and ticked-off state for the shopping list.
///
/// "Location" here means the region your device is set to, not GPS. The only
/// thing that actually needs to know where you are standing is the maps
/// search, and the maps app already knows - so this app never asks for a
/// location permission at all.
class ShoppingController extends ChangeNotifier {
  ShoppingController(this._storage, {String? deviceCountryCode})
      : _deviceCountryCode =
            deviceCountryCode ?? PlatformDispatcher.instance.locale.countryCode;

  final LocalStorageService _storage;
  final String? _deviceCountryCode;

  ShoppingRegion _region = regionByCode('XX');
  Set<String> _checked = <String>{};
  bool _loaded = false;

  ShoppingRegion get region => _region;
  bool get isLoaded => _loaded;

  /// True when the region came from storage rather than a locale guess, which
  /// is what the UI uses to say "detected" instead of claiming certainty.
  bool _explicit = false;
  bool get regionWasChosen => _explicit;

  bool isChecked(String id) => _checked.contains(id);

  Future<void> load() async {
    final storedCode = await _storage.loadShoppingRegion();
    _explicit = storedCode != null;
    _region = _explicit ? regionByCode(storedCode) : regionForCountry(_deviceCountryCode);
    _checked = (await _storage.loadShoppingChecked()).toSet();
    _loaded = true;
    notifyListeners();
  }

  Future<void> setRegion(ShoppingRegion region) async {
    _region = region;
    _explicit = true;
    notifyListeners();
    await _storage.saveShoppingRegion(region.code);
  }

  Future<void> toggle(String id) async {
    if (!_checked.remove(id)) _checked.add(id);
    notifyListeners();
    await _storage.saveShoppingChecked(_checked.toList());
  }

  Future<void> clearChecked() async {
    _checked = <String>{};
    notifyListeners();
    await _storage.saveShoppingChecked(const []);
  }

  List<ShoppingSection> sectionsFor(UserProfile profile) => shoppingFor(profile, _region);

  int checkedCountIn(List<ShoppingSection> sections) => sections
      .expand((s) => s.items)
      .where((item) => _checked.contains(item.id))
      .length;

  /// Opens the device's maps app on a search near the user.
  ///
  /// Returns false when nothing could handle it - the caller shows a message
  /// rather than leaving a button that appears to do nothing.
  Future<bool> openNearby(String query) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}',
    );
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
