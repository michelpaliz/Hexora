const _expenseImportHelpMessages = <String, ({String es, String en})>{
  'jsonWorkflow': (
    es: 'Importa gastos desde un JSON: adjunta el JSON, la factura original y revisa los importes antes de guardar.',
    en: 'Import expenses from JSON: attach the JSON, the original invoice and review totals before saving.',
  ),
  'promptAi': (
    es: 'Genera una guia para que la IA devuelva el JSON con el formato esperado por Hexora.',
    en: 'Generate guidance so AI returns JSON in the format Hexora expects.',
  ),
  'jsonPayload': (
    es: 'Pega aqui el JSON del gasto. Si adjuntas un archivo JSON, se cargara automaticamente en este editor.',
    en: 'Paste the expense JSON here. If you attach a JSON file, it will load into this editor automatically.',
  ),
  'advanced': (
    es: 'Usa estas opciones solo si necesitas forzar proveedor, grupo, movimiento bancario o cliente concretos.',
    en: 'Use these options only when you need to force a specific provider, group, bank entry or client.',
  ),
  'expenseType': (
    es: 'Define como se tratara el gasto: estandar, anticipo o liquidacion contra un anticipo existente.',
    en: 'Define how the expense is handled: standard, advance payment or settlement against an existing advance.',
  ),
  'discount': (
    es: 'Aplica un descuento al documento completo. Puedes indicar importe o porcentaje; el otro valor se sincroniza.',
    en: 'Apply a discount to the whole document. Enter either amount or percentage; the other value stays in sync.',
  ),
  'totals': (
    es: 'Activa el resumen si quieres validar el total del documento contra los importes que aparecen en la factura.',
    en: 'Enable the summary when you want to validate document totals against the amounts shown on the invoice.',
  ),
};

String expenseImportHelpText(String key, {required bool isSpanish}) {
  final message = _expenseImportHelpMessages[key];
  if (message == null) return '';
  return isSpanish ? message.es : message.en;
}
