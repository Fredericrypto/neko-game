#!/usr/bin/env python3
"""Adiciona ao project.godot a seção [internationalization] (idioma de fallback e tradução).
Só insere se ainda não existir; não altera mais nada. Uso (na raiz do projeto): python3 tools/add_localization_setting.py"""
import sys
P = "project.godot"
text = open(P, encoding="utf-8").read()
if "[internationalization]" in text:
    print("OK: project.godot já tem a seção [internationalization]; nada a fazer.")
    sys.exit(0)
block = '[internationalization]\n\nlocale/fallback="en"\nlocale/translations=PackedStringArray("res://locale/strings.en.translation")\n\n'
if "[rendering]" in text:
    text = text.replace("[rendering]", block + "[rendering]", 1)
else:
    text = text.rstrip("\n") + "\n\n" + block
open(P, "w", encoding="utf-8").write(text)
print("OK: seção [internationalization] adicionada ao project.godot.")
