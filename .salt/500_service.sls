{% set cfg = opts.ms_project %}
{% set data = cfg.data %}
{%- set locations = salt['mc_locations.settings']() %}
{#- init script is marked as started at first, but the daemon is not there #}
{{cfg.name}}-service:
  service.running:
    - name: supervisor.{{cfg.name}}
    - enable: True
  cmd.run:
    - name: {{locations.initd_dir}}/supervisor.{{cfg.name}} restart
    - onlyif: test "$({{cfg.project_root}}/bin/supervisorctl status 2>&1 |grep "refused connection"|wc -l)" != 0
    - user: root
    - watch:
      - service: {{cfg.name}}-service

{{cfg.name}}-reboot:
  file.managed:
    - name: {{cfg.data_root}}/restart.sh
    - user: root
    - group: root
    - mode: 755
    - template: jinja
    - contents: |
                #!/usr/bin/env bash
                {% for i in data.started_supervisor_programs %}
                {{ data.zroot}}/bin/supervisorctl start {{i}}
                {% endfor %}
                {% for i in data.supervisor_programs %}
                {%- if cfg.data['buildout']['settings']['v'].get('autostart_{0}'.format(i), "").lower() == 'true' %}
                {{ data.zroot}}/bin/supervisorctl restart {{i}}
                {%- endif %}
                {%- endfor %}
  cmd.run:
    - name: {{cfg.data_root}}/restart.sh
    - user: root
    - watch:
      - cmd: {{cfg.name}}-service

