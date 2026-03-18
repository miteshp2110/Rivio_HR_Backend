CREATE TABLE `permissions` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `module` VARCHAR(50) NOT NULL COMMENT 'e.g., Payroll, Leave, ATS',
  `key_name` VARCHAR(100) NOT NULL UNIQUE COMMENT 'e.g., APPROVE_PAYROLL'
);

CREATE TABLE `roles` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE `role_permissions` (
  `role_id` INT NOT NULL,
  `permission_id` INT NOT NULL,
  PRIMARY KEY (`role_id`, `permission_id`),
  FOREIGN KEY (`role_id`) REFERENCES `roles`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`permission_id`) REFERENCES `permissions`(`id`) ON DELETE CASCADE
);

CREATE TABLE `users` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `email` VARCHAR(100) NOT NULL UNIQUE,
  `password_hash` VARCHAR(255) NOT NULL,
  `role_id` INT NOT NULL,
  `status` ENUM('Active', 'Suspended') DEFAULT 'Active',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (`role_id`) REFERENCES `roles`(`id`)
);

-- Polymorphic Audit Log for tracking all system changes
CREATE TABLE `audit_logs` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
  `table_name` VARCHAR(50) NOT NULL,
  `record_id` INT NOT NULL,
  `action` ENUM('INSERT', 'UPDATE', 'DELETE') NOT NULL,
  `old_data` JSON NULL,
  `new_data` JSON NULL,
  `changed_by_user_id` INT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (`changed_by_user_id`) REFERENCES `users`(`id`) ON DELETE SET NULL
);

CREATE TABLE `locations` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(100) NOT NULL COMMENT 'e.g., Chennai Office',
  `currency_code` VARCHAR(3) NOT NULL DEFAULT 'INR',
  `timezone` VARCHAR(50) NOT NULL
);

CREATE TABLE `departments` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(100) NOT NULL UNIQUE,
  `manager_user_id` INT NULL COMMENT 'Department Head',
  FOREIGN KEY (`manager_user_id`) REFERENCES `users`(`id`) ON DELETE SET NULL
);

CREATE TABLE `designations` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `title` VARCHAR(100) NOT NULL,
  `department_id` INT NOT NULL,
  FOREIGN KEY (`department_id`) REFERENCES `departments`(`id`)
);

CREATE TABLE `employee_profiles` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `user_id` INT NOT NULL UNIQUE COMMENT 'Links to login credentials',
  `employee_code` VARCHAR(50) NOT NULL UNIQUE,
  `first_name` VARCHAR(50) NOT NULL,
  `last_name` VARCHAR(50) NOT NULL,
  `location_id` INT NOT NULL,
  `department_id` INT NOT NULL,
  `designation_id` INT NOT NULL,
  `reports_to_profile_id` INT NULL COMMENT 'Direct Manager',
  `employment_type` ENUM('Full-Time', 'Contract', 'Intern') DEFAULT 'Full-Time',
  `status` ENUM('Active', 'Probation', 'Notice_Period', 'Terminated') DEFAULT 'Active',
  `joining_date` DATE NOT NULL,
  `exit_date` DATE NULL,
  FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`location_id`) REFERENCES `locations`(`id`),
  FOREIGN KEY (`department_id`) REFERENCES `departments`(`id`),
  FOREIGN KEY (`designation_id`) REFERENCES `designations`(`id`),
  FOREIGN KEY (`reports_to_profile_id`) REFERENCES `employee_profiles`(`id`) ON DELETE SET NULL
);

CREATE TABLE `leave_types` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(50) NOT NULL COMMENT 'Sick, Casual, Earned',
  `yearly_allotment` DECIMAL(5,2) NOT NULL,
  `carry_forward_limit` DECIMAL(5,2) DEFAULT 0.00
);

-- Acts like a bank account for leaves
CREATE TABLE `employee_leave_balances` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `employee_profile_id` INT NOT NULL,
  `leave_type_id` INT NOT NULL,
  `year` YEAR NOT NULL,
  `allotted` DECIMAL(5,2) NOT NULL DEFAULT 0.00,
  `consumed` DECIMAL(5,2) NOT NULL DEFAULT 0.00,
  `balance` DECIMAL(5,2) GENERATED ALWAYS AS (allotted - consumed) STORED,
  UNIQUE KEY `idx_emp_leave_year` (`employee_profile_id`, `leave_type_id`, `year`),
  FOREIGN KEY (`employee_profile_id`) REFERENCES `employee_profiles`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`leave_type_id`) REFERENCES `leave_types`(`id`)
);

CREATE TABLE `leave_requests` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `employee_profile_id` INT NOT NULL,
  `leave_type_id` INT NOT NULL,
  `start_date` DATE NOT NULL,
  `end_date` DATE NOT NULL,
  `days_requested` DECIMAL(4,1) NOT NULL,
  `status` ENUM('Pending', 'Approved', 'Rejected') DEFAULT 'Pending',
  `approved_by_profile_id` INT NULL,
  FOREIGN KEY (`employee_profile_id`) REFERENCES `employee_profiles`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`leave_type_id`) REFERENCES `leave_types`(`id`),
  FOREIGN KEY (`approved_by_profile_id`) REFERENCES `employee_profiles`(`id`) ON DELETE SET NULL
);

CREATE TABLE `salary_components` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(100) NOT NULL COMMENT 'e.g., Basic, HRA, Provident Fund, TDS',
  `type` ENUM('Earning', 'Deduction', 'Statutory_Tax') NOT NULL,
  `is_taxable` BOOLEAN DEFAULT TRUE
);

-- Tracks salary history and current CTC
CREATE TABLE `compensation_revisions` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `employee_profile_id` INT NOT NULL,
  `effective_date` DATE NOT NULL,
  `annual_ctc` DECIMAL(15,2) NOT NULL,
  `reason` VARCHAR(255) NULL COMMENT 'e.g., Annual Hike, Promotion',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (`employee_profile_id`) REFERENCES `employee_profiles`(`id`) ON DELETE CASCADE
);

-- Maps exact monetary values to the current revision
CREATE TABLE `compensation_breakdowns` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `revision_id` INT NOT NULL,
  `component_id` INT NOT NULL,
  `monthly_amount` DECIMAL(12,2) NOT NULL,
  FOREIGN KEY (`revision_id`) REFERENCES `compensation_revisions`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`component_id`) REFERENCES `salary_components`(`id`)
);

-- Employees declare investments to lower their tax burden
CREATE TABLE `tax_investment_declarations` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `employee_profile_id` INT NOT NULL,
  `financial_year` VARCHAR(9) NOT NULL,
  `section_code` VARCHAR(50) NOT NULL COMMENT 'e.g., 80C, 80D',
  `declared_amount` DECIMAL(12,2) NOT NULL,
  `verified_amount` DECIMAL(12,2) DEFAULT 0.00 COMMENT 'Approved by HR upon proof submission',
  `proof_document_url` VARCHAR(255) NULL,
  FOREIGN KEY (`employee_profile_id`) REFERENCES `employee_profiles`(`id`) ON DELETE CASCADE
);

CREATE TABLE `pay_cycles` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `cycle_name` VARCHAR(100) NOT NULL COMMENT 'e.g., March 2026',
  `status` ENUM('Draft', 'Processing', 'Finalized', 'Paid') DEFAULT 'Draft'
);

CREATE TABLE `payslips` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
  `pay_cycle_id` INT NOT NULL,
  `employee_profile_id` INT NOT NULL,
  `gross_earnings` DECIMAL(15,2) NOT NULL,
  `total_deductions` DECIMAL(15,2) NOT NULL,
  `net_pay` DECIMAL(15,2) NOT NULL,
  `status` ENUM('Draft', 'Published') DEFAULT 'Draft',
  UNIQUE KEY `idx_cycle_emp` (`pay_cycle_id`, `employee_profile_id`),
  FOREIGN KEY (`pay_cycle_id`) REFERENCES `pay_cycles`(`id`),
  FOREIGN KEY (`employee_profile_id`) REFERENCES `employee_profiles`(`id`)
);

-- The immutable line items for the payslip
CREATE TABLE `payslip_items` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
  `payslip_id` BIGINT NOT NULL,
  `component_id` INT NOT NULL,
  `amount` DECIMAL(12,2) NOT NULL,
  FOREIGN KEY (`payslip_id`) REFERENCES `payslips`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`component_id`) REFERENCES `salary_components`(`id`)
);

CREATE TABLE `job_openings` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `department_id` INT NOT NULL,
  `location_id` INT NOT NULL,
  `title` VARCHAR(100) NOT NULL,
  `status` ENUM('Open', 'Closed', 'On_Hold') DEFAULT 'Open',
  FOREIGN KEY (`department_id`) REFERENCES `departments`(`id`),
  FOREIGN KEY (`location_id`) REFERENCES `locations`(`id`)
);

CREATE TABLE `candidates` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `job_opening_id` INT NOT NULL,
  `name` VARCHAR(100) NOT NULL,
  `email` VARCHAR(100) NOT NULL,
  `resume_url` VARCHAR(255) NOT NULL,
  `stage` ENUM('Applied', 'Interviewing', 'Offered', 'Hired', 'Rejected') DEFAULT 'Applied',
  FOREIGN KEY (`job_opening_id`) REFERENCES `job_openings`(`id`) ON DELETE CASCADE
);

CREATE TABLE `performance_reviews` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `employee_profile_id` INT NOT NULL,
  `reviewer_profile_id` INT NOT NULL,
  `review_period` VARCHAR(50) NOT NULL COMMENT 'e.g., Q1 2026',
  `rating` DECIMAL(3,2) NULL COMMENT 'e.g., 4.5 out of 5',
  `comments` TEXT NULL,
  `status` ENUM('Pending', 'Completed') DEFAULT 'Pending',
  FOREIGN KEY (`employee_profile_id`) REFERENCES `employee_profiles`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`reviewer_profile_id`) REFERENCES `employee_profiles`(`id`)
);

