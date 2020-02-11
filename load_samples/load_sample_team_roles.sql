INSERT employee_db.team_roles (
  employee_id,
  team_id,
  title_id,
  employee_type,
  start_date,
  end_date
)
VALUES 
    (1, 2, 3, "Contractor", "2015-01-01", "2017-01-01"),
    (1, 2, 2, "Full time", "2017-01-01", "2018-01-01"),
    (1, 1, 1, "Full time", "2018-01-01", NULL),
    (2, 2, 4, "Full time", "2016-02-01", "2018-02-01"),
    (2, 2, 2, "Full time", "2018-02-01", NULL),
    (3, 3, 3, "Contractor", "2017-03-01", "2019-03-01"),
    (3, 3, 2, "Full time", "2019-03-01", NULL),
    (4, 7, 3, "Full time", "2018-04-01", NULL),
    (5, 10, 4, "Contractor", "2019-05-01", NULL),
    (6, 7, 5, "Contractor", "2019-06-01", NULL),
    (7, 8, 3, "Full time", "2019-06-01", NULL),
    (8, 8, 7, "Contractor", "2019-06-01", NULL),
    (9, 10, 3, "Full time", "2019-06-01", NULL),
    (10, 10, 5, "Contractor", "2019-06-01", NULL),
    (11, 10, 6, "Contractor", "2019-06-01", NULL)
