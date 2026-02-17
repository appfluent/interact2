import 'dart:async';

import 'package:interact2/src/framework/framework.dart';
import 'package:interact2/src/input.dart';
import 'package:interact2/src/theme/theme.dart';
import 'package:interact2/src/utils/prompt.dart';

/// An input component.
class AsyncInput extends AsyncComponent<String> {
  /// Constructs an [AsyncInput] component with the default theme.
  AsyncInput({
    required this.prompt,
    this.validator,
    this.initialText = '',
    this.defaultValue,
  }) : theme = Theme.defaultTheme;

  /// Constructs an [AsyncInput] component with the supplied theme.
  AsyncInput.withTheme({
    required this.prompt,
    required this.theme,
    this.validator,
    this.initialText = '',
    this.defaultValue,
  });

  /// The theme for the component.
  final Theme theme;

  /// The prompt to be shown together with the user's input.
  final String prompt;

  /// The initial text to be filled in the input box.
  final String initialText;

  /// The value to be hinted in the [prompt] and will be used
  /// if the user's input is empty.
  final String? defaultValue;

  /// The function that runs with the value after the user has
  /// entered the input. If the function throw a [ValidationError]
  /// instead of returning `true`, the error will be shown and
  /// a new input will be asked.
  final Future<bool> Function(String)? validator;

  @override
  _AsyncInputState createState() => _AsyncInputState();
}

class _AsyncInputState extends State<AsyncInput> {
  String? value;
  String? error;

  @override
  void init() {
    super.init();
    value = component.initialText;
  }

  @override
  void dispose() {
    if (value != null) {
      context.writeln(
        promptSuccess(
          theme: component.theme,
          message: component.prompt,
          value: value!,
        ),
      );
    }
    super.dispose();
  }

  @override
  void render() {
    if (error != null) {
      context.writeln(
        promptError(
          theme: component.theme,
          message: error!,
        ),
      );
    }
  }

  @override
  Future<String> interact() async {
    while (true) {
      context.write(
        promptInput(
          theme: component.theme,
          message: component.prompt,
          hint: component.defaultValue,
        ),
      );
      final input = context.readLine(initialText: component.initialText);
      final line = input.isEmpty && component.defaultValue != null
          ? component.defaultValue!
          : input;

      if (component.validator != null) {
        try {
          await component.validator!(line);
        } on ValidationError catch (e) {
          setState(() {
            error = e.message;
          });
          continue;
        }
      }

      setState(() {
        value = line;
      });

      return value!;
    }
  }
}
