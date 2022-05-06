import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as path;
import 'package:unpub/unpub.dart' as unpub;
import 'package:unpub_aws/unpub_aws.dart' as unpub_aws;

void main(List<String> args) async {
  var parser = ArgParser();
  parser.addOption('host', abbr: 'h', defaultsTo: '0.0.0.0');
  parser.addOption('port', abbr: 'p', defaultsTo: '4000');
  parser.addOption(
    'database',
    abbr: 'd',
    defaultsTo: 'mongodb://localhost:27017/dart_pub',
  );
  parser.addOption('uploader');
  parser.addOption('bucket');

  var results = parser.parse(args);

  var host = results['host'] as String;
  var port = int.parse(results['port'] as String);
  var db = results['database'] as String;
  var uploader = results['uploader'] as String;
  var bucket = results['bucket'] as String;

  if (results.rest.isNotEmpty) {
    print('Got unexpected arguments: "${results.rest.join(' ')}".\n\nUsage:\n');
    print(parser.usage);
    exit(1);
  }

  var baseDir = path.absolute('unpub-packages');

  var mongoStore = unpub.MongoStore();
  await mongoStore.create(db);
  await mongoStore.db.open();

  var app = unpub.App(
    metaStore: mongoStore,
    packageStore: unpub_aws.S3Store(bucket),
    overrideUploaderEmail: uploader,
  );

  var server = await app.serve(host, port);
  print('Serving at http://${server.address.host}:${server.port}');
}
