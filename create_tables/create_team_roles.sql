CREATE TABLE employee_db.team_roles (
  system_id INT64 OPTIONS(description="Internal system ID used by the employee database"),
  team_id INT64 OPTIONS(description="Team ID"),
  title_id INT64 OPTIONS(description="Title ID"),
  employee_id STRING OPTIONS(description="Employee ID e.g. T/X-ID"),
  employee_type STRING OPTIONS(description="Type of employee e.g. FTE, contractor, vendor"),
  start_date DATE OPTIONS(description="Start date of the employee on this team in this role"),
  end_date DATE OPTIONS(description="End date of the employee on this team in this role"),
)
OPTIONS (
  description="Table containing employees and titles on teams with start and end dates"
)