import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/models/groups/group.dart';
import 'package:hexora/models/invoice/billing_profile.dart';
import 'package:hexora/presentation/screens/home/dashboard_preview/business_profile_card.dart';
import 'package:hexora/services/invoicing/billing_profile_api.dart';
import 'package:hexora/theme/themes/app_theme.dart';
import 'package:image_picker/image_picker.dart';

class _FakeBillingApi extends BillingProfileApi {
  _FakeBillingApi(this.profiles);

  final Map<String, BillingProfile?> profiles;
  final Map<String, Completer<BillingProfile?>> pending = {};
  final upserts = <BillingProfile>[];
  final websites = <String>[];
  final logos = <String>[];
  Completer<void>? saveGate;
  bool failUpsert = false;

  @override
  Future<BillingProfile?> getByGroup(String groupId) {
    final gate = pending[groupId];
    if (gate != null) return gate.future;
    return Future.value(profiles[groupId]);
  }

  @override
  Future<BillingProfile> upsert(BillingProfile profile) async {
    upserts.add(profile);
    await saveGate?.future;
    if (failUpsert) throw Exception('boom');
    // Mirror toPayload(): blank values are stored as null.
    final email = (profile.email ?? '').trim();
    return BillingProfile(
      id: profile.id,
      groupId: profile.groupId,
      legalName: profile.legalName,
      taxId: profile.taxId,
      logoUrl: profile.logoUrl,
      addressStreet: profile.addressStreet,
      addressCity: profile.addressCity,
      addressProvince: profile.addressProvince,
      addressPostalCode: profile.addressPostalCode,
      addressCountry: profile.addressCountry,
      email: email.isEmpty ? null : email,
      website: profile.website,
    );
  }

  @override
  Future<BillingProfile> updateWebsite({
    required String groupId,
    required String website,
  }) async {
    websites.add(website);
    return profiles[groupId]!.copyWith(website: website);
  }

  @override
  Future<BillingProfile> uploadLogo({
    required String groupId,
    required String filename,
    required List<int> bytes,
  }) async {
    logos.add(filename);
    return profiles[groupId]!.copyWith(logoUrl: 'https://cdn/logo.png');
  }
}

Group _group({
  String id = 'g1',
  String name = 'Cabo del Sol',
  String description = 'Mantenimiento de jardines y piscinas',
  String? photoUrl = 'https://cdn/photo.png',
  Map<String, String> roles = const {'u-admin': 'admin', 'u-member': 'member'},
}) =>
    Group(
      id: id,
      name: name,
      ownerId: 'u-owner',
      userRoles: roles,
      userIds: const [],
      createdTime: DateTime(2026),
      description: description,
      photoUrl: photoUrl,
    );

BillingProfile _profile({
  String groupId = 'g1',
  String legalName = 'Cabo del Sol S.L.',
  String taxId = 'B12345678',
  String? street = 'Calle Mayor 1',
  String? logoUrl = 'https://cdn/logo.png',
  String? website = 'https://cabodelsol.es',
  String? email = 'hola@cabodelsol.es',
  bool? isComplete,
}) =>
    BillingProfile(
      id: 'bp-$groupId',
      groupId: groupId,
      legalName: legalName,
      taxId: taxId,
      logoUrl: logoUrl,
      addressStreet: street,
      addressCity: 'Marbella',
      addressProvince: 'Málaga',
      addressPostalCode: '29600',
      addressCountry: 'España',
      website: website,
      email: email,
      isComplete: isComplete,
    );

class _Calls {
  final identity = <String>[];
  final photos = <XFile>[];
  int fiscal = 0;
}

Future<_Calls> _pump(
  WidgetTester tester, {
  required _FakeBillingApi api,
  Group? group,
  String userId = 'u-admin',
  Size size = const Size(1200, 800),
  Brightness brightness = Brightness.light,
  Completer<void>? identityGate,
  Completer<void>? photoGate,
  Future<({String name, List<int> bytes})?> Function(BuildContext)? pickLogo,
  bool settle = true,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  final calls = _Calls();
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.forPlatform(brightness, platform: TargetPlatform.windows),
    home: Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: BusinessProfileCard(
          group: group ?? _group(),
          currentUserId: userId,
          isEs: true,
          billingApi: api,
          onOpenSettings: () {},
          onOpenBillingProfile: () => calls.fiscal++,
          saveIdentity: (g, name, description) async {
            calls.identity.add('$name|$description');
            await identityGate?.future;
          },
          pickPhoto: () async => XFile.fromData(
            Uint8List.fromList([1, 2, 3]),
            name: 'photo.png',
          ),
          uploadPhoto: (g, f) async {
            calls.photos.add(f);
            await photoGate?.future;
          },
          pickInvoiceLogo: pickLogo ??
              (_) async => (name: 'logo.png', bytes: const [1, 2, 3]),
        ),
      ),
    ),
  ));
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
    await tester.pump();
  }
  return calls;
}

Finder _k(String key) => find.byKey(ValueKey(key));

void main() {
  group('evaluateBusinessSetup', () {
    ({BusinessSetupState state, List<BusinessSetupIssue> issues}) eval(
            BillingProfile? p,
            {Group? g}) =>
        evaluateBusinessSetup(
          group: g ?? _group(),
          profile: p,
          profileLoaded: true,
          isEs: true,
        );

    test('complete when legal name, tax id and fiscal address exist', () {
      expect(eval(_profile()).state, BusinessSetupState.complete);
    });

    test('missing invoice logo prevents setup completion', () {
      final r = eval(
        _profile(logoUrl: null, website: null),
        g: _group(photoUrl: null, description: ''),
      );
      expect(r.state, BusinessSetupState.attention);
      expect(r.issues.first.message, 'Añade el logotipo de facturación.');
      expect(r.issues.where((i) => i.critical), hasLength(1));
      expect(r.issues, hasLength(4));
    });

    test('missing fiscal address needs attention', () {
      final r = eval(_profile(street: null));
      expect(r.state, BusinessSetupState.attention);
      expect(r.issues.first.message, 'Falta completar la dirección fiscal.');
    });

    test('no billing profile is incomplete', () {
      expect(eval(null).state, BusinessSetupState.incomplete);
    });

    test('backend isComplete=false is respected', () {
      expect(eval(_profile(isComplete: false)).state,
          BusinessSetupState.attention);
    });

    test('a profile image alone never makes it "complete"', () {
      expect(eval(null, g: _group()).state, isNot(BusinessSetupState.complete));
    });
  });

  testWidgets('view mode: identity, fiscal data, status, no inputs',
      (tester) async {
    await _pump(tester, api: _FakeBillingApi({'g1': _profile()}));
    expect(find.text('Cabo del Sol'), findsOneWidget);
    expect(find.text('Mantenimiento de jardines y piscinas'), findsOneWidget);
    expect(find.text('B12345678'), findsOneWidget);
    expect(find.textContaining('Calle Mayor 1'), findsOneWidget);
    expect(find.text('https://cabodelsol.es'), findsOneWidget);
    expect(find.text('hola@cabodelsol.es'), findsOneWidget);
    expect(find.text('Configuración completa'), findsOneWidget);
    expect(tester.widget<Text>(_k('business-logo-status')).data, 'Configurado');
    expect(find.text('Cambiar'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    expect(_k('business-setup-warning'), findsNothing);
    final height = tester.getSize(_k('business-profile-card')).height;
    // Test glyphs are full em-squares, so real text is narrower and the
    // card shorter; this bounds the compact view mode.
    expect(height, lessThanOrEqualTo(220));
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile loading uses a pulsing skeleton instead of a spinner',
      (tester) async {
    final api = _FakeBillingApi({})
      ..pending['g1'] = Completer<BillingProfile?>();
    await _pump(tester, api: api, settle: false);

    expect(_k('business-profile-loading-skeleton'), findsOneWidget);
    expect(find.text('Comprobando configuración…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    api.pending['g1']!.complete(_profile());
    await tester.pumpAndSettle();
    expect(_k('business-profile-loading-skeleton'), findsNothing);
    expect(find.text('Configuración completa'), findsOneWidget);
  });

  testWidgets('warning shows the most important issue and the rest on demand',
      (tester) async {
    final calls = await _pump(tester,
        api: _FakeBillingApi({'g1': _profile(taxId: '', street: null)}));
    expect(find.text('Requiere atención'), findsOneWidget);
    // The status pill carries the headline; the note names the issue.
    expect(find.text('Falta el NIF/CIF.'), findsOneWidget);
    expect(find.text('Falta completar la dirección fiscal.'), findsNothing);
    await tester.tap(_k('business-setup-more'));
    await tester.pumpAndSettle();
    expect(find.text('Falta completar la dirección fiscal.'), findsOneWidget);
    await tester.tap(_k('business-setup-fix'));
    expect(calls.fiscal, 1);
  });

  testWidgets('read-only members get no editing controls', (tester) async {
    await _pump(tester,
        api: _FakeBillingApi({'g1': _profile()}), userId: 'u-member');
    expect(_k('business-edit'), findsNothing);
    expect(_k('business-logo-change'), findsNothing);
    expect(_k('business-photo-edit'), findsNothing);
    expect(_k('business-edit-fiscal'), findsNothing);
    expect(find.text('Cabo del Sol'), findsOneWidget);
  });

  testWidgets('edit + save name and email through the existing APIs',
      (tester) async {
    final api = _FakeBillingApi({'g1': _profile()});
    final calls = await _pump(tester, api: api);
    await tester.tap(_k('business-edit'));
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNWidgets(4));
    await tester.enterText(_k('business-edit-name'), 'Cabo del Sol Jardines');
    await tester.enterText(_k('business-edit-email'), 'info@cabodelsol.es');
    await tester.pump();
    await tester.tap(_k('business-edit-save'));
    await tester.pumpAndSettle();

    expect(calls.identity,
        ['Cabo del Sol Jardines|Mantenimiento de jardines y piscinas']);
    expect(api.upserts.single.email, 'info@cabodelsol.es');
    expect(api.upserts.single.taxId, 'B12345678',
        reason: 'fiscal fields are carried over unchanged');
    expect(api.websites, isEmpty);
    expect(find.byType(TextFormField), findsNothing, reason: 'back to view');
    expect(find.text('info@cabodelsol.es'), findsOneWidget);
  });

  testWidgets('website-only change uses the website endpoint', (tester) async {
    final api = _FakeBillingApi({'g1': _profile()});
    final calls = await _pump(tester, api: api);
    await tester.tap(_k('business-edit'));
    await tester.pumpAndSettle();
    await tester.enterText(_k('business-edit-website'), 'cabodelsol.com');
    await tester.pump();
    await tester.tap(_k('business-edit-save'));
    await tester.pumpAndSettle();
    expect(api.websites, ['https://cabodelsol.com']);
    expect(api.upserts, isEmpty);
    expect(calls.identity, isEmpty, reason: 'name/description unchanged');
  });

  testWidgets('cancel discards the edit session', (tester) async {
    final calls = await _pump(tester, api: _FakeBillingApi({'g1': _profile()}));
    await tester.tap(_k('business-edit'));
    await tester.pumpAndSettle();
    await tester.enterText(_k('business-edit-name'), 'Otro nombre');
    await tester.tap(_k('business-edit-cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Cabo del Sol'), findsOneWidget);
    await tester.tap(_k('business-edit'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextFormField>(_k('business-edit-name')).controller!.text,
      'Cabo del Sol',
    );
    expect(calls.identity, isEmpty);
  });

  testWidgets('validation blocks empty name and invalid email', (tester) async {
    final api = _FakeBillingApi({'g1': _profile()});
    final calls = await _pump(tester, api: api);
    await tester.tap(_k('business-edit'));
    await tester.pumpAndSettle();
    await tester.enterText(_k('business-edit-name'), '  ');
    await tester.enterText(_k('business-edit-email'), 'no-es-email');
    await tester.pump();
    await tester.tap(_k('business-edit-save'));
    await tester.pumpAndSettle();
    expect(find.text('El nombre es obligatorio'), findsOneWidget);
    expect(find.text('Email no válido'), findsOneWidget);
    expect(calls.identity, isEmpty);
    expect(api.upserts, isEmpty);
  });

  testWidgets('saving shows progress, blocks double submit, reports errors',
      (tester) async {
    final api = _FakeBillingApi({'g1': _profile()})
      ..saveGate = Completer<void>()
      ..failUpsert = true;
    await _pump(tester, api: api);
    await tester.tap(_k('business-edit'));
    await tester.pumpAndSettle();
    await tester.enterText(_k('business-edit-email'), 'nuevo@cabodelsol.es');
    await tester.pump();
    await tester.tap(_k('business-edit-save'));
    await tester.pump();
    expect(tester.widget<FilledButton>(_k('business-edit-save')).onPressed,
        isNull);
    await tester.tap(_k('business-edit-save'), warnIfMissed: false);
    api.saveGate!.complete();
    await tester.pumpAndSettle();
    expect(api.upserts, hasLength(1));
    expect(_k('business-edit-error'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(4),
        reason: 'stays in edit mode with the user input');
  });

  testWidgets('switching business ignores the previous business response',
      (tester) async {
    final api = _FakeBillingApi({
      'g2': _profile(groupId: 'g2', taxId: 'B99999999'),
    })
      ..pending['g1'] = Completer<BillingProfile?>();
    // g1 stays loading (its request is held open), so don't settle.
    await _pump(tester, api: api, settle: false);
    await _pump(tester,
        api: api,
        group: _group(id: 'g2', name: 'Sonoland Inmobiliaria'),
        settle: false);
    // The old business answers late: must not replace the new data.
    api.pending['g1']!.complete(_profile(taxId: 'B12345678'));
    await tester.pumpAndSettle();
    expect(find.text('Sonoland Inmobiliaria'), findsOneWidget);
    expect(find.text('B99999999'), findsOneWidget);
    expect(find.text('B12345678'), findsNothing);
  });

  testWidgets('invoice logo and profile image are managed separately',
      (tester) async {
    final api = _FakeBillingApi({'g1': _profile(logoUrl: null)});
    final calls = await _pump(tester, api: api);
    expect(find.text('Requiere atención'), findsOneWidget);
    expect(
        tester.widget<Text>(_k('business-logo-status')).data, 'Sin configurar');
    await tester.tap(find.text('Añadir'));
    await tester.pumpAndSettle();
    expect(api.logos, ['logo.png']);
    expect(calls.photos, isEmpty, reason: 'logo never touches the photo');
    expect(find.text('Configuración completa'), findsOneWidget);
    expect(tester.widget<Text>(_k('business-logo-status')).data, 'Configurado');

    await tester.tap(_k('business-photo-edit'));
    await tester.pumpAndSettle();
    expect(calls.photos, hasLength(1));
    expect(api.logos, hasLength(1), reason: 'photo never touches the logo');
  });

  testWidgets('photo upload uses the compact animated overlay', (tester) async {
    final photoGate = Completer<void>();
    await _pump(
      tester,
      api: _FakeBillingApi({'g1': _profile()}),
      photoGate: photoGate,
    );

    await tester.tap(_k('business-photo-edit'));
    await tester.pump();
    await tester.pump();
    expect(_k('business-photo-loading'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    photoGate.complete();
    await tester.pumpAndSettle();
    expect(_k('business-photo-loading'), findsNothing);
  });

  testWidgets('desktop: identity | fiscal grid | configuration, in order',
      (tester) async {
    await _pump(tester,
        api: _FakeBillingApi({'g1': _profile()}), size: const Size(1280, 800));
    final name = tester.getRect(find.text('Cabo del Sol'));
    final grid = tester.getRect(_k('business-profile-details'));
    final status = tester.getRect(_k('business-setup-status'));
    expect(name.bottom, lessThanOrEqualTo(grid.top),
        reason: 'the name heads the centre area');
    expect(grid.right, lessThan(status.left));
    // Labels above values instead of a single icon row.
    for (final label in [
      'Nombre fiscal',
      'NIF/CIF',
      'Dirección fiscal',
      'Sitio web',
      'Correo electrónico',
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(tester.getRect(find.text('NIF/CIF')).bottom,
        lessThanOrEqualTo(tester.getRect(find.text('B12345678')).top));
    // Status, logo and actions live together on the right.
    for (final key in [
      'business-logo-thumbnail',
      'business-edit',
      'business-open-settings',
    ]) {
      expect(
          tester.getRect(_k(key)).left, greaterThanOrEqualTo(status.left - 1),
          reason: key);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('legal name is hidden when it equals the commercial name',
      (tester) async {
    await _pump(tester,
        api: _FakeBillingApi({'g1': _profile(legalName: 'CABO DEL SOL')}),
        size: const Size(1280, 800));
    expect(find.text('Nombre fiscal'), findsNothing);
    expect(find.text('NIF/CIF'), findsOneWidget);
  });

  testWidgets(
      'missing optional values read "No indicado", warning is '
      'reserved for required data', (tester) async {
    await _pump(tester,
        api: _FakeBillingApi({'g1': _profile(website: null, email: null)}),
        size: const Size(1280, 800));
    expect(find.text('No indicado'), findsNWidgets(2));
    expect(_k('business-setup-warning'), findsNothing);
    expect(find.text('Configuración completa'), findsOneWidget);
  });

  testWidgets('tablet: configuration moves below the business information',
      (tester) async {
    await _pump(tester,
        api: _FakeBillingApi({'g1': _profile()}), size: const Size(800, 900));
    final grid = tester.getRect(_k('business-profile-details'));
    final status = tester.getRect(_k('business-setup-status'));
    expect(status.top, greaterThanOrEqualTo(grid.bottom));
    expect(tester.takeException(), isNull);
  });

  testWidgets('mobile: one-column fiscal information', (tester) async {
    await _pump(tester,
        api: _FakeBillingApi({'g1': _profile()}), size: const Size(380, 900));
    final nif = tester.getRect(find.text('NIF/CIF'));
    final address = tester.getRect(find.text('Dirección fiscal'));
    expect(address.top, greaterThan(nif.bottom), reason: 'stacked, one column');
    expect(nif.left, address.left);
    expect(tester.takeException(), isNull);
  });

  group('business image', () {
    Rect image(WidgetTester tester) =>
        tester.getRect(_k('business-profile-image'));
    Rect card(WidgetTester tester) =>
        tester.getRect(_k('business-profile-card'));
    double badge(WidgetTester tester) =>
        tester.widget<AnimatedOpacity>(_k('business-photo-badge')).opacity;

    testWidgets('desktop: wide image fills the card height without growing it',
        (tester) async {
      // Pointer platform (see variant): the camera badge appears on hover.
      await _pump(tester,
          api: _FakeBillingApi({'g1': _profile()}),
          size: const Size(1280, 800));
      final img = image(tester);
      final c = card(tester);
      expect(img.width, 210);
      expect(img.width, greaterThan(img.height * .9),
          reason: 'wider-than-tall business image');
      expect(img.height, greaterThanOrEqualTo(150));
      // 12 px internal padding top and bottom: the image spans the content.
      expect(img.top - c.top, closeTo(12, 1.5));
      expect(c.bottom - img.bottom, closeTo(12, 1.5));
      // Text and configuration sit to its right, not on top of it.
      expect(tester.getRect(find.text('Cabo del Sol')).left,
          greaterThan(img.right));
      expect(badge(tester), 0, reason: 'pointer layouts: badge on hover');
      expect(tester.takeException(), isNull);
    }, variant: TargetPlatformVariant.only(TargetPlatform.windows));

    testWidgets('missing image keeps the same area with a fallback',
        (tester) async {
      await _pump(tester,
          api: _FakeBillingApi({'g1': _profile()}),
          group: _group(photoUrl: null),
          size: const Size(1280, 800));
      final img = image(tester);
      expect(img.width, 210);
      expect(img.height, greaterThanOrEqualTo(150));
      expect(_k('business-default-image'), findsOneWidget);
      expect(_k('business-photo-edit'), findsOneWidget,
          reason: 'upload stays available');
    });

    testWidgets('edit mode keeps the image beside the growing form',
        (tester) async {
      await _pump(tester,
          api: _FakeBillingApi({'g1': _profile()}),
          size: const Size(1280, 800));
      final before = card(tester).height;
      await tester.tap(_k('business-edit'));
      await tester.pumpAndSettle();
      expect(card(tester).height, greaterThan(before));
      // 12 px padding + 1 px card border on each side.
      expect(image(tester).height, closeTo(card(tester).height - 26, 1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('mobile: wide image on top, badge always visible',
        (tester) async {
      await _pump(tester,
          api: _FakeBillingApi({'g1': _profile()}), size: const Size(380, 900));
      final img = image(tester);
      final c = card(tester);
      expect(img.width, closeTo(c.width - 26, 1));
      expect(img.height, 150);
      expect(tester.getRect(find.text('Cabo del Sol')).top,
          greaterThan(img.bottom));
      expect(badge(tester), 1, reason: 'no hover on touch');
      expect(tester.takeException(), isNull);
    });
  });

  for (final brightness in Brightness.values) {
    testWidgets('phone layout stacks without overflow ($brightness)',
        (tester) async {
      await _pump(tester,
          api: _FakeBillingApi({'g1': _profile(street: null)}),
          size: const Size(360, 800),
          brightness: brightness);
      expect(find.text('Cabo del Sol'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(_k('business-edit'));
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsNWidgets(4));
      expect(tester.takeException(), isNull);
    });
  }
}
