WITH months AS (
  SELECT
    dt
  FROM UNNEST(
      GENERATE_DATE_ARRAY(DATE('2015-01-01'), CURRENT_DATE(), INTERVAL 1 MONTH)
  ) AS dt
),
team_roles AS (
  SELECT
    team_roles.start_date,
    team_roles.end_date,
    team_roles.system_id,
    employees.first_name,
    team_roles.title_id,
    titles.title_name,
    team_roles.employee_type,
    team_roles.team_id,
    ROW_NUMBER() OVER (PARTITION BY team_roles.system_id ORDER BY team_roles.start_date) AS row_number,
    LAG(titles.title_name) OVER (PARTITION BY team_roles.system_id ORDER BY team_roles.start_date) AS last_title,
    LAG(team_roles.team_id) OVER (PARTITION BY team_roles.system_id ORDER BY team_roles.start_date) AS last_team,
    LAG(team_roles.employee_type) OVER (PARTITION BY team_roles.system_id ORDER BY team_roles.start_date) AS last_employee_type,
  FROM `test-employee-db.employee_db.team_roles` AS team_roles
  LEFT JOIN `test-employee-db.employee_db.employees` AS employees
  ON team_roles.system_id = employees.system_id
  LEFT JOIN `test-employee-db.employee_db.titles` AS titles
  ON team_roles.title_id = titles.title_id
),
new_hires AS (
  SELECT
    start_date,
    system_id,
    title_id,
    team_id
  FROM team_roles
  WHERE row_number = 1
),
promotions AS (
  SELECT
    start_date,
    system_id,
    title_id,
    team_id
  FROM team_roles
  WHERE
    row_number <> 1
    AND title_name <> last_title
),
team_changes AS (
  SELECT
    start_date,
    system_id,
    title_id,
    team_id
  FROM team_roles
  WHERE
    row_number <> 1
    AND team_id <> last_team
),
contract_conversions AS (
  SELECT
    start_date,
    system_id,
    title_id,
    team_id
  FROM team_roles
  WHERE
    row_number <> 1
    AND employee_type = "Full time"
    AND last_employee_type = "Contractor"
),
former_employees AS (
  SELECT
    start_date,
    system_id,
    title_id,
    team_id
  FROM team_roles
  WHERE
    employee_type = "Former"
),
summary AS (
  SELECT
    months.*,
    team_roles.*,
    CASE WHEN new_hires.system_id IS NOT NULL THEN 1 END AS new_hire_ind,
    CASE WHEN promotions.system_id IS NOT NULL THEN 1 END AS promotion_ind,
    CASE WHEN team_changes.system_id IS NOT NULL THEN 1 END AS team_change_ind,
    CASE WHEN contract_conversions.system_id IS NOT NULL THEN 1 END AS contract_conversion_ind,
    CASE WHEN former_employees.system_id IS NOT NULL THEN 1 END AS exit_ind,
    COUNT(new_hires.system_id) OVER (ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS employee_count
  FROM months
  LEFT JOIN team_roles
  ON
    EXTRACT(YEAR FROM months.dt) = EXTRACT(YEAR FROM team_roles.start_date)
    AND EXTRACT(MONTH FROM months.dt) = EXTRACT(MONTH FROM team_roles.start_date)
  LEFT JOIN new_hires
  ON
    team_roles.start_date = new_hires.start_date
    AND team_roles.system_id = new_hires.system_id
  LEFT JOIN promotions
  ON
    team_roles.start_date = promotions.start_date
    AND team_roles.system_id = promotions.system_id
  LEFT JOIN team_changes
  ON
    team_roles.start_date = team_changes.start_date
    AND team_roles.system_id = team_changes.system_id
  LEFT JOIN contract_conversions
  ON
    team_roles.start_date = contract_conversions.start_date
    AND team_roles.system_id = contract_conversions.system_id
  LEFT JOIN former_employees
  ON
    team_roles.start_date = former_employees.start_date
    AND team_roles.system_id = former_employees.system_id
)
SELECT
  dt,
  MAX(employee_count) - COUNT(exit_ind) AS net_employee_count,
  COUNT(new_hire_ind) AS new_hires,
  COUNT(promotion_ind) AS promotions,
  COUNT(team_change_ind) AS team_changes,
  COUNT(contract_conversion_ind) AS contract_conversions,
  COUNT(exit_ind) AS exits
FROM summary
GROUP BY dt
ORDER BY dt
