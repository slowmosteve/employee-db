WITH employees AS (
  SELECT
    *
  FROM
    `test-employee-db.employee_db.employees`
),
former_employees AS (
  SELECT
    employee_id,
    team_id,
    title_id,
    employee_type,
    start_date
  FROM
    `test-employee-db.employee_db.team_roles`
  WHERE
    end_date IS NULL
    AND employee_type = "Former"
),
hire_date AS (
  SELECT
    employee_id,
    MIN(start_date) AS min_start_date
  FROM
    `test-employee-db.employee_db.team_roles`
  GROUP BY employee_id
),
last_change_date AS (
  SELECT
    employee_id,
    MAX(new_state.value) AS last_change_date
  FROM
    `test-employee-db.employee_db.change_log`,
    UNNEST (new_state) AS new_state
  WHERE
    new_state.name = "start_date"
  GROUP BY
    employee_id
),
last_status AS (
  SELECT
    change_log.employee_id,
    change_log.change_type,
    change_log.old_state,
    change_log.new_state
  FROM
    `test-employee-db.employee_db.change_log` AS change_log,
    UNNEST (new_state) AS new_state
  JOIN last_change_date
  ON 
    change_log.employee_id = last_change_date.employee_id
    AND new_state.value = last_change_date.last_change_date
),
last_team AS (
  SELECT
    employee_id,
    old_state.value AS team_id
  FROM
    last_status,
    UNNEST (old_state) AS old_state
  WHERE
    old_state.name = "team_id"
),
last_title AS (
  SELECT
    employee_id,
    old_state.value AS title_id
  FROM
    last_status,
    UNNEST (old_state) AS old_state
  WHERE
    old_state.name = "title_id"
)
SELECT
  employees.*,
  former_employees.employee_type AS employee_type,
  hire_date.min_start_date AS hire_start_date,
  last_change_date.last_change_date AS last_change_date,
  last_status.change_type AS change_type,
  teams.team_name AS last_team,
  titles.title_name AS last_title,
  ROUND(DATE_DIFF(CAST(last_change_date.last_change_date AS DATE), hire_date.min_start_date, MONTH)/12, 1) AS tenure_years
FROM employees
JOIN hire_date
ON employees.employee_id = hire_date.employee_id
JOIN former_employees
ON employees.employee_id = former_employees.employee_id
JOIN last_change_date
ON former_employees.employee_id = last_change_date.employee_id
JOIN last_status
ON former_employees.employee_id = last_status.employee_id
JOIN last_team
ON former_employees.employee_id = last_team.employee_id
JOIN last_title
ON former_employees.employee_id = last_title.employee_id
JOIN `test-employee-db.employee_db.teams_hierarchy` AS teams
ON CAST(teams.team_id AS STRING) = last_team.team_id
JOIN `test-employee-db.employee_db.titles` AS titles
ON CAST(titles.title_id AS STRING) = last_title.title_id