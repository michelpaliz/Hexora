---
announcement_key: insights-question-suggestions
status: draft
verification: targeted_tests_and_analysis_passed
release_readiness: unreleased
---

## Español

Título: Preguntas sugeridas y cifras más claras

La pestaña Preguntar incorpora sugerencias sobre ingresos, gastos, facturas pendientes e ingresos por cliente. Puedes editar cada pregunta antes de enviarla. Los importes de las tablas y sus resúmenes respetan el idioma de la interfaz y la moneda indicada.

## English

Title: Suggested questions and clearer amounts

The Ask tab adds suggestions about income, expenses, unpaid invoices and income by client. Each question can be edited before sending. Amounts in structured tables and summaries follow the interface language and the specified currency.

## Internal verification

- Spanish/English suggestion and monetary formatting tests cover negative amounts, zero, currencies and unavailable values.
- A rendered structured-answer table test verifies localized cells and totals. All four targeted tests and static analysis pass.
- Broader chat suites currently report layout-width, empty-state and mobile history/table assertions; these remain outside this change's verified coverage.
- Live assistant answer accuracy and deployment have not been verified.
