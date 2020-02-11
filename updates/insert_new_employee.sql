-- query for adding new employees
-- employee IDs are incremented from existing IDs
-- REQUIRED: first_name, last_name, team_id, title_id, employee_type, gender

DECLARE new_employee_id INT64;
DECLARE first_name STRING;
DECLARE last_name STRING;
DECLARE team_id INT64;
DECLARE title_id INT64;
DECLARE employee_type STRING;
DECLARE gender STRING;
DECLARE start_date DATE;
DECLARE current_date DATE;
DECLARE new_employee_state ARRAY<STRUCT<name STRING, value STRING>>;

SET first_name = "First Name";
SET last_name = "Last Name";
SET team_id = NULL;
SET title_id = NULL;
SET employee_type = "Contractor"; -- Contractor, Full time
SET gender = NULL;
SET start_date = CURRENT_DATE();
SET current_date = CURRENT_DATE();
SET new_employee_id = (
  SELECT 
    MAX(employee_id) + 1
  FROM employee_db.employees
);
SET new_employee_state = [
  STRUCT(
    "title_id" AS name,
    CAST(title_id AS STRING) AS value
  ),
  STRUCT(
    "team_id" AS name,
    CAST(team_id AS STRING) AS value
  ),
  STRUCT(
    "employee_type" AS name,
    CAST(employee_type AS STRING) AS value
  ),
  STRUCT(
    "start_date" AS name,
    CAST(start_date AS STRING) AS value
  )
];

INSERT employee_db.employees (
  employee_id,
  first_name,
  last_name,
  gender
)
VALUES (new_employee_id, first_name, last_name, gender);

INSERT employee_db.team_roles (
  employee_id,
  team_id,
  title_id,
  employee_type,
  start_date
)
VALUES 
    (new_employee_id, team_id, title_id, employee_type, start_date);

INSERT employee_db.change_log (
  change_date,
  change_type,
  employee_id,
  new_state
)
VALUES (
  current_date, 
  "New hire", 
  new_employee_id, 
  new_employee_state
);