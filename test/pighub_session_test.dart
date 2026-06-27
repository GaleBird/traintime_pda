import 'package:flutter_test/flutter_test.dart';
import 'package:watermeter/repository/pighub_session.dart';

void main() {
  group('PigHubImage', () {
    test('parses current PigHub image API fields', () {
      final image = PigHubImage.fromJson({
        'id': 1303,
        'title': 'Sample Pig',
        'filename': 'sample-pig.jpg',
        'image_url': '/images/sample-pig.jpg',
      });

      expect(image.id, '1303');
      expect(image.title, 'Sample Pig');
      expect(image.thumbnail, '/images/sample-pig.jpg');
      expect(image.imageType, 'static');
      expect(image.url, 'https://www.pighub.top/images/sample-pig.jpg');
    });

    test('detects gif images from filename', () {
      final image = PigHubImage.fromJson({
        'id': 1300,
        'title': 'Captured Pig',
        'filename': 'captured-pig.gif',
        'image_url': '/images/captured-pig.gif',
      });

      expect(image.imageType, 'gif');
    });

    test('rejects malformed image records instead of building null URLs', () {
      expect(
        () => PigHubImage.fromJson({
          'id': 1303,
          'title': 'Sample Pig',
          'filename': 'sample-pig.jpg',
        }),
        throwsFormatException,
      );
    });
  });
}
