INSERT employee_db.team_roles (
  employee_id,
  team_id,
  title_id,
  employee_id,
  employee_type,
  start_date,
  end_date
)
VALUES 
    (1, 2, 3, "X001", "Contractor", "2015-01-01", "2017-01-01"),
    (1, 2, 2, "T001", "Full time", "2017-01-01", "2018-01-01"),
    (1, 1, 1, "T001", "Full time", "2018-01-01", NULL),
    (2, 2, 4, "T002", "Full time", "2016-02-01", "2018-02-01"),
    (2, 2, 2, "T002", "Full time", "2018-02-01", NULL),
    (3, 3, 3, "X002", "Contractor", "2017-03-01", "2019-03-01"),
    (3, 3, 2, "T003", "Full time", "2019-03-01", NULL),
    (4, 7, 3, "T004", "Full time", "2018-04-01", NULL),
    (5, 10, 4, "X003", "Contractor", "2019-05-01", NULL),
    (6, 7, 5, "X004", "Contractor", "2019-06-01", NULL),
    (7, 8, 3, "T005", "Full time", "2019-06-01", NULL),
    (8, 8, 7, "X005", "Contractor", "2019-06-01", NULL),
    (9, 10, 3, "T006", "Full time", "2019-06-01", NULL),
    (10, 10, 5, "X006", "Contractor", "2019-06-01", NULL),
    (11, 10, 6, "X007", "Contractor", "2019-06-01", NULL)
