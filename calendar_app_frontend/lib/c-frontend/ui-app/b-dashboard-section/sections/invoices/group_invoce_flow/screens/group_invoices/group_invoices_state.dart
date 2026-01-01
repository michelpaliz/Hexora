import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/invoice/billing_profile.dart';
import 'package:hexora/a-models/invoice/invoice.dart';

class GroupInvoicesState {
  final List<Invoice> invoices;
  final List<Invoice> drafts;
  final BillingProfile? billingProfile;
  final List<GroupClient> clients;

  final GroupClient? selectedClient;
  final Invoice? selectedInvoice;

  final bool loading;
  final String? error;

  final bool busyProfile;
  final String selectedMenu; // 'clients' | 'invoices'
  final bool businessExpanded;
  final bool totalsExpanded;

  const GroupInvoicesState({
    this.invoices = const [],
    this.drafts = const [],
    this.billingProfile,
    this.clients = const [],
    this.selectedClient,
    this.selectedInvoice,
    this.loading = true,
    this.error,
    this.busyProfile = false,
    this.selectedMenu = 'clients',
    this.businessExpanded = false,
    this.totalsExpanded = false,
  });

  GroupInvoicesState copyWith({
    List<Invoice>? invoices,
    List<Invoice>? drafts,
    BillingProfile? billingProfile,
    List<GroupClient>? clients,
    GroupClient? selectedClient,
    Invoice? selectedInvoice,
    bool? loading,
    String? error,
    bool? busyProfile,
    String? selectedMenu,
    bool? businessExpanded,
    bool? totalsExpanded,
  }) {
    return GroupInvoicesState(
      invoices: invoices ?? this.invoices,
      drafts: drafts ?? this.drafts,
      billingProfile: billingProfile ?? this.billingProfile,
      clients: clients ?? this.clients,
      selectedClient: selectedClient ?? this.selectedClient,
      selectedInvoice: selectedInvoice ?? this.selectedInvoice,
      loading: loading ?? this.loading,
      error: error,
      busyProfile: busyProfile ?? this.busyProfile,
      selectedMenu: selectedMenu ?? this.selectedMenu,
      businessExpanded: businessExpanded ?? this.businessExpanded,
      totalsExpanded: totalsExpanded ?? this.totalsExpanded,
    );
  }
}
