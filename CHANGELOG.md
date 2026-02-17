## 3.0.0

- Fixed multi-byte UTF-8 character input (accented/diacritical characters) on macOS and Linux
- Created `AsyncComponent` and `AsyncInput` to facilitate async validators
- Exported framework classes so developers can create their own components
- Updated sdk and dependencies to the most recent versions

## 2.2.0

- Update sdk and dependencies to the most recent ones
- Prevent cursor jumping from being seen on some terminals

## 2.1.1

- Call `reset` on Ctrl+C forced exits
- Add sigint handlers to components that don't read keys (spinners & progress)

## 2.1.0

- Make confirm components enter-able if `defaultValue` is supplied
- Add `reset` function which supports exception handling
- Allow overriding `Theme.defaultTheme` directly

## 2.0.1

- Fix a typo in the documentation

## 2.0.0

- Migrate to null safety

## 1.1.0

- Enforce stricter linter rules
- Add more documentation comments
- Change theme's `spinner` to `spinners` and accept `List<String>` instead of `String`

## 1.0.0

- Initial version, created by Stagehand
