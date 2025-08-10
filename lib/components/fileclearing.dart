import 'dart:io';
import 'package:path_provider/path_provider.dart';

import 'newtypes.dart';

Future<void> clearCache(List<FileData> files) async{
  for(var file in files){
    if(file.path.isNotEmpty){
      print(file.path);
    await deletePickedFile(file.path);}
  }
}
Future<void> deletePickedFile(String filePath) async {
  final file = File(filePath);
  if (await file.exists()) {
    await file.delete();
  }
}
