part of 'framework.dart';

final _defaultConsole = Console();

/// [Context] is used by [Component] and [State] to actually render
/// things to the console, and to act as a state store during rendering,
/// which will store things such as the number or renderings done and the
/// amount of lines used by a specific render, so that the [State] can
/// clear old lines and render new stuffs automatically.
class Context {
  /// Resets the Console.
  static void reset() {
    _defaultConsole.showCursor();
    _defaultConsole.resetColorAttributes();
  }

  final _console = _defaultConsole;

  int _renderCount = 0;

  /// Indicates how many times the [Context] has rendered.
  int get renderCount => _renderCount;

  /// Increases the [renderCount] by one.
  void increaseRenderCount() => _renderCount++;

  /// Sets the [renderCount] to `0`.
  void resetRenderCount() => _renderCount = 0;

  int _linesCount = 0;

  /// Indicates how many lines the context is used for rendering.
  int get linesCount => _linesCount;

  /// Increases the [linesCount] by one.
  void increaseLinesCount() => _linesCount++;

  /// Sets the [linesCount] to `0`.
  void resetLinesCount() => _linesCount = 0;

  /// Removes the lines from the last render and reset the lines count.
  void wipe() {
    erasePreviousLine(linesCount);
    resetLinesCount();
  }

  /// Returns terminal width in terms of characters.
  int get windowWidth => _console.windowWidth;

  /// Shows the cursor.
  void showCursor() => _console.showCursor();

  /// Hide the cursor.
  void hideCursor() => _console.hideCursor();

  /// Writes a string to the console.
  void write(String text) => _console.write(text);

  /// Increases the number of lines written for the current render,
  /// and writes a line to the the console.
  void writeln([String? text]) {
    increaseLinesCount();
    _console.writeLine(text);
  }

  /// Erase one line above the current cursor by default.
  ///
  /// If the argument [n] is supplied, it will repeat the process
  /// to [n] times.
  void erasePreviousLine([int n = 1]) {
    for (var i = 0; i < n; i++) {
      _console.cursorUp();
      _console.eraseLine();
    }
  }

  /// Reads a key press, same as dart_console library's
  /// `readKey()` function but this function handles the `Ctrl+C` key
  /// press to immediately exit from the process.
  Key readKey() => _handleKey(_console.readKey());

  /// Reads a line of input from the terminal with support for inline
  /// editing, cursor movement, and proper multi-byte UTF-8 character
  /// handling.
  ///
  /// This is a replacement for [readLine2] which uses dart_console's
  /// [readKey] internally. The [readKey] method reads one byte at a time
  /// and decodes it as a single character, which breaks multi-byte UTF-8
  /// sequences (e.g., accented characters like 'é' are two bytes: 0xC3
  /// 0xA9). This method detects UTF-8 lead bytes and reads the remaining
  /// continuation bytes to properly reconstruct the character.
  ///
  /// ## macOS Accent Popup Handling
  ///
  /// On macOS, when a user holds down a letter key and selects an accented
  /// variant from the popup (e.g., hold 'a' → select 'à'), the terminal
  /// receives:
  ///   1. The base ASCII character ('a')
  ///   2. The UTF-8 bytes of the accented character ('à') — no backspace
  ///
  /// This differs from Windows and Linux, where dead keys and compose keys
  /// send only the final composed character. To handle this, the method
  /// tracks whether the last inserted character was ASCII
  /// ([lastInsertedAscii]) and uses [_baseChar] to check if the incoming
  /// accented character is derived from it. If so, the base character is
  /// replaced rather than appended.
  ///
  /// ## Parameters
  ///
  /// - [initialText]: Pre-fills the input buffer. The cursor is placed at
  ///   the end of this text.
  /// - [noRender]: When `true`, suppresses all visual output. Used by the
  ///   [Password] component to hide user input.
  ///
  /// ## Supported Editing Keys
  ///
  /// - **Enter**: Submits the input
  /// - **Backspace / Ctrl+H**: Deletes character before cursor
  /// - **Delete / Ctrl+D**: Deletes character after cursor
  /// - **Left / Ctrl+B**: Moves cursor left
  /// - **Right / Ctrl+F**: Moves cursor right
  /// - **Home / Ctrl+A**: Moves cursor to start
  /// - **End / Ctrl+E**: Moves cursor to end
  /// - **Ctrl+U**: Clears entire line
  /// - **Ctrl+K**: Deletes from cursor to end
  /// - **Word Left (Ctrl+Left / Alt+B)**: Moves cursor to previous word
  ///   boundary
  String readLine({
    String initialText = '',
    bool noRender = false,
  }) {
    var buffer = initialText;
    var index = buffer.length;
    var lastInsertedAscii = false;

    final screenRow = _console.cursorPosition?.row ?? 0;
    final screenColOffset = _console.cursorPosition?.col ?? 0;
    final bufferMaxLength = _console.windowWidth - screenColOffset - 3;

    if (buffer.isNotEmpty && !noRender) {
      write(buffer);
    }

    while (true) {
      final key = readKey();

      if (key.isControl) {
        lastInsertedAscii = false;
        switch (key.controlChar) {
          case ControlCharacter.enter:
            writeln();
            return buffer;
          case ControlCharacter.backspace:
          case ControlCharacter.ctrlH:
            if (index > 0) {
              buffer = buffer.substring(0, index - 1) + buffer.substring(index);
              index--;
            }
          case ControlCharacter.delete:
          case ControlCharacter.ctrlD:
            if (index < buffer.length - 1) {
              buffer = buffer.substring(0, index) + buffer.substring(index + 1);
            }
          case ControlCharacter.ctrlU:
            buffer = '';
            index = 0;
          case ControlCharacter.ctrlK:
            buffer = buffer.substring(0, index);
          case ControlCharacter.arrowLeft:
          case ControlCharacter.ctrlB:
            index = index > 0 ? index - 1 : index;
          case ControlCharacter.arrowRight:
          case ControlCharacter.ctrlF:
            index = index < buffer.length ? index + 1 : index;
          case ControlCharacter.wordLeft:
            if (index > 0) {
              final bufferLeftOfCursor = buffer.substring(0, index - 1);
              final lastSpace = bufferLeftOfCursor.lastIndexOf(' ');
              index = lastSpace != -1 ? lastSpace + 1 : 0;
            }
          case ControlCharacter.home:
          case ControlCharacter.ctrlA:
            index = 0;
          case ControlCharacter.end:
          case ControlCharacter.ctrlE:
            index = buffer.length;
          default:
            break;
        }
      } else {
        var char = key.char;
        final firstByte = char.codeUnitAt(0);

        if (firstByte >= 0xC0) {
          // Multi-byte UTF-8 character detected.
          //
          // dart_console's readKey() reads a single byte and decodes it
          // independently, so a 2-byte character like 'é' (0xC3 0xA9)
          // arrives as two separate readKey() calls: first returning 'Ã'
          // (0xC3) and then '©' (0xA9). We detect the UTF-8 lead byte
          // pattern and read the expected number of continuation bytes:
          //
          //   Lead byte 0xC0-0xDF → 1 continuation byte  (2-byte chars)
          //   Lead byte 0xE0-0xEF → 2 continuation bytes (3-byte chars)
          //   Lead byte 0xF0-0xF7 → 3 continuation bytes (4-byte chars)
          final bytes = <int>[firstByte];
          int remaining;
          if (firstByte < 0xE0) {
            remaining = 1;
          } else if (firstByte < 0xF0) {
            remaining = 2;
          } else {
            remaining = 3;
          }
          for (var i = 0; i < remaining; i++) {
            final next = readKey();
            if (!next.isControl) {
              bytes.add(next.char.codeUnitAt(0));
            }
          }
          char = utf8.decode(bytes, allowMalformed: true);

          // Handle macOS accent popup replacement.
          // See class-level docs on _baseChar for full explanation.
          if (lastInsertedAscii && index > 0) {
            final prevChar = buffer[index - 1].toLowerCase();
            final base = _baseChar(char.runes.first);
            if (base != null && base.toLowerCase() == prevChar) {
              buffer = buffer.substring(0, index - 1) + buffer.substring(index);
              index--;
            }
          }

          lastInsertedAscii = false;
        } else {
          lastInsertedAscii = firstByte >= 32 && firstByte < 128;
        }

        if (buffer.length < bufferMaxLength) {
          if (index == buffer.length) {
            buffer += char;
            index += char.length;
          } else {
            buffer =
                buffer.substring(0, index) + char + buffer.substring(index);
            index += char.length;
          }
        }
      }

      if (!noRender) {
        _console.hideCursor();
        _console.cursorPosition = Coordinate(screenRow, screenColOffset);
        _console.eraseCursorToEnd();
        write(buffer);
        _console.cursorPosition =
            Coordinate(screenRow, screenColOffset + index);
        _console.showCursor();
      }
    }
  }

  /// Maps an accented Latin character's Unicode code point to its ASCII
  /// base letter.
  ///
  /// Returns the base letter as a [String], or `null` if the code point
  /// is not a recognized accented Latin character.
  ///
  /// Covers two Unicode blocks:
  /// - **Latin-1 Supplement** (U+00C0 – U+00FF): Common Western European
  ///   accented characters such as À, É, Ñ, Ü, etc.
  /// - **Latin Extended-A** (U+0100 – U+017F): Central and Eastern European
  ///   characters such as Ā, Ć, Ď, Ę, Ł, Ř, Ş, etc.
  ///
  /// This is used to detect macOS accent popup replacements. On macOS,
  /// when a user holds down a key (e.g., 'a') and selects an accented
  /// variant (e.g., 'à') from the popup, the terminal receives the base
  /// ASCII character followed immediately by the UTF-8 bytes of the
  /// accented character — with no backspace in between. By checking
  /// whether the accented character's base matches the previously
  /// inserted character, we can correctly replace it rather than
  /// appending.
  ///
  /// On Windows and Linux, accent input uses dead keys or compose keys,
  /// which send the final composed character directly. In those cases,
  /// this method still works correctly because the base character check
  /// prevents false replacements — the method only triggers a replacement
  /// when the previous character actually matches the base letter.
  static String? _baseChar(int codePoint) {
    // Latin-1 Supplement: U+00C0 - U+00FF
    // Covers: ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞß àáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿ
    // Zero entries indicate characters without a clear ASCII base
    // (e.g., Æ, ×, Þ, ß, æ, ÷, þ).
    const latin1 = [
      0x41,0x41,0x41,0x41,0x41,0x41, 0,0x43,  // À-Ç
      0x45,0x45,0x45,0x45,0x49,0x49,0x49,0x49, // È-Ï
      0x44,0x4E,0x4F,0x4F,0x4F,0x4F,0x4F, 0,  // Ð-×
      0x4F,0x55,0x55,0x55,0x55,0x59, 0, 0,    // Ø-ß
      0x61,0x61,0x61,0x61,0x61,0x61, 0,0x63,  // à-ç
      0x65,0x65,0x65,0x65,0x69,0x69,0x69,0x69, // è-ï
      0x64,0x6E,0x6F,0x6F,0x6F,0x6F,0x6F, 0,  // ð-÷
      0x6F,0x75,0x75,0x75,0x75,0x79, 0,0x79,  // ø-ÿ
    ];
    if (codePoint >= 0xC0 && codePoint <= 0xFF) {
      final base = latin1[codePoint - 0xC0];
      return base != 0 ? String.fromCharCode(base) : null;
    }

    // Latin Extended-A: U+0100 - U+017F
    // Covers pairs of uppercase/lowercase variants for the same base:
    // Ā/ā, Ă/ă, Ą/ą, Ć/ć, Ĉ/ĉ, ... Ź/ź, Ż/ż, Ž/ž, ſ
    // Zero entries indicate characters without a clear ASCII base
    // (e.g., IJ/ij ligatures, kra).
    const extA = [
      0x41,0x61,0x41,0x61,0x41,0x61,0x43,0x63, // Ā-ć
      0x43,0x63,0x43,0x63,0x43,0x63,0x44,0x64, // Ĉ-ď
      0x44,0x64,0x45,0x65,0x45,0x65,0x45,0x65, // Đ-ě
      0x45,0x65,0x45,0x65,0x47,0x67,0x47,0x67, // Ę-ġ
      0x47,0x67,0x47,0x67,0x48,0x68,0x48,0x68, // Ģ-ħ
      0x49,0x69,0x49,0x69,0x49,0x69,0x49,0x69, // Ĩ-ĭ
      0x49,0x69, 0, 0,0x4A,0x6A,0x4B,0x6B, 0, // Į-ĸ
      0x4C,0x6C,0x4C,0x6C,0x4C,0x6C,0x4C,0x6C, // Ĺ-ŀ
      0x4C,0x6C,0x4E,0x6E,0x4E,0x6E,0x4E,0x6E, // Ł-ň
      0x4E, 0,0x4F,0x6F,0x4F,0x6F,0x4F,0x6F,  // ŉ-ő
      0, 0,0x52,0x72,0x52,0x72,0x52,0x72,     // Œ-ŗ
      0x53,0x73,0x53,0x73,0x53,0x73,0x53,0x73, // Ś-ş
      0x54,0x74,0x54,0x74,0x54,0x74,0x55,0x75, // Ţ-ũ
      0x55,0x75,0x55,0x75,0x55,0x75,0x55,0x75, // Ū-ů
      0x55,0x75,0x57,0x77,0x59,0x79,0x59,0x5A, // Ű-Ź
      0x7A,0x5A,0x7A,0x5A,0x7A,0x73,          // ź-ſ
    ];
    if (codePoint >= 0x100 && codePoint <= 0x17F) {
      final idx = codePoint - 0x100;
      if (idx < extA.length) {
        final base = extA[idx];
        return base != 0 ? String.fromCharCode(base) : null;
      }
    }

    return null;
  }

  Key _handleKey(Key key) {
    if (key.isControl && key.controlChar == ControlCharacter.ctrlC) {
      writeln();
      reset();
      exit(1);
    }
    return key;
  }
}

/// Unlike a normal [Context], [BufferContext] writes lines to a specified
/// [StringBuffer] and run a reload function on every line written.
///
/// Useful when waiting for a rendering context when there is multiple
/// of them rendering at the same time. [MultipleSpinner] component used it
/// so when [Spinner]s are being rendered, they get rendered to a [String].
/// It later used the [setState] function to rendered the whole [String]
/// containing multiple [BufferContext]s to the console.
class BufferContext extends Context {
  /// Constructs a [BufferContext] with given properties.
  BufferContext({
    required this.buffer,
    required this.setState,
  });

  /// Buffer stores the lines written to the context.
  final StringBuffer buffer;

  /// Runs everytime something was written to the buffer.
  final void Function() setState;

  @override
  void writeln([String? text]) {
    buffer.clear();
    buffer.write(text);
    setState();
  }
}
