---
announcement_key: expense-creation-stepper
status: draft
verification: targeted_widget_tests_passed
release_readiness: unreleased
---

## Español

Título: Pasos más claros para registrar un gasto

El registro manual de gastos incorpora un panel de pasos que se puede expandir o contraer. Muestra el progreso y distingue los pasos actuales, completados y pendientes. La revisión utiliza las mismas comprobaciones que el guardado, y los datos introducidos se conservan al cambiar de paso o contraer el panel.

## English

Title: Clearer steps for recording an expense

Manual expense entry gains an expandable step panel showing progress and distinguishing current, completed and unavailable steps. Review uses the same validation as saving, and entered information is preserved when changing steps or collapsing the panel.

## Internal verification

- Targeted stepper widget tests cover collapsed and expanded layouts, animation overflow, state preservation, unavailable steps, revalidation and mobile menu restrictions.
- Existing compact expense form widget tests pass.
- Production deployment and live upload/save verification are pending.
