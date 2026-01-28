import 'package:RITArcade/components/new_types.dart';


int calculateTime(OrderData order) {
  const int PAGE_PRINT_TIME = 1;
  int total = order.pages * PAGE_PRINT_TIME;
  for(var file in order.files) {
    if (file.binding == "Soft Binding") total += 300*file.copies;
    if (file.binding == "Spiral Binding") total += 300*file.copies;
  }
  return total;
}