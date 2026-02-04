  847  systemctl restart ari_proxy.service
  848  tail -f recorder.log
  849  chmod +x dart_ari_proxy.exe
  850  systemctl restart ari_proxy.service
  851  tail -f recorder.log
  852  chmod +x dart_ari_proxy.exe
  853  systemctl restart ari_proxy.service
  854  tail -f recorder.log
  855  chmod +x dart_ari_proxy.exe
  856  systemctl restart ari_proxy.service
  857  tail -f recorder.log
  858  chmod +x dart_ari_proxy.exe
  859  systemctl restart ari_proxy.service
  860  tail -f recorder.log
  861  chmod +x dart_ari_proxy.exe
  862  systemctl restart ari_proxy.service
  863  tail -f recorder.log
  864  chmod +x dart_ari_proxy.exe
  865  systemctl restart ari_proxy.service
  866  tail -f recorder.log
  867  chmod +x dart_ari_proxy.exe
  868  systemctl restart ari_proxy.service
  869  tail -f recorder.log
  870  chmod +x dart_ari_proxy.exe
  871  systemctl restart ari_proxy.service
  872  tail -f recorder.log
  873  chmod +x dart_ari_proxy.exe
  874  systemctl restart ari_proxy.service
  875  tail -f recorder.log
  876  chmod +x dart_ari_proxy.exe
  877  systemctl restart ari_proxy.service
  878  chmod +x dart_ari_proxy.exe
  879  systemctl restart ari_proxy.service
  880  tail -f recorder.log
  881  chmod +x dart_ari_proxy.exe
  882  systemctl restart ari_proxy.service
  883  tail -f recorder.log
  884  chmod +x dart_ari_proxy.exe
  885  systemctl restart ari_proxy.service
  886  tail -f recorder.log
  887  cd /etc/asterisk
  888  cp extensions.conf extensions.bsckup_02_02_2026.conf
  889  cd /usr/src/ari_proxy/
  890  chmod +x dart_ari_proxy.exe
  891  systemctl restart ari_proxy.service
  892  systemctl status ari_proxy.service
  893  cd /etc/asterisk
  894  cp extensions.conf extensions.backup_02_02.conf
  895  history
  896  sudo asterisk -rx "dialplan reload"
  897  sudo asterisk -rx "dialplan show"
  898   sudo journalctl -u ari_proxy.service -r
  899  history
  900  sudo asterisk -rx "core show channels"
  901  watch -n 1 "sudo asterisk -rx 'core show channels'"
  902  sudo asterisk -rx "dialplan show"
  903  watch -n 1 "sudo asterisk -rx 'core show channels'"
  904  clear
  905  sudo asterisk -rx "dialplan show globals"
  906  sudo asterisk -rx "dialplan show 7@IVR-14"
  907  sudo asterisk -rx "dialplan reload"
  908  sudo asterisk -rx "dialplan show 7@IVR-14"
  909  watch -n 1 "sudo asterisk -rx 'core show channels'"
  910  sudo asterisk -rx "dialplan reload"
  911  sudo asterisk -rx "group show channels"
  912  clear
  913  watch -n 1 'asterisk -rx "group show channels"'
  914  watch -n 1 "echo '--- ALL CURRENT CALLS ---'; asterisk -rx 'core show channels' | grep SIP; echo ''; echo '--- RECORDER GROUP COUNT ---'; asterisk -rx 'group show channels'"
  915  watch -n 1 'asterisk -rx "group show channels"'
  916  watch -n 1 'asterisk -rx "core show channels"'
  917  sudo asterisk -rx "dialplan reload"
  918  sudo asterisk -rx "dialplan show s@omni-stasis"
  919  sudo asterisk -rx "group remove recorder_limit all"
  920  sudo asterisk -rx "group show channels"
  921  sudo asterisk -rx "dialplan reload"
  922  sudo asterisk -rx "dialplan show 7@IVR-14"
  923  clear
  924  sudo asterisk -rx "group remove recorder_limit all"
  925  sudo asterisk -rx "core show channels" | grep -E "omni-stasis|IVR-14"
  926  sudo asterisk -rx "dialplan reload"
  927  sudo asterisk -rx "core show channels" | grep -E "omni-stasis|IVR-14"
  928  cp extensions.conf extension.working.conf
  929  cp extensions.conf extensions.working.conf
  930  sudo asterisk -rx "dialplan reload"
  931  sudo asterisk -rx "dialplan show 7@IVR-14"
  932   sudo journalctl -u ari_proxy.service -r
  933  systemctl restart ari_proxy.service
  934  systemctl status ari_proxy.service
  935   sudo journalctl -u ari_proxy.service -r
  936  sudo asterisk -rx "core show channels" | grep -E "omni-stasis|IVR-14"
  937  sudo asterisk -rx "group show channels"
  938  sudo asterisk -rx "dialplan reload"
  939  sudo asterisk -rx "group show channels"
  940  sudo asterisk -rx "core show channels" | grep -E "omni-stasis|IVR-14"
  941  clear
  942  sudo asterisk -rx "core show channels" | grep -E "omni-stasis|IVR-14"
  943  sudo asterisk -rx "dialplan reload"
  944  sudo asterisk -rx "dialplan show 7@IVR-14"
  945  sudo asterisk -rx "core show channels" | grep -E "omni-stasis|IVR-14"
  946  sudo asterisk -rx "core show channels"
  947  sudo asterisk -rx "group remove recorder_limit all"
  948  sudo asterisk -rx "group show channels"
  949  sudo asterisk -rx "core show channels"
  950  sudo asterisk -rx "dialplan reload"
  951  systemctl restart ari_proxy.service
  952  sudo asterisk -rx "dialplan reload"
  953  sudo asterisk -rx "core show channels" | grep -E "omni-stasis|IVR-14"
  954  sudo asterisk -rx "group show channels"
  955  systemctl status kamailio
  956  # Enable the PowerTools/CRB repository
  957  sudo dnf config-manager --set-enabled ol8_codeready_builder
  958  # Ensure EPEL is installed
  959  sudo dnf install -y epel-release
  960  sudo tee /etc/yum.repos.d/kamailio.repo <<EOF
  961  [kamailio]
  962  name=Kamailio RPMs for RHEL/CentOS 8 - v6.0.x
  963  baseurl=https://rpm.kamailio.org/centos/8/6.0/6.0.x/x86_64/
  964  gpgcheck=0
  965  enabled=1
  966  EOF
  967  sudo dnf clean all
  968  sudo dnf makecache
  969  sudo asterisk -rx "dialplan reload"
  970  sudo asterisk -rx "core show channels"
  971  cd /etc/asterisk
  972  cp extensions.backup_02_02.conf extensions.conf
  973  sudo asterisk -rx "dialplan reload"
  974  sudo asterisk -rx "core show channels" | grep -E "omni-stasis|IVR-14"
  975  sudo asterisk -rx "dialplan show 7@IVR-14"
  976  chmod +x dart_ari_proxy.exe
  977  cd /usr/src/ari_proxy/
  978  chmod +x dart_ari_proxy.exe
  979  systemctl restart ari_proxy.service
  980  cd /usr/src/ari_proxy/
  981  chmod +x dart_ari_proxy.exe
  982  systemctl restart ari_proxy.service
  983  cd /usr/src/ari_proxy/
  984  systemctl status ari_proxy.service
  985  cd /etc/asterisk
  986  cp extensions.backup_02_02.conf extensions.conf
  987  cp extensions.work.conf extensions.conf
  988  cp extensions.working.conf extensions.conf
  989  sudo asterisk -rx "dialplan reload"
  990  sudo asterisk -rx "dialplan show 7@IVR-14"
  991  sudo asterisk -rx "core show channels" | grep -E "omni-stasis|IVR-14"
  992  sudo asterisk -rx "dialplan reload"
  993   sudo journalctl -u ari_proxy.service -r
  994  clear
  995   sudo journalctl -u ari_proxy.service -r
  996  clear
  997   sudo journalctl -u ari_proxy.service -r
  998  clear
  999  cd /usr/src/ari_proxy/
 1000  chmod +x dart_ari_proxy.exe
 1001   sudo journalctl -u ari_proxy.service -r
 1002  clear
 1003  cp extensions.backup_02_02.conf extensions.conf
 1004  cd /etc/asterisk/
 1005  cp extensions.backup_02_02.conf extensions.conf
 1006  cp extensions.conf extensions.working.conf
 1007  cp extensions.backup_02_02.conf extensions.conf
 1008  sudo asterisk -rx "dialplan reload"
 1009  cd /usr/src/ari_proxy/
 1010  systemctl restart ari_proxy.service
 1011  systemctl status ari_proxy.service
 1012   sudo journalctl -u ari_proxy.service -r
 1013  sudo asterisk -rx "core show channels" | grep -E "omni-stasis|IVR-14"
 1014  cp extensions.working.conf extensions.conf
 1015  cd /etc/asterisk
 1016  cp extensions.working.conf extensions.conf
 1017  sudo asterisk -rx "dialplan reload"
 1018  sudo asterisk -rx "core show channels" | grep -E "omni-stasis|IVR-14"
 1019  cp extensions.backup_02_02.conf extensions.conf
 1020  sudo asterisk -rx "dialplan reload"
 1021  cp extensions.conf extensions.backup_02_02.conf
 1022  sudo asterisk -rx "dialplan reload"
 1023  cd /usr/src/ari_proxy/
 1024  chmod +x dart_ari_proxy.exe
 1025  systemctl restart ari_proxy.service
 1026  systemctl status ari_proxy.service
 1027  cp extensions.working.conf extensions.conf
 1028  cd /etc/asterisk
 1029  cp extensions.working.conf extensions.conf
 1030  sudo asterisk -rx "dialplan reload"
 1031  history