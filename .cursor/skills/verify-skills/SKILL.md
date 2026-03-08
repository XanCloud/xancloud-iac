---
name: verify-skills
description: >
  Verifica que las skills en .cursor/skills estén correctamente estructuradas para que el
  agente las descubra y use. Trigger cuando se pida verificar, validar, revisar o auditar
  la estructura de las skills del proyecto, comprobar que están bien formadas, o asegurar
  que .cursor/skills cumple las convenciones de Cursor. Trigger ante "verifica las skills",
  "¿están bien estructuradas?", "revisa .cursor/skills", "auditar skills".
---

# Verificación de skills (Cursor)

Comprueba que cada skill en `.cursor/skills/` cumple la estructura y metadata que Cursor necesita para descubrirlas y aplicarlas.

## Alcance

- **Dónde:** `.cursor/skills/` del proyecto (cada subcarpeta con `SKILL.md` es una skill).
- **Qué:** Estructura de directorio, frontmatter YAML, descripción, y criterios de calidad según las convenciones de Cursor.

## Workflow

1. Listar todas las skills: buscar `SKILL.md` en `.cursor/skills/**`.
2. Para cada skill, ejecutar el checklist siguiente.
3. Reportar por skill con severidad (Bloqueante / Recomendación / OK).

## Checklist por skill

### 1. Estructura de directorio

- [ ] La skill vive en `.cursor/skills/{skill-name}/`.
- [ ] Existe `SKILL.md` en la raíz de esa carpeta (obligatorio).
- [ ] El nombre de carpeta usa solo minúsculas, números y guiones (ej. `xancloud-iac-modules`).

### 2. Frontmatter YAML

- [ ] El archivo empieza con un bloque `---` ... `---`.
- [ ] Campo **name**: presente, único, ≤64 caracteres, solo `a-z`, `0-9`, `-`.
- [ ] Campo **description**: presente, no vacío, ≤1024 caracteres.

### 3. Descripción (descubrimiento por el agente)

- [ ] Redactada en **tercera persona** (no "Puedes usar…" ni "Yo ayudo…").
- [ ] Incluye **QUÉ hace** la skill (capacidad concreta).
- [ ] Incluye **CUÁNDO** aplicarla (triggers: "Trigger cuando…", "Use when…", palabras clave).
- [ ] Términos de trigger alineados con el dominio (ej. módulos, pipeline, blueprints).

### 4. Cuerpo del SKILL.md

- [ ] Título principal (`#`) después del frontmatter.
- [ ] Instrucciones o secciones claras (pasos, convenciones, ejemplos).
- [ ] Referencias a otros archivos solo un nivel (ej. `[references/foo.md](references/foo.md)`), sin rutas anidadas profundas.
- [ ] Sin rutas tipo Windows (`\`).

### 5. Tamaño y mantenibilidad

- [ ] SKILL.md preferiblemente &lt;500 líneas; si es largo, considerar mover detalle a `reference.md` o similar.
- [ ] Terminología consistente en todo el archivo.

## Formato del reporte

Por cada skill, emitir:

```markdown
### {nombre-carpeta-skill}

- **name:** {valor del frontmatter}
- **Bloqueante:** [lista de fallos que impiden uso correcto, o "Ninguno"]
- **Recomendación:** [mejoras opcionales, o "Ninguna"]
- **Estado:** OK / Revisar
```

Al final, un resumen:

- Total skills revisadas.
- Cuántas OK vs cuántas con bloqueantes o recomendaciones.
- Lista de skills con bloqueantes para corregir primero.

## Comandos útiles

Listar skills del proyecto:

```bash
find .cursor/skills -name SKILL.md -type f
```

Contar líneas de un SKILL.md:

```bash
wc -l .cursor/skills/<skill-name>/SKILL.md
```

## Referencia

Las reglas de estructura y descripción siguen las convenciones de Cursor para Agent Skills (directorio con `SKILL.md`, frontmatter obligatorio, descripción en tercera persona con WHAT + WHEN). Para crear o reescribir skills, usar el skill **create-skill** en lugar de este.
