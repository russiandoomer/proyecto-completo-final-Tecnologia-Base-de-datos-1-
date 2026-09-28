# Entregable Final — Tecnología de Base de Datos I

## Migración de la base de datos employees desde MariaDB hacia PostgreSQL

**Estudiante:** Jeferson Willy Fulguera Seas
**Asignatura:** Tecnología de Base de Datos I
**Docente:** Ing. Jared López Leaño
**Fecha:** 28 de septiembre de 2026

---

## Descripción

Este repositorio contiene el informe final de la migración de la base de datos employees desde MariaDB 11.8.9 hacia PostgreSQL 18.6, ejecutada en un entorno Docker con pgloader 3.6.10.

## Contenido

| Archivo | Descripción |
|---|---|
| EntregableFinal_TBDI_Jeferson_Fulguera.md | Informe completo en Markdown |
| backup/pdb_employees_backup.dump.gz | Backup comprimido de PostgreSQL |
| scripts/migracion_final.load | Configuración de pgloader |
| scripts/migracion_final_log.txt | Log de la migración |
| scripts/punto2_vistas_postgresql.sql | SQL de las vistas adaptadas |
| docs/diccionario.md | Diccionario de datos |

## Resultados de la migración

| Aspecto | Resultado |
|---|---|
| Registros migrados | 3.919.015 |
| Tamaño transferido | 134.9 MB |
| Tiempo total | 55.7 segundos |
| Velocidad promedio | 70.300 filas/s |
| Errores | 0 |
| Tablas migradas | 6 de 6 |
| Vistas migradas | 2 de 2 |

## Verificaciones realizadas

- Conteo de filas (100% coincidencia)
- Checksum MD5 (idénticos)
- Comparación directa de filas (idénticas)
- Búsqueda de huérfanos (0 encontrados)

## Nota de uso

El archivo `scripts/migracion_final.load` usa marcadores para las credenciales de conexión. Antes de ejecutar la migración en un entorno local, reemplazar `USUARIO_MARIADB`, `CONTRASENA_MARIADB`, `USUARIO_POSTGRES` y `CONTRASENA_POSTGRES` por los valores reales del entorno.

## Referencias

- PostgreSQL Global Development Group. (2026). PostgreSQL 18 Documentation.
- pgloader. (2026). pgloader Documentation.
- MariaDB Foundation. (2026). MariaDB Documentation.
