import 'package:cloudflare_r2/cloudflare_r2.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../components/new_types.dart';

Future<void> uploader(OrderData order) async {
  print('Uploading files.....');
  String controllerAccountId = dotenv.env['CLOUDFLARE_ACCOUNT_ID'] ?? '';
  String controllerAccessId = dotenv.env['CLOUDFLARE_ACCESS_ID'] ?? '';
  String controllerSecretAccessKey =
      dotenv.env['CLOUDFLARE_SECRET_ACCESS_KEY'] ?? '';
  String controllerBucket = dotenv.env['CLOUDFLARE_BUCKET'] ?? '';
  try {
    CloudFlareR2.init(
      accoundId: controllerAccountId,
      accessKeyId: controllerAccessId,
      secretAccessKey: controllerSecretAccessKey,
    );
    for (var file in order.files) {
      print(file.name);
      await CloudFlareR2.putObject(
          bucket: controllerBucket,
          objectName: order.orderId + file.name,
          objectBytes: file.bytes,
          contentType: "application/pdf");
    }
  } catch (error) {
    print(error);
  }
}
