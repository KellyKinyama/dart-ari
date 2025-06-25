//  ParameterName                      : ParameterValue
//  ===================================================================================================
//  100rel                             : yes
//  accept_multiple_sdp_answers        : false
//  accountcode                        :
//  acl                                :
//  aggregate_mwi                      : true
//  allow                              : (opus|alaw|vp9|vp8|g729)
//  allow_overlap                      : true
//  allow_subscribe                    : true
//  allow_transfer                     : true
//  allow_unauthenticated_options      : false
//  aors                               : 8988
//  asymmetric_rtp_codec               : false
//  auth                               : 8988
//  bind_rtp_to_media_address          : false
//  bundle                             : true
//  call_group                         :
//  callerid                           : "Conrad de Wet" <8988>
//  callerid_privacy                   : allowed_not_screened
//  callerid_tag                       :
//  codec_prefs_incoming_answer        : prefer:pending, operation:intersect, keep:all, transcode:allow
//  codec_prefs_incoming_offer         : prefer:pending, operation:intersect, keep:all, transcode:allow
//  codec_prefs_outgoing_answer        : prefer:pending, operation:intersect, keep:all, transcode:allow
//  codec_prefs_outgoing_offer         : prefer:pending, operation:union, keep:all, transcode:allow
//  connected_line_method              : invite
//  contact_acl                        :
//  context                            : from-zesco
//  cos_audio                          : 0
//  cos_video                          : 0
//  device_state_busy_at               : 1
//  direct_media                       : false
//  direct_media_glare_mitigation      : none
//  direct_media_method                : invite
//  disable_direct_media_on_nat        : false
//  dtls_auto_generate_cert            : Yes
//  dtls_ca_file                       :
//  dtls_ca_path                       :
//  dtls_cert_file                     :
//  dtls_cipher                        :
//  dtls_fingerprint                   : SHA-256
//  dtls_private_key                   :
//  dtls_rekey                         : 0
//  dtls_setup                         : actpass
//  dtls_verify                        : Yes
//  dtmf_mode                          : rfc4733
//  fax_detect                         : false
//  fax_detect_timeout                 : 0
//  follow_early_media_fork            : true
//  force_avp                          : false
//  force_rport                        : true
//  from_domain                        :
//  from_user                          :
//  g726_non_standard                  : false
//  geoloc_incoming_call_profile       :
//  geoloc_outgoing_call_profile       :
//  ice_support                        : true
//  identify_by                        : username,ip
//  ignore_183_without_sdp             : false
//  inband_progress                    : false
//  incoming_call_offer_pref           : local
//  incoming_mwi_mailbox               :
//  language                           :
//  mailboxes                          :
//  max_audio_streams                  : 1
//  max_video_streams                  : 1
//  media_address                      :
//  media_encryption                   : dtls
//  media_encryption_optimistic        : false
//  media_use_received_transport       : true
//  message_context                    : textmessages
//  moh_passthrough                    : false
//  moh_suggest                        : default
//  mwi_from_user                      :
//  mwi_subscribe_replaces_unsolicited : no
//  named_call_group                   :
//  named_pickup_group                 :
//  notify_early_inuse_ringing         : false
//  one_touch_recording                : false
//  outbound_auth                      :
//  outbound_proxy                     :
//  outgoing_call_offer_pref           : remote_merge
//  overlap_context                    :
//  pickup_group                       :
//  preferred_codec_only               : false
//  record_off_feature                 : automixmon
//  record_on_feature                  : automixmon
//  refer_blind_progress               : true
//  rewrite_contact                    : false
//  rpid_immediate                     : false
//  rtcp_mux                           : true
//  rtp_engine                         : asterisk
//  rtp_ipv6                           : false
//  rtp_keepalive                      : 0
//  rtp_symmetric                      : false
//  rtp_timeout                        : 120
//  rtp_timeout_hold                   : 0
//  sdp_owner                          : -
//  sdp_session                        : Asterisk
//  security_negotiation               : no
//  send_aoc                           : false
//  send_connected_line                : yes
//  send_diversion                     : true
//  send_history_info                  : false
//  send_pai                           : false
//  send_rpid                          : false
//  set_var                            :
//  srtp_tag_32                        : false
//  stir_shaken                        : no
//  stir_shaken_profile                :
//  sub_min_expiry                     : 0
//  subscribe_context                  : subscriptions
//  suppress_q850_reason_headers       : false
//  t38_bind_udptl_to_media_address    : false
//  t38_udptl                          : false
//  t38_udptl_ec                       : none
//  t38_udptl_ipv6                     : false
//  t38_udptl_maxdatagram              : 0
//  t38_udptl_nat                      : false
//  tenantid                           :
//  timers                             : yes
//  timers_min_se                      : 90
//  timers_sess_expires                : 1800
//  tone_zone                          :
//  tos_audio                          : 0
//  tos_video                          : 0
//  transport                          : transport-wss
//  trust_connected_line               : yes
//  trust_id_inbound                   : false
//  trust_id_outbound                  : false
//  use_avpf                           : true
//  use_ptime                          : false
//  user_eq_phone                      : false
//  voicemail_extension                :
//  webrtc                             : yes

final Map<String, dynamic> endpointPush = {
  "fields": [
    {"attribute": "100rel", "value": "yes"},
    {"attribute": "accept_multiple_sdp_answers", "value": "false"},
    {"attribute": "accountcode", "value": ""},
    {"attribute": "acl", "value": ""},
    {"attribute": "aggregate_mwi", "value": "true"},
    {"attribute": "allow", "value": "(opus|alaw|vp9|vp8|g729)"},
    {"attribute": "allow_overlap", "value": "true"},
    {"attribute": "allow_subscribe", "value": "true"},
    {"attribute": "allow_transfer", "value": "true"},
    {"attribute": "allow_unauthenticated_options", "value": "false"},
    {"attribute": "aors", "value": "8988"},
    {"attribute": "asymmetric_rtp_codec", "value": "false"},
    {"attribute": "auth", "value": "8988"},
    {"attribute": "bind_rtp_to_media_address", "value": "false"},
    {"attribute": "bundle", "value": "true"},
    {"attribute": "call_group", "value": ""},
    {"attribute": "callerid", "value": "\"Conrad de Wet\" <8988>"},
    {"attribute": "callerid_privacy", "value": "allowed_not_screened"},
    {"attribute": "callerid_tag", "value": ""},
    {
      "attribute": "codec_prefs_incoming_answer",
      "value": "prefer:pending, operation:intersect, keep:all, transcode:allow"
    },
    {
      "attribute": "codec_prefs_incoming_offer",
      "value": "prefer:pending, operation:intersect, keep:all, transcode:allow"
    },
    {
      "attribute": "codec_prefs_outgoing_answer",
      "value": "prefer:pending, operation:intersect, keep:all, transcode:allow"
    },
    {
      "attribute": "codec_prefs_outgoing_offer",
      "value": "prefer:pending, operation:union, keep:all, transcode:allow"
    },
    {"attribute": "connected_line_method", "value": "invite"},
    {"attribute": "contact_acl", "value": ""},
    {"attribute": "context", "value": "from-zesco"},
    {"attribute": "cos_audio", "value": "0"},
    {"attribute": "cos_video", "value": "0"},
    {"attribute": "device_state_busy_at", "value": "1"},
    {"attribute": "direct_media", "value": "false"},
    {"attribute": "direct_media_glare_mitigation", "value": "none"},
    {"attribute": "direct_media_method", "value": "invite"},
    {"attribute": "disable_direct_media_on_nat", "value": "false"},
    {"attribute": "dtls_auto_generate_cert", "value": "Yes"},
    {"attribute": "dtls_ca_file", "value": ""},
    {"attribute": "dtls_ca_path", "value": ""},
    {"attribute": "dtls_cert_file", "value": ""},
    {"attribute": "dtls_cipher", "value": ""},
    {"attribute": "dtls_fingerprint", "value": "SHA-256"},
    {"attribute": "dtls_private_key", "value": ""},
    {"attribute": "dtls_rekey", "value": "0"},
    {"attribute": "dtls_setup", "value": "actpass"},
    {"attribute": "dtls_verify", "value": "Yes"},
    {"attribute": "dtmf_mode", "value": "rfc4733"},
    {"attribute": "fax_detect", "value": "false"},
    {"attribute": "fax_detect_timeout", "value": "0"},
    {"attribute": "follow_early_media_fork", "value": "true"},
    {"attribute": "force_avp", "value": "false"},
    {"attribute": "force_rport", "value": "true"},
    {"attribute": "from_domain", "value": ""},
    {"attribute": "from_user", "value": ""},
    {"attribute": "g726_non_standard", "value": "false"},
    {"attribute": "geoloc_incoming_call_profile", "value": ""},
    {"attribute": "geoloc_outgoing_call_profile", "value": ""},
    {"attribute": "ice_support", "value": "true"},
    {"attribute": "identify_by", "value": "username,ip"},
    {"attribute": "ignore_183_without_sdp", "value": "false"},
    {"attribute": "inband_progress", "value": "false"},
    {"attribute": "incoming_call_offer_pref", "value": "local"},
    {"attribute": "incoming_mwi_mailbox", "value": ""},
    {"attribute": "language", "value": ""},
    {"attribute": "mailboxes", "value": ""},
    {"attribute": "max_audio_streams", "value": "1"},
    {"attribute": "max_video_streams", "value": "1"},
    {"attribute": "media_address", "value": ""},
    {"attribute": "media_encryption", "value": "dtls"},
    {"attribute": "media_encryption_optimistic", "value": "false"},
    {"attribute": "media_use_received_transport", "value": "true"},
    {"attribute": "message_context", "value": "textmessages"},
    {"attribute": "moh_passthrough", "value": "false"},
    {"attribute": "moh_suggest", "value": "default"},
    {"attribute": "mwi_from_user", "value": ""},
    {"attribute": "mwi_subscribe_replaces_unsolicited", "value": "no"},
    {"attribute": "named_call_group", "value": ""},
    {"attribute": "named_pickup_group", "value": ""},
    {"attribute": "notify_early_inuse_ringing", "value": "false"},
    {"attribute": "one_touch_recording", "value": "false"},
    {"attribute": "outbound_auth", "value": ""},
    {"attribute": "outbound_proxy", "value": ""},
    {"attribute": "outgoing_call_offer_pref", "value": "remote_merge"},
    {"attribute": "overlap_context", "value": ""},
    {"attribute": "pickup_group", "value": ""},
    {"attribute": "preferred_codec_only", "value": "false"},
    {"attribute": "record_off_feature", "value": "automixmon"},
    {"attribute": "record_on_feature", "value": "automixmon"},
    {"attribute": "refer_blind_progress", "value": "true"},
    {"attribute": "rewrite_contact", "value": "false"},
    {"attribute": "rpid_immediate", "value": "false"},
    {"attribute": "rtcp_mux", "value": "true"},
    {"attribute": "rtp_engine", "value": "asterisk"},
    {"attribute": "rtp_ipv6", "value": "false"},
    {"attribute": "rtp_keepalive", "value": "0"},
    {"attribute": "rtp_symmetric", "value": "false"},
    {"attribute": "rtp_timeout", "value": "120"},
    {"attribute": "rtp_timeout_hold", "value": "0"},
    {"attribute": "sdp_owner", "value": "-"},
    {"attribute": "sdp_session", "value": "Asterisk"},
    {"attribute": "security_negotiation", "value": "no"},
    {"attribute": "send_aoc", "value": "false"},
    {"attribute": "send_connected_line", "value": "yes"},
    {"attribute": "send_diversion", "value": "true"},
    {"attribute": "send_history_info", "value": "false"},
    {"attribute": "send_pai", "value": "false"},
    {"attribute": "send_rpid", "value": "false"},
    {"attribute": "set_var", "value": ""},
    {"attribute": "srtp_tag_32", "value": "false"},
    {"attribute": "stir_shaken", "value": "no"},
    {"attribute": "stir_shaken_profile", "value": ""},
    {"attribute": "sub_min_expiry", "value": "0"},
    {"attribute": "subscribe_context", "value": "subscriptions"},
    {"attribute": "suppress_q850_reason_headers", "value": "false"},
    {"attribute": "t38_bind_udptl_to_media_address", "value": "false"},
    {"attribute": "t38_udptl", "value": "false"},
    {"attribute": "t38_udptl_ec", "value": "none"},
    {"attribute": "t38_udptl_ipv6", "value": "false"},
    {"attribute": "t38_udptl_maxdatagram", "value": "0"},
    {"attribute": "t38_udptl_nat", "value": "false"},
    {"attribute": "tenantid", "value": ""},
    {"attribute": "timers", "value": "yes"},
    {"attribute": "timers_min_se", "value": "90"},
    {"attribute": "timers_sess_expires", "value": "1800"},
    {"attribute": "tone_zone", "value": ""},
    {"attribute": "tos_audio", "value": "0"},
    {"attribute": "tos_video", "value": "0"},
    {"attribute": "transport", "value": "transport-wss"},
    {"attribute": "trust_connected_line", "value": "yes"},
    {"attribute": "trust_id_inbound", "value": "false"},
    {"attribute": "trust_id_outbound", "value": "false"},
    {"attribute": "use_avpf", "value": "true"},
    {"attribute": "use_ptime", "value": "false"},
    {"attribute": "user_eq_phone", "value": "false"},
    {"attribute": "voicemail_extension", "value": ""},
    {"attribute": "webrtc", "value": "yes"}
  ]
};

Map<String, dynamic> auth = {
  "fields": [
    {"attribute": "auth_type", "value": "userpass"},
    {"attribute": "username", "value": "8988"},
    {"attribute": "password", "value": "8988"}
  ]
};


Map<String, dynamic> aor = {
  "fields": [
    {"attribute": "max_contacts", "value": "1"},
    {"attribute": "qualify_frequency", "value": "60"},
    {"attribute": "outbound_proxy", "value": ""},
    {"attribute": "support_path", "value": "yes"},
    {"attribute": "rtp_timeout", "value": "120"},
    {"attribute": "rtp_timeout_hold", "value": "0"}
  ]
};

{
    "fields": [
         {
              "attribute": "support_path", 
              "value": "yes"
        },
        {
            "attribute": "remove_existing",
             "value": "yes"
        },
        {
            "attribute": "max_contacts",
             "value": "1"}
     ]
     
}

Map<String,dynamic> mytrunkAor= 
{
    "fields": [
         {
  "attribute":"authenticate_qualify","value": "false"},
 {
  "attribute":"contact" ,"value"             : "sip:10.44.0.56:5060"},
 



 {"attribute":"support_path"  ,"value"       : "false"}

    ]
    };

    Map<String, dynamic> mytrunkEndpoint = {
    "fields": [
        {
            "attribute": "100rel",
            "value": "yes"
        },
        {
            "attribute": "accept_multiple_sdp_answers",
            "value": "false"
        },
        {
            "attribute": "accountcode",
            "value": ""
        },
        {
            "attribute": "acl",
            "value": ""
        },
        {
            "attribute": "aggregate_mwi",
            "value": "true"
        },
        {
            "attribute": "allow",
            "value": "(alaw|g722|g729)"
        },
        {
            "attribute": "allow_overlap",
            "value": "true"
        },
        {
            "attribute": "allow_subscribe",
            "value": "true"
        },
        {
            "attribute": "allow_transfer",
            "value": "true"
        },
        {
            "attribute": "allow_unauthenticated_options",
            "value": "false"
        },
        {
            "attribute": "aors",
            "value": "mytrunk"
        },
        {
            "attribute": "asymmetric_rtp_codec",
            "value": "false"
        },
        {
            "attribute": "auth",
            "value": ""
        },
        {
            "attribute": "bind_rtp_to_media_address",
            "value": "false"
        },
        {
            "attribute": "bundle",
            "value": "false"
        },
        {
            "attribute": "call_group",
            "value": ""
        },
        {
            "attribute": "callerid",
            "value": "<unknown>"
        },
        {
            "attribute": "callerid_privacy",
            "value": "allowed_not_screened"
        },
        {
            "attribute": "callerid_tag",
            "value": ""
        },
        {
            "attribute": "codec_prefs_incoming_answer",
            "value": "prefer:pending, operation:intersect, keep:all, transcode:allow"
        },
        {
            "attribute": "codec_prefs_incoming_offer",
            "value": "prefer:pending, operation:intersect, keep:all, transcode:allow"
        },
        {
            "attribute": "codec_prefs_outgoing_answer",
            "value": "prefer:pending, operation:intersect, keep:all, transcode:allow"
        },
        {
            "attribute": "codec_prefs_outgoing_offer",
            "value": "prefer:pending, operation:union, keep:all, transcode:allow"
        },
        {
            "attribute": "connected_line_method",
            "value": "invite"
        },
        {
            "attribute": "contact_acl",
            "value": ""
        },
        {
            "attribute": "context",
            "value": "from-zesco"
        },
        {
            "attribute": "cos_audio",
            "value": "0"
        },
        {
            "attribute": "cos_video",
            "value": "0"
        },
        {
            "attribute": "device_state_busy_at",
            "value": "0"
        },
        {
            "attribute": "direct_media",
            "value": "false"
        },
        {
            "attribute": "direct_media_glare_mitigation",
            "value": "none"
        },
        {
            "attribute": "direct_media_method",
            "value": "invite"
        },
        {
            "attribute": "disable_direct_media_on_nat",
            "value": "false"
        },
        {
            "attribute": "dtls_auto_generate_cert",
            "value": "No"
        },
        {
            "attribute": "dtls_ca_file",
            "value": ""
        },
        {
            "attribute": "dtls_ca_path",
            "value": ""
        },
        {
            "attribute": "dtls_cert_file",
            "value": ""
        },
        {
            "attribute": "dtls_cipher",
            "value": ""
        },
        {
            "attribute": "dtls_fingerprint",
            "value": "SHA-256"
        },
        {
            "attribute": "dtls_private_key",
            "value": ""
        },
        {
            "attribute": "dtls_rekey",
            "value": "0"
        },
        {
            "attribute": "dtls_setup",
            "value": "active"
        },
        {
            "attribute": "dtls_verify",
            "value": "No"
        },
        {
            "attribute": "dtmf_mode",
            "value": "rfc4733"
        },
        {
            "attribute": "fax_detect",
            "value": "false"
        },
        {
            "attribute": "fax_detect_timeout",
            "value": "0"
        },
        {
            "attribute": "follow_early_media_fork",
            "value": "true"
        },
        {
            "attribute": "force_avp",
            "value": "false"
        },
        {
            "attribute": "force_rport",
            "value": "true"
        },
        {
            "attribute": "from_domain",
            "value": ""
        },
        {
            "attribute": "from_user",
            "value": ""
        },
        {
            "attribute": "g726_non_standard",
            "value": "false"
        },
        {
            "attribute": "geoloc_incoming_call_profile",
            "value": ""
        },
        {
            "attribute": "geoloc_outgoing_call_profile",
            "value": ""
        },
        {
            "attribute": "ice_support",
            "value": "true"
        },
        {
            "attribute": "identify_by",
            "value": "username,ip"
        },
        {
            "attribute": "ignore_183_without_sdp",
            "value": "false"
        },
        {
            "attribute": "inband_progress",
            "value": "false"
        },
        {
            "attribute": "incoming_call_offer_pref",
            "value": "local"
        },
        {
            "attribute": "incoming_mwi_mailbox",
            "value": ""
        },
        {
            "attribute": "language",
            "value": ""
        },
        {
            "attribute": "mailboxes",
            "value": ""
        },
        {
            "attribute": "max_audio_streams",
            "value": "1"
        },
        {
            "attribute": "max_video_streams",
            "value": "1"
        },
        {
            "attribute": "media_address",
            "value": ""
        },
        {
            "attribute": "media_encryption",
            "value": "no"
        },
        {
            "attribute": "media_encryption_optimistic",
            "value": "false"
        },
        {
            "attribute": "media_use_received_transport",
            "value": "false"
        },
        {
            "attribute": "message_context",
            "value": ""
        },
        {
            "attribute": "moh_passthrough",
            "value": "false"
        },
        {
            "attribute": "moh_suggest",
            "value": "default"
        },
        {
            "attribute": "mwi_from_user",
            "value": ""
        },
        {
            "attribute": "mwi_subscribe_replaces_unsolicited",
            "value": "no"
        },
        {
            "attribute": "named_call_group",
            "value": ""
        },
        {
            "attribute": "named_pickup_group",
            "value": ""
        },
        {
            "attribute": "notify_early_inuse_ringing",
            "value": "false"
        },
        {
            "attribute": "one_touch_recording",
            "value": "false"
        },
        {
            "attribute": "outbound_auth",
            "value": ""
        },
        {
            "attribute": "outbound_proxy",
            "value": ""
        },
        {
            "attribute": "outgoing_call_offer_pref",
            "value": "remote_merge"
        },
        {
            "attribute": "overlap_context",
            "value": ""
        },
        {
            "attribute": "pickup_group",
            "value": ""
        },
        {
            "attribute": "preferred_codec_only",
            "value": "false"
        },
        {
            "attribute": "record_off_feature",
            "value": "automixmon"
        },
        {
            "attribute": "record_on_feature",
            "value": "automixmon"
        },
        {
            "attribute": "refer_blind_progress",
            "value": "true"
        },
        {
            "attribute": "rewrite_contact",
            "value": "false"
        },
        {
            "attribute": "rpid_immediate",
            "value": "false"
        },
        {
            "attribute": "rtcp_mux",
            "value": "false"
        },
        {
            "attribute": "rtp_engine",
            "value": "asterisk"
        },
        {
            "attribute": "rtp_ipv6",
            "value": "false"
        },
        {
            "attribute": "rtp_keepalive",
            "value": "0"
        },
        {
            "attribute": "rtp_symmetric",
            "value": "false"
        },
        {
            "attribute": "rtp_timeout",
            "value": "0"
        },
        {
            "attribute": "rtp_timeout_hold",
            "value": "0"
        },
        {
            "attribute": "sdp_owner",
            "value": "-"
        },
        {
            "attribute": "sdp_session",
            "value": "Asterisk"
        },
        {
            "attribute": "security_negotiation",
            "value": "no"
        },
        {
            "attribute": "send_aoc",
            "value": "false"
        },
        {
            "attribute": "send_connected_line",
            "value": "yes"
        },
        {
            "attribute": "send_diversion",
            "value": "true"
        },
        {
            "attribute": "send_history_info",
            "value": "false"
        },
        {
            "attribute": "send_pai",
            "value": "false"
        },
        {
            "attribute": "send_rpid",
            "value": "false"
        },
        {
            "attribute": "set_var",
            "value": ""
        },
        {
            "attribute": "srtp_tag_32",
            "value": "false"
        },
        {
            "attribute": "stir_shaken",
            "value": "no"
        },
        {
            "attribute": "stir_shaken_profile",
            "value": ""
        },
        {
            "attribute": "sub_min_expiry",
            "value": "0"
        },
        {
            "attribute": "subscribe_context",
            "value": ""
        },
        {
            "attribute": "suppress_q850_reason_headers",
            "value": "false"
        },
        {
            "attribute": "t38_bind_udptl_to_media_address",
            "value": "false"
        },
        {
            "attribute": "t38_udptl",
            "value": "false"
        },
        {
            "attribute": "t38_udptl_ec",
            "value": "none"
        },
        {
            "attribute": "t38_udptl_ipv6",
            "value": "false"
        },
        {
            "attribute": "t38_udptl_maxdatagram",
            "value": "0"
        },
        {
            "attribute": "t38_udptl_nat",
            "value": "false"
        },
        {
            "attribute": "tenantid",
            "value": ""
        },
        {
            "attribute": "timers",
            "value": "yes"
        },
        {
            "attribute": "timers_min_se",
            "value": "90"
        },
        {
            "attribute": "timers_sess_expires",
            "value": "1800"
        },
        {
            "attribute": "tone_zone",
            "value": ""
        },
        {
            "attribute": "tos_audio",
            "value": "0"
        },
        {
            "attribute": "tos_video",
            "value": "0"
        },
        {
            "attribute": "transport",
            "value": "transport-udp"
        },
        {
            "attribute": "trust_connected_line",
            "value": "yes"
        },
        {
            "attribute": "trust_id_inbound",
            "value": "false"
        },
        {
            "attribute": "trust_id_outbound",
            "value": "false"
        },
        {
            "attribute": "use_avpf",
            "value": "false"
        },
        {
            "attribute": "use_ptime",
            "value": "false"
        },
        {
            "attribute": "user_eq_phone",
            "value": "false"
        },
        {
            "attribute": "voicemail_extension",
            "value": ""
        },
        {
            "attribute": "webrtc",
            "value": "no"
        }
    ]
}