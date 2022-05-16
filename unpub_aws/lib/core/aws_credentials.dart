import 'dart:cli';
import 'dart:io';
import 'dart:convert';

import 'package:http/http.dart' as http;

class AwsCredentials {
  String? awsAccessKeyId;
  String? awsSecretAccessKey;
  String? awsSessionToken;
  Map<String, String>? environment;
  Map<String, String>? containerCredentials;

  AwsCredentials(
      {this.awsAccessKeyId,
      this.awsSecretAccessKey,
      this.awsSessionToken,
      this.environment,
      this.containerCredentials}) {

    final env = environment ?? Platform.environment;
    environment ??= Platform.environment;
    awsAccessKeyId = awsAccessKeyId ?? env['AWS_ACCESS_KEY_ID'];
    awsSecretAccessKey = awsSecretAccessKey ?? env['AWS_SECRET_ACCESS_KEY'];

    if (awsAccessKeyId == null && awsSecretAccessKey == null) {
      var data = waitFor(getNodeCredentials());
      if (data != null) {
        awsAccessKeyId = data['AccessKeyId'];
        awsSecretAccessKey = data['SecretAccessKey'];
        awsSessionToken = data['Token'];
      }
    }

    if (awsAccessKeyId == null || awsSecretAccessKey == null) {
      throw ArgumentError(
          'You must provide a valid Access Key and Secret for AWS.');
    }
  }

  Future<Map<String, String>?> getContainerCredentials(
      Map<String, String> environment) async {
    try {
      var relativeUri =
          environment['AWS_CONTAINER_CREDENTIALS_RELATIVE_URI'] ?? '';
      var url = Uri.parse('http://169.254.170.2$relativeUri');
      print(url);
      var response = await http.read(url);
      print(response);
      return json.decode(response);
    } catch (e) {
      print(e);
      print('failed to get container credentials.');
    }
  }

  Future<Map<String, String>?> getNodeCredentials() async {
    try {
      var relativeUri = '/latest/meta-data/iam/security-credentials/';
      var url = Uri.parse('http://169.254.169.254$relativeUri');
      var node = await http.read(url);
      print(node);
      url = Uri.parse('$url$node');
      var response = await http.read(url);
      var credentials = json.decode(response);
      print(credentials.Expiration);
      return credentials;
    } catch (e) {
      print(e);
      print('failed to get node credentials.');
    }
  }
}
