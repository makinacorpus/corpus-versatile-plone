{% set cfg = opts.ms_project %}
{% set data = cfg.data %}
{{cfg.name}}-system-links:
  cmd.run:
    - user: root
    - name: |
            set -e
            cp -fv "{{data.zroot}}/etc/logrotate.conf" "/etc/logrotate.d/{{cfg.name}}"
            cp -fv "{{data.zroot}}/etc/supervisor.initd" "/etc/init.d/supervisor.{{cfg.name}}"
            cp -fv "{{data.zroot}}/etc/crontab"        "/etc/cron.d/{{cfg.name}}"
            chown -fv root:root "/etc/logrotate.d/{{cfg.name}}"
            chown -fv root:root "/etc/init.d/supervisor.{{cfg.name}}"
            chown -fv root:root "/etc/cron.d/{{cfg.name}}"
            chmod -fv 644 "/etc/logrotate.d/{{cfg.name}}"
            chmod -fv 700 "/etc/init.d/supervisor.{{cfg.name}}"
            chmod -fv 700 "/etc/cron.d/{{cfg.name}}"
