WITH hierarchy AS (
  SELECT
    * EXCEPT (sub_teams),
    sub_teams
  FROM `test-employee-db.employee_db.teams_hierarchy`,
    UNNEST (sub_teams) AS sub_teams
),
team_roles AS (
  SELECT *
  FROM `test-employee-db.employee_db.team_roles`
  WHERE
    end_date IS NULL
    AND title_id IN (1, 2, 3)
),
sub_team_managers AS (
  SELECT
    team_id,
    first_name
  FROM `test-employee-db.employee_db.team_roles` AS team_roles
  JOIN `test-employee-db.employee_db.employees` AS employees
  ON team_roles.system_id = employees.system_id
  WHERE
    end_date IS NULL
    AND title_id IN (2, 3)
),
sub_team_stats AS (
  SELECT
    team_id,
    SUM(CASE WHEN title_id = 2 THEN 1 ELSE 0 END) AS count_directors,
    SUM(CASE WHEN title_id = 3 THEN 1 ELSE 0 END) AS count_managers,
    SUM(CASE WHEN title_id NOT IN (1, 2, 3) THEN 1 ELSE 0 END) AS count_team_members
  FROM `test-employee-db.employee_db.team_roles` 
  WHERE
    end_date IS NULL
  GROUP BY team_id
),
-- sub_team_roles AS (
--   SELECT
--     team_roles.*,
--     employees.first_name,
--     titles.title_name,
--   FROM `test-employee-db.employee_db.team_roles` AS team_roles
--   JOIN `test-employee-db.employee_db.employees` AS employees
--   ON team_roles.employee_id = employees.employee_id
--   JOIN `test-employee-db.employee_db.titles` AS titles
--   ON team_roles.title_id = titles.title_id
--   WHERE
--     team_roles.end_date IS NULL
--     AND team_roles.title_id NOT IN (1, 2, 3)
-- ),
employees AS (
  SELECT *
  FROM `test-employee-db.employee_db.employees`
),
titles AS (
  SELECT *
  FROM `test-employee-db.employee_db.titles`
),
teams AS (
  SELECT team_id, team_name
  FROM `test-employee-db.employee_db.teams_hierarchy`
)
SELECT
  hierarchy.team_id,
  hierarchy.team_level,
  hierarchy.team_name,
  team_roles.system_id,
  employees.first_name,
  team_roles.title_id,
  titles.title_name,
  hierarchy.sub_teams,
  teams.team_name AS sub_team_name,
  sub_team_managers.first_name AS team_manager,
  CASE WHEN team_level = "VP" THEN sub_team_stats.count_directors END AS count_directors,
  CASE WHEN team_level = "Director" THEN sub_team_stats.count_managers 
    ELSE NULL
    END AS count_managers,
  CASE WHEN team_level = "Director" THEN sub_team_stats.count_team_members 
    ELSE NULL
    END AS count_team_members,
--   sub_team_roles.employee_id AS sub_team_employee_id,
--   sub_team_roles.first_name AS sub_team_employee_name,
--   sub_team_roles.title_name AS sub_team_employee_title,
--   sub_team_roles.employee_type,
--   sub_team_roles.start_date
FROM hierarchy
LEFT JOIN team_roles
ON hierarchy.team_id = team_roles.team_id
LEFT JOIN employees
ON team_roles.system_id = employees.system_id
LEFT JOIN titles
ON team_roles.title_id = titles.title_id
LEFT JOIN teams
ON hierarchy.sub_teams = teams.team_id
LEFT JOIN sub_team_managers
ON hierarchy.sub_teams = sub_team_managers.team_id
LEFT JOIN sub_team_stats
ON hierarchy.sub_teams = sub_team_stats.team_id
-- LEFT JOIN sub_team_roles
-- ON hierarchy.sub_teams = sub_team_roles.team_id
ORDER BY team_id