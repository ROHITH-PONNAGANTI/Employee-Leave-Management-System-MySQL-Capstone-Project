# Employee Leave Management System – MySQL

## 1. Project Overview

The Employee Leave Management System is a MySQL-based database project designed to manage employee leave requests, approvals, leave balances, and reporting. It uses a relational database structure to store employee and leave-related information and supports operational and analytical queries.

## 2. Problem Statement

Organizations need a centralized system to manage employee leave requests, approvals and reporting. Build a relational database that stores leave information and supports operational and analytical queries.

## 3. Project Objectives

- Design a relational database for employee leave management.
- Create tables with primary keys, foreign keys, and constraints.
- Store and manage employee, department, manager, leave type, and leave request data.
- Perform CRUD operations and SQL queries.
- Generate reports using joins, aggregate functions, grouping, and subqueries.
- Create views and stored procedures.
- Use transactions to approve and cancel leave requests.
- Maintain leave request logs and status history using triggers.

## 4. Technologies Used

- **Database:** MySQL 8.0+
- **SQL Tool:** MySQL Workbench
- **Documentation:** Markdown
- **Version Control:** Git and GitHub

## 5. Database Tables

| Table | Description |
|---|---|
| `Departments` | Stores department details. |
| `Employees` | Stores employee information and department references. |
| `Managers` | Stores manager details. |
| `Leave_Types` | Stores available leave categories. |
| `Leave_Requests` | Stores leave dates, duration, status, reason, employee, manager, and leave type. |
| `Leave_Balances` | Tracks allocated and remaining leave days for employees. |
| `Leave_Request_Log` | Records newly inserted leave requests. |
| `Leave_Status_History` | Records leave request status changes. |

## 6. SQL Concepts Implemented

- Database and table creation
- Primary keys and foreign keys
- Constraints and data validation
- INSERT, UPDATE, DELETE, and SELECT operations
- INNER JOIN and LEFT JOIN
- Aggregate functions: COUNT, SUM, and AVG
- GROUP BY and HAVING
- Subqueries
- String and date functions
- Views for approved and pending leave requests
- Stored procedures for manager and employee leave information
- Transactions for leave approval and cancellation
- Triggers for request logging and status history

## 7. Project Files

- `Problem_Statement.pdf` – Original project brief provided by the instructor.
- `employee_leave_management_system.sql` – Database schema, sample data, queries, views, procedures, and triggers.
- `Queries.sql` – SQL solutions organized by question number.
- `ER_Diagram.png` – Entity Relationship Diagram of the database.
- `Employee_Leave_Management.pptx` – Project presentation.
- `Project_Demo.mp4` – Project demonstration recording.

## 8. How to Run the Project

1. Install MySQL Server 8.0 or a compatible version and MySQL Workbench.
2. Open MySQL Workbench and connect to your MySQL server.
3. Open `employee_leave_management_system.sql`.
4. Review the script before execution. It contains `DROP DATABASE IF EXISTS`, which deletes and recreates the existing `employee_leave_management` database.
5. Execute the script to create the database, tables, sample records, views, stored procedures, and triggers.
6. Refresh the Schemas panel and select the `employee_leave_management` database.
7. Execute individual SQL queries to explore leave requests and generate reports.
8. Test stored procedures and transactions separately using the examples provided in the SQL script.

**Warning:** Run the setup script only when you are prepared to recreate the database. Back up any existing data you need to keep.

## 9. Example Queries

Display all leave requests:

```sql
SELECT * FROM Leave_Requests;
```

Display leave requests with employee names:

```sql
SELECT
    lr.leave_id,
    e.employee_name,
    lr.start_date,
    lr.end_date,
    lr.total_days,
    lr.status
FROM Leave_Requests lr
JOIN Employees e
    ON e.employee_id = lr.employee_id;
```

Count leave requests by status:

```sql
SELECT status, COUNT(*) AS request_count
FROM Leave_Requests
GROUP BY status;
```

View approved leave requests:

```sql
SELECT * FROM Approved_Leaves;
```

## 10. Expected Outcomes

- Organized storage of employee and leave-related information.
- Retrieval of leave requests by employee, manager, department, and status.
- Summary reports for leave requests and leave duration.
- Transaction-based leave approval and cancellation.
- Audit records for new requests and status changes.

## 11. Conclusion

This project demonstrates the use of relational database design and MySQL to manage employee leave information. It applies SQL querying, data relationships, reporting, views, stored procedures, transactions, and triggers to support leave management operations.

## 12. Project Deliverables

The repository contains the project problem statement, SQL scripts, ER diagram, presentation, demonstration video, and documentation, as these files are added to the repository.
