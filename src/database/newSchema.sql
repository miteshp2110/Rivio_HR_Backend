-- 1. Create independent tables first

CREATE TABLE HOLIDAYS (
    holiday_id INT AUTO_INCREMENT PRIMARY KEY,
    holiday_name VARCHAR(255),
    holiday_date DATE,
    holiday_type VARCHAR(100)
);

CREATE TABLE POLICIES (
    policy_id INT AUTO_INCREMENT PRIMARY KEY,
    policy_title VARCHAR(255),
    document_url VARCHAR(255),
    policy_type VARCHAR(100),
    uploaded_date DATE
);

CREATE TABLE SETTINGS (
    setting_id INT AUTO_INCREMENT PRIMARY KEY,
    setting_key VARCHAR(100),
    setting_value VARCHAR(255),
    scope VARCHAR(100)
);

CREATE TABLE PROJECTS (
    project_id INT AUTO_INCREMENT PRIMARY KEY,
    project_name VARCHAR(255),
    status VARCHAR(50),
    start_date DATE,
    end_date DATE
);

-- 2. Create DEPARTMENTS (Foreign Key for department_head_id added later)
CREATE TABLE DEPARTMENTS (
    department_id INT AUTO_INCREMENT PRIMARY KEY,
    department_name VARCHAR(255),
    department_head_id INT,
    team_size INT
);

-- 3. Create USERS table 
CREATE TABLE USERS (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255),
    email VARCHAR(255) UNIQUE,
    password VARCHAR(255),
    phone VARCHAR(20),
    role VARCHAR(50),
    designation VARCHAR(100),
    work_type VARCHAR(50),
    department_id INT,
    bank_details VARCHAR(255),
    address TEXT,
    theme_preference VARCHAR(50),
    FOREIGN KEY (department_id) REFERENCES DEPARTMENTS(department_id) ON DELETE SET NULL
);

-- 4. Resolve the Circular Dependency
ALTER TABLE DEPARTMENTS
ADD FOREIGN KEY (department_head_id) REFERENCES USERS(user_id) ON DELETE SET NULL;

-- 5. Create dependent tables (connected to USERS and others)

CREATE TABLE ATTENDANCE (
    attendance_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    attendance_date DATE,
    check_in_time TIME,
    check_out_time TIME,
    status VARCHAR(50),
    work_type VARCHAR(50),
    FOREIGN KEY (user_id) REFERENCES USERS(user_id) ON DELETE CASCADE
);

CREATE TABLE LEAVES (
    leave_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    approved_by INT,
    leave_type VARCHAR(100),
    start_date DATE,
    end_date DATE,
    status VARCHAR(50),
    reason TEXT,
    FOREIGN KEY (user_id) REFERENCES USERS(user_id) ON DELETE CASCADE,
    FOREIGN KEY (approved_by) REFERENCES USERS(user_id) ON DELETE SET NULL
);

CREATE TABLE LEAVE_BALANCES (
    balance_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    leave_type VARCHAR(100),
    total_allowed INT,
    used INT,
    remaining INT,
    FOREIGN KEY (user_id) REFERENCES USERS(user_id) ON DELETE CASCADE
);

CREATE TABLE PAYROLL (
    payroll_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    month_year VARCHAR(20),
    basic_salary DECIMAL(10,2),
    deductions DECIMAL(10,2),
    net_salary DECIMAL(10,2),
    payslip_url VARCHAR(255),
    disbursement_status VARCHAR(50),
    FOREIGN KEY (user_id) REFERENCES USERS(user_id) ON DELETE CASCADE
);

CREATE TABLE SCHEDULES (
    schedule_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    title VARCHAR(255),
    schedule_type VARCHAR(100),
    schedule_date DATE,
    schedule_time TIME,
    description TEXT,
    FOREIGN KEY (user_id) REFERENCES USERS(user_id) ON DELETE CASCADE
);

CREATE TABLE NOTIFICATIONS (
    notification_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    notification_type VARCHAR(100),
    message TEXT,
    is_read BOOLEAN DEFAULT FALSE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES USERS(user_id) ON DELETE CASCADE
);

CREATE TABLE JOBS (
    job_id INT AUTO_INCREMENT PRIMARY KEY,
    created_by INT,
    job_title VARCHAR(255),
    description TEXT,
    status VARCHAR(50),
    posted_date DATE,
    FOREIGN KEY (created_by) REFERENCES USERS(user_id) ON DELETE SET NULL
);

CREATE TABLE CANDIDATES (
    candidate_id INT AUTO_INCREMENT PRIMARY KEY,
    job_id INT,
    candidate_name VARCHAR(255),
    email VARCHAR(255),
    phone VARCHAR(20),
    resume_url VARCHAR(255),
    application_status VARCHAR(50),
    FOREIGN KEY (job_id) REFERENCES JOBS(job_id) ON DELETE CASCADE
);

CREATE TABLE PROJECT_MEMBERS (
    id INT AUTO_INCREMENT PRIMARY KEY,
    project_id INT,
    user_id INT,
    role_in_project VARCHAR(100),
    FOREIGN KEY (project_id) REFERENCES PROJECTS(project_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES USERS(user_id) ON DELETE CASCADE
);