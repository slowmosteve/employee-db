function onOpen() {
  // creates custom menus commands
  var ui = SpreadsheetApp.getUi();
  ui.createMenu('Employee DB Refresh')
    .addItem('Current snapshot', 'currentSnapshot')
    .addSeparator()
    .addItem('Former employees', 'formerEmployees')
    .addSeparator()
    .addItem('Monthly report', 'monthlyReport')
    .addToUi();
  ui.createMenu('Employee DB Update')
    .addItem('Add employees', 'addEmployees')
    .addSeparator()
    .addItem('Change employees', 'changeEmployees')
    .addSeparator()
    .addItem('Delete employees', 'deleteEmployees')
    .addToUi();
}

function currentSnapshot() {
  // overwrites the Current Snapshot sheet with the latest view
  var project_id = 'test-employee-db';
  var sheet_name = 'Current Snapshot';
  var query_string = 'SELECT * FROM employee_db.current_snapshot';
  updateSheet(project_id, sheet_name, query_string);
}

function formerEmployees() {
  // overwrites the Former Employees sheet with the latest view
  var project_id = 'test-employee-db';
  var sheet_name = 'Former Employees';
  var query_string = 'SELECT * FROM employee_db.former_employees';
  updateSheet(project_id, sheet_name, query_string);
}

function monthlyReport() {
  // overwrites the Monthly Report sheet with the latest view
  var project_id = 'test-employee-db';
  var sheet_name = 'Monthly Report';
  var query_string = 'SELECT * FROM employee_db.monthly_report';
  updateSheet(project_id, sheet_name, query_string);
}

function updateSheet(project_id, sheet_name, query_string) {
  // function to update sheets based on BigQuery views
  var projectId = project_id;
  var sheetName = sheet_name;
  var request = {
    query: query_string,
    useLegacySql: false
  };
  var queryResults = BigQuery.Jobs.query(request, projectId);
  var jobId = queryResults.jobReference.jobId;

  // check status
  var sleepTimeMs = 500;
  while (!queryResults.jobComplete) {
    Utilities.sleep(sleepTimeMs);
    sleepTimeMs *= 2;
    queryResults = BigQuery.Jobs.getQueryResults(projectId, jobId);
  }
  
  // store results in an array
  var rows = queryResults.rows;
  while (queryResults.pageToken) {
    queryResults = BigQuery.Jobs.getQueryResults(projectId, jobId, {
      pageToken: queryResults.pageToken
    });
    rows = rows.concat(queryResults.rows);
  }

  if (rows) {
    console.info('%d rows found.', rows.length);
    var data = new Array(rows.length);
    for (var i = 0; i < rows.length; i++) {
      var cols = rows[i].f;
      data[i] = new Array(cols.length);
      for (var j = 0; j < cols.length; j++) {
        data[i][j] = cols[j].v;
      }
    }
    
    // get the sheet sheetName and clear it or create a new sheet and rename to sheetName
    var ss = SpreadsheetApp.getActiveSpreadsheet();
    var currentSheet = ss.getSheetByName(sheetName);
    if (currentSheet === null) {
      currentSheet = ss.insertSheet(99);
      ss.renameActiveSheet(sheetName);
    } else {
      currentSheet.clear();
    }
    
    // get the column headers from the query and append them to the first row
    var headers = queryResults.schema.fields.map(function(field) {
      return field.name;
    });
    currentSheet.appendRow(headers);

    // populate the query results starting on row 2
    if (rows) {
      currentSheet.getRange(2, 1, rows.length, headers.length)
        .setValues(data)
    };
    
    // remove empty rows then resize columns
    var maxRows = currentSheet.getMaxRows();
    var lastRow = currentSheet.getLastRow();
    if (maxRows == lastRow){}
    else {currentSheet.deleteRows(lastRow+1, maxRows-lastRow)}
    currentSheet.autoResizeColumns(1,20)
    
    console.info('%d rows inserted.', rows.length);
  } else {
    console.info('No results found in BigQuery');
  }
}

// query used for adding employees
var addEmployeeQuery = `
  DECLARE max_employee_id INT64;
  SET max_employee_id = (
    SELECT 
      MAX(employee_id)
    FROM employee_db.employees
  );
  INSERT employee_db.employees (
    employee_id,
    first_name,
    last_name,
    gender
  )
  SELECT
    max_employee_id + ROW_NUMBER() OVER (ORDER BY first_name, last_name, team_id, title_id, start_date) AS employee_id,
    first_name,
    last_name,
    gender
  FROM \`test-employee-db.staging.add_employee\`;
  INSERT
    employee_db.team_roles (
      employee_id,
      team_id,
      title_id,
      employee_type,
      start_date
    )
  SELECT
    max_employee_id + ROW_NUMBER() OVER (ORDER BY first_name, last_name, team_id, title_id, start_date) AS employee_id,
    team_id,
    title_id,
    employee_type,
    SAFE.PARSE_DATE("%a %b %d %Y", SPLIT(start_date, ' 00:00:00 GMT')[OFFSET(0)]) AS start_date
  FROM
    \`test-employee-db.staging.add_employee\`;
  INSERT employee_db.change_log (
      change_date,
      change_type,
      employee_id,
      new_state
    )
  SELECT
    CURRENT_DATE() AS current_date,
    "New hire" AS change_type,
    max_employee_id + ROW_NUMBER() OVER (ORDER BY first_name, last_name, team_id, title_id, start_date) AS employee_id,
    [
      STRUCT("title_id" AS name, CAST(title_id AS STRING) AS value),
      STRUCT("team_id" AS name, CAST(team_id AS STRING) AS value),
      STRUCT("employee_type" AS name, employee_type AS value),
      STRUCT("start_date" AS name, CAST(SAFE.PARSE_DATE("%a %b %d %Y", SPLIT(start_date, ' 00:00:00 GMT')[OFFSET(0)]) AS STRING) AS value)
    ] AS new_state
  FROM
    \`test-employee-db.staging.add_employee\`;
  DELETE
  FROM
    \`test-employee-db.staging.add_employee\`
  WHERE
    TRUE;
  `;

function addEmployees() {
  // function for adding new employees
  var date = new Date();
  var projectId = 'test-employee-db';
  var staging_datasetId = 'staging';
  var staging_tableId = 'add_employee';
  var sheetName = 'Add Employees';
  var ss = SpreadsheetApp.getActiveSpreadsheet();
  var currentSheet = ss.getSheetByName(sheetName);
  
  // define staging table reference and schema
  var table = {
    tableReference: {
      projectId: projectId,
      datasetId: staging_datasetId,
      tableId: staging_tableId
    },
    schema: {
      fields: [
        {name: 'first_name', type: 'STRING'},
        {name: 'last_name', type: 'STRING'},
        {name: 'team_id', type: 'INTEGER'},
        {name: 'title_id', type: 'INTEGER'},
        {name: 'employee_type', type: 'STRING'},
        {name: 'gender', type: 'STRING'},
        {name: 'start_date', type: 'STRING'}
      ]
    }
  };
  
  // append the staging table
  var writeDispositionSetting = 'WRITE_APPEND';
  try {BigQuery.Tables.get(projectId, staging_datasetId, staging_tableId)}
  catch (error) {
    table = BigQuery.Tables.insert(table, projectId, staging_datasetId);
    Logger.log('Table created: %s', table.id);
  }
  
  var lastRow = currentSheet.getRange(currentSheet.getLastRow(),1)
                  .getNextDataCell(SpreadsheetApp.Direction.UP)
                  .getLastRow() + 1;
  var lastColumn = currentSheet.getRange(5,1)
                  .getNextDataCell(SpreadsheetApp.Direction.NEXT)
                  .getLastColumn();
  Logger.log('last row: ' + lastRow + ', last column: ' + lastColumn);
  var rows = currentSheet.getRange(6, 1, 2, 7).getValues();
  var row_range = [];
  rows.forEach(function (item, index) {
    console.log(item, index);
    row_range[index] = rows[index].slice(0,7);
    
    var rowsCSV = row_range[index].join(", ");
    var blob = Utilities.newBlob(rowsCSV, "text/csv");
    var data = blob.setContentType('application/octet-stream');
    
    // create the data upload job.
    var staging_job = {
      configuration: {
        load: {
          destinationTable: {
            projectId: projectId,
            datasetId: staging_datasetId,
            tableId: staging_tableId
          },
          skipLeadingRows: 0,
          writeDisposition: writeDispositionSetting
        }
      }
    };
    
    // run the staging table insert job
    var runJob = BigQuery.Jobs.insert(staging_job, projectId, data);
    Logger.log(runJob.status);
    var jobId = runJob.jobReference.jobId
    var status = BigQuery.Jobs.get(projectId, jobId);
    
    // wait for query to finish
    while (status.status.state === 'RUNNING') {
      Utilities.sleep(500);
      status = BigQuery.Jobs.get(projectId, jobId);
      Logger.log('Staging status: ' + status);
    }

  });
  
  Logger.log('Starting insert job');
  // insert the new data into production tables
  var insert_job = {
    query: addEmployeeQuery,
    useLegacySql: false
  };

  var queryResults = BigQuery.Jobs.query(insert_job, projectId);
  var insert_jobId = queryResults.jobReference.jobId;

  // check status
  var insert_status = BigQuery.Jobs.get(projectId, insert_jobId);
  var sleepTimeMs = 500;
  while (insert_status.status.state === 'RUNNING') {
    Utilities.sleep(sleepTimeMs);
    sleepTimeMs *= 2;
    insert_status = BigQuery.Jobs.get(projectId, insert_jobId);
    Logger.log('Insert status: ' + status);
  }
  // clear cells below headers once job is complete
  Logger.log('Job state: ' + insert_status.status.state);
  if (insert_status.status.state === 'DONE') {
    var range = currentSheet.getRange("A6:Z1000");
    range.clear();
  }
}