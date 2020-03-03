/**
 * A special function that runs when the spreadsheet is first
 * opened or reloaded. onOpen() is used to add custom menu
 * items to the spreadsheet.
 */
function onOpen() {
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
  // Overwrites the Current Snapshot sheet with the latest view
  var project_id = 'test-employee-db';
  var sheet_name = 'Current Snapshot';
  var query_string = 'SELECT * FROM employee_db.current_snapshot';
  updateSheet(project_id, sheet_name, query_string);
}

function formerEmployees() {
  // Overwrites the Former Employees sheet with the latest view
  var project_id = 'test-employee-db';
  var sheet_name = 'Former Employees';
  var query_string = 'SELECT * FROM employee_db.former_employees';
  updateSheet(project_id, sheet_name, query_string);
}

function monthlyReport() {
  // Overwrites the Monthly Report sheet with the latest view
  var project_id = 'test-employee-db';
  var sheet_name = 'Monthly Report';
  var query_string = 'SELECT * FROM employee_db.monthly_report';
  updateSheet(project_id, sheet_name, query_string);
}

function updateSheet(project_id, sheet_name, query_string) {
  // Replace this value with your project ID and the name of the sheet to update.
  var projectId = project_id;
  var sheetName = sheet_name;

  // Submit query
  var request = {
    query: query_string,
    useLegacySql: false
  };
  var queryResults = BigQuery.Jobs.query(request, projectId);
  var jobId = queryResults.jobReference.jobId;

  // Check on status
  var sleepTimeMs = 500;
  while (!queryResults.jobComplete) {
    Utilities.sleep(sleepTimeMs);
    sleepTimeMs *= 2;
    queryResults = BigQuery.Jobs.getQueryResults(projectId, jobId);
  }
  
  // Get all the rows of results
  var rows = queryResults.rows;
  while (queryResults.pageToken) {
    queryResults = BigQuery.Jobs.getQueryResults(projectId, jobId, {
      pageToken: queryResults.pageToken
    });
    rows = rows.concat(queryResults.rows);
  }
  
  if (rows) {
    console.info('%d rows found.', rows.length);
    // Append the results to an array
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
    
    //remove empty rows
    var maxRows = currentSheet.getMaxRows();
    var lastRow = currentSheet.getLastRow();
    if (maxRows == lastRow){}
    else {currentSheet.deleteRows(lastRow+1, maxRows-lastRow)}
    
    // resize columns
    currentSheet.autoResizeColumns(1,20)
    
    console.info('%d rows inserted.', rows.length);
  } else {
    console.info('No results found in BigQuery');
  }
}

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
  `;

function addEmployees() {
  // Update project ID, dataset, table
  var date = new Date();
  var unixtime = date.getTime();
  var projectId = 'test-employee-db';
  var staging_datasetId = 'staging';
  var staging_tableId = 'add_employee';

  // The URL of the Google Spreadsheet you wish to export to BigQuery:
  // var url = 'https://docs.google.com/spreadsheets/d/1g32v_5JuhhC-cPGZzCborJHrfp2xBY9X9DpNkN0ZrjI/';
  var sheetName = 'Add Employees';
  var ss = SpreadsheetApp.getActiveSpreadsheet();
  var currentSheet = ss.getSheetByName(sheetName);
  
  // Create the table.
  var table = {
    tableReference: {
      projectId: projectId,
      datasetId: staging_datasetId,
      tableId: staging_tableId
    },
    // Details about schema can be found here: https://cloud.google.com/bigquery/docs/schemas
    // Enter a schema below:
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
  
  // Overwrite the staging table
  var writeDispositionSetting = 'WRITE_TRUNCATE';
  try {BigQuery.Tables.get(projectId, staging_datasetId, staging_tableId)}
  catch (error) {
    table = BigQuery.Tables.insert(table, projectId, staging_datasetId);
    Logger.log('Table created: %s', table.id);
  }
  
  // read all rows 
  // var file = SpreadsheetApp.openByUrl(url).getSheetByName(sheetName);
  // var rows = file.getDataRange().getValues();
  // var lastRow = currentSheet.getLastRow();
  // var lastColumn = currentSheet.getLastColumn();
  var lastRow = currentSheet.getRange(currentSheet.getLastRow(),1)
                  .getNextDataCell(SpreadsheetApp.Direction.UP)
                  .getLastRow() + 1;
  var lastColumn = currentSheet.getRange(5, currentSheet.getLastColumn())
                  .getNextDataCell(SpreadsheetApp.Direction.NEXT)
                  .getLastColumn();
  Logger.log('last row: ' + lastRow + ', last column: ' + lastColumn);
  var rows = currentSheet.getRange(6, 1, 6, 7).getValues();
  Logger.log('data: ' + rows)
  var rowsCSV = rows.join("\n");
  var blob = Utilities.newBlob(rowsCSV, "text/csv");
  var data = blob.setContentType('application/octet-stream');

  // Create the data upload job.
  var staging_job = {
    configuration: {
      load: {
        destinationTable: {
          projectId: projectId,
          datasetId: staging_datasetId,
          tableId: staging_tableId
        },
        skipLeadingRows: 1,
        writeDisposition: writeDispositionSetting
      }
    }
  };
  
  // send the job to BigQuery so it will run your query
  var runJob = BigQuery.Jobs.insert(staging_job, projectId, data);
  Logger.log(runJob.status);
  var jobId = runJob.jobReference.jobId
  Logger.log('jobId: ' + jobId);
  var status = BigQuery.Jobs.get(projectId, jobId);
  
  // wait for the query to finish running before you move on
  while (status.status.state === 'RUNNING') {
    Utilities.sleep(500);
    status = BigQuery.Jobs.get(projectId, jobId);
    Logger.log('Status: ' + status);
  }
  
  Logger.log('Starting insert job');
  // insert the new data into production tables
  var insert_job = {
    query: addEmployeeQuery,
    // query: `
    //   DECLARE max_employee_id INT64;
    //   SET max_employee_id = (
    //     SELECT 
    //       MAX(employee_id)
    //     FROM employee_db.employees
    //   );
    //   INSERT employee_db.employees (
    //     employee_id,
    //     first_name,
    //     last_name,
    //     gender
    //   )
    //   SELECT
    //     max_employee_id + ROW_NUMBER() OVER (ORDER BY first_name, last_name, team_id, title_id, start_date) AS employee_id,
    //     first_name,
    //     last_name,
    //     gender
    //   FROM \`test-employee-db.staging.${staging_tableId}\`;
    //   INSERT
    //     employee_db.team_roles (
    //       employee_id,
    //       team_id,
    //       title_id,
    //       employee_type,
    //       start_date
    //     )
    //   SELECT
    //     max_employee_id + ROW_NUMBER() OVER (ORDER BY first_name, last_name, team_id, title_id, start_date) AS employee_id,
    //     team_id,
    //     title_id,
    //     employee_type,
    //     SAFE.PARSE_DATE("%a %b %d %Y", SPLIT(start_date, ' 00:00:00 GMT')[OFFSET(0)]) AS start_date
    //   FROM
    //     \`test-employee-db.staging.${staging_tableId}\`;
    //   INSERT employee_db.change_log (
    //       change_date,
    //       change_type,
    //       employee_id,
    //       new_state
    //     )
    //   SELECT
    //     CURRENT_DATE() AS current_date,
    //     "New hire" AS change_type,
    //     max_employee_id + ROW_NUMBER() OVER (ORDER BY first_name, last_name, team_id, title_id, start_date) AS employee_id,
    //     [
    //       STRUCT("title_id" AS name, CAST(title_id AS STRING) AS value),
    //       STRUCT("team_id" AS name, CAST(team_id AS STRING) AS value),
    //       STRUCT("employee_type" AS name, employee_type AS value),
    //       STRUCT("start_date" AS name, CAST(SAFE.PARSE_DATE("%a %b %d %Y", SPLIT(start_date, ' 00:00:00 GMT')[OFFSET(0)]) AS STRING) AS value)
    //     ] AS new_state
    //   FROM
    //     \`test-employee-db.staging.${staging_tableId}\`;
    // `,
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
    Logger.log('Status: ' + status);
  }
  // clear cells below headers once job is complete
  Logger.log('Job state: ' + insert_status.status.state);
  if (insert_status.status.state === 'DONE') {
    // var range = currentSheet.getRange("A6:Z1000");
    var maxRows = currentSheet.getMaxRows();
    var maxColumns = currentSheet.getMaxColumns();
    var range = currentSheet.getRange(6, maxColumns, maxRows);
    range.clear();
  }
}