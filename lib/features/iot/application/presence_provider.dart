import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'iot_provider.dart';

/// The presence topic for a central — the actual MQTT Last-Will topic, not
/// a made-up name for it. Universally subscribable by any authenticated
/// user via the shared IoT policy's `topicfilter/*/will` grant. In AWS IoT
/// policy resources only `*` is a wildcard (and it matches colons fine);
/// the MQTT wildcards `+`/`#` are treated as literal characters there —
/// which is why every past `+`-based policy attempt failed. The raw
/// identityId (colon and all) is fine in the topic itself.
String presenceTopicFor(String identityId) => '$identityId/will';

/// A central's live online/offline state, read from the retained MQTT
/// Last-Will message on its presence topic. Readable by any authenticated
/// user who knows the central's identityId — no per-relationship grant.
enum PresenceStatus { unknown, online, offline }

final presenceStatusProvider = Provider.family<PresenceStatus, String>((ref, identityId) {
  final msgAsync = ref.watch(iotMessageStreamProvider(presenceTopicFor(identityId)));
  final payload = msgAsync.valueOrNull?.payload;
  if (payload == null) return PresenceStatus.unknown;

  try {
    final status = (jsonDecode(payload) as Map<String, dynamic>)['status'] as String?;
    return status == 'online' ? PresenceStatus.online : PresenceStatus.offline;
  } catch (_) {
    return PresenceStatus.unknown;
  }
});
