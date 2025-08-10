import 'package:cloudflare_r2/cloudflare_r2.dart';
import '../components/newtypes.dart';

Future<void> uploader(OrderData order) async {
  print('Uploading files.....');
    String controllerAccountId = "c066124110c7d4aa00b8e423e288d1c6";
    String controllerAccessId = "170f089e4646d57ca32a729ddf9eab14";
    String controllerSecretAccessKey = "d9757111f8ab64edf2d81468c06e8845714df24dcaad17e59da93dffa588aad8";
    String controllerBucket = "testfiles";
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
