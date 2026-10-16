# ADR 0001: State management with GetX

- **Status:** Accepted
- **Context:** The template needs one state management approach to demonstrate
  layering and testing. Candidates: GetX, Riverpod, BLoC.

## Decision

Use **GetX** for state, dependency injection and routing, behind clean seams.

## Why GetX here

- Very little boilerplate, so the architecture and the CI pipeline stay the focus.
- Reactive state (`Rx`, `Obx`), bindings and routing in one dependency.
- Controllers are plain Dart classes. With constructor injection they're unit-testable
  without a widget tree (see `tasks_controller_test.dart`).

## Trade-offs, stated honestly

- **Service locator.** `Get.find` is global, runtime-resolved DI. Mistakes surface at
  runtime rather than compile time. Mitigation: controllers receive dependencies through
  constructors; `Get.find` appears only in bindings and `GetView`.
- **Breadth.** One package covers state, DI, routing and more, which couples the app to
  it more tightly than single-purpose libraries would.
- **Ecosystem opinion.** Riverpod and BLoC are widely preferred for large teams, mainly
  for compile-time safety and stricter conventions. Check the package's current
  maintenance status before committing a long-lived product to it.

## Consequences

Business logic lives in controllers that depend only on domain interfaces, and widgets
only read state. Because of that, moving to Riverpod or BLoC later means rewriting the
thin presentation layer, not the domain, data or tests of the repository.

## When to choose differently

Prefer Riverpod or BLoC for large, long-lived codebases with many contributors, or where
compile-time dependency checking is a hard requirement.
