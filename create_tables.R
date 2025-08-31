library(DBI)

CREATE_USERS_TABLE_STATEMENT = '
  CREATE TABLE IF NOT EXISTS users (
    id
      INTEGER
      NOT NULL
      PRIMARY KEY
      AUTOINCREMENT,
    username
      VARCHAR(255)
      UNIQUE
      NOT NULL
  )'

CREATE_SKILL_CATEGORIES_TABLE_STATEMENT = '
  CREATE TABLE IF NOT EXISTS skill_categories (
    id 
      INTEGER
      NOT NULL
      PRIMARY KEY
      AUTOINCREMENT,
    name
      VARCHAR(255)
      NOT NULL,
    parent_id
      BIGINT
      NULL
      REFERENCES skill_categories(id)
      DEFERRABLE
      INITIALLY DEFERRED
  )'

CREATE_SKILLS_TABLE_STATEMENT = '
  CREATE TABLE IF NOT EXISTS skills (
    id
      INTEGER
      NOT NULL
      PRIMARY KEY
      AUTOINCREMENT,
    name
      VARCHAR(255)
      NOT NULL,
    category_id
      BIGINT
      NOT NULL
      REFERENCES skill_categories(id)
      DEFERRABLE
      INITIALLY DEFERRED
  )'

CREATE_SKILL_ENTRIES_TABLE_STATEMENT = '
  CREATE TABLE IF NOT EXISTS skill_entries (
    id
      INTEGER
      NOT NULL
      PRIMARY KEY
      AUTOINCREMENT,
    proficiency
      SMALLINT
      NOT NULL,
    used_in_last_six_months
      BOOL
      NOT NULL,
    last_modified
      DATETIME
      NOT NULL,
    user_id
      BIGINT
      NOT NULL
      REFERENCES users(id)
      DEFERRABLE
      INITIALLY DEFERRED,
    skill_id
      BIGINT
      NOT NULL
      REFERENCES skill_categories(id)
      DEFERRABLE
      INITIALLY DEFERRED,
    CONSTRAINT
      UX_skill_entries_user_id_skill_id
      UNIQUE (user_id, skill_id)
  )'

CREATE_ORGANISATION_GRADES_TABLE_STATEMENT = '
  CREATE TABLE IF NOT EXISTS organisation_grades (
    id
      INTEGER
      NOT NULL
      PRIMARY KEY
      AUTOINCREMENT,
    name
      VARCHAR(255)
      NOT NULL
      UNIQUE
  )'

CREATE_ORGANISATION_PROFESSIONS_TABLE_STATEMENT = '
  CREATE TABLE IF NOT EXISTS organisation_professions (
    id
      INTEGER
      NOT NULL
      PRIMARY KEY
      AUTOINCREMENT,
    name
      VARCHAR(255)
      NOT NULL
      UNIQUE
  )'

CREATE_ORGANISATION_UNITS_TABLE_STATEMENT = '
  CREATE TABLE IF NOT EXISTS organisation_units (
    id
      INTEGER
      NOT NULL
      PRIMARY KEY
      AUTOINCREMENT,
    name
      VARCHAR(255)
      NOT NULL
      UNIQUE
  )'

CREATE_GENDERS_TABLE_STATEMENT = '
  CREATE TABLE IF NOT EXISTS genders (
    id
      INTEGER
      NOT NULL
      PRIMARY KEY
      AUTOINCREMENT,
    name
      VARCHAR(255)
      NOT NULL
      UNIQUE
  )'

CREATE_PROFILES_TABLE_STATEMENT = '
  CREATE TABLE IF NOT EXISTS profiles (
    id
      INTEGER
      NOT NULL
      PRIMARY KEY
      AUTOINCREMENT,
    years_as_analyst
      SMALLINT
      UNSIGNED
      NOT NULL
      CHECK (years_as_analyst >= 0),
    years_at_current_grade
      SMALLINT
      UNSIGNED
      NOT NULL
      CHECK (years_at_current_grade >= 0),
    user_id
      BIGINT
      UNIQUE
      NOT NULL
      REFERENCES users(id)
      DEFERRABLE
      INITIALLY DEFERRED,
    gender_id
      BIGINT
      NOT NULL
      REFERENCES genders(id)
      DEFERRABLE
      INITIALLY DEFERRED,
    grade_id
      BIGINT
      NOT NULL
      REFERENCES organisation_grades(id)
      DEFERRABLE
      INITIALLY DEFERRED,
    profession_id
      BIGINT
      NOT NULL
      REFERENCES organisation_professions(id)
      DEFERRABLE
      INITIALLY DEFERRED,
    unit_id
      BIGINT
      NOT NULL
      REFERENCES organisation_units(id)
      DEFERRABLE
      INITIALLY DEFERRED
  )'

CREATE_INDEX_STATEMENTS = c(
  '
  CREATE INDEX IF NOT EXISTS
    FK_skill_categories_parent_id
  ON
    skill_categories (parent_id)',
  '
  CREATE INDEX IF NOT EXISTS
    FK_skills_category_id
  ON
    skills (category_id)',
  '
  CREATE INDEX IF NOT EXISTS
    FK_skill_entries_user_id
  ON
    skill_entries (user_id)',
  '
  CREATE INDEX IF NOT EXISTS
    FK_skill_entries_skill_id
  ON
    skill_entries (skill_id)',
  '
  CREATE INDEX IF NOT EXISTS
    FK_profiles_user_id
  ON
    profiles (user_id)',
  '
  CREATE INDEX IF NOT EXISTS
    FK_profiles_grade_id
  ON
    profiles (grade_id)',
  '
  CREATE INDEX IF NOT EXISTS
    FK_profiles_profession_id
  ON
    profiles (profession_id)',
  '
  CREATE INDEX IF NOT EXISTS
    FK_profiles_unit_id
  ON
    profiles (unit_id)',
  '
  CREATE INDEX IF NOT EXISTS
    FK_profiles_gender_id
  ON
    profiles (gender_id)',
  '
  CREATE UNIQUE INDEX IF NOT EXISTS
    UX_skill_categories_name_parent_id
  ON
    skill_categories(name, COALESCE(parent_id, -1))',
  '
  CREATE UNIQUE INDEX IF NOT EXISTS
    UX_skills_category_id_name
  ON
    skills(COALESCE(category_id, -1), name)',
  '
  CREATE INDEX IF NOT EXISTS
    IX_skills_category_name
  ON
    skills(category_id, name)',
  '
  CREATE INDEX IF NOT EXISTS
    IX_skills_name
  ON
    skills(name)'
)

tryCatch(
  expr = {
    conn <- dbConnect(RSQLite::SQLite(), 'database.db')
    dbExecute(conn, CREATE_USERS_TABLE_STATEMENT)
    dbExecute(conn, CREATE_SKILL_CATEGORIES_TABLE_STATEMENT)
    dbExecute(conn, CREATE_SKILLS_TABLE_STATEMENT)
    dbExecute(conn, CREATE_SKILL_ENTRIES_TABLE_STATEMENT)
    dbExecute(conn, CREATE_ORGANISATION_GRADES_TABLE_STATEMENT)
    dbExecute(conn, CREATE_ORGANISATION_PROFESSIONS_TABLE_STATEMENT)
    dbExecute(conn, CREATE_ORGANISATION_UNITS_TABLE_STATEMENT)
    dbExecute(conn, CREATE_GENDERS_TABLE_STATEMENT)
    dbExecute(conn, CREATE_PROFILES_TABLE_STATEMENT)
    for (statement in CREATE_INDEX_STATEMENTS) {
      dbExecute(conn, statement)
    }
  },
  finally = {
    dbDisconnect(conn)
  }
)



