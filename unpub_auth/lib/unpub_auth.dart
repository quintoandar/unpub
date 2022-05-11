import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:oauth2/oauth2.dart' as oauth2;
import 'package:http/http.dart' as http;

import 'utils.dart';
import 'credentials_ext.dart';

const _tokenEndpoint = 'https://oauth2.googleapis.com/token';
const _authEndpoint = 'https://accounts.google.com/o/oauth2/auth';
const _scopes = ['openid', 'https://www.googleapis.com/auth/userinfo.email'];

get _identifier => utf8.decode(base64.decode(
    r'NDY4NDkyNDU2MjM5LTJja2wxdTB1dGloOHRzZWtnMGxpZ2NpY2VqYm8wbnZkLmFwcHMuZ29vZ2xldXNlcmNvbnRlbnQuY29t'));
get _secret => utf8
    .decode(base64.decode(r'R09DU1BYLUxHMWZTV052UjA0S0NrWVZRMTVGS3J1cGJ5bFk='));

enum Flow {
  login,
  logout,
  migrate,
  getToken,
}

Future<void> run({Flow flow = Flow.getToken, Object? args}) async {
  switch (flow) {
    case Flow.login:
      await _goAuth();
      break;
    case Flow.logout:
      await removeCredentialsFromLocal();
      break;
    case Flow.migrate:
      await migrate(args);
      break;
    case Flow.getToken:
      await getToken();
      break;
  }
}

Future<void> migrate(Object? args) async {
  if (args == null || args is! String) {
    Utils.stdoutPrint("$args is invalid");
    exit(1);
  }
  if (File(args).existsSync() == false) {
    Utils.stdoutPrint("$args is not exist.");
    exit(1);
  }

  final isValid =
      oauth2.Credentials.fromJson(await File(args).readAsString()).isValid();
  if (isValid) {
    await File(args).copy(Utils.credentialsFilePath);
    Utils.stdoutPrint(
        'Migrate from $args success.\nNew credentials file is saved at ${Utils.credentialsFilePath}');
    return;
  }
}

Future<void> getToken() async {
  final credentials = await readCredentialsFromLocal();

  if (credentials?.isValid() ?? false) {
    /// unpub-credentials.json is valid.
    /// Refresh and write it to file.
    await refreshCredentials(credentials!);
  } else {
    /// unpub-credentials.json is not exist or invalid.
    /// We should get a new Credentials file.
    Utils.stdoutPrint('${Utils.credentialsFilePath} is not found or invalid.'
        '\nPlease call unpub_auth login first.');
    exit(1);
  }
  return;
}

Future<void> _goAuth() async {
  final client = await clientWithAuthorization();
  writeNewCredentials(client.credentials);
  Utils.stdoutPrint(client.credentials.accessToken);
}

/// Write the new credentials file to unpub-credentials.json
void writeNewCredentials(oauth2.Credentials credentials) {
  File(Utils.credentialsFilePath).writeAsStringSync(credentials.toJson());
}

/// Refresh `accessToken` of credentials
Future<void> refreshCredentials(oauth2.Credentials credentials) async {
  final client = oauth2.Client(
      oauth2.Credentials.fromJson(credentials.toJson()),
      identifier: _identifier,
      secret: _secret, onCredentialsRefreshed: (credential) async {
    writeNewCredentials(credential);
  });
  await client.refreshCredentials();
  Utils.stdoutPrint(client.credentials.accessToken);
}

/// Create a client with authorization.
Future<oauth2.Client> clientWithAuthorization() async {
  final grant = oauth2.AuthorizationCodeGrant(
      _identifier, Uri.parse(_authEndpoint), Uri.parse(_tokenEndpoint),
      secret: _secret, basicAuth: false, httpClient: http.Client());

  final completer = Completer();

  final server = await Utils.bindServer('localhost', 43230);
  shelf_io.serveRequests(server, (request) {
    if (request.url.path == 'authorized') {
      /// That's safe.
      /// see [dart-lang/pub/lib/src/oauth2.dart#L238:L240](https://github.com/dart-lang/pub/blob/400f21e9883ce6555b66d3ef82f0b732ba9b9fc8/lib/src/oauth2.dart#L238:L240)
      server.close();
      return shelf.Response.ok(r'unpub Authorized Successfully.');
    }

    if (request.url.path.isNotEmpty) {
      /// Forbid all other requests.
      return shelf.Response.notFound('Invalid URI.');
    }

    Utils.stdoutPrint('Authorization received, processing...');

    /// Redirect to authorized page.
    final resp =
        shelf.Response.found('http://localhost:${server.port}/authorized');

    completer.complete(
        grant.handleAuthorizationResponse(Utils.queryToMap(request.url.query)));

    return resp;
  });

  final authUrl = grant
          .getAuthorizationUrl(Uri.parse('http://localhost:${server.port}'),
              scopes: _scopes)
          .toString() +
      '&access_type=offline&approval_prompt=force';
  Utils.stdoutPrint(
      'unpub needs your authorization to upload packages on your behalf.\n'
      'In a web browser, go to $authUrl\n'
      'Then click "Allow access".\n\n'
      'Waiting for your authorization...');

  var client = await completer.future;
  Utils.stdoutPrint('Successfully authorized.\n');
  return client;
}

/// Read credential file from local path.
Future<oauth2.Credentials?> readCredentialsFromLocal() async {
  final credentialFile = File(Utils.credentialsFilePath);

  final exists = await credentialFile.exists();
  if (!exists) {
    Utils.stdoutPrint('${Utils.credentialsFilePath} is not exist.\n'
        'Please run `unpub_auth login` first');
    return null;
  }

  final fileContent = await credentialFile.readAsString();

  return oauth2.Credentials.fromJson(fileContent);
}

/// Remove credential file from local path.
Future<void> removeCredentialsFromLocal() async {
  await File(Utils.credentialsFilePath).delete();
  Utils.stdoutPrint('${Utils.credentialsFilePath} has been deleted.');
}
