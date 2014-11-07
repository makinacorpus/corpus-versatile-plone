{% set cfg = opts.ms_project %}
{% set data = cfg.data %}
include:
  - makina-states.localsettings.python
{# workaround the l;ibjpegturbo transitional
 package hell by installing it explicitly #}
prepreq-pre-{{cfg.name}}:
  pkg.{{salt['mc_pkgs.settings']()['installmode']}}:
    - pkgs:
      - libjpeg-dev

prepreq-{{cfg.name}}:
  pkg.{{salt['mc_pkgs.settings']()['installmode']}}:
    - require:
      - pkgrepo: deadsnakes-ppa
    - pkgs:
      - liblcms2-2
      - liblcms2-dev
      - autoconf
      - automake
      - libpcre3-dev
      - build-essential
      - bzip2
      - gettext
      - git
      - groff
      - libbz2-dev
      - libcurl4-openssl-dev
      - libdb-dev
      - libgdbm-dev
      - libreadline-dev
      - libfreetype6-dev
      - libsigc++-2.0-dev
      - libsqlite0-dev
      - libsqlite3-dev
      - libtiff5
      - libtiff5-dev
      - libwebp5
      - libwebp-dev
      - python2.6
      - python2.6-dev
      - libssl-dev
      - libtool
      - libxml2-dev
      - libxslt1-dev
      - libopenjpeg-dev
      - libopenjpeg2
      - m4
      - man-db
      - pkg-config
      - poppler-utils
      - python-dev
      - python-imaging
      - python-setuptools
      - tcl8.4
      - tcl8.4-dev
      - tcl8.5
      - tcl8.5-dev
      - tk8.5-dev
      - wv
      - zlib1g-dev
      - subversion
      - unzip
      - ldap-utils
      - libldap-2.4-2
      - libldap2-dev
      - libsasl2-dev
      - libcrypto++-dev
      - libssl-dev
      - python{{data.py_ver}}
      - python{{data.py_ver}}-dev

var-dirs-{{cfg.name}}:
  file.directory:
    - require:
      - pkg: prepreq-{{cfg.name}}
    - names:
      - {{cfg.data['var-directory']}}
      - {{cfg.data.buildout.settings.buildout['download-cache']}}
      - {{cfg.data.buildout.settings.buildout['download-directory']}}
      - {{cfg.data.buildout.settings.buildout['parts-directory']}}
      - {{cfg.data.buildout.settings.buildout['eggs-directory']}}
      - {{data.www_dir}}
    - makedirs: true
    - user: {{cfg.user}}
    - group: {{cfg.group}}

var-dirs-s-{{cfg.name}}:
  file.symlink:
    - name: "{{data.zroot}}/var"
    - target: "{{data['var-directory']}}"
    - require:
      - file: var-dirs-{{cfg.name}}

{{cfg.name}}-wgetplone:
  cmd.run:
    - name: wget -c "{{data.installer_url}}"
    - unless: test -e "{{data.plone_arc}}"
    - cwd: {{cfg.data_root}}
    - user: {{cfg.user}}
    - require:
      - file: var-dirs-{{cfg.name}}

{{cfg.name}}-unpackplone:
  cmd.run:
    - name: tar xzvf {{data.plone_arc}}
    - unless: test -e {{data.plone_root}}/buildout_templates
    - cwd: {{cfg.data_root}}
    - user: {{cfg.user}}
    - require:
      - cmd: {{cfg.name}}-wgetplone

{{cfg.name}}-unpackcache:
  cmd.run:
    - name: tar xjf {{data.plone_root}}/packages/buildout-cache.tar.bz2
    - unless: test -e {{data.zroot}}/var/buildout-cache/eggs/Products.CMFCore*
    - cwd: {{data.zroot}}/var
    - user: {{cfg.user}}
    - require:
      - cmd: {{cfg.name}}-unpackplone
      - file: var-dirs-s-{{cfg.name}}

# {{cfg.name}}-old-eggs:
#   cmd.run:
#     - name: cp -rf "{{cfg.project_root}}/old-eggs/"* buildout-cache/eggs
#     - onlyif: test -e "{{cfg.project_root}}"
#     - cwd: {{data.zroot}}/var
#     - user: {{cfg.user}}
#     - require:
#       - cmd: {{cfg.name}}-unpackplone
#       - file: var-dirs-s-{{cfg.name}}

{{cfg.name}}-patch-pil:
  cmd.run:
    - name: sed -i -re "s/get_dist\('PIL'\).version/get_dist('Pillow').version/g" ./var/buildout-cache/eggs/*.egg/Products/CMFPlone/MigrationTool.py
    - unless: grep -qi pillow ./var/buildout-cache/eggs/*.egg/Products/CMFPlone/MigrationTool.py
    - cwd: {{data.zroot}}
    - user: {{cfg.user}}
    - require:
      - cmd: {{cfg.name}}-unpackcache

{% if data.get('sys_encoding', '') %}
{{cfg.name}}-setenc:
  file.managed:
    - contents: |
                import sys
                sys.setdefaultencoding('{{data.sys_encoding}}')
    - mode: 755
    - makedirs: true
    - user: root
    - group: root
    - names:
      - /usr/lib/python{{data.py_ver}}/site-packages/site-customize.py
      - {{data.py_inst}}/lib/python{{data.py_ver}}/site-packages/site-customize.py
      - {{data.py_root}}/lib/python{{data.py_ver}}/site-packages/site-customize.py
    - require:
      - pkg: prepreq-{{cfg.name}}
{% endif %}
