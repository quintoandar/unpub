import 'package:mongo_dart/mongo_dart.dart';
import 'package:unpub/unpub.dart' as unpub;

main(List<String> args) async {
  const dbUri = 'mongodb://localhost:27017/dart_pub';

  final db = Db(dbUri);
  await db.open(); // make sure the MongoDB connection opened

  var metaStore = unpub.MongoStore(db);
  await metaStore.create(dbUri);

  final app = unpub.App(
    metaStore: unpub.MongoStore(db),
    packageStore: unpub.FileStore('./unpub-packages'),
  );

  final server = await app.serve('0.0.0.0', 4000);
  print('Serving at http://${server.address.host}:${server.port}');
}
