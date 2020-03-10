-- query for updating employee records
-- REQUIRED: employee_id, change_date, change_type, new_team_id, new_title_id, new_employee_type

DECLARE change_system_id INT64;
DECLARE change_date DATE;
DECLARE change_type STRING;
DECLARE new_team_id INT64;
DECLARE new_title_id INT64;
DECLARE new_employee_type STRING;
DECLARE old_employee_state ARRAY<STRUCT<name STRING, value STRING>>;
DECLARE new_employee_state ARRAY<STRUCT<name STRING, value STRING>>;

SET change_system_id = 6;
SET change_date = CURRENT_DATE();
SET change_type = "Promotion"; -- Promotion, Contractor to FTE, Team Change, Termination, Voluntary Exit
SET new_team_id = 2;
SET new_title_id = 2;
SET new_employee_type = "Full time"; -- Contractor, Full time, Leave, Former
SET new_employee_state = [
  STRUCT(
    "title_id" AS name,
    CAST(new_title_id AS STRING) AS value
  ),
  STRUCT(
    "team_id" AS name,
    CAST(new_team_id AS STRING) AS value
  ),
  STRUCT(
    "employee_type" AS name,
    CAST(new_employee_type AS STRING) AS value
  ),
  STRUCT(
    "start_date" AS name,
    CAST(change_date AS STRING) AS value
  )
];
SET old_employee_state = (
  WITH old_state AS (
    SELECT
      title_id,
      team_id,
      employee_type,
      start_date
    FROM
      employee_db.team_roles
    WHERE
      system_id = change_system_id  
      AND end_date IS NULL
  )
  SELECT
    ARRAY[
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
    ]
  FROM old_state
);

-- update previous role with end date
UPDATE employee_db.team_roles
SET end_date = change_date
WHERE
  system_id = change_system_id
  AND end_date IS NULL;

-- add new role
INSERT employee_db.team_roles (
  system_id,
  team_id,
  title_id,
  employee_type,
  start_date
)
VALUES 
    (change_system_id, new_team_id, new_title_id, new_employee_type, change_date);

-- update change log
INSERT employee_db.change_log (
  change_date,
  change_type,
  system_id,
  old_state,
  new_state
)
VALUES (
  current_date, 
  change_type, 
  change_system_id, 
  old_employee_state,
  new_employee_state
);