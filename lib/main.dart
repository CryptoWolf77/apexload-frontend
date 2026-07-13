import 'package:apexload/bootstrap.dart';
import 'package:apexload/core/constants/app_edition.dart';
import 'package:flutter/services.dart';

Future<void> main() => bootstrapApexLoad(AppEdition.fromFlavor(appFlavor));
