-- Global Universities Explorer - Database Schema & Seed Data
-- Run with: psql -U postgres -d universities_db -f schema.sql

-- Drop & recreate
DROP TABLE IF EXISTS user_favorites CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS scholarships CASCADE;
DROP TABLE IF EXISTS programs CASCADE;
DROP TABLE IF EXISTS universities CASCADE;
DROP TABLE IF EXISTS countries CASCADE;

-- ── Tables ─────────────────────────────────────────────────────────────────

CREATE TABLE countries (
    id   SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    flag_emoji VARCHAR(10),
    description TEXT
);

CREATE TABLE universities (
    id            SERIAL PRIMARY KEY,
    name          VARCHAR(200) NOT NULL,
    country_id    INTEGER REFERENCES countries(id),
    city          VARCHAR(100),
    website       VARCHAR(300),
    logo_url      VARCHAR(300),
    description   TEXT,
    founded_year  INTEGER,
    ranking_score INTEGER DEFAULT 50,  -- 0-100 internal score
    address       TEXT
);

CREATE TABLE programs (
    id              SERIAL PRIMARY KEY,
    university_id   INTEGER REFERENCES universities(id),
    name            VARCHAR(200) NOT NULL,
    degree_level    VARCHAR(50) CHECK (degree_level IN ('Undergraduate','Masters','PhD')),
    field_of_study  VARCHAR(100),
    language        VARCHAR(50),
    min_gpa         NUMERIC(3,2),
    tuition_fee     INTEGER,        -- Annual USD
    duration_years  NUMERIC(3,1),
    description     TEXT
);

CREATE TABLE users (
    id            SERIAL PRIMARY KEY,
    username      VARCHAR(50) NOT NULL UNIQUE,
    email         VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE user_favorites (
    id            SERIAL PRIMARY KEY,
    user_id       INTEGER REFERENCES users(id) ON DELETE CASCADE,
    university_id INTEGER REFERENCES universities(id) ON DELETE CASCADE,
    program_id    INTEGER REFERENCES programs(id) ON DELETE CASCADE,
    UNIQUE(user_id, university_id, program_id)
);

CREATE TABLE scholarships (
    id            SERIAL PRIMARY KEY,
    name          VARCHAR(200) NOT NULL,
    university_id INTEGER REFERENCES universities(id) ON DELETE CASCADE,
    country_id    INTEGER REFERENCES countries(id) ON DELETE CASCADE,
    amount        VARCHAR(100), -- Description of amount (e.g. "Full Tuition", "$5,000")
    deadline      DATE,
    description   TEXT,
    link          VARCHAR(300)
);

CREATE TABLE users (
    id            SERIAL PRIMARY KEY,
    username      VARCHAR(50) NOT NULL UNIQUE,
    email         VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE user_favorites (
    id            SERIAL PRIMARY KEY,
    user_id       INTEGER REFERENCES users(id) ON DELETE CASCADE,
    university_id INTEGER REFERENCES universities(id) ON DELETE CASCADE,
    program_id    INTEGER REFERENCES programs(id) ON DELETE CASCADE,
    UNIQUE(user_id, university_id, program_id)
);

CREATE TABLE scholarships (
    id            SERIAL PRIMARY KEY,
    name          VARCHAR(200) NOT NULL,
    university_id INTEGER REFERENCES universities(id) ON DELETE CASCADE,
    country_id    INTEGER REFERENCES countries(id) ON DELETE CASCADE,
    amount        VARCHAR(100), -- Description of amount (e.g. "Full Tuition", "$5,000")
    deadline      DATE,
    description   TEXT,
    link          VARCHAR(300)
);

-- ── Countries ──────────────────────────────────────────────────────────────

INSERT INTO countries (name, flag_emoji, description) VALUES
('United Kingdom', '🇬🇧', 'Home to some of the world''s oldest and most prestigious universities, the UK offers world-class education with rich cultural heritage.'),
('United States',  '🇺🇸', 'The US hosts the largest number of top-ranked universities globally, offering unparalleled research opportunities and diverse campus life.'),
('Australia',      '🇦🇺', 'Australia''s universities are known for research excellence, multicultural campuses, and a high quality of life for international students.'),
('Germany',        '🇩🇪', 'Germany offers mostly tuition-free education at public universities with strong focus on engineering, science, and technology.'),
('France',         '🇫🇷', 'France combines academic excellence with cultural richness, offering affordable education and programs in business, arts, and sciences.'),
('Canada',         '🇨🇦', 'Canada is renowned for its welcoming immigration policies, diverse communities, and high-quality universities across all disciplines.'),
('Turkey',         '🇹🇷', 'Turkey offers affordable, quality education with scholarships available for international students through the Türkiye Scholarships program.');

-- ── Universities ───────────────────────────────────────────────────────────

INSERT INTO universities (name, country_id, city, website, description, founded_year, ranking_score) VALUES
-- UK
('University of Oxford',        1, 'Oxford',     'https://www.ox.ac.uk',         'The oldest university in the English-speaking world, renowned for rigorous academics and iconic collegiate system.', 1096, 99),
('University of Cambridge',     1, 'Cambridge',  'https://www.cam.ac.uk',        'One of the world''s leading research universities with 121 Nobel Prize affiliates.', 1209, 98),
('Imperial College London',     1, 'London',     'https://www.imperial.ac.uk',   'A world top-ten university focused on science, engineering, medicine and business.', 1907, 92),
('University of Manchester',    1, 'Manchester', 'https://www.manchester.ac.uk', 'A Russell Group university known for its research impact and vibrant student community.', 1824, 85),
('University of Edinburgh',     1, 'Edinburgh',  'https://www.ed.ac.uk',         'Scotland''s ancient university with strong programs in medicine, law, and the arts.', 1583, 84),

-- USA
('Massachusetts Institute of Technology', 2, 'Cambridge, MA', 'https://www.mit.edu',      'MIT is a world leader in STEM education and cutting-edge research across all disciplines.', 1861, 100),
('Stanford University',                   2, 'Stanford, CA',  'https://www.stanford.edu', 'Located in Silicon Valley, Stanford excels in entrepreneurship, technology, and business.', 1885, 99),
('Harvard University',                    2, 'Cambridge, MA', 'https://www.harvard.edu',  'The oldest university in the US, Harvard is globally recognised across all academic fields.', 1636, 98),
('California Institute of Technology',    2, 'Pasadena, CA',  'https://www.caltech.edu',  'Caltech is a small but elite university known for science and engineering excellence.', 1891, 95),
('University of California, Berkeley',    2, 'Berkeley, CA',  'https://www.berkeley.edu', 'A leading public research university known for academic freedom and social impact.', 1868, 90),

-- Australia
('University of Melbourne',        3, 'Melbourne',  'https://www.unimelb.edu.au',  'Australia''s leading university known for its breadth model and research excellence.', 1853, 88),
('Australian National University', 3, 'Canberra',   'https://www.anu.edu.au',      'Australia''s national research university with a focus on public policy and science.', 1946, 85),
('University of Sydney',           3, 'Sydney',     'https://www.sydney.edu.au',   'Australia''s first university, offering strong programs in law, medicine, and arts.', 1850, 84),
('University of Queensland',       3, 'Brisbane',   'https://www.uq.edu.au',       'A research-intensive university ranked in the world top 50 for multiple disciplines.', 1909, 80),

-- Germany
('Technical University of Munich', 4, 'Munich',    'https://www.tum.de',           'Germany''s top-ranked technical university, excelling in engineering and natural sciences.', 1868, 90),
('Ludwig Maximilian University',   4, 'Munich',    'https://www.lmu.de',           'One of Germany''s oldest universities with strength across humanities and sciences.', 1472, 87),
('Heidelberg University',          4, 'Heidelberg','https://www.uni-heidelberg.de', 'Germany''s oldest university, renowned for medicine, natural sciences, and law.', 1386, 85),
('Humboldt University of Berlin',  4, 'Berlin',    'https://www.hu-berlin.de',     'A prestigious Berlin university with 57 Nobel laureates among its alumni and faculty.', 1810, 82),

-- France
('Sorbonne University',            5, 'Paris',    'https://www.sorbonne-universite.fr', 'One of the world''s most famous universities, with strengths in arts, sciences, and medicine.', 1257, 88),
('École Polytechnique',            5, 'Palaiseau', 'https://www.polytechnique.edu',     'France''s elite grande école, producing leaders in science, technology, and public service.', 1794, 90),
('Sciences Po Paris',              5, 'Paris',    'https://www.sciencespo.fr',          'The leading French institution for social sciences, political science, and international affairs.', 1872, 82),

-- Canada
('University of Toronto',     6, 'Toronto',   'https://www.utoronto.ca',    'Canada''s top-ranked university with exceptional research output and diverse campus life.', 1827, 91),
('McGill University',         6, 'Montreal',  'https://www.mcgill.ca',      'A world-class research university in bilingual Montreal with strong medicine and law programs.', 1821, 88),
('University of British Columbia', 6, 'Vancouver', 'https://www.ubc.ca',    'A globally ranked university on Canada''s beautiful Pacific coast known for sustainability research.', 1908, 85),

-- Turkey
('Middle East Technical University', 7, 'Ankara',   'https://www.metu.edu.tr', 'Turkey''s leading technical university offering English-medium instruction in science and engineering.', 1956, 72),
('Bogazici University',              7, 'Istanbul', 'https://www.boun.edu.tr', 'A prestigious Turkish university offering English-medium programs with a strong liberal arts tradition.', 1863, 70),
('Bilkent University',               7, 'Ankara',   'https://www.bilkent.edu.tr','Turkey''s first private non-profit university, known for computer science and engineering.', 1984, 68);

-- ── Programs ───────────────────────────────────────────────────────────────

INSERT INTO programs (university_id, name, degree_level, field_of_study, language, min_gpa, tuition_fee, duration_years) VALUES

-- Oxford (id=1)
(1,'Computer Science','Undergraduate','Computer Science','English',3.80,42000,3),
(1,'Computer Science (MSc)','Masters','Computer Science','English',3.70,35000,1),
(1,'Engineering Science','Undergraduate','Engineering','English',3.80,42000,4),
(1,'MBA','Masters','Business','English',3.60,62000,1),
(1,'DPhil Computer Science','PhD','Computer Science','English',3.70,25000,3),

-- Cambridge (id=2)
(2,'Computer Science','Undergraduate','Computer Science','English',3.85,42000,3),
(2,'Advanced Computer Science (MPhil)','Masters','Computer Science','English',3.75,36000,1),
(2,'Engineering','Undergraduate','Engineering','English',3.85,42000,4),
(2,'MBA (Judge Business School)','Masters','Business','English',3.60,65000,1),
(2,'PhD Engineering','PhD','Engineering','English',3.75,24000,3),

-- Imperial (id=3)
(3,'Computing','Undergraduate','Computer Science','English',3.70,40000,4),
(3,'Computing (MSc)','Masters','Computer Science','English',3.60,36000,1),
(3,'Mechanical Engineering','Undergraduate','Engineering','English',3.70,40000,4),
(3,'Business Analytics (MSc)','Masters','Business','English',3.50,43000,1),

-- Manchester (id=4)
(4,'Computer Science','Undergraduate','Computer Science','English',3.40,29000,3),
(4,'Advanced Computer Science (MSc)','Masters','Computer Science','English',3.30,27000,1),
(4,'Mechanical Engineering','Undergraduate','Engineering','English',3.40,29000,4),
(4,'Business Administration (MBA)','Masters','Business','English',3.20,31000,1),
(4,'PhD Computer Science','PhD','Computer Science','English',3.50,18000,3),

-- Edinburgh (id=5)
(5,'Artificial Intelligence','Undergraduate','Computer Science','English',3.50,32000,4),
(5,'Data Science (MSc)','Masters','Computer Science','English',3.40,28000,1),
(5,'Engineering','Undergraduate','Engineering','English',3.50,32000,4),
(5,'Business (MBA)','Masters','Business','English',3.30,34000,1),

-- MIT (id=6)
(6,'Computer Science','Undergraduate','Computer Science','English',3.90,57000,4),
(6,'Electrical Engineering & CS (MEng)','Masters','Computer Science','English',3.80,57000,1),
(6,'Mechanical Engineering','Undergraduate','Engineering','English',3.90,57000,4),
(6,'MBA (Sloan)','Masters','Business','English',3.70,77000,2),
(6,'PhD Computer Science','PhD','Computer Science','English',3.80,0,4),

-- Stanford (id=7)
(7,'Computer Science','Undergraduate','Computer Science','English',3.90,57000,4),
(7,'Computer Science (MS)','Masters','Computer Science','English',3.80,57000,1),
(7,'Electrical Engineering','Undergraduate','Engineering','English',3.90,57000,4),
(7,'MBA (GSB)','Masters','Business','English',3.70,74000,2),
(7,'PhD Computer Science','PhD','Computer Science','English',3.80,0,5),

-- Harvard (id=8)
(8,'Computer Science','Undergraduate','Computer Science','English',3.90,54000,4),
(8,'Data Science (MS)','Masters','Computer Science','English',3.80,50000,2),
(8,'Business Administration (MBA)','Masters','Business','English',3.70,73000,2),
(8,'PhD Computer Science','PhD','Computer Science','English',3.80,0,5),

-- Caltech (id=9)
(9,'Computer Science','Undergraduate','Computer Science','English',3.90,57000,4),
(9,'Computer Science (MS)','Masters','Computer Science','English',3.80,57000,2),
(9,'Engineering','Undergraduate','Engineering','English',3.90,57000,4),
(9,'PhD Engineering','PhD','Engineering','English',3.80,0,4),

-- UC Berkeley (id=10)
(10,'Computer Science','Undergraduate','Computer Science','English',3.70,44000,4),
(10,'Computer Science (MS)','Masters','Computer Science','English',3.60,27000,2),
(10,'Mechanical Engineering','Undergraduate','Engineering','English',3.70,44000,4),
(10,'MBA (Haas)','Masters','Business','English',3.60,65000,2),
(10,'PhD Computer Science','PhD','Computer Science','English',3.70,0,5),

-- Melbourne (id=11)
(11,'Computer Science','Undergraduate','Computer Science','English',3.30,37000,3),
(11,'Computer Science (MS)','Masters','Computer Science','English',3.20,35000,2),
(11,'Engineering','Undergraduate','Engineering','English',3.30,37000,4),
(11,'MBA','Masters','Business','English',3.20,45000,2),
(11,'PhD Computer Science','PhD','Computer Science','English',3.40,18000,3),

-- ANU (id=12)
(12,'Computer Science','Undergraduate','Computer Science','English',3.20,34000,3),
(12,'Computing (Master)','Masters','Computer Science','English',3.10,30000,2),
(12,'Engineering','Undergraduate','Engineering','English',3.20,34000,4),
(12,'MBA','Masters','Business','English',3.00,38000,1),

-- Sydney (id=13)
(13,'Computer Science','Undergraduate','Computer Science','English',3.20,35000,3),
(13,'Information Technology (MIT)','Masters','Computer Science','English',3.10,31000,2),
(13,'Engineering','Undergraduate','Engineering','English',3.30,35000,4),
(13,'MBA','Masters','Business','English',3.10,42000,2),

-- Queensland (id=14)
(14,'Computer Science','Undergraduate','Computer Science','English',3.00,32000,3),
(14,'Information Technology (MIT)','Masters','Computer Science','English',3.00,28000,2),
(14,'Engineering','Undergraduate','Engineering','English',3.00,32000,4),
(14,'MBA','Masters','Business','English',2.90,38000,2),

-- TU Munich (id=15)
(15,'Informatics','Undergraduate','Computer Science','German',3.20,500,3),
(15,'Informatics (MSc)','Masters','Computer Science','English',3.30,1000,2),
(15,'Mechanical Engineering','Undergraduate','Engineering','German',3.20,500,4),
(15,'Management (MSc)','Masters','Business','English',3.20,12000,2),
(15,'PhD Informatics','PhD','Computer Science','English',3.40,0,3),

-- LMU Munich (id=16)
(16,'Computer Science','Undergraduate','Computer Science','German',3.10,400,3),
(16,'Computer Science (MSc)','Masters','Computer Science','English',3.20,1000,2),
(16,'Business Administration','Undergraduate','Business','German',3.10,400,3),
(16,'Business Administration (MSc)','Masters','Business','German',3.20,500,2),

-- Heidelberg (id=17)
(17,'Computer Science','Undergraduate','Computer Science','German',3.00,500,3),
(17,'Computer Science (MSc)','Masters','Computer Science','German',3.10,500,2),
(17,'Biosciences','Undergraduate','Engineering','German',3.10,500,3),

-- Humboldt Berlin (id=18)
(18,'Computer Science','Undergraduate','Computer Science','German',3.00,400,3),
(18,'Computer Science (MSc)','Masters','Computer Science','German',3.10,400,2),
(18,'Business & Economics','Undergraduate','Business','German',3.00,400,3),

-- Sorbonne (id=19)
(19,'Computer Science','Undergraduate','Computer Science','French',3.00,3000,3),
(19,'Computer Science (MSc)','Masters','Computer Science','French',3.10,5000,2),
(19,'Mathematics','Undergraduate','Engineering','French',3.20,3000,3),
(19,'International Business (MBA)','Masters','Business','French',3.00,15000,1),

-- Polytechnique (id=20)
(20,'Engineering','Undergraduate','Engineering','French',3.70,15000,3),
(20,'Data Science (MSc)','Masters','Computer Science','English',3.60,16000,1),
(20,'Engineering (MSc)','Masters','Engineering','English',3.60,16000,1),
(20,'PhD Engineering','PhD','Engineering','English',3.70,0,3),

-- Sciences Po (id=21)
(21,'Political Science','Undergraduate','Business','French',3.30,14000,3),
(21,'International Business (MBA)','Masters','Business','English',3.30,22000,2),
(21,'International Affairs (MA)','Masters','Business','English',3.20,20000,2),

-- U of Toronto (id=22)
(22,'Computer Science','Undergraduate','Computer Science','English',3.40,40000,4),
(22,'Applied Computing (MScAC)','Masters','Computer Science','English',3.30,24000,1),
(22,'Engineering','Undergraduate','Engineering','English',3.40,40000,4),
(22,'MBA (Rotman)','Masters','Business','English',3.30,52000,2),
(22,'PhD Computer Science','PhD','Computer Science','English',3.50,0,4),

-- McGill (id=23)
(23,'Computer Science','Undergraduate','Computer Science','English',3.30,30000,4),
(23,'Computer Science (MSc)','Masters','Computer Science','English',3.20,18000,2),
(23,'Engineering','Undergraduate','Engineering','English',3.30,30000,4),
(23,'MBA (Desautels)','Masters','Business','English',3.20,37000,2),
(23,'PhD Computer Science','PhD','Computer Science','English',3.40,0,4),

-- UBC (id=24)
(24,'Computer Science','Undergraduate','Computer Science','English',3.30,37000,4),
(24,'Computer Science (MSc)','Masters','Computer Science','English',3.20,10000,2),
(24,'Engineering','Undergraduate','Engineering','English',3.30,37000,4),
(24,'MBA (Sauder)','Masters','Business','English',3.20,42000,2),

-- METU (id=25)
(25,'Computer Engineering','Undergraduate','Computer Science','English',3.00,6000,4),
(25,'Computer Engineering (MSc)','Masters','Computer Science','English',3.00,4000,2),
(25,'Electrical & Electronics Engineering','Undergraduate','Engineering','English',3.00,6000,4),
(25,'Business Administration (MBA)','Masters','Business','English',2.80,5000,2),
(25,'PhD Computer Engineering','PhD','Computer Science','English',3.20,2000,4),

-- Bogazici (id=26)
(26,'Computer Engineering','Undergraduate','Computer Science','English',2.90,8000,4),
(26,'Computer Engineering (MSc)','Masters','Computer Science','English',2.80,5000,2),
(26,'Management Information Systems','Masters','Business','English',2.80,6000,2),
(26,'Industrial Engineering','Undergraduate','Engineering','English',2.90,8000,4),

-- Bilkent (id=27)
(27,'Computer Science','Undergraduate','Computer Science','English',2.80,15000,4),
(27,'Computer Science (MSc)','Masters','Computer Science','English',2.70,8000,2),
(27,'Engineering','Undergraduate','Engineering','English',2.80,15000,4),
(27,'MBA','Masters','Business','English',2.70,10000,2);

-- ── Scholarships ────────────────────────────────────────────────────────────

INSERT INTO scholarships (name, university_id, country_id, amount, deadline, description, link) VALUES
('Clarendon Fund', 1, 1, 'Full Tuition + Stipend', '2026-01-20', 'One of the largest graduate scholarship schemes at Oxford.', 'https://www.ox.ac.uk/clarendon'),
('Gates Cambridge Scholarship', 2, 1, 'Full Cost of Study', '2025-12-01', 'For outstanding applicants from countries outside the UK.', 'https://www.gatescambridge.org/'),
('Rhodes Scholarship', 1, 1, 'Full Tuition + Living Expenses', '2025-10-01', 'The oldest and perhaps most prestigious international scholarship program.', 'https://www.rhodeshouse.ox.ac.uk/'),
('DAAD Scholarship', NULL, 4, 'Full Stipend + Travel', '2026-02-15', 'For international students to study in Germany.', 'https://www.daad.de/en/'),
('Fulbright Program', NULL, 2, 'Full Funding', '2025-10-15', 'The flagship international educational exchange program sponsored by the U.S. government.', 'https://foreign.fulbrightonline.org/'),
('Turkey Scholarships (Türkiye Bursları)', NULL, 7, 'Full Tuition + Stipend + Housing', '2026-02-20', 'Comprehensive government-funded scholarship for international students.', 'https://www.turkiyeburslari.gov.tr/'),
('Chevening Scholarships', NULL, 1, 'Full Funding', '2025-11-05', 'UK government''s global scholarship programme, funded by the FCDO.', 'https://www.chevening.org/'),
('Melbourne Research Scholarship', 11, 3, 'Full Fee Offset + Living Allowance', '2025-10-31', 'For high-achieving students undertaking graduate research.', 'https://scholarships.unimelb.edu.au/');

