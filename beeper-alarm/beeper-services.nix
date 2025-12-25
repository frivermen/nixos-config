{ pkgs, ...}: {
  systemd.timers."work-beeper10" = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      Unit = "work-beeper10.service";
      AccuracySec = "1s";
      OnCalendar = [
        "Mon..Fri *-*-* 11:50:00 Asia/Yekaterinburg"
        "Mon..Fri *-*-* 15:50:00 Asia/Yekaterinburg"
      ];
    };
  };
  systemd.services."work-beeper10" = {
    script = ''
      set -eu
      ${pkgs.beep}/bin/beep -f 2800 -l 500
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
  };

  systemd.timers."work-beeper2" = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      Unit = "work-beeper2.service";
      AccuracySec = "1s";
      OnCalendar = [
        "Mon..Fri *-*-* 11:58:00 Asia/Yekaterinburg"
        "Mon..Fri *-*-* 15:58:00 Asia/Yekaterinburg"
      ];
    };
  };
  systemd.services."work-beeper2" = {
    script = ''
      set -eu
      ${pkgs.beep}/bin/beep -f 2800 -l 500 -r 2
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
  };

  systemd.timers."work-beeper0" = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      Unit = "work-beeper0.service";
      AccuracySec = "1s";
      OnCalendar = [
        "Mon..Fri *-*-* 12:00:00 Asia/Yekaterinburg"
        "Mon..Fri *-*-* 16:00:00 Asia/Yekaterinburg"
      ];
    };
  };
  systemd.services."work-beeper0" = {
    script = ''
      set -eu
      ${pkgs.beep}/bin/beep -f 2800 -l 1000
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
  };
}
