import 'package:mongo_dart/mongo_dart.dart';
import 'package:unpub/unpub.dart' as unpub;

main(List<String> args) async {
  const dbUri = 'mongodb://localhost:27017/dart_pub';

  var metaStore = unpub.MongoStore();
  await metaStore.create(dbUri);
  await metaStore.db.open();

  final app = unpub.App(
    metaStore: metaStore,
    packageStore: unpub.FileStore('./unpub-packages'),
  );

  final server = await app.serve('0.0.0.0', 4000);
  print('Serving at http://${server.address.host}:${server.port}');
}
