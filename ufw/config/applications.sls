# -*- coding: utf-8 -*-
# vim: ft=sls

{#- Get the `tplroot` from `tpldir` #}
{%- set tplroot = tpldir.split('/')[0] %}
{%- set sls_package_install = tplroot ~ '.package.install' %}
{%- set sls_enable_service  = tplroot ~ '.service.enable' %}
{%- set sls_reload_service  = tplroot ~ '.service.reload' %}
{%- from tplroot ~ "/map.jinja" import ufw with context %}

{%- set enabled = ufw.get('enabled', False) %}

include:
  - {{ sls_package_install }}
  - {{ sls_enable_service }}
  - {{ sls_reload_service }}

# Applications
{%- for app_name, app_details in ufw.get('applications', {}).items() %}

  {%- set from_addr_raw = app_details.get('from_addr', [None]) %}
  {%- set from_addrs = [from_addr_raw] if from_addr_raw is string else from_addr_raw %}

  {%- for from_addr in from_addrs %}
    {%- set deny    = app_details.get('deny', None) %}
    {%- set limit   = app_details.get('limit', None) %}
    {%- set method  = 'deny' if deny else ('limit' if limit else 'allow') %}
    {%- set to_addr = app_details.get('to_addr', None) %}
    {%- set comment = app_details.get('comment', None) %}
    {%- set require = app_details.get('require', None) %}
    {%- set interface = app_details.get('interface', None) %}
    {%- set interface_out = app_details.get('interface_out', None) %}
    {%- set route     = app_details.get('route', None) %}
    {%- set prepend   = app_details.get('prepend', None) %}
    {%- set app_name  = app_details.get('app_name', app_name) %}

    {%- set n_uple = [from_addr, to_addr, interface, interface_out]|select("ne", None)|join('-') %}
    {% if n_uple != '' %}
    {% set n_uple = '-'+n_uple %}
    {% endif %}
    {%- if route %}
    {%- set tmp = n_uple %}
    {%- set n_uple = tmp +'-route' %}
    {%- endif %}

ufw-app-{{ method }}-{{ app_name }}{{ n_uple }}:
  ufw.{{ method }}:
    - app: '"{{ app_name }}"'
    {%- if from_addr is not none %}
    - from_addr: {{ from_addr }}
    {%- endif %}
    {%- if to_addr is not none %}
    - to_addr: {{ to_addr }}
    {%- endif %}
    # Debian Jessie doesn't implement the **comment** directive
    # CentOS-6 throws an UTF-8 error
    {%- if comment is not none and salt['grains.get']('osfinger') != 'Debian-8' and salt['grains.get']('osfinger') != 'CentOS-6' %}
    - comment: '"{{ comment }}"'
    {%- endif %}
    {%- if interface is not none %}
    - interface: {{ interface }}
    {%- endif %}
    {%- if interface_out is not none %}
    - out_interface: {{ interface_out }}
    {%- endif %}
    {%- if prepend is not none %}
    - prepend: {{ prepend }}
    {%- endif %}
    {%- if route is not none %}
    - route: {{ route }}
    {%- endif %}
    {%- if require %}
    - require:
      - file: ufw-file-app-{{ require }}
    {%- endif %}
    {%- if enabled %}
    - listen_in:
      - cmd: reload-ufw
    {%- endif %}
  {%- endfor %}
{%- endfor %}
