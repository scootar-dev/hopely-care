import 'package:flutter_riverpod/legacy.dart';
import 'package:image_picker/image_picker.dart';

const communityPhotoIntentKey = 'hopely.community-photo-intent';

class RecoveredCommunityPhoto {
  const RecoveredCommunityPhoto(this.userId, this.communityId, this.file);
  final String userId, communityId;
  final XFile file;
}

final recoveredCommunityPhotoProvider = StateProvider<RecoveredCommunityPhoto?>(
  (ref) => null,
);
