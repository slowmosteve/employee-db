CREATE TABLE employee_db.employees (
  system_id INT64 OPTIONS(description="Internal system ID used by the employee database"),
  first_name STRING OPTIONS(description="Employee first name"),
  last_name STRING OPTIONS(description="Employee last name"),
)
OPTIONS (
  description="Table containing employee information"
)