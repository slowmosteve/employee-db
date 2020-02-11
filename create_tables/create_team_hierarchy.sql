CREATE TABLE employee_db.teams_hierarchy (
  team_id INT64 OPTIONS(description="Team ID"),
  team_level STRING OPTIONS(description="Type of team e.g. manager, director, VP"),
  team_name STRING OPTIONS(description="Team name"),
  sub_teams ARRAY<STRING> OPTIONS(description="Array of teams that are contained within this team"),
)
OPTIONS (
  description="Table containing team IDs and names with hierarchical relationships"
)