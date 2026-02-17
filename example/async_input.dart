import 'dart:io' show stdout;

import 'package:interact2/interact.dart' show AsyncInput, ValidationError;

void main() async {
  stdout.writeln("Check email availability via async call");
  final email = await AsyncInput(
    prompt: "Your email",
    defaultValue: "admin@test.com",
    validator: (String value) async {
      if (!value.contains('@')) {
        throw ValidationError("Not a valid email");
      }
      return await fakeServerCheck(value);
    },
  ).interact();
  stdout.writeln(email);
}

Future<bool> fakeServerCheck(String email) async {
  await Future.delayed(const Duration(milliseconds: 500));
  final taken = ["admin@test.com", "user@test.com"];
  if (taken.contains(email)) {
    throw ValidationError("Email '$email' already taken");
  }
  return true;
}