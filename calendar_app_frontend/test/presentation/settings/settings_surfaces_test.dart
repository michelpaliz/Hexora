import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/groups/group.dart';
import 'package:hexora/models/invoice/billing_profile.dart';
import 'package:hexora/models/user/user.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/panels/settings/sections/settings_members_section.dart';
import 'package:hexora/presentation/screens/workspace/sections/enable_banking/widgets/folder_section_card.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/group_invoices/widgets/billing_profile_inline_editor.dart';
import 'package:hexora/presentation/screens/workspace/sections/members/presentation/domain/models/members_ref.dart';
import 'package:hexora/presentation/screens/workspace/sections/members/presentation/domain/models/members_vm.dart';
import 'package:hexora/services/auth/auth_provider.dart';
import 'package:hexora/services/groups/domain/group_domain.dart';
import 'package:hexora/services/groups/invite/repository/invite_repository.dart';
import 'package:hexora/services/invoicing/billing_profile_api.dart';
import 'package:hexora/services/user/repository/i_user_repository.dart';
import 'package:hexora/theme/colors/app_colors.dart';
import 'package:hexora/theme/themes/app_theme.dart';
import 'package:provider/provider.dart';

class _Fake {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeGroupDomain extends _Fake implements GroupDomain {}

class _FakeInvites extends _Fake implements InvitationRepository {}

class _FakeAuth extends _Fake implements AuthProvider {}

class _FakeUsers extends _Fake implements IUserRepository {
  @override
  Future<User> getUserBySelector(String selector) =>
      Future<User>.error(StateError('offline'));
}

final _group = Group(
  id: 'g1',
  name: 'Cabo del Sol',
  ownerId: 'u-owner',
  userRoles: const {'u-owner': 'owner', 'ana': 'admin'},
  userIds: const ['u-owner', 'ana'],
  createdTime: DateTime(2026),
  description: '',
);

class _VM extends MembersVM {
  _VM()
      : super(
          group: _group,
          groupDomain: _FakeGroupDomain(),
          inviteRepo: _FakeInvites(),
          auth: _FakeAuth(),
        );

  @override
  List<MemberRef> get accepted => const [
        MemberRef(
            username: 'ana',
            role: 'admin',
            statusToken: 'Accepted',
            ownerId: 'u-owner'),
        MemberRef(
            username: 'luis',
            role: 'member',
            statusToken: 'Accepted',
            ownerId: 'u-owner'),
      ];

  @override
  List<MemberRef> get pending => const [];

  @override
  List<MemberRef> get notAccepted => const [];
}

Widget _app(Widget child, {Brightness brightness = Brightness.light}) =>
    MaterialApp(
      theme: AppTheme.forPlatform(brightness, platform: TargetPlatform.windows),
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        backgroundColor: AppColors.workspaceCanvas,
        body: child,
      ),
    );

Future<void> _size(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

ColorScheme _cs(WidgetTester tester) =>
    Theme.of(tester.element(find.byType(Scaffold))).colorScheme;

BoxDecoration _deco(WidgetTester tester, Finder finder) =>
    tester.widget<Container>(finder).decoration! as BoxDecoration;

void main() {
  group('Miembros', () {
    Future<void> pumpMembers(WidgetTester tester,
        {Brightness brightness = Brightness.light}) async {
      await _size(tester, const Size(1100, 800));
      await tester.pumpWidget(_app(
        Provider<IUserRepository>.value(
          value: _FakeUsers(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: SettingsMembersSection(
              group: _group,
              membersVM: _VM(),
              isLoading: false,
            ),
          ),
        ),
        brightness: brightness,
      ));
      await tester.pumpAndSettle();
    }

    for (final brightness in Brightness.values) {
      testWidgets(
          'no outer white folder; white list; compact empty detail '
          '($brightness)', (tester) async {
        await pumpMembers(tester, brightness: brightness);
        final cs = _cs(tester);
        expect(find.byType(FolderSectionCard), findsNothing);

        final list = find.byKey(const ValueKey('settings-member-list'));
        expect(_deco(tester, list).color, cs.surface);
        expect(tester.getSize(list).width, 240, reason: 'width unchanged');

        final empty = find.byKey(const ValueKey('settings-member-empty'));
        expect(empty, findsOneWidget);
        expect(find.text('Selecciona un miembro'), findsOneWidget);
        expect(
          find.text('Elige un miembro para consultar sus permisos y detalles.'),
          findsOneWidget,
        );
        expect(
            find.byKey(const ValueKey('settings-member-detail')), findsNothing);
        // The empty state is compact, not a full-height panel.
        expect(tester.getSize(empty).height, lessThan(160));
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('tabs: selected keeps its style, inactive are transparent',
        (tester) async {
      await pumpMembers(tester);
      final cs = _cs(tester);
      Color? chipColor(String label) {
        final chip = find
            .ancestor(
              of: find.text(label),
              matching: find.byType(AnimatedContainer),
            )
            .first;
        return (tester.widget<AnimatedContainer>(chip).decoration!
                as BoxDecoration)
            .color;
      }

      expect(chipColor('Miembros'), cs.primaryContainer);
      expect(chipColor('Pendiente'), Colors.transparent);
      expect(find.text('Guía de permisos'), findsOneWidget);
    });
  });

  group('Perfil de facturación', () {
    Future<void> pumpBilling(WidgetTester tester,
        {Brightness brightness = Brightness.light}) async {
      await _size(tester, const Size(1100, 900));
      await tester.pumpWidget(_app(
        BillingProfileInlineEditor(
          initial: const BillingProfile(
            groupId: 'g1',
            legalName: 'Cabo del Sol S.L.',
            taxId: 'B12345678',
          ),
          groupId: 'g1',
          api: BillingProfileApi(),
          onSaved: (_) {},
          showFolder: false,
        ),
        brightness: brightness,
      ));
      await tester.pumpAndSettle();
    }

    for (final brightness in Brightness.values) {
      testWidgets(
          'form card ends with its content; sticky white save bar '
          '($brightness)', (tester) async {
        await pumpBilling(tester, brightness: brightness);
        final cs = _cs(tester);
        final card = find.byKey(const ValueKey('billing-tab-card')).first;
        final bar = find.byKey(const ValueKey('billing-profile-save-bar'));
        expect(_deco(tester, card).color, cs.surface);
        expect(_deco(tester, card).borderRadius, BorderRadius.circular(12));

        final barDeco = _deco(tester, bar);
        expect(barDeco.color, cs.surface);
        expect((barDeco.border! as Border).top.style, BorderStyle.solid);
        expect(tester.getRect(card).bottom,
            lessThanOrEqualTo(tester.getRect(bar).top));
        expect(find.text('Descartar'), findsOneWidget);
        expect(find.text('Guardar cambios'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('pale-blue inputs and one active tab indicator',
        (tester) async {
      await pumpBilling(tester);
      final cs = _cs(tester);
      final field = tester.widget<TextField>(find.byType(TextField).first);
      final fill = field.decoration!.fillColor!;
      expect(fill, isNot(cs.surface));
      expect(fill.b, greaterThan(fill.r), reason: 'pale-blue tint');

      final tabs = tester
          .widget<TabBar>(find.byKey(const ValueKey('billing-profile-tabs')));
      expect(tabs.labelColor, cs.primary);
      expect(tabs.dividerColor, Colors.transparent);
      expect(tabs.indicator, isA<BoxDecoration>());
    });

    testWidgets('narrow width: save bar wraps instead of overflowing',
        (tester) async {
      await _size(tester, const Size(360, 800));
      await tester.pumpWidget(_app(BillingProfileInlineEditor(
        initial: const BillingProfile(
            groupId: 'g1', legalName: 'Cabo del Sol S.L.', taxId: 'B1'),
        groupId: 'g1',
        api: BillingProfileApi(),
        onSaved: (_) {},
        showFolder: false,
      )));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
