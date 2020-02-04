# Do It All In A Spreadsheet?

The computations required to implement various edit checks and results reports
are fairly straight-forward in SQL.  However, the requirement of standing up a
DB server and copying all the data from the spreadsheet, running the procs and
copying the data back into a spreadsheet is inconvenient at best and
insurmountable for most people.  In the ideal case, the users would only have to
populate the test results in the spreadsheet, and all the edit checks would be
performed, and all the results would be tallied within that same spreadsheet.

So the question is:  Can we do it?  There are two main classes of tasks to be
performed:
1. Data Validation
1. Reporting

## Data Validation

### Configuration and Master Data Edit Checks
Here's the list of edit checks/cleanup for config and master data:

|Level | Competition | School | Student | Edit Check
|:---: | :---------: | :----: | :-----: | ----------
|  X   |      X      |   X    |    X  : | duplicate record
|  X   |      X      |   X    |    X  : | leading and trailing spaces on all fields
|  X   |      X      |   X    |    X  : | non-alpha name
|      |             |        |    X  : | ID / Level mismatch

### Test Result / Score Edit Checks
And here's the list of edit checks for test result data
- Unknown Level Id
- Unknown Competition Id
- Unknown Student Id
- Mismatch between Student Level and Test Level.  Students testing _up_ a level
  is allowed, but testing _down_ is not.
- Duplicate results: student takes a test multiple times, or two students fill
  in the same student ID.
  - If possible, the student name should be checked against the ID on the test
    form to guard against typos (_e.g._ 4012 vs 4021)
  - Otherwise we ignore all but the highest score
- Score exceeds maximum possible (Need new attribute on Competition table)

### Cleanup Processes
Edit checks should be implemented as a combination of
- conditional formatting to highlight cells or rows with bad data
- macros to automatically clean the data (_e.g._ trim leading and trailing
  spaces on all fields)

## Reporting
There are several reports to be generated from the test result data
- Participation: Basically just a list of every student and all their test
  results grouped by school so that the teachers know who participated in what
  competitions, and which students didn't participate in any.
- Top 10 _scores_ for each competition at each competition level.  All students
  with the top score are awarded 10 points.  All students with the next highest
  score are awarded 9 points, etc.
- Top overall students.  Typically top 10, but if tie for 10th place, list them
  all.
- Top schools by Quantitative / Qualitative ranking

To get the desired list of reports in the most efficient way possible:
1. Make a copy of the test results sheet called "Points Awarded"
1. Sort the copy by competition, test (not student) level, and score descending
1. For each competition + level
   - initialize variables:
     - array of scores: [0] = infinity, [1] - [10] zero
     - current "place": 0
   - if score on current row is less than scores[place] then
     - increment place
     - set scores[place] = score from current row
     - set points earned on current row to `max(0,11-place)`
1. Make a copy of the "Points Awarded" sheet called "Participation"
1. Sort the Participation sheet by Student Id
1. For each student on the student master list
   - Locate the student on the Participation sheet, either via a `vlookup` API
     or a binary search
   - If student Id is not found in the test results, add student Id to a list of
     non-participating students
1. For each student who did not participate
   - Add a row with "{Student Did Not Participate}" as the Competition name
1. Sort the Participation sheet by School, Level, Last Name, First Name,
   Competition. **This is the final Participation Report**
1. Initialize associative array with all schools
1. Loop through student master and increment delegate count for schools in the
   associative array
1. Make a new sheet called "Top 10 by Competition"
1. For each Competition + Level
   - Put Competition Name in column A on a new row
   - Put Level Name in column B on a new row
   - For each Test Result where Points > 0
     - Put Place, Points, School Name, Student Name, Student Level in columns
       C through H on a new row
     - Add student total points to associative array
     - Add school total points to associative array
   - Add a blank row
   - **This is the final Top 10 Report**
1. Make a new sheet called "Top 10 Overall"
1. Turn the Student assoc array into a standard array and sort by points desc
1. Check the score at the 10th spot.  Ensure that you include all students who
   achieved that score (so that a tie for 10th place doesn't artificially award
   a one of the students 10th place based on alphabetical order)
1. Add top 10 student information to the new sheet.  **This is the final Top 10
   Overall Report**
1. In the School assoc array, compute the average points per delegate,
   defaulting to 0 if there are no delegates.
1. Make a new sheet called School Rankings.
1. Turn the school assoc array into a normal array
1. Define boolean variable IsQuant = true
1. While the array is not empty
   1. Sort the schools using a function that compares either total points or
      points per delegate depending on the value of IsQuant.
   1. Shift the array to get the school with the most points and add it to the
      sheet with either the quantitative or qualitative place set.
   1. set IsQuant = ! IsQuant
1. **This is the final School Standings Report**

> NOTE: In the WJCL 2020 season, schools were divided up into "large" and
"small" sizes, and the qual/quant rankings were assigned separately by school
size.  If that's the new norm, then we'll need a new attribute on the school
table and will have to modify the School Standings report logic accordingly.

> TODO: Investigate the Google Sheets [`QUERY`](https://support.google.com/docs/answer/3093343?hl=en) function to see how much of the
above could be implemented using that.

## Google Sheets

### Spreadsheet Generator
Create a "master" spreadsheet or a Google Form used to generate JCL
spreadsheets.  Have a field holding the desired spreadsheet name, and some apps
scripting to generate the spreadsheet.
- [SpreadsheetApp](https://developers.google.com/apps-script/reference/spreadsheet/spreadsheet-app.html).[create(name)](https://developers.google.com/apps-script/reference/spreadsheet/spreadsheet-app.html#create(String))
- [Spreadsheet](https://developers.google.com/apps-script/reference/spreadsheet/spreadsheet.html).[insertSheet(sheetName, sheetIndex, options)](https://developers.google.com/apps-script/reference/spreadsheet/spreadsheet.html#insertSheet(String,Integer,Object))
  The options may not be useful at this point.  The only option that's
  documented is to specify a template sheet, which we wouldn't use since all of
  our sheets hold different types of data
- Then use the [Sheet](https://developers.google.com/apps-script/reference/spreadsheet/sheet) object and associated methods to create the sheets:
  - Headers
  - Computed Columns (gray, warning if someone tries to modify them)
