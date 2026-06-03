--database and schema initil part2

do $$
begin
    if exists (select 1 from information_schema.schemata where schema_name = 'elearning') then
        revoke all privileges on all tables in schema elearning from elearning_readonly;
        revoke all privileges on all tables in schema elearning from elearning_writer;
        revoke all privileges on schema elearning from elearning_readonly;
        revoke all privileges on schema elearning from elearning_writer;
    end if;
end $$;

drop schema if exists elearning cascade;

drop role if exists elearning_readonly;
drop role if exists elearning_writer;

create role elearning_readonly;
create role elearning_writer;

create schema if not exists elearning;
set search_path to elearning, public;

--tables

create table instructors (
    instructor_id int generated always as identity,
    full_name varchar(100) not null,
    email varchar(120) not null constraint uq_instructor_email unique,
    specialization varchar(100) not null,
    rating numeric(3,2) not null constraint chk_instructor_rating check (rating >= 0.00 and rating <= 5.00),
    created_at timestamp not null default current_timestamp,
    constraint pk_instructors primary key (instructor_id)
);

create table course_categories (
    category_id int generated always as identity,
    category_name varchar(100) not null constraint uq_category_name unique,
    description varchar(255) null,
    created_at timestamp not null default current_timestamp,
    constraint pk_course_categories primary key (category_id)
);

create table courses (
    course_id int generated always as identity,
    instructor_id int not null,
    category_id int not null,
    title varchar(150) not null constraint uq_course_title unique,
    price numeric(10,2) not null constraint chk_course_price check (price >= 0),
    level varchar(20) not null constraint chk_course_level check (level in ('Beginner', 'Intermediate', 'Advanced')),
    duration_hours int not null constraint chk_course_duration check (duration_hours > 0),
    description text null,
    created_at timestamp not null default current_timestamp,
    constraint pk_courses primary key (course_id),
    constraint fk_courses_instructors foreign key (instructor_id) references instructors(instructor_id) on delete restrict,
    constraint fk_courses_categories foreign key (category_id) references course_categories(category_id) on delete restrict
);

create table lessons (
    lesson_id int generated always as identity,
    course_id int not null,
    lesson_title varchar(150) not null,
    lesson_order int not null constraint chk_lesson_order check (lesson_order > 0),
    duration_minutes int constraint chk_lesson_duration check (duration_minutes > 0),
    created_at timestamp not null default current_timestamp,
    constraint pk_lessons primary key (lesson_id),
    constraint fk_lessons_courses foreign key (course_id) references courses(course_id) on delete cascade
);

create table students (
    student_id int generated always as identity,
    full_name varchar(100) not null, 
    email varchar(120) not null constraint uq_student_email unique,
    gender varchar(10) not null constraint chk_student_gender check (gender in ('Male', 'Female', 'Other')),
    registration_date date not null constraint chk_student_reg_date check (registration_date > date '2026-01-01'),
    status varchar(20) not null default 'active' constraint chk_student_status check (status in ('active', 'inactive')),
    created_at timestamp not null default current_timestamp,
    constraint pk_students primary key (student_id)
);

create table enrollments (
    enrollment_id int generated always as identity,
    student_id int not null,
    course_id int not null,
    enrollment_date date not null constraint chk_enrollment_date check (enrollment_date > date '2026-01-01'),
    progress_percent int not null default 0 constraint chk_enrollment_progress check (progress_percent >= 0 and progress_percent <= 100),
    status varchar(20) not null default 'active' constraint chk_enrollment_status check (status in ('active', 'completed', 'dropped')),
    constraint pk_enrollments primary key (enrollment_id),
    constraint fk_enrollments_students foreign key (student_id) references students(student_id) on delete cascade,
    constraint fk_enrollments_courses foreign key (course_id) references courses(course_id) on delete restrict,
    constraint uq_student_course_enrollment unique (student_id, course_id)
);

create table payments (
    payment_id int generated always as identity,
    enrollment_id int not null,
    quantity int not null constraint chk_payment_quantity check (quantity > 0),
    unit_price numeric(10,2) not null constraint chk_payment_unit_price check (unit_price >= 0),
    total_price numeric(10,2) generated always as (quantity * unit_price) stored,
    payment_date timestamp not null default current_timestamp,
    payment_method varchar(20) not null constraint chk_payment_method check (payment_method in ('Card', 'PayPal', 'Bank Transfer', 'Other')),
    status varchar(20) not null default 'paid' constraint chk_payment_status check (status in ('paid', 'refunded', 'failed')),
    constraint pk_payments primary key (payment_id),
    constraint fk_payments_enrollments foreign key (enrollment_id) references enrollments(enrollment_id) on delete restrict
);

--alter table part3

alter table instructors alter column specialization type varchar(150);

alter table courses add column updated_at timestamp null;

alter table payments alter column payment_method set default 'Card';

alter table students add constraint chk_student_name_length check (length(full_name) >= 2);

alter table course_categories drop column description;

--insert part4

truncate table payments, enrollments, lessons, courses, course_categories, students, instructors restart identity cascade;

insert into instructors (full_name, email, specialization, rating) values
('Aisha Zhumagali', 'aisha.zh@platform.edu', 'Advanced Machine Learning & AI', 5.00),
('Saida Tauman', 'saida.t@platform.edu', 'Software Engineering & Compilers', 4.85),
('Rayhan Saktasheva', 'rayhan.s@platform.edu', 'Mathematics & Algorithms', 4.90),
('Nurdaulet Zhumabay', 'nurdaulet.zh@platform.edu', 'Operating Systems & C', 4.75),
('Aruzhan Tolegenova', 'aruzhan.t@platform.edu', 'Web Technologies & Networks', 4.60);

insert into course_categories (category_name) values
('Development'), ('Data Science'), ('Design'), ('Business'), ('Marketing');

insert into courses (instructor_id, category_id, title, price, level, duration_hours, description) values
(
    (select instructor_id from instructors where email = 'aisha.zh@platform.edu'),
    (select category_id from course_categories where category_name = 'Data Science'),
    'Introduction to Machine Learning Models', 99.99, 'Intermediate', 45, 'Comprehensive deep-dive into standard ML models.'
),
(
    (select instructor_id from instructors where email = 'saida.t@platform.edu'),
    (select category_id from course_categories where category_name = 'Development'),
    'Advanced C++ Programming Standards', 149.99, 'Advanced', 60, 'Master modern compilation tricks.'
),
(
    (select instructor_id from instructors where email = 'rayhan.s@platform.edu'),
    (select category_id from course_categories where category_name = 'Data Science'),
    'Discrete Mathematics For Software Architecture', 49.99, 'Beginner', 20, 'Foundational math concepts.'
),
(
    (select instructor_id from instructors where email = 'nurdaulet.zh@platform.edu'),
    (select category_id from course_categories where category_name = 'Development'),
    'Linux Kernel Internals & Architecture', 199.99, 'Advanced', 80, 'Understand processes and memory management.'
),
(
    (select instructor_id from instructors where email = 'aruzhan.t@platform.edu'),
    (select category_id from course_categories where category_name = 'Development'),
    'Building Modern Multi-tier Web Applications', 79.99, 'Beginner', 35, 'Learn protocols and client-side scripts.'
);

insert into lessons (course_id, lesson_title, lesson_order, duration_minutes) values
((select course_id from courses where title = 'Introduction to Machine Learning Models'), 'Linear Regression Math Foundations', 1, 45),
((select course_id from courses where title = 'Introduction to Machine Learning Models'), 'Gradient Descent Optimization Frameworks', 2, 60),
((select course_id from courses where title = 'Advanced C++ Programming Standards'), 'Understanding Smart Pointers & Move Semantics', 1, 90),
((select course_id from courses where title = 'Advanced C++ Programming Standards'), 'Template Metaprogramming and Type Traits', 2, 120),
((select course_id from courses where title = 'Discrete Mathematics For Software Architecture'), 'Set Theory and Boolean Predicates', 1, 30),
((select course_id from courses where title = 'Discrete Mathematics For Software Architecture'), 'Graph Structures and Routing Computations', 2, 50),
((select course_id from courses where title = 'Linux Kernel Internals & Architecture'), 'Process Scheduling and Context Switches', 1, 110),
((select course_id from courses where title = 'Linux Kernel Internals & Architecture'), 'Virtual File System Layouts Explained', 2, 95),
((select course_id from courses where title = 'Building Modern Multi-tier Web Applications'), 'HTTP/3 Protocols and Keep-Alive Structs', 1, 40),
((select course_id from courses where title = 'Building Modern Multi-tier Web Applications'), 'Asynchronous Event Event-Loops inside Browsers', 2, 55);

insert into students (full_name, email, gender, registration_date, status) values
('Symbat Kadyrgali', 'symbat.k@outlook.com', 'Female', '2026-01-15', 'active'),
('Dias Ermekov', 'dias.e@gmail.com', 'Male', '2026-02-01', 'inactive'), 
('Daniyar Kusainov', 'daniyar.k@yahoo.com', 'Male', '2026-02-20', 'active'),
('Asel Muratova', 'asel.m@tech.io', 'Female', '2026-03-02', 'active'),
('Madina Saparova', 'madina.s@tech.io', 'Female', '2026-03-11', 'active'),
('Alibek Umarov', 'alibek.u@show.net', 'Male', '2026-04-01', 'active'),
('Zarina Akhmetova', 'zarina.a@vandelay.com', 'Female', '2026-04-12', 'active'),
('Rustam Aliyev', 'rustam.a@hogwarts.edu', 'Male', '2026-05-01', 'active'),
('Bekzhan Isaev', 'bekzhan.i@jurassic.com', 'Male', '2026-05-18', 'active'),
('Kamila Omarova', 'kamila.o@hollywood.com', 'Female', '2026-05-28', 'active');

insert into enrollments (student_id, course_id, enrollment_date, progress_percent, status) values
((select student_id from students where email = 'symbat.k@outlook.com'), (select course_id from courses where title = 'Introduction to Machine Learning Models'), '2026-01-16', 45, 'active'),
((select student_id from students where email = 'dias.e@gmail.com'), (select course_id from courses where title = 'Linux Kernel Internals & Architecture'), '2026-02-05', 0, 'dropped'), 
((select student_id from students where email = 'daniyar.k@yahoo.com'), (select course_id from courses where title = 'Discrete Mathematics For Software Architecture'), '2026-02-22', 100, 'completed'),
((select student_id from students where email = 'asel.m@tech.io'), (select course_id from courses where title = 'Advanced C++ Programming Standards'), '2026-03-05', 40, 'active'),
((select student_id from students where email = 'madina.s@tech.io'), (select course_id from courses where title = 'Building Modern Multi-tier Web Applications'), '2026-03-12', 80, 'active');

insert into enrollments (student_id, course_id, enrollment_date, progress_percent, status)
select 
    student_id, 
    (select course_id from courses where title = 'Introduction to Machine Learning Models'), 
    '2026-06-01', 
    0, 
    'active'
from students 
where registration_date >= '2026-04-01' and status = 'active';

insert into payments (enrollment_id, quantity, unit_price, payment_method, status) values
((select enrollment_id from enrollments where student_id = (select student_id from students where email = 'symbat.k@outlook.com') and course_id = (select course_id from courses where title = 'Introduction to Machine Learning Models')), 1, 99.99, 'Card', 'paid'),
((select enrollment_id from enrollments where student_id = (select student_id from students where email = 'dias.e@gmail.com') and course_id = (select course_id from courses where title = 'Linux Kernel Internals & Architecture')), 1, 199.99, 'PayPal', 'refunded'), 
((select enrollment_id from enrollments where student_id = (select student_id from students where email = 'daniyar.k@yahoo.com') and course_id = (select course_id from courses where title = 'Discrete Mathematics For Software Architecture')), 1, 49.99, 'Bank Transfer', 'paid'),
((select enrollment_id from enrollments where student_id = (select student_id from students where email = 'asel.m@tech.io') and course_id = (select course_id from courses where title = 'Advanced C++ Programming Standards')), 1, 149.99, 'Card', 'paid'),
((select enrollment_id from enrollments where student_id = (select student_id from students where email = 'madina.s@tech.io') and course_id = (select course_id from courses where title = 'Building Modern Multi-tier Web Applications')), 1, 79.99, 'Card', 'paid');

--update and delete part5

update enrollments 
set status = 'completed' 
where progress_percent = 100;

update courses 
set level = 'Advanced', updated_at = current_timestamp 
from course_categories 
where courses.category_id = course_categories.category_id 
  and courses.duration_hours > 50;

begin;

delete from payments 
where status in ('failed', 'refunded')
returning payment_id, enrollment_id, total_price, status;

rollback;

--grant revoke part6

grant usage on schema elearning to elearning_readonly;
grant select on all tables in schema elearning to elearning_readonly;

grant usage on schema elearning to elearning_writer;
grant insert, update on payments to elearning_writer;

revoke update on payments from elearning_writer;