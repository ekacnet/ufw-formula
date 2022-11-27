# -*- coding: utf-8 -*-
# vim: ft=sls

{#- Get the `tplroot` from `tpldir` #}
{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ "/map.jinja" import ufw with context %}

{%- if ufw.get('enabled', False) %}

app-update-ufw:
  cmd.wait:  # noqa: 213
    - name: ufw app update all

{%- endif %}
