CREATE TABLE employee_db.change_log (
  change_date DATE OPTIONS(description="Date of change"),
  change_type STRING OPTIONS(description="Type of change e.g. promotion, team change, contract to FTE, termination"),
  system_id INT64 OPTIONS(description="Internal system ID used by the employee database"),
  old_state ARRAY<
    STRUCT<
      name STRING,
      value STRING>
    >
    OPTIONS(description="Previous state of employee record"),
  new_state ARRAY<
    STRUCT<
      name STRING,
      value STRING>
    >
    OPTIONS(description="New state of employee record"),
)
OPTIONS (
  description="Table containing log of changes for employees"
)