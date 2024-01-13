-- 1. Who are the top 10 earners in the organization?

select emp.id, emp.first_name, emp.last_name, sal.salary
from employees emp inner join salaries sal on emp.id = sal.employee_id
order by sal.salary desc
limit 10

-- 2. How are the employees distributed in the departments i.e. What is the employee count in each department?

select dep.name, count(emp.id) employee_count
from departments dep inner join employees emp on dep.id = emp.department_id
group by dep.name
order by employee_count desc

-- 3. What is the average salary by department?

select dep.name, avg(sal.salary) avg_sal
from departments dep inner join employees emp on dep.id = emp.department_id
inner join salaries sal on emp.id = sal.employee_id
group by dep.name
order by avg_sal desc

-- 4. Show employees with multiple salaries

-- A - Update script:

update salaries set end_date = '2022-12-31' where id = 1;
insert into salaries values (2001, 60000, '2023-01-01', '2023-11-18', 1);

update salaries set end_date = '2021-12-31' where id = 54;
insert into salaries values (2002, 70000, '2022-01-01', '2023-11-18', 54);

update salaries set end_date = '2023-06-30' where id = 20;
insert into salaries values (2003, 55000, '2023-07-01', '2023-11-18', 20);

-- B - Query

select emp.id, emp.first_name, emp.last_name, sal.start_date, sal.end_date, sal.salary
from employees emp inner join salaries sal on emp.id = sal.employee_id
where emp.id IN 
(
select employee_id from salaries group by employee_id having count(*) > 1
);

-- 5 - What is the employee count by job title?

select t.name, count(emp.id)
from titles t inner join employees emp on t.id = emp.title_id
group by t.name

-- 6 - What is the average salary by job title?

select t.name, round(avg(sal.salary), 2)
from titles t inner join employees emp on emp.title_id = t.id
inner join salaries sal on sal.employee_id = emp.id
group by t.name

-- 7 - How has the average salary changed over time, and are there any notable trends?

select extract(year from start_date) start_year, avg(salary)
from salaries 
group by extract(year from start_date)
order by start_year
