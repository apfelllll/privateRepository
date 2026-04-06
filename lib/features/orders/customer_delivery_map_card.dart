import 'dart:async';

import 'package:doordesk/features/orders/customer_detail_constants.dart';
import 'package:doordesk/models/customer_draft.dart';
import 'package:doordesk/services/maps/delivery_address_geocode.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_windows/webview_windows.dart';

/// Optional: `flutter run --dart-define=GOOGLE_MAPS_EMBED_API_KEY=…`
/// — Maps Embed API **und** Geocoding API (gleicher Key, beide in Google Cloud aktivieren).
/// Ohne Key: Geocoding per Nominatim (Fallback), Embed weiter `output=embed`.

/// Wie „Karten-Widget“ auf Webseiten: gleiche Logik wie `<iframe src="…">`.
Uri googleMapsEmbedPageUri(String query) {
  const apiKey = String.fromEnvironment('GOOGLE_MAPS_EMBED_API_KEY');
  if (apiKey.isNotEmpty) {
    return Uri.https('www.google.com', '/maps/embed/v1/place', {
      'key': apiKey,
      'q': query,
      'zoom': '18',
      'language': 'de',
    });
  }
  return Uri.https('www.google.com', '/maps', {
    'q': query,
    'output': 'embed',
    'z': '18',
    'hl': 'de',
  });
}

String _escapeHtmlDoubleQuotedAttr(String value) {
  return value
      .replaceAll('&', '&amp;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;')
      .replaceAll('<', '&lt;');
}

String _googleMapsEmbedIframeHtml(String query) {
  final src = googleMapsEmbedPageUri(query).toString();
  final srcAttr = _escapeHtmlDoubleQuotedAttr(src);
  return '''
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
<style>html,body{margin:0;padding:0;height:100%;overflow:hidden;background:#e5e3df}</style>
</head>
<body>
<iframe title="Karte" width="100%" height="100%" style="border:0;display:block"
 src="$srcAttr"
 allowfullscreen loading="lazy" referrerpolicy="no-referrer-when-downgrade"></iframe>
</body>
</html>''';
}

Uri googleMapsSearchUriForQuery(String query) {
  return Uri.parse(
    'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}',
  );
}

Future<void> openGoogleMapsSearch(String query) async {
  final uri = googleMapsSearchUriForQuery(query);
  if (!await canLaunchUrl(uri)) return;
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

bool _mapsWebViewFlutterSupported() {
  if (kIsWeb) return false;
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      return true;
    default:
      return false;
  }
}

bool _mapsWindowsWebViewSupported() {
  return !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;
}

/// Kartenbereich mit Lieferadresse — eingebettet wie auf Webseiten (iframe / Embed API).
class CustomerDeliveryMapCard extends StatefulWidget {
  const CustomerDeliveryMapCard({super.key, required this.customer});

  final CustomerDraft customer;

  @override
  State<CustomerDeliveryMapCard> createState() =>
      _CustomerDeliveryMapCardState();
}

class _CustomerDeliveryMapCardState extends State<CustomerDeliveryMapCard> {
  WebViewController? _controller;

  /// `lat,lng` für exakten Pin oder Adresstext als Fallback (nach Geocodierung).
  String? _embedQuery;

  @override
  void initState() {
    super.initState();
    unawaited(_resolveEmbedQuery());
  }

  Future<void> _resolveEmbedQuery() async {
    final q = widget.customer.mapsDeliveryAddressQuery;
    if (q == null || !mounted) return;

    final point = await geocodeAddressForMapPin(q);
    if (!mounted) return;

    final embed = point != null
        ? formatLatLngForGoogleMaps(point.lat, point.lng)
        : q;

    setState(() => _embedQuery = embed);
    _loadMobileHtml(embed);
  }

  void _loadMobileHtml(String embedQuery) {
    if (!_mapsWebViewFlutterSupported()) return;
    _controller ??= WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000));
    _controller!.loadHtmlString(
      _googleMapsEmbedIframeHtml(embedQuery),
      baseUrl: 'https://www.google.com',
    );
  }

  @override
  void didUpdateWidget(covariant CustomerDeliveryMapCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final q = widget.customer.mapsDeliveryAddressQuery;
    final oldQ = oldWidget.customer.mapsDeliveryAddressQuery;
    if (q == oldQ) return;

    if (q == null) {
      setState(() {
        _embedQuery = null;
        _controller = null;
      });
      return;
    }

    setState(() {
      _embedQuery = null;
      _controller = null;
    });
    unawaited(_resolveEmbedQuery());
  }

  Future<void> _openExternal() async {
    final qHuman = widget.customer.mapsDeliveryAddressQuery;
    if (qHuman == null) return;
    final dest = _embedQuery ?? qHuman;
    await openGoogleMapsSearch(dest);
  }

  Widget _fallbackLaunchTile(String q, ThemeData theme) {
    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(
        alpha: 0.35,
      ),
      child: InkWell(
        onTap: _openExternal,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.map_rounded,
                  size: 44,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  q,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Text(
                  'Tippen — Google Maps öffnen.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final q = widget.customer.mapsDeliveryAddressQuery;
    const height = kCustomerDeliveryMapCardHeight;
    final borderRadius = BorderRadius.circular(22);
    final outline = theme.colorScheme.outlineVariant.withValues(alpha: 0.55);
    final mobile = _mapsWebViewFlutterSupported();
    final windows = _mapsWindowsWebViewSupported();

    if (q != null && _embedQuery == null) {
      return SizedBox(
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            border: Border.all(color: outline),
          ),
          child: Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ),
      );
    }

    if (q == null) {
      return SizedBox(
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.35,
            ),
            borderRadius: borderRadius,
            border: Border.all(color: outline),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Lieferadresse ergänzen, um die Karte anzuzeigen.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      );
    }

    final eq = _embedQuery!;
    final embedUrl = googleMapsEmbedPageUri(eq).toString();

    final Widget mapCore = windows
        ? _WindowsGoogleMapEmbed(
            key: ValueKey(embedUrl),
            embedQuery: eq,
            fallback: _fallbackLaunchTile(q, theme),
          )
        : mobile && _controller != null
            ? WebViewWidget(
                controller: _controller!,
                gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                  Factory<EagerGestureRecognizer>(
                    () => EagerGestureRecognizer(),
                  ),
                },
              )
            : _fallbackLaunchTile(q, theme);

    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          border: Border.all(color: outline),
        ),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: Stack(
            fit: StackFit.expand,
            children: [
              mapCore,
              Positioned(
                top: 6,
                right: 6,
                child: Material(
                  color: theme.colorScheme.surface.withValues(alpha: 0.92),
                  elevation: 1,
                  borderRadius: BorderRadius.circular(12),
                  clipBehavior: Clip.antiAlias,
                  child: IconButton(
                    tooltip: 'In Google Maps öffnen',
                    onPressed: _openExternal,
                    icon: Icon(
                      Icons.open_in_new_rounded,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// WebView2 (Windows): gleiche iframe-Hülle wie mobil — Embed-API darf nicht top-level geladen werden.
class _WindowsGoogleMapEmbed extends StatefulWidget {
  const _WindowsGoogleMapEmbed({
    super.key,
    required this.embedQuery,
    required this.fallback,
  });

  /// Fertiger `q`-Wert fürs Embed (Koordinaten `lat,lng` oder Adresstext).
  final String embedQuery;
  final Widget fallback;

  @override
  State<_WindowsGoogleMapEmbed> createState() => _WindowsGoogleMapEmbedState();
}

class _WindowsGoogleMapEmbedState extends State<_WindowsGoogleMapEmbed> {
  final WebviewController _controller = WebviewController();
  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_init());
  }

  Future<void> _init() async {
    try {
      await _controller.initialize();
      await _controller.setBackgroundColor(Colors.transparent);
      await _controller.setPopupWindowPolicy(WebviewPopupWindowPolicy.deny);
      await _controller.loadStringContent(
        _googleMapsEmbedIframeHtml(widget.embedQuery),
      );
      if (!mounted) return;
      setState(() => _ready = true);
    } catch (e, st) {
      debugPrint('DoorDesk WebView2 (Karte): $e\n$st');
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void didUpdateWidget(covariant _WindowsGoogleMapEmbed oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.embedQuery != widget.embedQuery && _ready) {
      unawaited(
        _controller.loadStringContent(
          _googleMapsEmbedIframeHtml(widget.embedQuery),
        ),
      );
    }
  }

  @override
  void dispose() {
    unawaited(_controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return widget.fallback;
    if (!_ready || !_controller.value.isInitialized) {
      return Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }
    return Webview(_controller);
  }
}
