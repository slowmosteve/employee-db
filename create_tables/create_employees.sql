CREATE TABLE employee_db.employees (
  employee_id INT64 OPTIONS(description="Employee ID"),
  first_name STRING OPTIONS(description="Employee first name"),
  last_name STRING OPTIONS(description="Employee last name"),
  gender STRING OPTIONS(description="Gender of the employee"),
)
OPTIONS (
  description="Table containing employee information"
)