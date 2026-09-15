import 'package:hexora/presentation/features/dashboard/sections/invoices/group_invoices/expense_upload/expense_import_help_text.dart';
import 'package:test/test.dart';

void main() {
  test('returns the existing Spanish help text for every key', () {
    expect(
      expenseImportHelpText('jsonWorkflow', isSpanish: true),
      'Importa gastos desde un JSON: adjunta el JSON, la factura original y revisa los importes antes de guardar.',
    );
    expect(
      expenseImportHelpText('promptAi', isSpanish: true),
      'Genera una guia para que la IA devuelva el JSON con el formato esperado por Hexora.',
    );
    expect(
      expenseImportHelpText('jsonPayload', isSpanish: true),
      'Pega aqui el JSON del gasto. Si adjuntas un archivo JSON, se cargara automaticamente en este editor.',
    );
    expect(
      expenseImportHelpText('advanced', isSpanish: true),
      'Usa estas opciones solo si necesitas forzar proveedor, grupo, movimiento bancario o cliente concretos.',
    );
    expect(
      expenseImportHelpText('expenseType', isSpanish: true),
      'Define como se tratara el gasto: estandar, anticipo o liquidacion contra un anticipo existente.',
    );
    expect(
      expenseImportHelpText('discount', isSpanish: true),
      'Aplica un descuento al documento completo. Puedes indicar importe o porcentaje; el otro valor se sincroniza.',
    );
    expect(
      expenseImportHelpText('totals', isSpanish: true),
      'Activa el resumen si quieres validar el total del documento contra los importes que aparecen en la factura.',
    );
  });

  test('returns the existing English help text for every key', () {
    expect(
      expenseImportHelpText('jsonWorkflow', isSpanish: false),
      'Import expenses from JSON: attach the JSON, the original invoice and review totals before saving.',
    );
    expect(
      expenseImportHelpText('promptAi', isSpanish: false),
      'Generate guidance so AI returns JSON in the format Hexora expects.',
    );
    expect(
      expenseImportHelpText('jsonPayload', isSpanish: false),
      'Paste the expense JSON here. If you attach a JSON file, it will load into this editor automatically.',
    );
    expect(
      expenseImportHelpText('advanced', isSpanish: false),
      'Use these options only when you need to force a specific provider, group, bank entry or client.',
    );
    expect(
      expenseImportHelpText('expenseType', isSpanish: false),
      'Define how the expense is handled: standard, advance payment or settlement against an existing advance.',
    );
    expect(
      expenseImportHelpText('discount', isSpanish: false),
      'Apply a discount to the whole document. Enter either amount or percentage; the other value stays in sync.',
    );
    expect(
      expenseImportHelpText('totals', isSpanish: false),
      'Enable the summary when you want to validate document totals against the amounts shown on the invoice.',
    );
  });

  test('returns an empty string for unknown keys', () {
    expect(expenseImportHelpText('unknown', isSpanish: true), '');
    expect(expenseImportHelpText('unknown', isSpanish: false), '');
  });
}
