INSERT employee_db.teams_hierarchy (
  team_id,
  team_level,
  team_name,
  sub_teams
)
VALUES 
    (1, "VP", "Leadership Team", [2, 3, 4, 5, 6]),
    (2, "Director", "Marketing", [7, 8]),
    (3, "Director", "Operations", [9, 10]),
    (4, "Director", "Finance", []),
    (5, "Director", "Information Technology", []),
    (6, "Director", "Human Resources", []),
    (7, "Manager", "Marketing - Squad 1", []),
    (8, "Manager", "Marketing - Squad 2", []),
    (9, "Manager", "Operations - Squad 1", []),
    (10, "Manager", "Operations - Squad 2", [])