-- query for deleting employee records
-- REQUIRED: system_id

DECLARE delete_system_id INT64;

SET delete_system_id = 6;

-- delete from employee table
DELETE FROM employee_db.employees
WHERE system_id = delete_system_id;

-- delete from team_roles table
DELETE FROM employee_db.team_roles
WHERE system_id = delete_system_id;

-- delete from change_log table
DELETE FROM employee_db.change_log
WHERE system_id = delete_system_id;