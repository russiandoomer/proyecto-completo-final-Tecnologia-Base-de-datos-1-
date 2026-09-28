# Diccionario de Datos — Base employees

**Origen:** MariaDB 11.8.9 (contenedor Docker)
**Base de datos:** employees
**Motor:** InnoDB
**Colación:** utf8mb4_uca1400_ai_ci
**Fecha:** 28 de septiembre de 2026

---

## 1. Resumen de tablas

| Tabla | Descripción | Registros | Tamaño |
|---|---|---|---|
| departments | Catálogo de departamentos | 9 | 0.03 MB |
| employees | Datos personales de empleados | 299379 | 14.52 MB |
| dept_emp | Historial empleado-departamento | 331143 | 17.03 MB |
| dept_manager | Gerentes por departamento | 24 | 0.03 MB |
| salaries | Salarios históricos | 2838426 | 95.63 MB |
| titles | Cargos históricos | 442189 | 19.56 MB |

> **Vistas:** current_dept_emp y dept_emp_latest_date son derivadas de las tablas anteriores y no se incluyen en el diccionario.

---

## 2. Diccionario detallado

### 2.1 Tabla departments

**Descripción:** Catálogo de departamentos de la empresa. Cada departamento tiene un código único y un nombre único.

| Columna | Tipo | Long. | Nulo | Clave | Default | Comentario |
|---|---|---|---|---|---|---|
| dept_no | char | 4 | NO | PK | — | Código único del departamento (ej: d001, d002). Formato fijo de 4 caracteres. |
| dept_name | varchar | 40 | NO | UNIQUE | — | Nombre oficial del departamento (ej: Marketing, Finance). No puede repetirse. |

**Índices:** PRIMARY (dept_no), UNIQUE (dept_name)
**Registros:** 9

---

### 2.2 Tabla employees

**Descripción:** Tabla principal con datos personales de cada empleado. emp_no es la clave principal y se usa como FK en el resto de tablas.

| Columna | Tipo | Long. | Nulo | Clave | Default | Comentario |
|---|---|---|---|---|---|---|
| emp_no | int | 11 | NO | PK | — | Número único de empleado. Se usa como FK en las demás tablas. |
| birth_date | date | — | NO | — | — | Fecha de nacimiento del empleado. |
| first_name | varchar | 14 | NO | — | — | Primer nombre del empleado. |
| last_name | varchar | 16 | NO | — | — | Apellido del empleado. |
| gender | enum('M','F') | 1 | NO | — | — | Género del empleado: M = Masculino, F = Femenino. En PostgreSQL se convierte a tipo gender_enums. |
| hire_date | date | — | NO | — | — | Fecha de contratación del empleado. |

**Índices:** PRIMARY (emp_no)
**Registros:** 299379

---

### 2.3 Tabla dept_emp

**Descripción:** Tabla histórica que registra en qué departamento ha trabajado cada empleado y durante qué período.

| Columna | Tipo | Long. | Nulo | Clave | Default | Comentario |
|---|---|---|---|---|---|---|
| emp_no | int | 11 | NO | PK, FK | — | Número de empleado. FK a employees.emp_no (ON DELETE CASCADE). |
| dept_no | char | 4 | NO | PK, FK | — | Código del departamento. FK a departments.dept_no (ON DELETE CASCADE). |
| from_date | date | — | NO | PK | — | Fecha de inicio en el departamento. |
| to_date | date | — | NO | — | — | Fecha de fin en el departamento. |

**Índices:** PRIMARY (emp_no, dept_no), KEY (dept_no)
**Registros:** 331143

---

### 2.4 Tabla dept_manager

**Descripción:** Tabla histórica que registra qué empleado ha sido gerente de cada departamento y durante qué período.

| Columna | Tipo | Long. | Nulo | Clave | Default | Comentario |
|---|---|---|---|---|---|---|
| emp_no | int | 11 | NO | PK, FK | — | Número de empleado gerente. FK a employees.emp_no (ON DELETE CASCADE). |
| dept_no | char | 4 | NO | PK, FK | — | Código del departamento. FK a departments.dept_no (ON DELETE CASCADE). |
| from_date | date | — | NO | PK | — | Fecha de inicio como gerente. |
| to_date | date | — | NO | — | — | Fecha de fin como gerente. |

**Índices:** PRIMARY (emp_no, dept_no), KEY (dept_no)
**Registros:** 24

---

### 2.5 Tabla salaries

**Descripción:** Tabla histórica que registra los salarios de cada empleado a lo largo del tiempo.

| Columna | Tipo | Long. | Nulo | Clave | Default | Comentario |
|---|---|---|---|---|---|---|
| emp_no | int | 11 | NO | PK, FK | — | Número de empleado. FK a employees.emp_no (ON DELETE CASCADE). |
| salary | int | 11 | NO | — | — | Monto del salario en moneda local. |
| from_date | date | — | NO | PK | — | Fecha desde la cual aplica el salario. |
| to_date | date | — | NO | — | — | Fecha hasta la cual aplicó el salario. |

**Índices:** PRIMARY (emp_no, from_date)
**Registros:** 2838426

---

### 2.6 Tabla titles

**Descripción:** Tabla histórica que registra los cargos que ha tenido cada empleado a lo largo del tiempo.

| Columna | Tipo | Long. | Nulo | Clave | Default | Comentario |
|---|---|---|---|---|---|---|
| emp_no | int | 11 | NO | PK, FK | — | Número de empleado. FK a employees.emp_no (ON DELETE CASCADE). |
| title | varchar | 50 | NO | PK | — | Nombre del cargo (ej: Senior Engineer, Manager). |
| from_date | date | — | NO | PK | — | Fecha de inicio del cargo. |
| to_date | date | — | YES | — | NULL | Fecha de fin del cargo. Puede ser NULL si el cargo sigue vigente. |

**Índices:** PRIMARY (emp_no, title, from_date)
**Registros:** 442189

---

## 3. Relaciones de integridad referencial

| Tabla origen | Columna | Tabla destino | Columna | ON DELETE | Restricción |
|---|---|---|---|---|---|
| dept_emp | emp_no | employees | emp_no | CASCADE | dept_emp_ibfk_1 |
| dept_emp | dept_no | departments | dept_no | CASCADE | dept_emp_ibfk_2 |
| dept_manager | emp_no | employees | emp_no | CASCADE | dept_manager_ibfk_1 |
| dept_manager | dept_no | departments | dept_no | CASCADE | dept_manager_ibfk_2 |
| salaries | emp_no | employees | emp_no | CASCADE | salaries_ibfk_1 |
| titles | emp_no | employees | emp_no | CASCADE | titles_ibfk_1 |

> Todos los FK usan ON DELETE CASCADE. Al eliminar un empleado se eliminan automáticamente sus registros en dept_emp, dept_manager, salaries y titles.

---

## 4. Observaciones para la migración a PostgreSQL

| Elemento | MariaDB | PostgreSQL | Acción |
|---|---|---|---|
| gender | enum('M','F') | gender_enums | Crear CREATE TYPE gender_enums AS ENUM ('M','F') |
| int(11) | int | INTEGER / BIGINT | Mapeo directo |
| varchar(n) | varchar(14) | character varying(14) | Mapeo directo |
| char(4) | char(4) | character(4) | Mapeo directo |
| date | date | date | Mapeo directo |
| ENGINE=InnoDB | — | — | Eliminar cláusula |
| utf8mb4 | — | UTF8 | Configurar base |
| Backticks | — | Comillas dobles | Reemplazar |
