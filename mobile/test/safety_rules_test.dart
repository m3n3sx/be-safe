import 'package:alertmap/family/invite_link.dart';
import 'package:alertmap/map/marker_collision.dart';
import 'package:alertmap/services/signal_dedup.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('invite parser accepts the canonical link and rejects other hosts', () {
    expect(parseInvite('https://besafe.org.pl/family/join?code=ab12cd34'), 'AB12CD34');
    expect(parseInvite('besafe://family/join/AB12CD34'), 'AB12CD34');
    expect(parseInvite('https://evil.example/family/join?code=AB12CD34'), isNull);
    expect(canSelfJoinAs('parent'), isFalse);
    expect(canSelfJoinAs('family_member'), isTrue);
  });

  test('identical coordinates stay put and SOS is listed first', () {
    final items = [
      CollisionItem(id: 'h1', lat: 52.2, lng: 21, kind: 'hazard'),
      CollisionItem(id: 's1', lat: 52.2, lng: 21, kind: 'sos'),
      CollisionItem(id: 'm1', lat: 52.2, lng: 21, kind: 'member'),
    ];
    final groups = clusterItems(items, project: (item) => (x: item.lng, y: item.lat));
    expect(groups, hasLength(1));
    expect(groups.single.displayOnly, isTrue);
    expect(groups.single.items.map((e) => e.id).toList(), ['s1', 'h1', 'm1']);
    expect(groups.single.anchorLat, 52.2);
    expect(groups.single.anchorLng, 21);
    expect(items.first.lat, 52.2);
  });

  test('socket and push copies of one SOS collapse', () {
    final dedup = SignalDedup();
    expect(
      dedup.present({
        'id': 'notif-1',
        'type': 'family_sos',
        'data': {'alert_id': 'alert-9', 'notification_id': 'notif-1'},
      }),
      isTrue,
    );
    expect(
      dedup.present({
        'id': 'notif-1',
        'type': 'family_sos',
        'alert_id': 'alert-9',
        'data': {'alert_id': 'alert-9'},
      }),
      isFalse,
    );
  });

  test('dismiss is not acknowledgement and an expired alarm stays down', () {
    final now = DateTime.utc(2026, 11, 5, 12);
    expect(
      shouldShowSosLatch(
        acknowledged: false,
        alertStatus: 'active',
        expiresAt: now.add(const Duration(hours: 1)),
        now: now,
        shownThisProcess: false,
      ),
      isTrue,
    );
    expect(
      shouldShowSosLatch(
        acknowledged: true,
        alertStatus: 'active',
        expiresAt: now.add(const Duration(hours: 1)),
        now: now,
        shownThisProcess: false,
      ),
      isFalse,
    );
    expect(
      shouldShowSosLatch(
        acknowledged: false,
        alertStatus: 'active',
        expiresAt: now.subtract(const Duration(minutes: 1)),
        now: now,
        shownThisProcess: false,
      ),
      isFalse,
    );
  });
}
