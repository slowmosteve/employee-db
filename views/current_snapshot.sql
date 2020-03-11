WITH employees AS (
  SELECT
    *
  FROM
    `test-employee-db.employee_db.employees`
),
hire_date AS (
  SELECT
    system_id,
    MIN(start_date) AS min_start_date
  FROM
    `test-employee-db.employee_db.team_roles`
  GROUP BY system_id
),
current_roles AS (
  SELECT
    system_id,
    employee_id,
    team_id,
    title_id,
    employee_type,
    start_date
  FROM
    `test-employee-db.employee_db.team_roles`
  WHERE
    end_date IS NULL
    AND employee_type NOT IN ("Former", "Leave")
),
titles AS (
  SELECT
    *
  FROM
    `test-employee-db.employee_db.titles`
),
teams AS (
  SELECT
    *
  FROM
    `test-employee-db.employee_db.teams_hierarchy`
)
SELECT
  current_roles.employee_id AS employee_id,
  employees.*,
  titles.title_id AS title_id,
  titles.title_name AS current_title,
  teams.team_id AS team_id,
  teams.team_name AS current_team,
  current_roles.employee_type AS employee_type,
  hire_date.min_start_date AS hire_start_date,
  current_roles.start_date AS current_role_start_date,
  ROUND(DATE_DIFF(CURRENT_DATE(), hire_date.min_start_date, MONTH)/12, 1) AS tenure_years
FROM employees
JOIN hire_date
ON employees.system_id = hire_date.system_id
JOIN current_roles
ON employees.system_id = current_roles.system_id
JOIN titles
ON current_roles.title_id = titles.title_id
JOIN teams
ON current_roles.team_id = teams.team_id
ORDER BY current_team, title_id