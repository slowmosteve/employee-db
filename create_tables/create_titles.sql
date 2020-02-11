CREATE TABLE employee_db.titles (
  title_id INT64 OPTIONS(description="Title ID"),
  title_name STRING OPTIONS(description="Title Name")
)
OPTIONS (
  description="Table containing title IDs and names"
)