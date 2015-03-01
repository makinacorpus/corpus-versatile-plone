{% set cfg = opts.ms_project %}
{% set data = cfg.data %}
{% set scfg = salt['mc_utils.json_dump'](cfg) %}
{% set py_root = data.py_root %}
{% set p = "{0}".format(data.py_ver).replace('.', '') %}

#
# attention, for py24 to install collective.recipe.env
# from github via requirements !
#
{% if data.py_ver < 2.5 %}
{{cfg.name}}-p-build:
  file.managed:
    - name: {{cfg.data_root}}/buildpy.sh
    - source: salt://makina-projects/{{cfg.name}}/files/buildpy.sh
    - template: jinja
    - user: {{cfg.user}}
    - group: {{cfg.group}}
    - mode: 0755
  cmd.run:
    - name: export PREFIX="{{data.py_inst}}";{{cfg.data_root}}/buildpy.sh
    - user: {{cfg.user}}
    - unless: test -e "{{data.py_inst}}/bin/python"
    - require:
      - file: {{cfg.name}}-p-build
{% endif%}

{{cfg.name}}-venv:
  virtualenv.managed:
    - name: {{data.py_root}}
    - pip_download_cache: {{cfg.data_root}}/cache
    - user: {{cfg.user}}
    {% if data.py_ver >= 2.5 %}
    - python: /usr/bin/python{{data.py_ver}}
    {% else %}
    - venv_bin: {{data.py_inst}}/bin/virtualenv
    - python: {{data.py_inst}}/bin/python
    - require:
      - cmd: {{cfg.name}}-p-build
    {% endif %}
    - use_vt: true
  cmd.run:
    - name: |
            . {{data.py_root}}/bin/activate;
            pip install -r "{{data.requirements}}" --download-cache "{{cfg.data_root}}/cache"
    - onlyif: test -e "{{data.requirements}}"
    - env:
       - CFLAGS: "-I/usr/include/gdal"
    - cwd: {{data.zroot}}
    - use_vt: true
    - download_cache: {{cfg.data_root}}/cache
    - user: {{cfg.user}}
    - require:
      - virtualenv: {{cfg.name}}-venv
  file.symlink:
    - name: {{cfg.project_root}}/develop_eggs
    - target: {{data.py_root}}/src
    - makedirs: true
    - onlyif: test -e "{{data.py_root}}/src"
    - require:
      - cmd: {{cfg.name}}-venv

{# install the django app in develop if we have a setup.py #}
{{cfg.name}}-develop:
  cmd.run:
    - name: |
            . {{data.py_root}}/bin/activate;
            pip install -e .
    - env:
       - CFLAGS: "-I/usr/include/gdal"
    - cwd: {{data.zroot}}
    - onlyif: test -e setup.py
    - use_vt: true
    - download_cache: {{cfg.data_root}}/cache
    - user: {{cfg.user}}
    - require:
      - file: {{cfg.name}}-venv

{% if data.py_ver < 2.5 %}
{{cfg.name}}-venv-2:
  cmd.run:
    - name: |
            . {{data.py_root}}/bin/activate;
            pip install --upgrade setuptools==0.6c11 zc.buildout==1.7.0 "https://github.com/collective/collective.recipe.environment/archive/0.2.0.zip"
    - onlyif: test -e "{{data.requirements}}" && test "x$("{{data.py}}" -c "import collective.recipe.environment";echo $?)" = "x1"
    - cwd: {{data.zroot}}
    - use_vt: true
    - download_cache: {{cfg.data_root}}/cache
    - user: {{cfg.user}}
    - require:
      - file: {{cfg.name}}-venv
{% endif %}

{{cfg.name}}-venv-cleanup:
  file.absent:
    - name: {{cfg.project_root}}/develop_eggs
    - onlyif: test ! -e "{{data.py_root}}/src"
    - require:
      - file: {{cfg.name}}-venv
      - cmd: {{cfg.name}}-venv-2
