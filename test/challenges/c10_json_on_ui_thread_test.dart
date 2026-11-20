import 'package:flutter_test/flutter_test.dart';
import 'package:machine_round/challenges/c10_json_on_ui_thread/fixed.dart';
import 'package:machine_round/challenges/c10_json_on_ui_thread/shared.dart';

void main() {
  test('background parsing gives the same result as the UI-thread version', () async {
    final body = buildCatalogJson(5000);
    final sync = parseProducts(body);
    final background = await parseProductsInBackground(body);
    expect(background, hasLength(sync.length));
    expect(background.last.name, sync.last.name);
    expect(background.last.price, sync.last.price);
  });
}
