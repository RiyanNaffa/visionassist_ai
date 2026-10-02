# Contributing to VisionAssist AI

Thank you for contributing to an accessibility-focused project!

## Code of Conduct

Be respectful and inclusive. We follow the [Contributor Covenant](https://www.contributor-covenant.org/).

## Getting Started

1. Fork the repository and create a feature branch:
   ```bash
   git checkout -b feat/my-feature
   ```
2. Run the bootstrap script:
   ```bash
   bash scripts/bootstrap.sh
   ```
3. Copy `.env.example` to `.env` and fill in your settings.

## Development

```bash
# Run the app
flutter run --dart-define-from-file=.env

# Analyze
flutter analyze

# Test
flutter test --coverage
```

## Pull Request Guidelines

- Keep PRs focused on a single concern.
- All public APIs must have `///` doc comments.
- No `print()` — use `debugPrint()`.
- All user-facing strings must go in `lib/core/constants/app_strings.dart`.
- Run `flutter analyze` with zero errors before opening a PR.
- Add or update tests for any changed logic.
- Wrap all interactive widgets in `Semantics` with an Indonesian label.
- Minimum touch target: **72 dp**.

## Adding a Currency Model

See `assets/models/README.md` for the full model contract.

## Security

Do **not** bundle any LLM API keys in the app.
Remote Q&A must route through the backend proxy (`API_PROXY_URL`).
