WITH employees AS (
  SELECT
    *
  FROM
    `test-employee-db.employee_db.employees`
),
former_employees AS (
  SELECT
    system_id,
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
    system_id,
    MIN(start_date) AS min_start_date
  FROM
    `test-employee-db.employee_db.team_roles`
  GROUP BY system_id
),
last_change_date AS (
  SELECT
    system_id,
    MAX(new_state.value) AS last_change_date
  FROM
    `test-employee-db.employee_db.change_log`,
    UNNEST (new_state) AS new_state
  WHERE
    new_state.name = "start_date"
  GROUP BY
    system_id
),
last_status AS (
  SELECT
    change_log.system_id,
    change_log.change_type,
    change_log.old_state,
    change_log.new_state
  FROM
    `test-employee-db.employee_db.change_log` AS change_log,
    UNNEST (new_state) AS new_state
  JOIN last_change_date
  ON 
    change_log.system_id = last_change_date.system_id
    AND new_state.value = last_change_date.last_change_date
),
last_team AS (
  SELECT
    system_id,
    old_state.value AS team_id
  FROM
    last_status,
    UNNEST (old_state) AS old_state
  WHERE
    old_state.name = "team_id"
),
last_title AS (
  SELECT
    system_id,
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
ON employees.system_id = hire_date.system_id
JOIN former_employees
ON employees.system_id = former_employees.system_id
JOIN last_change_date
ON former_employees.system_id = last_change_date.system_id
JOIN last_status
ON former_employees.system_id = last_status.system_id
JOIN last_team
ON former_employees.system_id = last_team.system_id
JOIN last_title
ON former_employees.system_id = last_title.system_id
JOIN `test-employee-db.employee_db.teams_hierarchy` AS teams
ON CAST(teams.team_id AS STRING) = last_team.team_id
JOIN `test-employee-db.employee_db.titles` AS titles
ON CAST(titles.title_id AS STRING) = last_title.title_id