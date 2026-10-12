import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mocktail/mocktail.dart';

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

MockSecureStorage createSecureStorage({bool failDelete = false}) {
  final storage = MockSecureStorage();
  final values = <String, String>{};

  when(
    () => storage.write(
      key: any(named: 'key'),
      value: any(named: 'value'),
      aOptions: any(named: 'aOptions'),
      iOptions: any(named: 'iOptions'),
      lOptions: any(named: 'lOptions'),
      wOptions: any(named: 'wOptions'),
      mOptions: any(named: 'mOptions'),
      webOptions: any(named: 'webOptions'),
    ),
  ).thenAnswer((invocation) async {
    final key = invocation.namedArguments[#key] as String;
    final value = invocation.namedArguments[#value] as String?;
    if (value == null) {
      values.remove(key);
    } else {
      values[key] = value;
    }
  });

  when(
    () => storage.read(
      key: any(named: 'key'),
      aOptions: any(named: 'aOptions'),
      iOptions: any(named: 'iOptions'),
      lOptions: any(named: 'lOptions'),
      wOptions: any(named: 'wOptions'),
      mOptions: any(named: 'mOptions'),
      webOptions: any(named: 'webOptions'),
    ),
  ).thenAnswer((invocation) async {
    return values[invocation.namedArguments[#key] as String];
  });

  when(
    () => storage.containsKey(
      key: any(named: 'key'),
      aOptions: any(named: 'aOptions'),
      iOptions: any(named: 'iOptions'),
      lOptions: any(named: 'lOptions'),
      wOptions: any(named: 'wOptions'),
      mOptions: any(named: 'mOptions'),
      webOptions: any(named: 'webOptions'),
    ),
  ).thenAnswer((invocation) async {
    return values.containsKey(invocation.namedArguments[#key] as String);
  });

  when(
    () => storage.delete(
      key: any(named: 'key'),
      aOptions: any(named: 'aOptions'),
      iOptions: any(named: 'iOptions'),
      lOptions: any(named: 'lOptions'),
      wOptions: any(named: 'wOptions'),
      mOptions: any(named: 'mOptions'),
      webOptions: any(named: 'webOptions'),
    ),
  ).thenAnswer((invocation) async {
    if (failDelete && key == 'github_oauth_access_token') {
      throw StateError('secure storage delete failed');
    }
    values.remove(invocation.namedArguments[#key] as String);
  });

  return storage;
}
