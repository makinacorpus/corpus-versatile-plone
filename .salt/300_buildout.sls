{% set cfg = opts.ms_project %}
{% set data = cfg.data %}
{%- set sdata = salt['mc_utils.json_dump'](cfg.data) %}
{#- Run the project buildout but skip the maintainance parts #}
{#- Wrap the salt configured setting in a file inputable to buildout #}
{% if data.buildout.settings.versions.get('Pillow', '') == '1.7.8' %}
{{cfg.name}}-usr-sym:
  file.symlink:
    - name: /usr/include/freetype
    - target: /usr/include/freetype2
    - require_in:
      - file: {{cfg.name}}-buildout-project
{% endif %}
{{cfg.name}}-buildout-prod:
  file.symlink:
    - name: {{data.zroot}}/etc/prod.cfg
    - target: {{cfg.project_root}}/.salt/files/prod.cfg
    - makedirs: true
{{cfg.name}}-buildout-project:
  file.managed:
    - template: jinja
    - name: {{data.zroot}}/buildout-salt.cfg
    - source: salt://makina-projects/{{cfg.name}}/files/settings.cfg
    - user: {{cfg.user}}
    - group: {{cfg.group}}
    - mode: 770
    - defaults:
        project_name: {{cfg.name}}
    - watch:
      - file: {{cfg.name}}-buildout-prod
  {% if data.py_ver > 2.5 %}
  buildout.installed:
    - name: {{data.zroot}}
    - config: buildout-salt.cfg
    - runas: {{cfg.user}}
    - newest: {{{'true': True}.get(cfg.data.buildout.settings.buildout.get('newest', 'false').lower(), False)  }}
    - python: "{{data.py}}"
    - use_vt: true
    - output_loglevel: info
  {% else %}
  cmd.run:
    - name: {{data.py_root}}/bin/buildout -Nc buildout-salt.cfg
    - user: {{cfg.user}}
    - use_vt: true
    - cwd: {{data.zroot}}
    - watch:
      - file: {{cfg.name}}-buildout-project
  {% endif %}
