import 'package:cloudflare_r2/cloudflare_r2.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../components/newtypes.dart';

Future<void> uploader(OrderData order) async {
  print('Uploading files.....');
  String controllerAccountId = dotenv.env['CLOUDFLARE_ACCOUNT_ID'] ?? 'c066124110c7d4aa00b8e423e288d1c6';
  String controllerAccessId = dotenv.env['CLOUDFLARE_ACCESS_ID'] ?? '170f089e4646d57ca32a729ddf9eab14';
  String controllerSecretAccessKey = dotenv.env['CLOUDFLARE_SECRET_ACCESS_KEY'] ?? 'd9757111f8ab64edf2d81468c06e8845714df24dcaad17e59da93dffa588aad8';
  String controllerBucket = dotenv.env['CLOUDFLARE_BUCKET'] ?? 'testfiles';
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
    }
    catch(error){
      print(error);
    }
  }
