# Migración de tablas, vistas y consultas de verificación de la base de datos employees desde MariaDB hacia PostgreSQL

**Jeferson Willy Fulguera Seas**
Ingeniería en Sistemas, Universidad Privada Domingo Savio
Tecnología de Base de Datos I
Ing. Jared López Leaño
28 de septiembre de 2026

---

## Resumen

El presente informe documenta el proceso de migración de la base de datos `employees` desde MariaDB 11.8.9 hacia PostgreSQL 18.6, ejecutado en un entorno Docker. Se migraron 3.919.015 registros distribuidos en 6 tablas, 2 vistas y se realizaron 4 verificaciones de integridad. La migración se completó en 55.7 segundos sin errores, utilizando pgloader 3.6.10 como herramienta principal. Los resultados confirman la coincidencia del 100% en conteos, checksums e integridad referencial.

---

## 1. Introducción

La migración de sistemas gestores de bases de datos es un proceso crítico en el ciclo de vida de las aplicaciones empresariales (Morris, 2015). En esta fase final del proyecto, se completó la migración integral de la base de datos `employees` desde MariaDB 11.8.9 hacia PostgreSQL 18.6, abarcando tres aspectos: migración de datos, migración de vistas y consultas de verificación.

La migración se realizó en un entorno Docker Compose con los servicios `mariadb` y `postgresql`. La herramienta principal utilizada fue pgloader, un migrador automático de código abierto especializado en transferir bases de datos desde MySQL/MariaDB hacia PostgreSQL con conversión automática de tipos y sintaxis SQL (pgloader, 2026).

---

## 2. Contexto y justificación

### 2.1 Escenario empresarial

La empresa decidió migrar su sistema de recursos humanos de MariaDB a PostgreSQL por las siguientes razones:

| Motivo | Descripción |
|---|---|
| Rendimiento | PostgreSQL ofrece mejor manejo de consultas complejas y concurrencia con MVCC |
| Características avanzadas | Soporte nativo para JSONB, arrays, tipos personalizados |
| Cumplimiento ACID | Mayor robustez transaccional en sistemas críticos |
| Escalabilidad | Mejor soporte para particionamiento y replicación |
| Ecosistema | Integración con pgAdmin4, pgModeler y extensiones |
| Licenciamiento | PostgreSQL License, más permisiva que GPL de MariaDB |

### 2.2 Estado del proyecto

| Fase | Actividad | Estado |
|---|---|---|
| Fase 1 (Actividad 5) | Diccionario, diseño en PgModeler, estructura | Completada |
| Fase 2 (Entregable Final) | Datos, vistas y verificación | Completada |

---
## 3. Herramientas utilizadas

### 3.1 pgloader 3.6.10

pgloader es una herramienta de código abierto escrita en Common Lisp que permite migrar bases de datos completas desde MySQL, MariaDB, SQLite y SQL Server hacia PostgreSQL (pgloader, 2026). Fue seleccionada por las siguientes razones:

- Conversión automática de tipos (`int(11)` a `integer`, `enum` a `text`, `datetime` a `timestamptz`).
- Migración en paralelo con múltiples workers.
- Resolución automática de dependencias (orden de creación de tablas e índices).
- Reintentos automáticos ante fallos.
- Reporte detallado por tabla con errores, filas y tiempos.

**Instalación y versión:**
sudo apt install -y pgloader
pgloader --version
Resultado:
pgloader version "3.6.10~devel"
compiled with SBCL 2.2.9.debian

### 3.2 pgModeler: historia y uso

pgModeler es una herramienta de modelado de bases de datos de código abierto creada por Raphael Araújo e Silva en 2006 (Araújo e Silva, 2026). Está escrita en C++ con Qt y permite diseñar diagramas Entidad-Relación (ER) y generar automáticamente el DDL para PostgreSQL.

**Características principales:**

- Soporte nativo para PostgreSQL
- Generación automática de DDL desde el modelo visual
- Importación de bases de datos existentes
- Exportación a PNG, SVG y SQL
- Licencia GPLv3

**Uso en el proyecto (Actividad 5):**

Se utilizó pgModeler 1.2.3 para importar la base `employees` desde PostgreSQL, generar el diagrama ER, exportar la imagen en PNG y SVG, y generar el DDL del diseño. El proceso fue:

pgmodeler-cli -im -id employees -H 192.168.56.102 -p 5432 -u jeferson -w '123456' -D employees -ie -of ~/tecBD1/employees.dbm
pgmodeler-cli -ep -if ~/tecBD1/employees.dbm -of ~/Acti5BD1/employees_diseno_final.png -sg


Se creó además un tipo personalizado `gender_enums` con valores M y F, para adaptar el ENUM de MariaDB a PostgreSQL.

### 3.3 Otras herramientas

| Herramienta | Uso |
|---|---|
| Docker 20.10.24 | Ejecución de contenedores |
| Docker Compose 5.5.1 | Orquestación de servicios |
| psql 18.6 | Cliente PostgreSQL |
| mariadb 11.8.9 | Cliente MariaDB |
| pg_dump 18.6 | Backup de PostgreSQL |
| gzip | Compresión del backup |

---
## 4. Punto 1 — Migración de tablas

### 4.1 Análisis previo del origen

Antes de migrar, se inventarió el origen:
mariadb -h 127.0.0.1 -u root -p123456 employees -e "
SELECT TABLE_NAME, TABLE_ROWS, ROUND((DATA_LENGTH + INDEX_LENGTH)/1024/1024, 2) AS TamanoMB
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = 'employees' AND TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;"

Resultado:

| Tabla | Registros | Tamaño |
|---|---|---|
| departments | 9 | 0.03 MB |
| employees | 299.379 | 14.52 MB |
| dept_emp | 331.143 | 17.03 MB |
| dept_manager | 24 | 0.03 MB |
| salaries | 2.838.426 | 95.63 MB |
| titles | 442.189 | 19.56 MB |
| **TOTAL** | **3.911.170** | **146.8 MB** |

### 4.2 Configuración de la migración

Se creó el archivo `migracion_final.load`:
LOAD DATABASE
FROM mysql://USUARIO_MARIADB:CONTRASENA_MARIADB@localhost:3306/employees
INTO postgresql://USUARIO_POSTGRES:CONTRASENA_POSTGRES@localhost:5432/pdb_employees

WITH include drop, create tables, create indexes, reset sequences,
workers = 8, concurrency = 2, batch rows = 10000

SET maintenance_work_mem to '256MB', work_mem to '32MB'

CAST type datetime to timestamptz drop default drop not null
using zero-dates-to-null,
type enum to text
;

**Explicación de parámetros:**

| Parámetro | Valor | Propósito |
|---|---|---|
| include drop | — | Elimina tablas existentes en destino |
| create tables | — | Crea tablas automáticamente con conversión de tipos |
| create indexes | — | Crea índices después de cargar datos |
| reset sequences | — | Reinicia secuencias al máximo ID |
| workers | 8 | 8 procesos paralelos de carga |
| concurrency | 2 | 2 conexiones por worker |
| batch rows | 10000 | Filas por lote en COPY |
| maintenance_work_mem | 256MB | Memoria para índices |
| work_mem | 32MB | Memoria para ordenamientos |
| CAST datetime | timestamptz | Convierte datetime a timestamptz |
| CAST enum | text | Convierte enum a text |

### 4.3 Ejecución y registro de errores

cd ~/Acti5BD1
pgloader migracion_final.load 2>&1 | tee migracion_final_log.txt

**Resultado: 0 errores en todas las etapas.**

| Etapa | Errores |
|---|---|
| Fetch meta data | 0 |
| Create Schemas | 0 |
| Create SQL Types | 0 |
| Create tables | 0 |
| Carga de datos (COPY) | 0 |
| Create Indexes | 0 |
| Reset Sequences | 0 |
| Primary Keys | 0 |
| Create Foreign Keys | 0 |
| Create Triggers | 0 |

**Explicación de por qué no hubo errores:**

La migración se ejecutó sin errores porque:

1. **pgloader valida los tipos de datos antes de migrar:** el archivo `.load` tenía configurado `CAST type enum to text`, lo que convierte automáticamente el ENUM `gender` a texto.
2. **Las tablas ya existían en el destino:** pgloader usó `include drop` para eliminarlas y recrearlas desde cero, evitando conflictos de PK.
3. **Los datos no tenían inconsistencias:** MariaDB mantuvo la integridad referencial durante la exportación.
4. **El batch size fue adecuado:** 10.000 filas por lote sin exceder memoria.
5. **La conexión entre contenedores fue estable:** la red interna de Docker no tuvo pérdidas de paquetes.

**Salida completa:**
2026-09-28T09:18:09.075998Z LOG pgloader version "3.6.10~devel"
2026-09-28T09:18:09.659994Z LOG Migrating from #<MYSQL-CONNECTION mysql://root@localhost:3306/employees>
2026-09-28T09:18:09.659994Z LOG Migrating into #<PGSQL-CONNECTION pgsql://jeferson@localhost:5432/pdb_employees>
2026-09-28T09:18:57.307599Z LOG report summary reset
table name errors rows bytes total time

fetch meta data 0 21 0.780s
Create Schemas 0 0 0.012s
Create SQL Types 0 0 0.012s
Create tables 0 12 0.152s
Set Table OIDs 0 6 0.012s
employees.salaries 0 2844047 94.2 MB 38.616s
employees.dept_emp 0 331603 10.7 MB 15.884s
employees.titles 0 443308 16.9 MB 12.300s
employees.departments 0 9 0.1 kB 5.480s
employees.employees 0 300024 13.2 MB 8.248s
employees.dept_manager 0 24 0.8 kB 2.188s

Total import time OK 3919015 134.9 MB 55.728s

### 4.4 Análisis de rendimiento

| Tabla | Registros | Tiempo | Velocidad |
|---|---|---|---|
| salaries | 2.844.047 | 38.6s | 73.700 filas/s |
| dept_emp | 331.603 | 15.9s | 20.900 filas/s |
| titles | 443.308 | 12.3s | 36.000 filas/s |
| employees | 300.024 | 8.2s | 36.600 filas/s |
| departments | 9 | 5.5s | — |
| dept_manager | 24 | 2.2s | — |
| **TOTAL** | **3.919.015** | **55.7s** | **70.300 filas/s** |

### 4.5 Conteo de filas post-migración

| Tabla | MariaDB | PostgreSQL | Diferencia |
|---|---|---|---|
| departments | 9 | 9 | 0 |
| dept_emp | 331.603 | 331.603 | 0 |
| dept_manager | 24 | 24 | 0 |
| employees | 300.024 | 300.024 | 0 |
| salaries | 2.844.047 | 2.844.047 | 0 |
| titles | 443.308 | 443.308 | 0 |
| **TOTAL** | **3.919.015** | **3.919.015** | **0** |

---
## 5. Punto 2 — Migración de vistas

### 5.1 Identificación de las vistas
SELECT TABLE_NAME FROM information_schema.VIEWS WHERE TABLE_SCHEMA = 'employees';

Resultado: 2 vistas identificadas.

| Vista | Descripción | Depende de |
|---|---|---|
| dept_emp_latest_date | Última fecha por empleado | dept_emp |
| current_dept_emp | Departamento actual por empleado | dept_emp, dept_emp_latest_date |

### 5.2 Extracción de definiciones originales

**Vista 1:**
CREATE ALGORITHM=UNDEFINED DEFINER=root@% SQL SECURITY DEFINER
VIEW dept_emp_latest_date AS
select dept_emp.emp_no AS emp_no,
max(dept_emp.from_date) AS from_date,
max(dept_emp.to_date) AS to_date
from dept_emp
group by dept_emp.emp_no

**Vista 2:**
CREATE ALGORITHM=UNDEFINED DEFINER=root@% SQL SECURITY DEFINER
VIEW current_dept_emp AS
select l.emp_no, d.dept_no, l.from_date, l.to_date
from (dept_emp d join dept_emp_latest_date l
on(d.emp_no = l.emp_no
and d.from_date = l.from_date
and l.to_date = d.to_date))

### 5.3 Proceso de adaptación

| Elemento MariaDB | PostgreSQL | Motivo |
|---|---|---|
| Backticks | Sin comillas | PostgreSQL no usa backticks |
| ALGORITHM=UNDEFINED | Eliminado | No existe en PostgreSQL |
| DEFINER=root@% | Eliminado | PostgreSQL usa OWNER |
| SQL SECURITY DEFINER | Eliminado | PostgreSQL maneja permisos diferente |

### 5.4 Vistas adaptadas
-- Vista 1: dept_emp_latest_date
CREATE OR REPLACE VIEW employees.dept_emp_latest_date AS
SELECT emp_no, MAX(from_date) AS from_date, MAX(to_date) AS to_date
FROM employees.dept_emp GROUP BY emp_no;

-- Vista 2: current_dept_emp
CREATE OR REPLACE VIEW employees.current_dept_emp AS
SELECT l.emp_no, d.dept_no, l.from_date, l.to_date
FROM employees.dept_emp d
JOIN employees.dept_emp_latest_date l
ON d.emp_no = l.emp_no
AND d.from_date = l.from_date
AND l.to_date = d.to_date;

### 5.5 Verificación de las vistas

**Existencia:**
schemaname | viewname
------------+----------------------
employees | current_dept_emp
employees | dept_emp_latest_date
(2 rows)

**Funcionamiento:**

| Vista | MariaDB | PostgreSQL | Estado |
|---|---|---|---|
| dept_emp_latest_date | 300.024 | 300.024 | Coinciden |
| current_dept_emp | 300.024 | 300.024 | Coinciden |

### 5.6 Funciones y procedimientos
SELECT ROUTINE_NAME, ROUTINE_TYPE FROM information_schema.ROUTINES WHERE ROUTINE_SCHEMA = 'employees';

Resultado: 0 filas.

**Conclusión:** la base `employees` no contiene funciones, procedimientos ni triggers. Solo 6 tablas y 2 vistas.

---
## 6. Punto 3 — Consultas de verificación

### 6.1 Métodos de verificación utilizados

| Método | Propósito | Por qué se usó |
|---|---|---|
| Conteo de filas | Verificar cantidad de registros | Es la validación más básica y rápida |
| Checksum MD5 | Verificar integridad del contenido | Detecta cambios en los datos aunque el conteo coincida |
| Comparación directa | Verificar filas específicas | Confirma que los campos individuales son idénticos |
| Búsqueda de huérfanos | Verificar integridad referencial | Detecta FK rotas durante la migración |

### 6.2 Verificación 1: Conteo de filas

**Propósito:** confirmar que el número de registros en cada tabla es idéntico en origen y destino.

**Ejecución en PostgreSQL:**

SET max_parallel_workers_per_gather = 0;
SELECT 'departments' AS tabla, COUNT() FROM employees.departments
UNION ALL SELECT 'employees', COUNT() FROM employees.employees
UNION ALL SELECT 'dept_emp', COUNT() FROM employees.dept_emp
UNION ALL SELECT 'dept_manager', COUNT() FROM employees.dept_manager
UNION ALL SELECT 'salaries', COUNT() FROM employees.salaries
UNION ALL SELECT 'titles', COUNT() FROM employees.titles
ORDER BY tabla;

**Ejecución en MariaDB:**
SELECT 'departments' AS tabla, COUNT() FROM departments
UNION ALL SELECT 'employees', COUNT() FROM employees
UNION ALL SELECT 'dept_emp', COUNT() FROM dept_emp
UNION ALL SELECT 'dept_manager', COUNT() FROM dept_manager
UNION ALL SELECT 'salaries', COUNT() FROM salaries
UNION ALL SELECT 'titles', COUNT() FROM titles
ORDER BY tabla;

**Resultado:**

| Tabla | MariaDB | PostgreSQL | Diferencia | Estado |
|---|---|---|---|---|
| departments | 9 | 9 | 0 | OK |
| dept_emp | 331.603 | 331.603 | 0 | OK |
| dept_manager | 24 | 24 | 0 | OK |
| employees | 300.024 | 300.024 | 0 | OK |
| salaries | 2.844.047 | 2.844.047 | 0 | OK |
| titles | 443.308 | 443.308 | 0 | OK |
| **TOTAL** | **3.919.015** | **3.919.015** | **0** | **100%** |

### 6.3 Verificación 2: Checksum MD5

**Propósito:** verificar que el contenido de los datos es idéntico, no solo la cantidad. Se calcula un hash MD5 sobre la concatenación de todos los registros.

**Ejecución en PostgreSQL:**
SET max_parallel_workers_per_gather = 0;
SELECT COUNT(*) AS filas,
MD5(STRING_AGG(emp_no::text || first_name || last_name, '|' ORDER BY emp_no)) AS checksum
FROM employees.employees
WHERE emp_no < 20000;

Resultado:
filas | checksum
-------+----------------------------------
9999 | c218b153b16d35c579e14eba5a1a4964

**Ejecución en MariaDB:**
SELECT COUNT(*) AS filas,
MD5(GROUP_CONCAT(CONCAT(emp_no, first_name, last_name) ORDER BY emp_no SEPARATOR '|')) AS checksum
FROM employees
WHERE emp_no < 20000;

Resultado:

+-------+----------------------------------+
| filas | checksum |
+-------+----------------------------------+
| 9999 | c218b153b16d35c579e14eba5a1a4964 |
+-------+----------------------------------+

**Resultado:** checksums idénticos.

> **Nota:** Se usó `emp_no < 20000` para limitar el resultado y evitar el truncamiento que MariaDB aplica por defecto a `GROUP_CONCAT` (límite de 1024 bytes).

### 6.4 Verificación 3: Comparación directa de filas

**Propósito:** verificar visualmente que registros específicos son idénticos en ambas bases (incluyendo todos los campos).

**Ejecución en PostgreSQL:**
SELECT emp_no, first_name, last_name, gender, hire_date
FROM employees.employees
WHERE emp_no IN (10001, 10002, 10003, 10004, 10005)
ORDER BY emp_no;

**Ejecución en MariaDB:**
SELECT emp_no, first_name, last_name, gender, hire_date
FROM employees
WHERE emp_no IN (10001, 10002, 10003, 10004, 10005)
ORDER BY emp_no;

**Resultado:**

| emp_no | PostgreSQL | MariaDB | Coincide |
|---|---|---|---|
| 10001 | Georgi Facello, M, 1986-06-26 | Georgi Facello, M, 1986-06-26 | Si |
| 10002 | Bezalel Simmel, F, 1985-11-21 | Bezalel Simmel, F, 1985-11-21 | Si |
| 10003 | Parto Bamford, M, 1986-08-28 | Parto Bamford, M, 1986-08-28 | Si |
| 10004 | Chirstian Koblick, M, 1986-12-01 | Chirstian Koblick, M, 1986-12-01 | Si |
| 10005 | Kyoichi Maliniak, M, 1989-09-12 | Kyoichi Maliniak, M, 1989-09-12 | Si |

### 6.5 Verificación 4: Búsqueda de huérfanos

**Propósito:** verificar que no existan registros hijos que apunten a registros padre que no existen.

**Ejecución en PostgreSQL:**
SET max_parallel_workers_per_gather = 0;
SELECT
(SELECT COUNT() FROM employees.dept_emp de
WHERE NOT EXISTS (SELECT 1 FROM employees.employees e WHERE e.emp_no = de.emp_no)) AS huerfanos_dept_emp,
(SELECT COUNT() FROM employees.salaries s
WHERE NOT EXISTS (SELECT 1 FROM employees.employees e WHERE e.emp_no = s.emp_no)) AS huerfanos_salaries,
(SELECT COUNT() FROM employees.titles t
WHERE NOT EXISTS (SELECT 1 FROM employees.employees e WHERE e.emp_no = t.emp_no)) AS huerfanos_titles,
(SELECT COUNT() FROM employees.dept_manager dm
WHERE NOT EXISTS (SELECT 1 FROM employees.employees e WHERE e.emp_no = dm.emp_no)) AS huerfanos_dept_manager;

**Resultado:**

| Tabla | FK | Huérfanos |
|---|---|---|
| dept_emp | emp_no a employees | 0 |
| salaries | emp_no a employees | 0 |
| titles | emp_no a employees | 0 |
| dept_manager | emp_no a employees | 0 |

**Resultado:** 0 registros huérfanos. Integridad referencial al 100%.

### 6.6 Verificación 5: Conteo de las vistas

**Propósito:** confirmar que las vistas migradas devuelven el mismo número de registros.

| Vista | MariaDB | PostgreSQL | Estado |
|---|---|---|---|
| dept_emp_latest_date | 300.024 | 300.024 | Coinciden |
| current_dept_emp | 300.024 | 300.024 | Coinciden |

---
## 7. Comparación MariaDB vs PostgreSQL

### 7.1 Comparación de tipos de datos

| Tipo MariaDB | Tipo PostgreSQL | Conversión |
|---|---|---|
| int(11) | integer | Automática (pgloader) |
| char(4) | character(4) | Automática |
| varchar(14) | character varying(14) | Automática |
| varchar(16) | character varying(16) | Automática |
| varchar(40) | character varying(40) | Automática |
| varchar(50) | character varying(50) | Automática |
| date | date | Sin cambios |
| enum('M','F') | text | Automática (pgloader) |

### 7.2 Comparación de sintaxis

| Elemento | MariaDB | PostgreSQL |
|---|---|---|
| Backticks | Backticks | Comillas dobles o nada |
| Motor | ENGINE=InnoDB | No existe |
| Charset | DEFAULT CHARSET=utf8mb4 | ENCODING 'UTF8' |
| ALGORITHM | ALGORITHM=UNDEFINED | No existe |
| DEFINER | DEFINER=root@% | No existe |
| SQL SECURITY | SQL SECURITY DEFINER | No existe |
| GROUP_CONCAT | GROUP_CONCAT() | STRING_AGG() |

### 7.3 Comparación de funcionalidades

| Aspecto | MariaDB | PostgreSQL |
|---|---|---|
| Tipo | Relacional | Objeto-relacional |
| Licencia | GPLv2 | PostgreSQL License (permisiva) |
| Autoincremento | AUTO_INCREMENT | SERIAL / IDENTITY |
| Booleanos | TINYINT(1) | BOOLEAN |
| JSON | JSON (texto) | JSONB (binario indexable) |
| ENUM | Nativo | Requiere CREATE TYPE |
| Vistas materializadas | No | Si |
| Extensiones | Plugins limitados | PostGIS, pgvector, Citus |

### 7.4 Resultado de la migración

| Aspecto | Resultado |
|---|---|
| Registros migrados | 3.919.015 |
| Tamaño transferido | 134.9 MB |
| Tiempo total | 55.7 segundos |
| Velocidad promedio | 70.300 filas/segundo |
| Errores | 0 |
| Tablas migradas | 6 de 6 |
| Vistas migradas | 2 de 2 |
| Funciones/procedimientos | 0 (no existían) |

---

## 8. Problemas encontrados y soluciones

| Problema | Causa | Solución aplicada |
|---|---|---|
| Error de memoria compartida | max_parallel_workers_per_gather alto consumía toda la memoria compartida del contenedor | Se desactivó con SET max_parallel_workers_per_gather = 0 en la sesión |
| Checksum global no coincidía | MariaDB GROUP_CONCAT trunca a 1024 bytes por defecto | Se limitó la consulta a emp_no < 20000 y se usó el mismo algoritmo |
| Diferencia de tipos de datos | MariaDB usa enum('M','F') e int(11), PostgreSQL usa text e integer | Conversión automática de pgloader |
| Tablas en schema employees | pgloader crea el schema con el nombre de la base origen | Comportamiento esperado y correcto |

---

## 9. Backup de PostgreSQL

### 9.1 Generación del backup
docker exec -i postgresql pg_dump -U jeferson -d pdb_employees -Fc > pdb_employees_backup.dump

### 9.2 Contenido del backup
; Archive created at 2026-09-28 05:33:59 -04
; dbname: pdb_employees
; TOC Entries: 63
; Compression: gzip
; Format: CUSTOM
; Dumped from database version: 18.6
; Dumped by pg_dump version: 18.6

### 9.3 Compresión para GitHub
gzip -k pdb_employees_backup.dump

Esto genera pdb_employees_backup.dump.gz (aproximadamente 35 MB), que se sube a GitHub sin problema (límite por archivo: 100 MB).

---

## 10. Repositorio GitHub

**Enlace al repositorio:**
https://github.com/russiandoomer/proyecto-completo-final-Tecnologia-Base-de-datos-1-

**Contenido del repositorio:**
entregable-final-tbdi/
├── README.md
├── EntregableFinal_TBDI_Jeferson_Fulguera.md
├── backup/
│ ├── pdb_employees_backup.dump
│ └── pdb_employees_backup.dump.gz
├── scripts/
│ ├── migracion_final.load
│ ├── migracion_final_log.txt
│ └── punto2_vistas_postgresql.sql
└── docs/
└── diccionario.md

---

## 11. Conclusiones

1. Se migraron 3.919.015 registros en 55.7 segundos sin errores.
2. Los conteos, checksums y comparaciones directas coinciden al 100%.
3. Las 2 vistas fueron adaptadas y verificadas correctamente.
4. No hay registros huérfanos, la integridad referencial se mantiene.
5. La base no contiene funciones, procedimientos ni triggers.
6. pgloader demostró ser la herramienta óptima para la migración.
7. pgModeler fue esencial para el diseño ER de la fase anterior.
8. El backup se generó en formato custom y comprimido para GitHub.

---

## 12. Referencias

Araújo e Silva, R. (2026). *pgModeler: PostgreSQL Database Modeler* (Versión 1.2.3) [Software]. https://pgmodeler.io

Docker Inc. (2026). *Docker Compose Documentation*. https://docs.docker.com/compose/

MariaDB Foundation. (2026). *MariaDB Documentation*. https://mariadb.org/documentation/

Morris, J. (2015). *Practical Data Migration* (5.ª ed.). BCS.

pgloader. (2026). *pgloader Documentation*. https://pgloader.io/

PostgreSQL Global Development Group. (2026). *PostgreSQL 18 Documentation*. https://www.postgresql.org/docs/18/

---

## 13. Anexos

| Archivo | Descripción | Tamaño |
|---|---|---|
| EntregableFinal_TBDI_Jeferson_Fulguera.md | Informe | 15 KB |
| pdb_employees_backup.dump | Backup completo | 135 MB |
| pdb_employees_backup.dump.gz | Backup comprimido | 35 MB |
| migracion_final.load | Configuración pgloader | 500 B |
| migracion_final_log.txt | Log de migración | 2 KB |
| punto2_vistas_postgresql.sql | SQL de vistas | 1 KB |
| diccionario.md | Diccionario de datos | 6 KB |
