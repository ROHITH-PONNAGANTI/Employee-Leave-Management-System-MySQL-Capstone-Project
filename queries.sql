-- Employee Leave Management System - MySQL Capstone Project
-- Compatible with MySQL 8.0+
-- Run this script in MySQL Workbench. It recreates the project database.

DROP DATABASE IF EXISTS employee_leave_management;
CREATE DATABASE employee_leave_management;
USE employee_leave_management;

-- 1. Database schema
CREATE TABLE Departments (
    department_id INT PRIMARY KEY,
    department_name VARCHAR(50) NOT NULL UNIQUE
);
	
CREATE TABLE Employees (
    employee_id INT PRIMARY KEY,
    department_id INT NOT NULL,
    employee_name VARCHAR(100) NOT NULL,
    phone VARCHAR(15),
    email VARCHAR(120) UNIQUE,
    CONSTRAINT fk_employee_department
        FOREIGN KEY (department_id) REFERENCES Departments(department_id)
);

CREATE TABLE Managers (
    manager_id INT PRIMARY KEY,
    manager_name VARCHAR(100) NOT NULL
);

CREATE TABLE Leave_Types (
    leave_type_id INT PRIMARY KEY,
    leave_type_name VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE Leave_Requests (
    leave_id INT PRIMARY KEY,
    employee_id INT NOT NULL,
    manager_id INT NOT NULL,
    leave_type_id INT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    total_days INT NOT NULL,
    status ENUM('Pending', 'Approved', 'Rejected', 'Cancelled') NOT NULL DEFAULT 'Pending',
    reason VARCHAR(255),
    CONSTRAINT fk_leave_employee FOREIGN KEY (employee_id) REFERENCES Employees(employee_id),
    CONSTRAINT fk_leave_manager FOREIGN KEY (manager_id) REFERENCES Managers(manager_id),
    CONSTRAINT fk_leave_type FOREIGN KEY (leave_type_id) REFERENCES Leave_Types(leave_type_id),
    CONSTRAINT chk_leave_dates CHECK (end_date >= start_date),
    CONSTRAINT chk_total_days CHECK (total_days > 0)
);

-- Added because questions 24 and 30 require leave-balance tracking.
-- This example allocates 20 days per employee for each paid leave type.
-- Unpaid Leave has zero allocated days and is not deducted from a paid balance.
CREATE TABLE Leave_Balances (
    employee_id INT NOT NULL,
    leave_type_id INT NOT NULL,
    allocated_days INT NOT NULL DEFAULT 20,
    remaining_days INT NOT NULL DEFAULT 20,
    PRIMARY KEY (employee_id, leave_type_id),
    FOREIGN KEY (employee_id) REFERENCES Employees(employee_id),
    FOREIGN KEY (leave_type_id) REFERENCES Leave_Types(leave_type_id),
    CHECK (allocated_days >= 0),
    CHECK (remaining_days >= 0),
    CHECK (remaining_days <= allocated_days)
);

-- 2. Sample data from the supplied project brief
INSERT INTO Departments VALUES
(1,'HR'), (2,'IT'), (3,'Finance'), (4,'Sales'), (5,'Administration');

INSERT INTO Managers VALUES
(1,'Ramesh'), (2,'Priya'), (3,'Kiran'), (4,'Sneha'), (5,'Arun');

INSERT INTO Leave_Types VALUES
(1,'Casual Leave'), (2,'Sick Leave'), (3,'Earned Leave'),
(4,'Maternity Leave'), (5,'Unpaid Leave');

INSERT INTO Employees VALUES
(101,1,'Aarav','9876500001','aarav@mail.com'),
(102,2,'Bhavya','9876500002','bhavya@mail.com'),
(103,3,'Charan','9876500003','charan@mail.com'),
(104,4,'Divya','9876500004','divya@mail.com'),
(105,5,'Esha','9876500005','esha@mail.com'),
(106,2,'Farhan','9876500006','farhan@mail.com'),
(107,1,'Gopi','9876500007','gopi@mail.com'),
(108,3,'Hari','9876500008','hari@mail.com'),
(109,4,'Isha','9876500009','isha@mail.com'),
(110,5,'John','9876500010','john@mail.com');

-- Note: the sample dates are from July 2026 as supplied in the PDF.
INSERT INTO Leave_Requests VALUES
(1001,101,1,1,'2026-07-01','2026-07-03',3,'Approved','Personal work'),
(1002,102,2,2,'2026-07-02','2026-07-04',3,'Pending','Fever'),
(1003,103,3,3,'2026-07-05','2026-07-06',2,'Approved','Vacation'),
(1004,104,4,1,'2026-07-07','2026-07-08',2,'Rejected','Family function'),
(1005,105,5,5,'2026-07-10','2026-07-12',3,'Approved','Personal'),
(1006,106,2,2,'2026-07-11','2026-07-11',1,'Pending','Medical'),
(1007,107,1,1,'2026-07-13','2026-07-15',3,'Approved','Travel'),
(1008,108,3,3,'2026-07-16','2026-07-20',5,'Approved','Vacation'),
(1009,109,4,2,'2026-07-18','2026-07-19',2,'Rejected','Sick'),
(1010,110,5,1,'2026-07-21','2026-07-22',2,'Pending','Personal');

-- Initialize balances for all employee/leave-type combinations.
-- Unpaid Leave (type 5) is set to zero allocated/remaining days.
INSERT INTO Leave_Balances (employee_id, leave_type_id, allocated_days, remaining_days)
SELECT e.employee_id, lt.leave_type_id,
       CASE WHEN lt.leave_type_id = 5 THEN 0 ELSE 20 END,
       CASE WHEN lt.leave_type_id = 5 THEN 0 ELSE 20 END
FROM Employees e
CROSS JOIN Leave_Types lt;

-- Deduct balances for the already-approved paid leave records in sample data.
UPDATE Leave_Balances b
JOIN (
    SELECT employee_id, leave_type_id, SUM(total_days) AS days_used
    FROM Leave_Requests
    WHERE status = 'Approved' AND leave_type_id <> 5
    GROUP BY employee_id, leave_type_id
) u ON u.employee_id = b.employee_id AND u.leave_type_id = b.leave_type_id
SET b.remaining_days = GREATEST(0, b.remaining_days - u.days_used);

-- 3. SQL questions (1-26)

-- Q1. List all leave requests.
SELECT * FROM Leave_Requests;

-- Q2. Display leave requests with employee name.
SELECT lr.leave_id, e.employee_name, lr.start_date, lr.end_date,
       lr.total_days, lr.status, lr.reason
FROM Leave_Requests lr
JOIN Employees e ON e.employee_id = lr.employee_id;

-- Q3. Show approved leave requests.
SELECT * FROM Leave_Requests WHERE status = 'Approved';

-- Q4. Show pending leave requests.
SELECT * FROM Leave_Requests WHERE status = 'Pending';

-- Q5. Employees currently on leave (today must fall within approved leave dates).
SELECT DISTINCT e.employee_id, e.employee_name, lr.start_date, lr.end_date
FROM Employees e
JOIN Leave_Requests lr ON lr.employee_id = e.employee_id
WHERE lr.status = 'Approved'
  AND CURDATE() BETWEEN lr.start_date AND lr.end_date;

-- Q6. Count leave requests department-wise (include departments with zero requests).
SELECT d.department_id, d.department_name, COUNT(lr.leave_id) AS request_count
FROM Departments d
LEFT JOIN Employees e ON e.department_id = d.department_id
LEFT JOIN Leave_Requests lr ON lr.employee_id = e.employee_id
GROUP BY d.department_id, d.department_name
ORDER BY request_count DESC, d.department_name;

-- Q7. Count leave requests by status.
SELECT status, COUNT(*) AS request_count
FROM Leave_Requests
GROUP BY status;

-- Q8. Average requested leave days by department.
SELECT d.department_name, ROUND(AVG(lr.total_days), 2) AS average_leave_days
FROM Departments d
JOIN Employees e ON e.department_id = d.department_id
JOIN Leave_Requests lr ON lr.employee_id = e.employee_id
GROUP BY d.department_id, d.department_name;

-- Q9. Employee(s) with the maximum total approved leave days.
SELECT e.employee_id, e.employee_name, SUM(lr.total_days) AS approved_leave_days
FROM Employees e
JOIN Leave_Requests lr ON lr.employee_id = e.employee_id
WHERE lr.status = 'Approved'
GROUP BY e.employee_id, e.employee_name
HAVING SUM(lr.total_days) = (
    SELECT MAX(employee_days)
    FROM (
        SELECT SUM(total_days) AS employee_days
        FROM Leave_Requests
        WHERE status = 'Approved'
        GROUP BY employee_id
    ) AS totals
);

-- Q10. Department(s) with the maximum number of leave requests.
SELECT d.department_name, COUNT(lr.leave_id) AS request_count
FROM Departments d
JOIN Employees e ON e.department_id = d.department_id
JOIN Leave_Requests lr ON lr.employee_id = e.employee_id
GROUP BY d.department_id, d.department_name
HAVING COUNT(lr.leave_id) = (
    SELECT MAX(dept_count)
    FROM (
        SELECT COUNT(lr2.leave_id) AS dept_count
        FROM Departments d2
        JOIN Employees e2 ON e2.department_id = d2.department_id
        JOIN Leave_Requests lr2 ON lr2.employee_id = e2.employee_id
        GROUP BY d2.department_id
    ) AS counts_by_department
);

-- Q11. Employees with more than 2 leave requests.
SELECT e.employee_id, e.employee_name, COUNT(lr.leave_id) AS request_count
FROM Employees e
JOIN Leave_Requests lr ON lr.employee_id = e.employee_id
GROUP BY e.employee_id, e.employee_name
HAVING COUNT(lr.leave_id) > 2;

-- Q12. Employees who never applied for leave.
SELECT e.employee_id, e.employee_name
FROM Employees e
LEFT JOIN Leave_Requests lr ON lr.employee_id = e.employee_id
WHERE lr.leave_id IS NULL;

-- Q13. Latest 5 leave requests.
SELECT * FROM Leave_Requests
ORDER BY start_date DESC, leave_id DESC
LIMIT 5;

-- Q14. Leave requests whose start date is in the last 30 days.
SELECT *
FROM Leave_Requests
WHERE start_date >= CURDATE() - INTERVAL 30 DAY
  AND start_date <= CURDATE()
ORDER BY start_date DESC;

-- Q15. Employee names in uppercase and lowercase.
SELECT employee_name,
       UPPER(employee_name) AS uppercase_name,
       LOWER(employee_name) AS lowercase_name
FROM Employees;

-- Q16. First 3 characters of employee names.
SELECT employee_name, LEFT(employee_name, 3) AS first_three_characters
FROM Employees;

-- Q17. Calculate leave duration from dates (inclusive).
SELECT leave_id, start_date, end_date,
       DATEDIFF(end_date, start_date) + 1 AS calculated_days,
       total_days AS stored_days
FROM Leave_Requests;

-- Q18. Generate leave reference, e.g. EL-1001.
SELECT leave_id, CONCAT('EL-', leave_id) AS leave_reference
FROM Leave_Requests;

-- Q19. Leave types used more than 5 times.
SELECT lt.leave_type_name, COUNT(lr.leave_id) AS times_used
FROM Leave_Types lt
JOIN Leave_Requests lr ON lr.leave_type_id = lt.leave_type_id
GROUP BY lt.leave_type_id, lt.leave_type_name
HAVING COUNT(lr.leave_id) > 5;

-- Q20. Manager-wise approved leave count.
SELECT m.manager_id, m.manager_name, COUNT(lr.leave_id) AS approved_count
FROM Managers m
LEFT JOIN Leave_Requests lr
  ON lr.manager_id = m.manager_id AND lr.status = 'Approved'
GROUP BY m.manager_id, m.manager_name
ORDER BY approved_count DESC;

-- Q21. Employees whose individual leave request exceeds their department's average request duration.
SELECT e.employee_id, e.employee_name, lr.leave_id, lr.total_days,
       dept_avg.average_days
FROM Employees e
JOIN Leave_Requests lr ON lr.employee_id = e.employee_id
JOIN (
    SELECT e2.department_id, AVG(lr2.total_days) AS average_days
    FROM Employees e2
    JOIN Leave_Requests lr2 ON lr2.employee_id = e2.employee_id
    GROUP BY e2.department_id
) AS dept_avg ON dept_avg.department_id = e.department_id
WHERE lr.total_days > dept_avg.average_days;

-- Q22. Monthly leave statistics based on leave start month.
SELECT DATE_FORMAT(start_date, '%Y-%m') AS leave_month,
       COUNT(*) AS request_count,
       SUM(total_days) AS requested_days,
       SUM(status = 'Approved') AS approved_requests,
       SUM(status = 'Pending') AS pending_requests,
       SUM(status = 'Rejected') AS rejected_requests
FROM Leave_Requests
GROUP BY DATE_FORMAT(start_date, '%Y-%m')
ORDER BY leave_month;

-- Q23. Longest leave taken (approved requests; include ties).
SELECT lr.leave_id, e.employee_name, lr.start_date, lr.end_date, lr.total_days
FROM Leave_Requests lr
JOIN Employees e ON e.employee_id = lr.employee_id
WHERE lr.status = 'Approved'
  AND lr.total_days = (
      SELECT MAX(total_days)
      FROM Leave_Requests
      WHERE status = 'Approved'
  );

-- Q24. Remaining leave balance.
SELECT e.employee_id, e.employee_name, lt.leave_type_name,
       b.allocated_days, b.remaining_days,
       b.allocated_days - b.remaining_days AS used_days
FROM Leave_Balances b
JOIN Employees e ON e.employee_id = b.employee_id
JOIN Leave_Types lt ON lt.leave_type_id = b.leave_type_id
ORDER BY e.employee_id, lt.leave_type_id;

-- Q25. Open leave requests (pending).
SELECT * FROM Leave_Requests WHERE status = 'Pending';

-- Q26. Rejected leave requests.
SELECT * FROM Leave_Requests WHERE status = 'Rejected';

-- 4. Views (Q27-Q28)
CREATE VIEW Approved_Leaves AS
SELECT lr.leave_id, e.employee_name, lt.leave_type_name, lr.start_date,
       lr.end_date, lr.total_days, lr.status, lr.reason
FROM Leave_Requests lr
JOIN Employees e ON e.employee_id = lr.employee_id
JOIN Leave_Types lt ON lt.leave_type_id = lr.leave_type_id
WHERE lr.status = 'Approved';

CREATE VIEW Pending_Leaves AS
SELECT lr.leave_id, e.employee_name, lt.leave_type_name, lr.start_date,
       lr.end_date, lr.total_days, lr.status, lr.reason
FROM Leave_Requests lr
JOIN Employees e ON e.employee_id = lr.employee_id
JOIN Leave_Types lt ON lt.leave_type_id = lr.leave_type_id
WHERE lr.status = 'Pending';

-- Example:
-- SELECT * FROM Approved_Leaves;
-- SELECT * FROM Pending_Leaves;

-- 5. Transactions (Q29-Q30)
-- Q29. Approve a pending request safely and deduct balance for paid leave.
-- Change @leave_id to the request you want to approve.
-- If the request is not Pending or balance is insufficient, rollback.
DELIMITER //
CREATE PROCEDURE Approve_Leave(IN p_leave_id INT)
BEGIN
    DECLARE v_employee_id INT;
    DECLARE v_leave_type_id INT;
    DECLARE v_days INT;
    DECLARE v_status VARCHAR(20);
    DECLARE v_remaining INT;
    DECLARE v_found INT DEFAULT 1;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;
    SELECT employee_id, leave_type_id, total_days, status
      INTO v_employee_id, v_leave_type_id, v_days, v_status
    FROM Leave_Requests
    WHERE leave_id = p_leave_id
    FOR UPDATE;

    IF v_status <> 'Pending' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Only Pending requests can be approved';
    END IF;

    IF v_leave_type_id <> 5 THEN
        SELECT remaining_days INTO v_remaining
        FROM Leave_Balances
        WHERE employee_id = v_employee_id AND leave_type_id = v_leave_type_id
        FOR UPDATE;

        IF v_remaining < v_days THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insufficient leave balance';
        END IF;

        UPDATE Leave_Balances
        SET remaining_days = remaining_days - v_days
        WHERE employee_id = v_employee_id AND leave_type_id = v_leave_type_id;
    END IF;

    UPDATE Leave_Requests SET status = 'Approved' WHERE leave_id = p_leave_id;
    COMMIT;
END //

-- Q30. Cancel an approved request and restore paid leave balance.
-- Only an Approved request can be cancelled; its paid balance is restored once.
CREATE PROCEDURE Cancel_Leave(IN p_leave_id INT)
BEGIN
    DECLARE v_employee_id INT;
    DECLARE v_leave_type_id INT;
    DECLARE v_days INT;
    DECLARE v_status VARCHAR(20);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;
    SELECT employee_id, leave_type_id, total_days, status
      INTO v_employee_id, v_leave_type_id, v_days, v_status
    FROM Leave_Requests
    WHERE leave_id = p_leave_id
    FOR UPDATE;

    IF v_status <> 'Approved' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Only Approved requests can be cancelled';
    END IF;

    IF v_leave_type_id <> 5 THEN
        UPDATE Leave_Balances
        SET remaining_days = LEAST(allocated_days, remaining_days + v_days)
        WHERE employee_id = v_employee_id AND leave_type_id = v_leave_type_id;
    END IF;

    UPDATE Leave_Requests SET status = 'Cancelled' WHERE leave_id = p_leave_id;
    COMMIT;
END //
DELIMITER ;

-- Usage examples (run separately after setup):
-- CALL Approve_Leave(1002);
-- CALL Cancel_Leave(1001);

-- 6. Stored procedures (Q31-Q32)
DELIMITER //
CREATE PROCEDURE Get_Manager_Leave_Requests(IN p_manager_id INT)
BEGIN
    SELECT e.employee_name, lt.leave_type_name, lr.start_date,
           lr.end_date, lr.status
    FROM Leave_Requests lr
    JOIN Employees e ON e.employee_id = lr.employee_id
    JOIN Leave_Types lt ON lt.leave_type_id = lr.leave_type_id
    WHERE lr.manager_id = p_manager_id
    ORDER BY lr.start_date DESC;
END //

CREATE PROCEDURE Get_Employee_Approved_Leave_Days(IN p_employee_id INT)
BEGIN
    SELECT p_employee_id AS employee_id,
           COALESCE(SUM(total_days), 0) AS total_approved_leave_days
    FROM Leave_Requests
    WHERE employee_id = p_employee_id
      AND status = 'Approved';
END //
DELIMITER ;

-- Usage examples:
-- CALL Get_Manager_Leave_Requests(2);
-- CALL Get_Employee_Approved_Leave_Days(101);

-- 7. Audit tables and triggers (Q33-Q34)
CREATE TABLE Leave_Request_Log (
    log_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    leave_id INT NOT NULL,
    employee_id INT NOT NULL,
    leave_type_id INT NOT NULL,
    status VARCHAR(20) NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE Leave_Status_History (
    history_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    leave_id INT NOT NULL,
    employee_id INT NOT NULL,
    old_status VARCHAR(20) NOT NULL,
    new_status VARCHAR(20) NOT NULL,
    changed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

DELIMITER //
CREATE TRIGGER trg_leave_request_insert
AFTER INSERT ON Leave_Requests
FOR EACH ROW
BEGIN
    INSERT INTO Leave_Request_Log (leave_id, employee_id, leave_type_id, status)
    VALUES (NEW.leave_id, NEW.employee_id, NEW.leave_type_id, NEW.status);
END //

CREATE TRIGGER trg_leave_status_update
AFTER UPDATE ON Leave_Requests
FOR EACH ROW
BEGIN
    IF OLD.status <> NEW.status THEN
        INSERT INTO Leave_Status_History
            (leave_id, employee_id, old_status, new_status)
        VALUES
            (NEW.leave_id, NEW.employee_id, OLD.status, NEW.status);
    END IF;
END //
DELIMITER ;

