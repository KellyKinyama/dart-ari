 sudo journalctl -u ari_proxy.service -r

 dart compile exe  bin/dart_ari.dart --target-os=linux  

  sudo asterisk -rx "core show channels"

  

   sudo asterisk -rx "dialplan show globals"

---

## ARI call recorder

Docs moved to [docs/ari-recorder/](docs/ari-recorder/README.md).

- [How to run bin/record_calls.dart](docs/ari-recorder/how-to-run.md)
- [Externalmedia daemon protocol](docs/ari-recorder/daemon-protocol.md)
- [Library API additions (dart_ari)](docs/ari-recorder/library-api.md)
- [Implementation notes / gotchas](docs/ari-recorder/implementation-notes.md)
