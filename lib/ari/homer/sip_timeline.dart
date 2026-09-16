import 'homer_client.dart';

/// The per-call SIP timeline derived from Homer's message stream, plus
/// a classification of who ended the call. Mirrors the Laravel
/// `stasis_call_sip_timeline` table.
class SipTimeline {
  SipTimeline({
    this.inviteAt,
    this.ringingAt,
    this.answeredAt,
    this.agentAnsweredAt,
    this.byeAt,
    this.cancelAt,
    this.terminatedAt,
    this.hangupInitiator,
    this.hangupMethod,
    this.hangupStatusCode,
    this.hangupBy,
  });

  final DateTime? inviteAt;
  final DateTime? ringingAt;
  final DateTime? answeredAt;

  /// The moment the media (SDP `c=IN IP4 …`) first leaves the B2BUA anchor
  /// (e.g. OXE at 10.1.8.226) and lands on a real agent phone IP. This is
  /// the true "agent picked up" time. Null if the media never left the
  /// anchor (call handled entirely by the system / never reached an agent).
  ///
  /// Distinct from [answeredAt], which is the first 200 OK — in a B2BUA
  /// topology that is the anchor auto-answering, so `answeredAt ≈ inviteAt`
  /// (ring 0) while the human answer happens later at [agentAnsweredAt].
  final DateTime? agentAnsweredAt;

  final DateTime? byeAt;
  final DateTime? cancelAt;
  final DateTime? terminatedAt;

  /// `caller` | `callee` | `system` | `unknown`
  final String? hangupInitiator;

  /// `BYE` | `CANCEL` | `FAILURE` | null
  final String? hangupMethod;

  /// Final SIP status code observed on the terminating transaction
  /// (200 for a normal BYE-ACK, 487 for CANCEL, 486/5xx/6xx for
  /// failures).
  final int? hangupStatusCode;

  /// Business-meaning label: `customer` | `agent` | `system` | `unknown`.
  /// Independent of raw SIP direction — computed by comparing the SIP
  /// party that sent BYE against the known customer phone number.
  final String? hangupBy;

  Map<String, dynamic> toJson() => {
    if (inviteAt != null) 'invite_at': inviteAt!.toIso8601String(),
    if (ringingAt != null) 'ringing_at': ringingAt!.toIso8601String(),
    if (answeredAt != null) 'answered_at': answeredAt!.toIso8601String(),
    if (agentAnsweredAt != null)
      'agent_answered_at': agentAnsweredAt!.toIso8601String(),
    if (byeAt != null) 'bye_at': byeAt!.toIso8601String(),
    if (cancelAt != null) 'cancel_at': cancelAt!.toIso8601String(),
    if (terminatedAt != null) 'terminated_at': terminatedAt!.toIso8601String(),
    if (hangupInitiator != null) 'hangup_initiator': hangupInitiator,
    if (hangupMethod != null) 'hangup_method': hangupMethod,
    if (hangupStatusCode != null) 'hangup_status_code': hangupStatusCode,
  };

  /// Walk one dialog's chronological message list and reduce it to
  /// the timeline columns.
  ///
  /// [callerFromUser] is the SIP `From` user of the ORIGINAL INVITE — we
  /// compare against it to decide who sent the BYE:
  ///
  ///   - BYE.From == INVITE.From  →  caller hung up (in-dialog BYE
  ///                                 puts the sending party in From)
  ///   - BYE.From == INVITE.To    →  callee hung up
  ///   - CANCEL                  →  caller (SIP semantics)
  ///   - only 4xx/5xx/6xx final  →  system (Asterisk/proxy rejected)
  ///   - none of the above       →  unknown
  ///
  /// [customerNumber] is the business-side phone number (Laravel's
  /// `recordings.src`). When supplied, `hangupBy` is derived by
  /// digit-suffix-matching the BYE's `From` user against it — giving a
  /// topology-independent `customer` | `agent` | `system` | `unknown`
  /// classification. This works correctly whether Asterisk saw the INVITE
  /// from the customer side directly or from a B2BUA acting on behalf of
  /// the agent (OXE, etc.), which invert the raw SIP direction.
  static SipTimeline reduce(
    List<HomerMessage> messages, {
    String? callerFromUser,
    String? customerNumber,
    List<String> mediaAnchorPrefixes = const ['10.1.8.', '10.1.101.'],
  }) {
    DateTime? inviteAt;
    DateTime? ringingAt;
    DateTime? answeredAt;
    DateTime? agentAnsweredAt;
    DateTime? byeAt;
    DateTime? cancelAt;
    DateTime? terminatedAt;
    String? byeFrom;
    int? lastFinalCode;

    for (final m in messages) {
      terminatedAt = m.createDate;

      // Detect the media leaving the B2BUA anchor → real agent pickup.
      // Any message may carry SDP (INVITE, re-INVITE, 200 OK); the first
      // one whose c=IN IP4 is not an anchor IP marks the agent answer.
      if (agentAnsweredAt == null) {
        final ip = m.sdp?.ip;
        if (ip != null &&
            ip.isNotEmpty &&
            !mediaAnchorPrefixes.any(ip.startsWith)) {
          agentAnsweredAt = m.createDate;
        }
      }

      final method = m.method ?? '';
      if (method == 'INVITE') {
        inviteAt ??= m.createDate;
      } else if (method == 'BYE') {
        if (byeAt == null) {
          byeAt = m.createDate;
          byeFrom = m.fromUser;
        }
      } else if (method == 'CANCEL') {
        cancelAt ??= m.createDate;
      } else if (m.isResponse) {
        final code = m.statusCode;
        if (code == null) continue;
        if (code == 180) {
          ringingAt ??= m.createDate;
        } else if (code == 200 &&
            (m.cseq ?? '').toUpperCase().contains('INVITE')) {
          answeredAt ??= m.createDate;
        }
        if (code >= 400) {
          lastFinalCode = code;
        } else if (code >= 200) {
          lastFinalCode ??= code;
        }
      }
    }

    String? initiator;
    String? hangupMethod;
    int? statusCode;

    if (byeAt != null) {
      hangupMethod = 'BYE';
      statusCode = 200;
      if (callerFromUser != null && byeFrom != null) {
        initiator = (byeFrom == callerFromUser) ? 'caller' : 'callee';
      } else {
        initiator = 'unknown';
      }
    } else if (cancelAt != null) {
      hangupMethod = 'CANCEL';
      statusCode = 487;
      initiator = 'caller';
    } else if (lastFinalCode != null && lastFinalCode >= 400) {
      hangupMethod = 'FAILURE';
      statusCode = lastFinalCode;
      initiator = 'system';
    } else {
      initiator = 'unknown';
    }

    // Business classification. Compare the terminating party's From-user
    // digit-suffix against the known customer number — topology-independent.
    String? hangupBy;
    final custSuffix = _digitSuffix(customerNumber);
    if (hangupMethod == 'FAILURE') {
      hangupBy = 'system';
    } else if (hangupMethod == 'BYE' && byeFrom != null && custSuffix != null) {
      final bs = _digitSuffix(byeFrom);
      hangupBy = (bs != null && bs == custSuffix) ? 'customer' : 'agent';
    } else if (hangupMethod == 'CANCEL' && custSuffix != null) {
      // CANCEL is always from the caller side of the SIP dialog. If that
      // matches the customer, it's a caller-side abandon; otherwise the
      // B2BUA/agent gave up before answer.
      final invFromSuffix = _digitSuffix(callerFromUser);
      hangupBy = (invFromSuffix != null && invFromSuffix == custSuffix)
          ? 'customer'
          : 'agent';
    } else if (hangupMethod != null) {
      hangupBy = 'unknown';
    }

    return SipTimeline(
      inviteAt: inviteAt,
      ringingAt: ringingAt,
      answeredAt: answeredAt,
      agentAnsweredAt: agentAnsweredAt,
      byeAt: byeAt,
      cancelAt: cancelAt,
      terminatedAt: terminatedAt,
      hangupInitiator: initiator,
      hangupMethod: hangupMethod,
      hangupStatusCode: statusCode,
      hangupBy: hangupBy,
    );
  }

  /// Extract the last 9 digits of [v] for suffix comparison. Returns
  /// null if [v] has fewer than 7 digits (too short to be a phone number).
  static String? _digitSuffix(String? v) {
    if (v == null) return null;
    final digits = v.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 7) return null;
    return digits.length <= 9 ? digits : digits.substring(digits.length - 9);
  }
}
