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

# Interfaces
{%- for interface_name, interface_details in ufw.get('interfaces', {}).items() %}
  {%- if ':' in interface_name %}
  {%- set interface_out = interface_name.split(':')[1] %}
  {%- set interface_name = interface_name.split(':')[0] %}
  {%- else %}
  {% set interface_out = None %}
  {%- endif %}
  {%- set deny    = interface_details.get('deny', None) %}
  {%- set limit   = interface_details.get('limit', None) %}
  {%- set comment = interface_details.get('comment', None) %}
  {%- set route     = interface_details.get('route', None) %}
  {%- set prepend   = interface_details.get('prepend', None) %}
  {%- set method    = 'deny' if deny else ('limit' if limit else 'allow') %}

{%- set n_uple = '' %}
{%- if interface_out %}
{%- set n_uple = n_uple+'-'+interface_out %}
{%- endif %}
{%- if route %}
{%- set tmp = n_uple %}
{%- set n_uple = tmp +'-route' %}
{%- endif %}

ufw-interface-{{ method }}-{{ interface_name }}{{ n_uple }}:
  ufw.{{ method }}:
    {%- if interface_name != 'any' %}
    - interface: {{ interface_name }}
    {%- endif %}
    {%- if comment is not none %}
    - comment: '"{{ comment }}"'
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
    {%- if enabled %}
    - listen_in:
      - cmd: reload-ufw
    {%- endif %}
{%- endfor %}
