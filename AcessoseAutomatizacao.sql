-- Tabela employee
CREATE TABLE IF NOT EXISTS employee (
    Fname VARCHAR(50),
    Minit CHAR(1),
    Ssn CHAR(9) PRIMARY KEY,
    Bdate DATE,
    Address VARCHAR(100),
    Sex CHAR(1),
    Saley DECIMAL(10, 2),
    Super_ssn CHAR(9),
    Dno INT,
    FOREIGN KEY (Super_ssn) REFERENCES employee(Ssn)
);

-- Tabela department
CREATE TABLE IF NOT EXISTS department (
    Dname VARCHAR(50),
    Dnumber INT PRIMARY KEY,
    Mgr_ssn CHAR(9),
    Mgr_start_date DATE,
    FOREIGN KEY (Mgr_ssn) REFERENCES employee(Ssn)
);

-- Tabela dept_locations
CREATE TABLE IF NOT EXISTS dept_locations (
    Dnumber INT,
    Dlocation VARCHAR(100),
    PRIMARY KEY (Dnumber, Dlocation),
    FOREIGN KEY (Dnumber) REFERENCES department(Dnumber)
);

-- Tabela project
CREATE TABLE IF NOT EXISTS project (
    Pname VARCHAR(50),
    Pnumber INT PRIMARY KEY,
    Plocation VARCHAR(100),
    Dnum INT,
    FOREIGN KEY (Dnum) REFERENCES department(Dnumber)
);

-- Tabela works_on
CREATE TABLE IF NOT EXISTS works_on (
    Essn CHAR(9),
    Pno INT,
    hours DECIMAL(5, 2),
    PRIMARY KEY (Essn, Pno),
    FOREIGN KEY (Essn) REFERENCES employee(Ssn),
    FOREIGN KEY (Pno) REFERENCES project(Pnumber)
);

-- Tabela dependent
CREATE TABLE IF NOT EXISTS dependent (
    Essn CHAR(9),
    Dependent_name VARCHAR(50),
    Sex CHAR(1),
    Bdate DATE,
    Relationship VARCHAR(50),
    PRIMARY KEY (Essn, Dependent_name),
    FOREIGN KEY (Essn) REFERENCES employee(Ssn)
);

--  Número de Empregados por Departamento e Localidade
CREATE VIEW emp_by_dept_location AS
SELECT d.Dname, dl.Dlocation, COUNT(e.Ssn) AS num_employees
FROM department d
JOIN dept_locations dl ON d.Dnumber = dl.Dnumber
LEFT JOIN employee e ON d.Dnumber = e.Dno
GROUP BY d.Dname, dl.Dlocation;

-- Lista de Departamentos e Seus Gerentes
CREATE VIEW dept_and_managers AS
SELECT d.Dname, d.Dnumber, e.Fname AS ManagerName
FROM department d
LEFT JOIN employee e ON d.Mgr_ssn = e.Ssn;

-- Projetos com Maior Número de Empregados
CREATE VIEW projects_with_most_employees AS
SELECT p.Pname, p.Pnumber, COUNT(w.Essn) AS num_employees
FROM project p
LEFT JOIN works_on w ON p.Pnumber = w.Pno
GROUP BY p.Pname, p.Pnumber
ORDER BY num_employees DESC;

--  Lista de Projetos, Departamentos e Gerentes
CREATE VIEW project_dept_managers AS
SELECT p.Pname, p.Pnumber, d.Dname, e.Fname AS ManagerName
FROM project p
JOIN department d ON p.Dnum = d.Dnumber
LEFT JOIN employee e ON d.Mgr_ssn = e.Ssn;

-- Quais Empregados Possuem Dependentes e Se São Gerentes
CREATE VIEW employees_with_dependents_and_managers AS
SELECT e.Ssn, e.Fname, d.Dname AS DepartmentName, CASE WHEN e.Ssn IN (SELECT Mgr_ssn FROM department) THEN 'Manager' ELSE 'Non-Manager' END AS IsManager
FROM employee e
JOIN dependent dep ON e.Ssn = dep.Essn
LEFT JOIN department d ON e.Dno = d.Dnumber;

-- Quais Empregados Possuem Dependentes e Se São Gerentes
CREATE VIEW employees_with_dependents_and_managers AS
SELECT e.Ssn, e.Fname, d.Dname AS DepartmentName, 
       CASE WHEN e.Ssn IN (SELECT Mgr_ssn FROM department) THEN 'Manager' ELSE 'Non-Manager' END AS IsManager
FROM employee e
JOIN dependent dep ON e.Ssn = dep.Essn
LEFT JOIN department d ON e.Dno = d.Dnumber;



-- Definindo Permissões de Acesso
-- Criar o Usuário
-- Criar usuário gerente
CREATE USER 'manager'@'localhost' IDENTIFIED BY 'password';

-- Criar usuário empregado
CREATE USER 'employee'@'localhost' IDENTIFIED BY 'password';

-- Conceder Permissões

-- Permissões para o usuário gerente
GRANT SELECT ON emp_by_dept_location TO 'manager'@'localhost';
GRANT SELECT ON dept_and_managers TO 'manager'@'localhost';
GRANT SELECT ON projects_with_most_employees TO 'manager'@'localhost';
GRANT SELECT ON project_dept_managers TO 'manager'@'localhost';
GRANT SELECT ON employees_with_dependents_and_managers TO 'manager'@'localhost';

-- Permissões para o usuário empregado
GRANT SELECT ON employees_with_dependents_and_managers TO 'employee'@'localhost';

-- Criação da Tabela de Histórico de Empregados
CREATE TABLE IF NOT EXISTS employee_history (
    Ssn CHAR(9),
    Fname VARCHAR(50),
    Minit CHAR(1),
    Bdate DATE,
    Address VARCHAR(100),
    Sex CHAR(1),
    Saley DECIMAL(10, 2),
    Super_ssn CHAR(9),
    Dno INT,
    removal_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (Ssn)
);

-- Criação do Trigger Before Delete
DELIMITER //
CREATE TRIGGER before_employee_delete
BEFORE DELETE ON employee
FOR EACH ROW
BEGIN
    INSERT INTO employee_history (Ssn, Fname, Minit, Bdate, Address, Sex, Saley, Super_ssn, Dno)
    VALUES (OLD.Ssn, OLD.Fname, OLD.Minit, OLD.Bdate, OLD.Address, OLD.Sex, OLD.Saley, OLD.Super_ssn, OLD.Dno);
END //
DELIMITER ;

-- Criação da Tabela de Histórico de Salários
CREATE TABLE IF NOT EXISTS salary_history (
    Ssn CHAR(9),
    old_salary DECIMAL(10, 2),
    new_salary DECIMAL(10, 2),
    change_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (Ssn, change_date),
    FOREIGN KEY (Ssn) REFERENCES employee(Ssn)
);

-- Criação do Trigger Before Update
DELIMITER //
CREATE TRIGGER before_salary_update
BEFORE UPDATE ON employee
FOR EACH ROW
BEGIN
    IF OLD.Saley <> NEW.Saley THEN
        INSERT INTO salary_history (Ssn, old_salary, new_salary)
        VALUES (OLD.Ssn, OLD.Saley, NEW.Saley);
    END IF;
END //
DELIMITER ;








