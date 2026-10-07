<p align="center">
  <img src="documentation/images/logo-esprit.png" alt="ESPRIT" width="320">
</p>

<h1 align="center">MyBudget</h1>

<p align="center"><strong>Gestion des dépenses personnelles</strong><br>5SAE7, ESPRIT School of Engineering</p>

MyBudget is an offline Android application for personal finance. A local profile records income and expenses, organises them by category, sets a spending limit, and shows the situation on a dashboard.

The shared app shell and the SQLite foundation are in place. Feature modules are not implemented yet. Behaviour is defined in the cahier des charges. The build order is defined in the development plan.

## Documentation

| Document | Role |
| --- | --- |
| [Cahier des charges](documentation/CAHIER_DES_CHARGES.md) | Scope, database, architecture, diagrams, and acceptance |
| [Development plan](documentation/DEVELOPMENT_PLAN.md) | Phases, module ownership, Git workflow, tests, and demo |
| [Screen mockups](documentation/MOCKUPS.md) | Phone screens for every feature |

## Stack

- Flutter and Dart
- SQLite through `sqflite`
- Riverpod
- Offline only

The database contains exactly four tables: `users`, `categories`, `transactions`, and `budgets`.

## Team

Four developers. Each developer owns one table and the full module around it: model, data access, business rules, screens, state, and tests.

| Developer | Module |
| --- | --- |
| Developer 1 | Users |
| Developer 2 | Categories |
| Developer 3 | Transactions |
| Developer 4 | Budgets |

Shared setup is done once, before the feature branches. Phase 0 of the development plan is the gate: nobody starts feature code before that sign-off.

## Run the app

Fetch packages, then run on an Android device or emulator:

    flutter pub get
    flutter run

The database file is created on the device. Automated tests use an in-memory database.

## Status

The project shell and the four-table database are ready. Each developer can start their feature module from Phase 3 of the development plan.
