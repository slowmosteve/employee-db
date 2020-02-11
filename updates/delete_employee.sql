-- query for deleting employee records
-- REQUIRED: employee_id

DECLARE delete_employee_id INT64;

SET delete_employee_id = 6;

-- delete from employee table
DELETE FROM employee_db.employees
WHERE employee_id = delete_employee_id;

-- delete from team_roles table
DELETE FROM employee_db.team_roles
WHERE employee_id = delete_employee_id;

-- delete from change_log table
DELETE FROM employee_db.change_log
WHERE employee_id = delete_employee_id;