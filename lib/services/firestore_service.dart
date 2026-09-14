import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  Future<void> saveProfile(AppUser user) {
    return _users.doc(user.uid).set(user.toMap(), SetOptions(merge: true));
  }

  /// A doc only counts as a real profile once onboarding has actually run.
  /// (A stub doc can exist earlier than that - e.g. an FCM token save that
  /// creates the document with `SetOptions(merge: true)` before the user
  /// has filled in a name.)
  bool _isOnboarded(Map<String, dynamic> data) {
    final name = data['name'];
    return name is String && name.isNotEmpty;
  }

  Future<AppUser?> getProfile(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists || !_isOnboarded(doc.data()!)) return null;
    return AppUser.fromMap(doc.id, doc.data()!);
  }

  Stream<AppUser?> profileStream(String uid) {
    return _users.doc(uid).snapshots().map((doc) {
      if (!doc.exists || !_isOnboarded(doc.data()!)) return null;
      return AppUser.fromMap(doc.id, doc.data()!);
    });
  }

  /// Straight (opposite-gender) matching for Man/Woman; "Other" is shown to
  /// and sees everyone, so it isn't left with an empty deck.
  bool _canSee(String myGender, String candidateGender) {
    if (myGender == 'Other' || candidateGender == 'Other') return true;
    return myGender != candidateGender;
  }

  /// Fetches a batch of candidate profiles for the discover deck, excluding
  /// the current user, anyone already liked, and anyone outside the current
  /// user's shown-to gender group. People passed on are deliberately kept
  /// in - the deck loops back over them rather than exhausting for good.
  Future<List<AppUser>> getDiscoverCandidates(
    String myUid, {
    required String myGender,
  }) async {
    final swipedSnap = await _db
        .collection('swipes')
        .doc(myUid)
        .collection('targets')
        .get();
    final likedIds = swipedSnap.docs
        .where((d) => d.data()['liked'] == true)
        .map((d) => d.id)
        .toSet();

    final usersSnap = await _users.limit(100).get();
    final candidates = usersSnap.docs
        .where((d) =>
            d.id != myUid &&
            !likedIds.contains(d.id) &&
            _isOnboarded(d.data()) &&
            _canSee(myGender, d.data()['gender'] as String? ?? ''))
        .map((d) => AppUser.fromMap(d.id, d.data()))
        .toList();
    candidates.shuffle();
    return candidates;
  }

  static String matchIdFor(String uidA, String uidB) {
    final ids = [uidA, uidB]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  /// Records a swipe. Returns the matched user's uid if this swipe created
  /// a mutual match, otherwise null.
  Future<String?> recordSwipe({
    required String myUid,
    required String targetUid,
    required bool liked,
  }) async {
    await _db
        .collection('swipes')
        .doc(myUid)
        .collection('targets')
        .doc(targetUid)
        .set({'liked': liked, 'at': FieldValue.serverTimestamp()});

    if (!liked) return null;

    final theirSwipe = await _db
        .collection('swipes')
        .doc(targetUid)
        .collection('targets')
        .doc(myUid)
        .get();

    final theyLikedMe = theirSwipe.exists && theirSwipe.data()?['liked'] == true;
    if (!theyLikedMe) return null;

    final matchId = matchIdFor(myUid, targetUid);
    await _db.collection('matches').doc(matchId).set({
      'users': [myUid, targetUid],
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessage': '',
      'lastMessageAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return targetUid;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> matchesStream(String myUid) {
    return _db
        .collection('matches')
        .where('users', arrayContains: myUid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots();
  }

  Future<DateTime?> getMatchCreatedAt(String matchId) async {
    final doc = await _db.collection('matches').doc(matchId).get();
    final timestamp = doc.data()?['createdAt'] as Timestamp?;
    return timestamp?.toDate();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> messagesStream(String matchId) {
    return _db
        .collection('matches')
        .doc(matchId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  Future<void> sendMessage({
    required String matchId,
    required String senderId,
    required String text,
  }) async {
    final matchRef = _db.collection('matches').doc(matchId);
    await matchRef.collection('messages').add({
      'senderId': senderId,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await matchRef.set({
      'lastMessage': text,
      'lastMessageAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
