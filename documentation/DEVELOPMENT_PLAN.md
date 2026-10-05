# MyBudget — Development Plan

**Product name:** MyBudget — Gestion des dépenses personnelles  
**Document type:** Step-by-step development roadmap  
**Companion specification:** `CAHIER_DES_CHARGES.md`  
**Team:** 4 developers, one database table each  

This plan explains how the team builds the application after the documentation phase. It contains tasks, order, ownership, and checks. It does not contain application source code.

Product behaviour is defined in the cahier des charges. If the two documents disagree, the cahier des charges wins on behaviour and this plan wins on phase order.

---

## 1. Rules before anyone writes feature code

1. Finish Phase 0 as a team. Feature implementation stays closed until the Phase 0 sign-off is recorded.
2. Finish Phase 1 and Phase 2 on shared chore branches, with every developer reviewing, before any `feature/*` branch is created.
3. After Phase 2, each developer writes code only in their feature folder and the matching test folder, plus the pull request for that module.
4. The database stays at exactly four application tables: `users`, `categories`, `transactions`, `budgets`.
5. Calculated budget and dashboard figures are computed in memory. They are not new columns and not a new table.
6. State management is Riverpod, as decided in the cahier des charges.
7. The application is offline-first. No backend is introduced.

Suggested cadence for a student team (adjust to the real calendar):

| When | Focus |
| --- | --- |
| First working block | Phase 0, Phase 1, Phase 2 together |
| Next two blocks | Phase 3 in parallel |
| Following block | Phase 4 merge, then Phase 5 dashboard |
| Final block | Phase 6, Phase 7, Phase 8, Phase 9 |

---

## 2. Roles during the roadmap

| Role | Person | Writes |
| --- | --- | --- |
| Phase 1 and Phase 2 driver | Developer 1 prepares the commits | Shared project and database foundation |
| Reviewers of shared work | Developers 2, 3, and 4 | Review comments, then approval |
| Users owner | Developer 1 | `lib/features/users/`, user tests, `feature/users` |
| Categories owner | Developer 2 | `lib/features/categories/`, category tests, `feature/categories` |
| Transactions owner | Developer 3 | `lib/features/transactions/`, transaction tests, `feature/transactions` |
| Budgets owner | Developer 4 | `lib/features/budgets/`, budget tests, `feature/budgets` |
| Dashboard | All four, led by Developers 3 and 4 | `lib/features/dashboard/` on `feature/dashboard` in Phase 5 |

Developer 1 driving Phase 1 and Phase 2 does not transfer ownership of categories, transactions, or budgets.

---

## PHASE 0 — Preparation

No developer begins feature implementation during this phase. No Flutter project is created in this phase. The existing repository stays documentation-only until Phase 1.

### 0.1 Validate the cahier des charges

The team reads `CAHIER_DES_CHARGES.md` together and confirms:

- The product is a local profile, not an online account.
- Currency is a label on the profile. History is not converted.
- Predefined categories are rows inserted at profile creation.
- Category delete is restricted while transactions or budgets point at that category.
- Transaction type and category type must match.
- Budgets exist only for expense categories.
- Budget overlap is rejected in domain logic.
- Warning starts at 80% used. Exceeded starts above 100%.
- Dashboard and statistics read existing rows.

Record disagreements as edits to the cahier des charges, reviewed by all four, before continuing.

### 0.2 Validate the database schema

Confirm the four tables, their columns, primary keys, foreign keys, checks, indexes, and delete behaviour in section 8 of the cahier des charges. Confirm that `updated_at` belongs on `users` and that spent, remaining, and percentage are absent from `budgets`.

### 0.3 Validate the architecture

Confirm the `lib/` tree, the data / domain / presentation split, Riverpod, and the rule that widgets do not contain SQL.

### 0.4 Validate responsibilities

Each developer restates their table, their screens, and the contracts they provide or consume (section 10.3 of the cahier des charges). Names to freeze in this meeting:

- `activeUserIdProvider`
- `seedDefaultCategories`
- category picker restricted by type
- `sumExpenses`
- `listRecentTransactions`
- budget progress for a given date

### 0.5 Validate UI navigation

Walk the screen list and the navigation diagram: profile gate, dashboard, transactions, budgets, statistics, categories, profile. Confirm empty states for a new profile, an empty history, and an empty budget list.

### 0.6 Validate the Git strategy

Confirm branch names, protected `main`, pull requests into `develop`, commit style, and the merge order users → categories → transactions → budgets → dashboard.

### 0.7 Create the development backlog

Copy the task checklist at the end of this plan into the team's tracker (issues, board, or a shared note). Each task has one owner. Shared tasks are owned by the Phase 1 / Phase 2 driver until they merge, then they become team-owned.

### 0.8 Phase 0 exit gate

Phase 0 is complete when all four developers agree, in writing in the team channel or a short meeting note, that sections 0.1 through 0.7 are accepted.

**Until that agreement exists, nobody starts Phase 1 feature work, and nobody starts Phase 3.**

---

## PHASE 1 — Project initialization

Branch: `chore/project-setup`, created from `develop` after `develop` exists. Target of the pull request: `develop`. Reviewers: Developers 2, 3, and 4. Driver: Developer 1.

Do this phase as one shared pull request. Feature folders stay empty apart from a placeholder file only if the tooling requires the directory to exist. No feature behaviour is implemented here.

### 1. Create the Flutter project

Create the Flutter application in the existing repository root so the Git history and the two specification files remain. The application name used in Flutter is `mybudget`. The Android target is the one the team will demonstrate.

Outcome: the project builds and shows the default Flutter start screen.

### 2. Configure Dart and Flutter

Pin a current stable Flutter SDK that the whole team installs. Enable the standard analyser with the recommended lint set so all four developers see the same warnings. Agree the minimum Android version the course environment supports and record it in the README during Phase 8 (a stub README update in this phase is enough to say how to fetch dependencies and run the app).

### 3. Configure Git

- Keep the specification files.
- Ignore Flutter build outputs, IDE files, and the local database file if one appears during later tests.
- Create `develop` from the default branch if it does not exist yet.
- Treat `main` as protected: no direct commits, updates only from `develop` at the end.
- Agree the commit prefixes: `feat`, `fix`, `test`, `docs`, `chore`.

### 4. Create branches

In this phase, create only:

```text
main
develop
chore/project-setup
```

Do not create `feature/users`, `feature/categories`, `feature/transactions`, or `feature/budgets` yet. Those branches start after Phase 2 is on `develop`.

### 5. Configure the project structure

Create the directories described in the cahier des charges:

```text
lib/core/database
lib/core/constants
lib/core/errors
lib/core/utils
lib/core/theme
lib/features/users/data
lib/features/users/domain
lib/features/users/presentation
lib/features/categories/data
lib/features/categories/domain
lib/features/categories/presentation
lib/features/transactions/data
lib/features/transactions/domain
lib/features/transactions/presentation
lib/features/budgets/data
lib/features/budgets/domain
lib/features/budgets/presentation
lib/shared/widgets
lib/shared/models
```

Leave `features/dashboard` for Phase 5 so the parallel phase does not invite a fifth module too early. Add the matching `test/` folders for core and the four features.

### 6. Add the required dependencies

Add only:

- `flutter_riverpod`
- `sqflite`
- `path`
- `path_provider`
- `intl`

Dev dependencies stay with the Flutter SDK test packages already present (`flutter_test`, and `integration_test` when the team reaches Phase 6). Any extra package needs a team decision in a chore pull request.

### 7. Configure SQLite

Add the platform configuration `sqflite` needs for Android. Do not create tables in this step. Table creation is Phase 2. Confirm the app still builds.

### 8. Configure state management

Wrap the root widget in Riverpod's `ProviderScope` from `main.dart`. Add no feature providers yet. Document in a short comment at the root that feature providers are owned inside each feature's presentation folder.

### 9. Configure routing

Add a navigation shell with the four destinations Dashboard, Transactions, Budgets, and More. Destinations may show a shared empty placeholder. Register route names the feature owners will fill:

- profile gate
- profile
- categories and category form
- transactions and transaction form
- budgets and budget form
- dashboard
- statistics

The shell reads `activeUserIdProvider` later. In Phase 1 the provider does not exist yet, so the shell can open the placeholder home. Developer 1 replaces the gate behaviour on `feature/users`.

### 10. Configure the theme

Define colours, text styles, spacing, input decoration, and three status colours for budget state: normal, warning, exceeded. Feature screens must use this theme.

### 11. Create shared components

Phase 1 also delivers the first shared widgets and types, still inside the same chore pull request:

| Component | Purpose |
| --- | --- |
| Empty state | Title plus one sentence, used by every list |
| Error view | Shared message area for a failed load |
| Confirm dialog | Destructive confirmation for deletes |
| Amount text | Formats a number with the active currency scale |
| Loading indicator | One progress indicator for lists and forms |
| Failure types | Validation, conflict, not found, restrict, database |
| Date and money helpers | ISO dates, month bounds, decimal scale per currency, inclusive date overlap |

### Phase 1 exit gate

- The chore pull request is approved by the other three developers and merged into `develop`.
- The application builds.
- Feature folders contain no business behaviour.
- `main` is unchanged apart from whatever the team uses as the repository default until the final promotion.

---

## PHASE 2 — Database foundation

Branch: `chore/database-foundation`, created from `develop` after Phase 1 has merged. Driver: Developer 1. Reviewers: Developers 2, 3, and 4. This phase creates the schema and the shared helper. It does not implement feature repositories or screens.

### 1. Define the database schema

Translate section 8 of the cahier des charges into the database creation statements held by `core/database`. Include:

- the four tables and only those four
- primary keys
- foreign keys with the cascade and restrict actions from the specification
- checks for type, period, positive amounts, and `end_date >= start_date`
- unique email
- unique `(user_id, name, type)` on categories
- the indexes named in the specification

### 2. Create the database helper

One helper opens `mybudget.db` through `path_provider`, exposes a single shared database instance, and is the only place that calls the SQLite open API.

### 3. Configure the database version

Set the schema version to `1`. Store the version in the helper. Document that version `2` and later require a team migration pull request.

### 4. Create the migration strategy

On create, run the version 1 script. On upgrade, run incremental steps from the old version to the new version inside one migration path. Phase 2 ships the version 1 path only. The upgrade function exists so later changes have a place to go, and it performs no extra work while the stored version is already 1.

### 5. Enable foreign keys

Every time the database is opened, run the SQLite pragma that turns foreign keys on. Add a test that proves a child row cannot reference a missing user.

### 6. Define constraints

Keep the checks and unique constraints in the database as well as in the future domain validators. The domain layer is what the forms call. The database is the backstop.

### 7. Test database initialization

Add a core test that opens a temporary database, initialises it, and closes it. The test must not touch the developer's real application database.

### 8. Verify all four tables

The same test reads the SQLite catalogue of application tables and expects exactly:

```text
users
categories
transactions
budgets
```

Fail the test if a fifth application table appears, or if one of the four is missing. SQLite's own internal catalogue entries are ignored by filtering to application tables.

### 9. Verify relationships

Add tests that:

- inserting a category for a missing user fails
- inserting a transaction for a missing category fails
- inserting a budget for a missing category fails
- deleting a user removes that user's categories, transactions, and budgets
- deleting a category that still has a transaction fails
- deleting a category that still has a budget fails
- deleting a transaction leaves the category and the budget in place
- deleting a budget leaves transactions in place

### 10. Verify CRUD infrastructure

The helper must allow a caller to insert, query, update, and delete. Phase 2 proves this with a small core test that inserts one user row and reads it back, then deletes it. Feature repositories are not written in this phase. That user insert in the test is fixture data inside the test, not the profile feature.

### Phase 2 exit gate

- The pull request is approved by Developers 2, 3, and 4 and merged into `develop`.
- Schema tests pass, including the exact-four-tables assertion.
- Foreign keys are proven on.
- Only then does each developer create their feature branch from `develop`.

---

## PHASE 3 — Parallel development

Create these branches from the `develop` commit that contains Phase 2:

```text
feature/users          Developer 1
feature/categories     Developer 2
feature/transactions   Developer 3
feature/budgets        Developer 4
```

Work at the same time. Merge `develop` into the feature branch at least once a day. Do not edit another developer's feature folder. Do not change `lib/core/database` on a feature branch. If a shared helper is missing, stop and open a small `chore/` pull request reviewed by the team.

Each workstream ends with a pull request into `develop`. The author runs their module tests first. Another developer reviews. The author does not merge their own pull request. Merge order is defined in Phase 4: a branch may be ready early and still wait until its dependencies are on `develop`.

Contracts may be stubbed locally so coding can proceed. Examples: Developer 1 calls `seedDefaultCategories` through a function Developer 2 publishes; until that function is on `develop`, Developer 1 depends on the agreed name and completes the real call before the users pull request merges if categories have already merged, or documents the follow-up commit on `feature/users` immediately after categories merge. The users pull request must contain the real seed call before it is accepted if `feature/categories` is already on `develop`. If categories land second, Developer 1 adds the seed call in a follow-up commit on `feature/users` before that pull request merges, or in a `fix` pull request the same day if users already merged. The team picks one of those two and writes it on the pull request. The seed must exist before the demonstration.

### DEV 1 — USERS

Owner: Developer 1. Branch: `feature/users`. Read sections 6.1, 8.2, 8.7, 8.8, 8.9, and 10 of the cahier des charges before coding.

Tasks, in order:

1. Create the user domain model with `id`, `name`, `email`, `currency`, `createdAt`, and `updatedAt`.
2. Implement profile validation: trimmed name length, email shape, lowercase email storage, and the five currency codes. Default proposal is `TND`.
3. Define the user repository contract: create, update, delete, get by id, list.
4. Implement the SQLite mapping and the repository with the shared database helper.
5. Implement create. Set `created_at` and `updated_at` from the shared clock helper.
6. Implement read of one profile and of every profile, ordered by name.
7. Implement update of name, email, and currency. Refresh `updated_at`. Leave existing amounts untouched when currency changes.
8. Implement delete of one profile and rely on database cascade for the other tables.
9. Add `activeUserIdProvider` held in memory for the session. On launch, if exactly one profile exists, select it. If several exist, open the profile gate. If none exist, open creation.
10. Persist nothing extra for the active profile. There is no settings table. A simple last-selected id may be kept only if it is stored in a column that already exists. It is not. Keep the active id in Riverpod state, and on cold start apply the rule in task 9.
11. Build the profile gate screen: create form, and list of existing profiles when any exist.
12. Build the profile screen: name, email, currency, creation date, actions to edit, switch, and delete.
13. Build the edit screen with the same validation as create.
14. Add the currency selector limited to `TND`, `EUR`, `USD`, `GBP`, and `MAD`.
15. Add the destructive confirm dialog before delete, naming the profile.
16. After a successful create, call `seedDefaultCategories` for the new id.
17. Map validation, conflict (duplicate email), and database failures to the shared error types and show them on the form.
18. Write unit tests for validation, including duplicate-shape emails that differ only by case, empty name, and unknown currency.
19. Write repository tests: insert, unique email, update, delete, and cascade removal of a category, a transaction, and a budget that belonged to that user.
20. Write widget tests for the create form and the delete confirmation.
21. Open the pull request into `develop` with the requirements covered and the tests run.
22. Respond to review and merge only through a reviewer.

Definition of done: FR-USR-01 through FR-USR-10 behave as specified on the feature branch, the user tests pass, and the pull request is approved.

### DEV 2 — CATEGORIES

Owner: Developer 2. Branch: `feature/categories`. Read sections 6.2, 8.3, 8.7, 8.8, and 8.9 before coding.

Tasks, in order:

1. Create the category domain model and the type values `EXPENSE` and `INCOME`.
2. Read icon keys and predefined category definitions from `core/constants`. Do not copy a second list into the feature.
3. Implement validation: trimmed name length 1–40, type, icon key, and case-insensitive uniqueness for the same user and type.
4. Define the repository contract: create, update, delete, list by user, get by id, seed defaults, reassign.
5. Implement SQLite mapping and CRUD through the shared helper.
6. Implement `seedDefaultCategories(userId)` inserting the 13 predefined rows from the cahier des charges.
7. Implement list and type filter for the active profile from `activeUserIdProvider`.
8. Implement update of name and icon.
9. Refuse a type change when any transaction or budget references the category. Allow the type change when nothing references it.
10. Implement delete. When the database restrict rule fails, return the shared restrict error.
11. Implement reassignment: move transactions and budgets from the source category to a target category of the same user and the same type, then allow delete. Reject a target of a different type or a different user.
12. Build the category management screen, grouped or filtered by type, including predefined and custom rows together.
13. Build the category form with name, type, and icon selection from the catalogue.
14. Publish the category picker widget that other modules can open, with an optional type restriction.
15. Map duplicate name, restrict delete, and validation errors onto the screens.
16. Write unit tests for normalisation, icon rejection, and type-change refusal.
17. Write repository tests for seed, uniqueness, delete of an unused category, restrict when a transaction exists, restrict when a budget exists, and successful reassignment.
18. Write widget tests for the form and for a blocked delete.
19. Open the pull request. It merges after `feature/users` is on `develop`, because categories need a real user id in the integrated app. Coding does not wait for that merge.
20. Respond to review. Developer 3 and Developer 4 should review the picker contract.

Definition of done: FR-CAT-01 through FR-CAT-10, tests passing, picker usable by the other features, pull request approved.

### DEV 3 — TRANSACTIONS

Owner: Developer 3. Branch: `feature/transactions`. Read sections 6.3, 8.1, 8.4, 8.8, 8.9, and 12 before coding.

Tasks, in order:

1. Create the transaction domain model. Keep the name distinct from a database transaction in code reviews and class names, as in the class diagram (`TransactionRecord` or an equivalent clear name).
2. Define a query object for search text, type, category id, inclusive date range, sort field, and sort direction.
3. Implement validation: amount greater than zero, decimal scale from the active currency, type, optional description length, valid date, category present, category owned by the active user, category type equal to transaction type.
4. Define the repository contract: create, update, delete, get, search, sum by type and range, sum of expenses for a category and range, list recent.
5. Implement insert and update. Do not change `user_id` or `created_at` on update.
6. Implement delete of a single transaction without deleting the category or the budget.
7. Implement history listing for the active user, default order transaction date descending then creation time descending.
8. Implement search on description, case-insensitive substring.
9. Implement filters for type, category, and date range, combined together.
10. Implement sort by date, amount, and category name, both directions.
11. Implement `sumExpenses`, monthly and all-time sums, and `listRecentTransactions` exactly as the contracts named in Phase 0. These reads are what budgets and the dashboard will call.
12. Build the history screen with search, filter, and sort controls.
13. Build the create and edit form for income and expense, using the category picker restricted to the chosen type.
14. Build delete with the shared confirm dialog.
15. Map validation and foreign-key failures onto the form.
16. Write unit tests for amount scale (`TND` versus `EUR`), empty description stored as absent, future dates allowed, and type mismatch rejected.
17. Write repository tests for CRUD, user/category alignment, combined filters, sort, sums, and recent list.
18. Write widget tests for the form and for an empty history.
19. Open the pull request. Merge it only after users and categories are on `develop`.
20. Respond to review. Developer 4 reviews the `sumExpenses` contract.

Definition of done: FR-TXN-01 through FR-TXN-10, the read contracts used by budgets, tests passing, pull request approved.

### DEV 4 — BUDGETS

Owner: Developer 4. Branch: `feature/budgets`. Read sections 6.4, 8.5, 8.9, and 12 before coding.

Tasks, in order:

1. Create the budget domain model and the period values `MONTHLY` and `CUSTOM`.
2. Create a progress type with spent, remaining, percentage used, and state. This type is not a table and is not persisted.
3. Implement a pure calculator:
   - `remaining = amount_limit - spent`
   - `percentage_used = spent / amount_limit * 100`
   - normal below 80, warning from 80 through 100, exceeded above 100
4. Implement validation: expense category of the active user, positive limit, decimal scale, period, `end_date >= start_date`, monthly range equal to one calendar month, no inclusive overlap with another budget of the same user and category.
5. Use the shared month-bounds and overlap helpers. Do not reimplement date arithmetic in the feature.
6. Define the repository contract: create, update, delete, list by user, list covering a date.
7. Implement CRUD. Do not add columns for spent, remaining, or percentage.
8. On create and update, load existing budgets for that user and category and reject overlap before writing.
9. After a successful read, call `sumExpenses` for each budget's category and date range, then run the calculator. Income transactions must not affect the sum, which is already guaranteed if `sumExpenses` counts only `EXPENSE`.
10. Build the budget list showing limit, spent, remaining, percentage, and state colour from the theme.
11. Build the form: expense category picker, limit, monthly month picker, and custom date range.
12. Implement edit with the same overlap rule, ignoring the budget being edited when checking overlap with itself.
13. Implement delete with confirmation. Transactions remain.
14. Map overlap and income-category errors onto the form.
15. Write unit tests for the calculator at 0%, 79%, 80%, 100%, and above 100%, including a negative remaining when spent exceeds the limit.
16. Write unit tests that a monthly period becomes the first and last day of the chosen month, and that touching endpoints count as overlap.
17. Write repository tests for CRUD, income category rejection, overlap rejection, and progress that changes when an expense inside the range is added and when an expense outside the range is ignored.
18. Write widget tests for the form and for the three visual states.
19. Open the pull request. Merge it only after transactions are on `develop`.
20. Respond to review. Developer 3 confirms the expense sum is the only input to progress.

Definition of done: FR-BDG-01 through FR-BDG-10, no stored aggregates, tests passing, pull request approved.

### Daily habits during Phase 3

- Merge `develop` into the feature branch.
- Keep commits small and prefixed with the module name.
- If two people need the same shared change, one chore pull request carries it.
- Post a short end-of-day note: tasks finished, contract questions, blockers.

---

## PHASE 4 — Integration

Parallel coding is already allowed after Phase 2. Integration is the ordered merge into `develop` and the checks that follow each merge.

Logical dependency:

```text
Users
  ↓
Categories
  ↓
Transactions
  ↓
Budgets
  ↓
Dashboard / Statistics
```

### Merge order

| Step | Pull request | Wait until | Why |
| --- | --- | --- | --- |
| 1 | `feature/users` | Phase 2 on `develop` | Profiles have no feature dependency |
| 2 | `feature/categories` | Users merged | Categories reference `user_id` and are seeded from profile creation |
| 3 | `feature/transactions` | Users and categories merged | A transaction needs a profile and a same-type category |
| 4 | `feature/budgets` | Transactions merged | Progress reads expense sums |
| 5 | `feature/dashboard` | Budgets merged | The dashboard reads all four modules |

After each merge, every open feature branch merges `develop` in before the next day of work.

### Integration branches

- Feature integration happens on `develop`.
- Do not integrate by merging feature branches into each other.
- `feature/dashboard` is created from `develop` only when step 4 has merged.
- `main` stays untouched until Phase 7.

### Conflict resolution

| Situation | Action |
| --- | --- |
| Conflict inside one feature folder | The owner resolves it. |
| Conflict in `pubspec.yaml`, `lib/core/**`, or the navigation shell | Stop. Move the change into one chore pull request reviewed by all four. Replay the feature branch afterward. |
| Two implementations of the same contract | The provider name from Phase 0 wins. The other implementation is removed by its author. |
| Schema edit discovered on a feature branch | Revert it from the feature branch. Open a migration pull request from `develop` that all four review. |

### Database compatibility checks after each merge

On `develop`, run:

1. The schema test that lists exactly four application tables.
2. The foreign-key tests from Phase 2.
3. The repository tests of every module already merged.
4. A smoke launch of the app: create a profile, confirm predefined categories exist, and open each destination that already has a screen.

### Cross-module testing during integration

| After merge | Scenario |
| --- | --- |
| Categories | Create a profile and count 13 predefined categories. Edit one. Delete an unused custom category. |
| Transactions | Add an expense on a predefined category, filter by that category, and confirm an income category cannot be saved as an expense. |
| Budgets | Create a monthly budget, add an expense in that month and category, and confirm remaining and percentage. Add an expense in another month and confirm it is ignored. |

Dashboard scenarios belong to Phase 5 and Phase 6.

---

## PHASE 5 — Dashboard

Branch: `feature/dashboard` from `develop` after budgets have merged. No new table. No new dependency outside the list from Phase 1.

The dashboard feature contains domain calculations and presentation only. It calls the repositories that already exist.

### Who does what

| Piece | Lead | Support |
| --- | --- | --- |
| Active profile and currency formatting | Developer 1 | — |
| Category name and icon on charts and lists | Developer 2 | — |
| Balance, income, expenses, monthly totals, recent transactions, category sums | Developer 3 | Developer 1 reviews currency scale |
| Remaining budget and warning list | Developer 4 | Developer 3 reviews the expense query |
| Screen layout and statistics navigation | Developer 3 and Developer 4 together | Developers 1 and 2 review |

### Tasks

1. Add `lib/features/dashboard/domain` and `lib/features/dashboard/presentation`.
2. Define a dashboard snapshot built in memory: balance, total income, total expenses, monthly income, monthly expenses, remaining budget for budgets covering today, warning and exceeded budgets, five recent transactions, current-month spending by category.
3. Define a statistics snapshot for a selected month: expenses by category, six-month expense series, six-month income series, income versus expenses, most expensive category, spending evolution, budget consumption for budgets that overlap that month.
4. Implement the calculations with the formulas in section 12 of the cahier des charges. Call transaction and budget repositories. Do not copy those queries into a second SQL file that could drift, unless the repository method is missing. If it is missing, add the method on the owning feature through that owner's review, not as a private query in the dashboard.
5. Replace the dashboard placeholder in the shell.
6. Show every amount with the active profile currency.
7. When no budget covers today, show the empty budget message from the cahier des charges.
8. Add the statistics screen and a month selector. Opening it writes nothing.
9. Add widget tests with fake repositories that prove the snapshot math for a fixed set of rows.
10. Add a schema assertion in the test run that still sees four tables after the dashboard tests.
11. Open the pull request. All four developers review. Merge into `develop`.

### Formulas the dashboard must use

```text
balance = total_income - total_expenses
monthly_income = income dated in the current calendar month
monthly_expenses = expenses dated in the current calendar month
spent = expenses of that budget category between start_date and end_date
remaining = amount_limit - spent
percentage_used = spent / amount_limit * 100
```

Remaining budget on the dashboard is the sum of `remaining` for budgets whose range contains today.

Most expensive category is the highest expense sum in the selected month. Equal sums are ordered by category name ascending, and the first name wins.

---

## PHASE 6 — Testing

Run tests on `develop` after the dashboard has merged. Fix failures on a short `fix/` branch owned by the module that failed, reviewed as usual.

### Unit tests

| Area | Owner | Cases |
| --- | --- | --- |
| User validation | Dev 1 | Name length, email, currency codes, case-insensitive duplicate email |
| Category validation | Dev 2 | Name, icon, type, uniqueness key |
| Transaction validation | Dev 3 | Amount scale, type alignment, description length, date |
| Budget validation | Dev 4 | Limit, month bounds, overlap, income category refused |
| Budget calculator | Dev 4 | 0, 79, 80, 100, above 100, negative remaining |
| Dashboard math | Dev 3 and Dev 4 | Balance, month filter, most expensive category tie, budgets that do not cover today |

Models are covered by constructing valid and invalid values and checking the validation result. Repositories are covered in the integration section below because they need SQLite.

### Integration tests

Use a temporary database for every test.

| Area | Cases |
| --- | --- |
| Database | Four tables only, foreign keys on, version is 1 |
| Users CRUD | Create, update, unique email, delete |
| Categories CRUD | Seed, create, update, delete unused |
| Transactions CRUD | Create, update, delete, filters, sort, sums |
| Budgets CRUD | Create, update, delete, overlap |
| Relationships | User cascade; category restrict; transaction delete leaves category; budget delete leaves transactions; transaction user matches category user |
| Budget progress | Expense inside the range increases spent; expense outside does not; income does not |

### UI tests

| Area | Cases |
| --- | --- |
| Navigation | Profile gate, then the four shell destinations, statistics from the dashboard, categories and profile from More |
| Forms | Empty submit shows validation; valid submit leaves the form |
| User screens | Create, edit, delete confirmation |
| Category screens | Create, blocked delete |
| Transaction screens | Create expense, create income, filter |
| Budget screens | Create monthly budget, see a state badge |
| Dashboard | Totals match the transactions just entered in the test |

### Cross-module scenario

Automate this flow, and also walk it manually once:

1. Create a profile named for the test, currency `TND`.
2. Confirm the predefined categories exist.
3. Create a custom expense category.
4. Create an income transaction on Salary.
5. Create an expense on the custom category, dated inside the current month.
6. Create a monthly budget on that custom category with a limit above the expense.
7. Read progress: spent equals the expense, remaining equals limit minus spent, percentage matches the formula, state follows the thresholds.
8. Add another expense on the same category large enough to pass 100%.
9. Confirm the state is exceeded and remaining is negative.
10. Open the dashboard and confirm balance, monthly totals, the warning or exceeded budget, and the recent list.
11. Open statistics and confirm the custom category is the most expensive for the month when its sum is the highest.
12. Query the table catalogue and confirm exactly four application tables.

---

## PHASE 7 — Final integration

Work on `develop`. Promote to `main` only when the checklist below is true and a pull request from `develop` to `main` is approved by all four developers.

### Final checklist

- [ ] Profile, categories, transactions, budgets, dashboard, and statistics are all reachable.
- [ ] Unit tests pass.
- [ ] Integration tests pass.
- [ ] UI tests pass.
- [ ] The cross-module scenario passes.
- [ ] Schema test reports exactly `users`, `categories`, `transactions`, `budgets`.
- [ ] Foreign keys are on.
- [ ] User delete cascades.
- [ ] Category delete is restricted while referenced, and reassignment works.
- [ ] Budget rows contain no spent, remaining, or percentage columns.
- [ ] Dashboard math matches section 12 of the cahier des charges on the demo data.
- [ ] No second copy of validation or money formatting remains in a feature.
- [ ] No unused package was added.
- [ ] No route in the shell opens a missing screen.
- [ ] The demo path from Phase 9 completes without a crash.
- [ ] Validation messages appear for the rejected cases in section 8.9 of the cahier des charges.
- [ ] Database and conflict errors use the shared error types.
- [ ] Screens use the shared theme, including warning and exceeded colours.
- [ ] The app performs the demo with the device network disabled.
- [ ] `main` is updated only by the approved pull request from `develop`.

---

## PHASE 8 — Documentation

Update `README.md` and keep the two specification files true. Documentation tasks:

| Topic | Content | Owner |
| --- | --- | --- |
| Installation | Flutter SDK, fetch dependencies, run on Android | Phase 1 driver, reviewed by all |
| Architecture | Pointer to the cahier des charges tree and Riverpod choice | Developer 1 |
| Database | Four tables, version, foreign keys, where the helper lives | Developer 1 |
| Git workflow | Branches, commits, pull requests, merge order | Developer 2 |
| Developer responsibilities | The ownership table | Developer 2 |
| Features | Short description of profile, categories, transactions, budgets, dashboard | Each owner writes their paragraph |
| Testing | Commands the team uses to run unit, integration, and UI tests | Developer 3 |
| Known limitations | No cloud sync, no currency conversion, no notifications, Android is the acceptance target, overlap is enforced in domain code | Developer 4 |
| Future improvements | Optional later ideas that must stay out of the current schema unless a new specification version says otherwise: recurring transactions, export, extra currencies | Developer 4 drafts, team approves |

Known limitations to record honestly:

- Amounts stay in the numbers that were typed when the currency label changes.
- One device only.
- Email does not authenticate the person.
- Category icons are a fixed catalogue.
- Statistics cover a six-month window as specified, not an arbitrary chart builder.

---

## PHASE 9 — Demonstration

Rehearse once on a clean install, network disabled, before the graded or public demo. Speak to the four modules as each step happens so ownership is visible.

| Step | Action | What the audience should see |
| --- | --- | --- |
| 1 | Create a profile with a name, an email, and currency `TND` | Profile is stored. Thirteen predefined categories appear. |
| 2 | Add one custom expense category with an icon | The category is listed with the predefined ones. |
| 3 | Add an income on Salary | History shows an income. All-time and monthly income increase. |
| 4 | Add several expenses on different categories, including the custom one, inside the current month | History, filters, and category spending change. |
| 5 | Create a monthly budget on the custom category | The budget shows spent, remaining, and percentage computed from those expenses. |
| 6 | Add another expense on that category inside the month | Spent increases. Remaining decreases. Percentage is recalculated. The budget row in the database is unchanged apart from its original columns. |
| 7 | Show the budget list | Normal, warning, or exceeded matches 80% and 100%. |
| 8 | Show remaining amount | It equals limit minus spent, and it is negative if the limit is passed. |
| 9 | Open the dashboard | Balance, monthly income, monthly expenses, remaining budget, warnings, and recent transactions match the rows just entered. |
| 10 | Open statistics | Expenses by category, income versus expenses, most expensive category, six-month evolution, and budget consumption match the same rows. |

Close the demo by showing the four tables in the database inspector or the schema test output.

Optional extra, if time remains: delete the profile and show that categories, transactions, and budgets for that profile are gone.

---

## Developer dependency matrix

| Module | Users | Categories | Transactions | Budgets |
| --- | --- | --- | --- | --- |
| Users | — | — | — | — |
| Categories | Yes | — | — | — |
| Transactions | Yes | Yes | — | — |
| Budgets | Yes | Yes | Yes | — |
| Dashboard | Yes | Yes | Yes | Yes |

Why each dependency exists:

- **Categories → Users.** Every category row needs a `user_id`. Predefined categories are inserted when a profile is created.
- **Transactions → Users.** Every transaction is scoped to the active profile, and `user_id` is a foreign key.
- **Transactions → Categories.** Every transaction needs a category of the same type owned by that profile. The form uses the category picker.
- **Budgets → Users.** Every budget is scoped to the active profile.
- **Budgets → Categories.** A budget is attached to one expense category. Income categories are rejected.
- **Budgets → Transactions.** Spent, remaining, percentage, and state are sums of expense transactions in the budget window. Those sums are not stored on the budget.
- **Dashboard → all four.** Currency and profile come from users, labels and icons from categories, money movement from transactions, and limits and warnings from budgets.

Users do not wait on the other modules to store a profile. They do call category seeding, which is why the seed contract is agreed in Phase 0 and must be present before the demo even though the users table itself has no foreign key to categories.

---

## Task checklist

### Project setup

- [ ] Phase 0 sign-off recorded by all four developers
- [ ] Cahier des charges accepted
- [ ] Schema accepted
- [ ] Architecture accepted
- [ ] Responsibilities and contract names accepted
- [ ] Navigation accepted
- [ ] Git strategy accepted
- [ ] Backlog created
- [ ] Flutter project created
- [ ] Dart and Flutter SDK aligned
- [ ] Git ignore and commit style configured
- [ ] `develop` created
- [ ] `main` protected from direct feature commits
- [ ] Architecture directories created
- [ ] Dependencies configured (`flutter_riverpod`, `sqflite`, `path`, `path_provider`, `intl`)
- [ ] Riverpod `ProviderScope` in place
- [ ] Navigation shell in place
- [ ] Theme in place
- [ ] Shared widgets and error types in place

### Database

- [ ] Database helper created
- [ ] Schema version set to 1
- [ ] Migration path in place
- [ ] Foreign keys enabled on open
- [ ] Users table
- [ ] Categories table
- [ ] Transactions table
- [ ] Budgets table
- [ ] Primary keys
- [ ] Foreign keys and delete actions
- [ ] Checks and unique constraints
- [ ] Indexes
- [ ] Exactly four application tables verified by a test
- [ ] Relationship tests
- [ ] Database tests passing on `develop`

### Developer 1 — Users

- [ ] User model
- [ ] User validation
- [ ] User repository
- [ ] User CRUD
- [ ] Active profile state
- [ ] Profile gate
- [ ] Profile screen
- [ ] Edit profile screen
- [ ] Currency selection
- [ ] Profile delete confirmation
- [ ] Seed call after create
- [ ] User error handling
- [ ] User unit tests
- [ ] User repository tests
- [ ] User widget tests
- [ ] Pull request `feature/users` reviewed and merged

### Developer 2 — Categories

- [ ] Category model
- [ ] Category validation
- [ ] Category repository
- [ ] Category CRUD
- [ ] Predefined seed
- [ ] Icon selection
- [ ] Type rules
- [ ] Restrict delete
- [ ] Reassignment
- [ ] Category management screen
- [ ] Category form
- [ ] Category picker for other modules
- [ ] Category error handling
- [ ] Category unit tests
- [ ] Category repository tests
- [ ] Category widget tests
- [ ] Pull request `feature/categories` reviewed and merged

### Developer 3 — Transactions

- [ ] Transaction model
- [ ] Transaction validation
- [ ] Transaction repository
- [ ] Create expense
- [ ] Create income
- [ ] Update transaction
- [ ] Delete transaction
- [ ] History
- [ ] Search
- [ ] Filter by type, category, and date
- [ ] Sort
- [ ] Sum and recent-list contracts
- [ ] Transaction screens
- [ ] Transaction error handling
- [ ] Transaction unit tests
- [ ] Transaction repository tests
- [ ] Transaction widget tests
- [ ] Pull request `feature/transactions` reviewed and merged

### Developer 4 — Budgets

- [ ] Budget model
- [ ] Progress type (not stored)
- [ ] Budget calculator
- [ ] Budget validation and overlap
- [ ] Budget repository
- [ ] Budget CRUD
- [ ] Monthly period
- [ ] Custom period
- [ ] Category assignment limited to expenses
- [ ] Remaining, percentage, warning, exceeded
- [ ] Budget screens
- [ ] Budget error handling
- [ ] Budget unit tests
- [ ] Budget repository tests
- [ ] Budget widget tests
- [ ] Pull request `feature/budgets` reviewed and merged

### Integration

- [ ] Categories integrated with users and seeding
- [ ] Categories + transactions
- [ ] Users + transactions
- [ ] Transactions + budgets
- [ ] Daily branch sync practiced
- [ ] Schema still four tables after every merge
- [ ] Dashboard
- [ ] Statistics
- [ ] Dashboard pull request reviewed by all four

### Final

- [ ] Unit tests
- [ ] Integration tests
- [ ] UI tests
- [ ] Cross-module scenario
- [ ] No duplicate calculations stored in the database
- [ ] No broken navigation
- [ ] No crash on the demo path
- [ ] Consistent theme
- [ ] Offline check
- [ ] README and module notes
- [ ] Known limitations written
- [ ] `develop` promoted to `main` by pull request
- [ ] Demo rehearsed

---

## Acceptance criteria

The project is complete when all of the following are true.

1. The application runs on Android.
2. SQLite works with the network disabled, including after a restart.
3. Exactly four application tables exist: `users`, `categories`, `transactions`, `budgets`.
4. Each table has the create, read, update, and delete behaviour defined in the cahier des charges.
5. A person can create, edit, display, switch, and delete a local profile, and can select a currency.
6. A person can create and manage predefined and custom categories, including icons and types.
7. A referenced category cannot be deleted until references are moved or removed.
8. A person can create income and expense transactions, then edit, delete, search, filter, and sort them.
9. A person can create, edit, and delete a budget linked to an expense category and a period.
10. Budget consumption uses `remaining = limit - expenses` and `percentage_used = expenses / limit * 100`, with warning at 80% and exceeded above 100%.
11. Dashboard figures and statistics match the stored rows and are not stored in their own table.
12. Unit, integration, and UI tests cover the major behaviours, and the cross-module scenario passes.
13. The Phase 9 demo completes with no critical defect and no crash.
14. Git history shows the feature branches and pull requests into `develop`, and `main` contains the integrated result.
15. Each developer's work is identifiable on their branch and in their feature folder.

---

## Document control

| Item | Rule |
| --- | --- |
| Changing phase order | Requires agreement from all four developers, recorded before the affected work starts. |
| Changing a contract name | Update Phase 0 notes, the cahier des charges section 10.3, and every owner who consumes the contract, in one reviewed pull request. |
| Starting early | Feature implementation does not start before Phase 0 sign-off. Feature branches do not start before Phase 2 is merged. |
