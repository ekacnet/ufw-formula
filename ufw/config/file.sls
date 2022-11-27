# -*- coding: utf-8 -*-
# vim: ft=sls

{#- Get the `tplroot` from `tpldir` #}
{%- set tplroot = tpldir.split('/')[0] %}
{%- set sls_package_install = tplroot ~ '.package.install' %}
{%- from tplroot ~ "/map.jinja" import ufw with context %}
{%- from tplroot ~ "/libtofs.jinja" import files_switch with context %}

include:
  - {{ sls_package_install }}

ufw-default-file-file-managed:
  file.managed:
    - name:     {{ ufw.default_file }}
    - user:     root
    - group:    root
    - template: jinja
    - source: {{ files_switch(['ufw.default.tmpl', 'ufw.default.tmpl.jinja'],
                              lookup='ufw-default-file-file-managed'
                 )
              }}
    - require:
      - sls: {{ sls_package_install }}
    - context:
        ufw_settings: {{ ufw.settings | json }}

ufw-sysctl-file-file-managed:
  file.managed:
    - name:     {{ ufw.sysctl_file }}
    - user:     root
    - group:    root
    - template: jinja
    - source: {{ files_switch(['ufw.sysctl.tmpl', 'ufw.sysctl.tmpl.jinja'],
                              lookup='ufw-sysctl-file-file-managed'
                 )
              }}
    - require:
      - sls: {{ sls_package_install }}
    - context:
        ufw_sysctl: {{ ufw.sysctl | json }}

{% if ufw.get('applications_files') %}
{% for filename, config in ufw.get('applications_files').items() %}
ufw-file-app-{{ filename }}:
  file.managed:
    - name: /etc/ufw/applications.d/{{ filename }}
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - source: salt://ufw/files/application.tmpl.jinja
    - context:
        config: {{ config | json }}
{% endfor %}
{% else %}
/etc/ufw/applications.d:
  file.recurse:
    - user: root
    - group: root
    - file_mode: 644
    - clean: False
    - source: salt://ufw/files/applications.d
{% endif %}
