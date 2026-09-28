-- ============================================================
-- Vistas adaptadas de MariaDB a PostgreSQL
-- Base: pdb_employees
-- Schema: employees
-- ============================================================

-- ------------------------------------------------------------
-- Vista 1: dept_emp_latest_date
-- Descripción: Última fecha (from_date, to_date) por empleado
-- Adaptación: se eliminaron backticks y la cláusula
--             ALGORITHM=UNDEFINED DEFINER=... SQL SECURITY DEFINER
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW employees.dept_emp_latest_date AS
SELECT
    emp_no,
    MAX(from_date) AS from_date,
    MAX(to_date) AS to_date
FROM employees.dept_emp
GROUP BY emp_no;

-- ------------------------------------------------------------
-- Vista 2: current_dept_emp
-- Descripción: Departamento actual de cada empleado, uniendo
--              dept_emp con la última fecha registrada
-- Depende de: employees.dept_emp_latest_date
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW employees.current_dept_emp AS
SELECT
    l.emp_no,
    d.dept_no,
    l.from_date,
    l.to_date
FROM employees.dept_emp d
JOIN employees.dept_emp_latest_date l
    ON d.emp_no = l.emp_no
   AND d.from_date = l.from_date
   AND l.to_date = d.to_date;
