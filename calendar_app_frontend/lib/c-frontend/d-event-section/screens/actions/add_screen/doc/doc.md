

```md
/screens/add_screen/add_event/
│
├── add_event.dart                // 👈 Main StatefulWidget entry point
│   ├─ Initializes logic via `initializeLogic()`
│   ├─ Provides access to providers (User, Group, Notification)
│   └─ Passes `this` to AddEventForm as logic and dialogs
│
├── functions/
│   ├── add_event_logic.dart      // 🔁 Logic Mixin
│   │   ├─ Manages local state (loading, selected users, etc.)
│   │   ├─ Holds form controllers (title, location, etc.)
│   │   ├─ Handles selection UI like date/time pickers, color, repetition
│   │   └─ Interacts with services to add event and update group
│   │
│   └── add_event_dialogs.dart    // 💬 Dialog Mixin
│       ├─ showRepetitionDialog() – Called on duplicate date conflict
│       ├─ showErrorDialog() – General error fallback
│       └─ buildRepetitionDialog() – Shown when user enables repetition
│
├── widgets/
│   ├── form/
│   │   ├── add_event_form.dart   // 📋 Layout of the form
│   │   │   ├─ Accepts logic + dialogs as input
│   │   │   ├─ Renders all input widgets
│   │   │   └─ Binds button/form to logic methods
│   │   │
│   │   ├── title_input_widget.dart
│   │   ├── description_input_widget.dart
│   │   ├── note_input_widget.dart
│   │   ├── location_input_widget.dart
│   │   ├── date_picker_widget.dart
│   │   ├── color_picker_widget.dart
│   │   ├── repetition_toggle_widget.dart
│   │   └── add_event_button_widget.dart
│   │
│   └── dialog/
│       └── user_expandable_card.dart // 👥 User selector (with callback)
```

This structure reflects separation of concerns and improves maintainability. Would you like this exported to a `.md` file for reference?
