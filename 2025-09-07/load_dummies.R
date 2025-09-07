library(DBI)
library(lubridate)

INSERT_USER_STATEMENT = '
  INSERT INTO
    users (username)
  VALUES
    (?)
  ON CONFLICT DO NOTHING'

INSERT_GENDER_STATEMENT = '
  INSERT INTO
    genders (name)
  VALUES
    (?)
  ON CONFLICT DO NOTHING'

INSERT_GRADE_STATEMENT = '
  INSERT INTO
    organisation_grades (name)
  VALUES
    (?)
  ON CONFLICT DO NOTHING'

INSERT_PROFESSION_STATEMENT = '
  INSERT INTO
    organisation_professions (name)
  VALUES
    (?)
  ON CONFLICT DO NOTHING'

GET_PROFESSION_ID_STATEMENT = '
  SELECT
    id
  FROM
    organisation_professions
  WHERE
    name = ?'

INSERT_UNIT_STATEMENT = '
  INSERT INTO
    organisation_units (name)
  VALUES
    (?)
  ON CONFLICT DO NOTHING'

INSERT_SKILL_CATEGORY_STATEMENT = '
  INSERT INTO
    skill_categories (name, parent_id, profession_id)
  VALUES
    (?, ?, ?)
  ON CONFLICT DO NOTHING'

INSERT_SKILL_STATEMENT = '
  INSERT INTO
    skills (name, category_id)
  VALUES
    (?, ?)
  ON CONFLICT DO NOTHING'

GET_SKILL_CATEGORY_ID_STATEMENT = '
  SELECT
    id
  FROM
    skill_categories
  WHERE
    name = ?'

INSERT_SKILL_ENTRY_STATEMENT = '
  INSERT INTO
    skill_entries (
      user_id,
      skill_id,
      proficiency,
      used_in_last_six_months,
      period,
      last_modified
    )
  VALUES
    (?, ?, ?, ?, ?, ?)
  ON CONFLICT DO NOTHING'

tryCatch(
  expr = {
    conn <- dbConnect(RSQLite::SQLite(), 'database.db')
    
    # Test users:
    for (username in c('alpha', 'beta', 'delta', 'epsilon', 'gamma')) {
      dbExecute(conn, INSERT_USER_STATEMENT, params = c(username))
    }
    
    # Gender options:
    dbExecute(conn, INSERT_GENDER_STATEMENT, params = c('Man'))
    dbExecute(conn, INSERT_GENDER_STATEMENT, params = c('Woman'))
    dbExecute(conn, INSERT_GENDER_STATEMENT, params = c('Non-Binary'))
    dbExecute(conn, INSERT_GENDER_STATEMENT, params = c('Other'))
    dbExecute(conn, INSERT_GENDER_STATEMENT, params = c('Prefer not to say'))
    
    # Grade options:
    dbExecute(conn, INSERT_GRADE_STATEMENT, params = c('AO'))
    dbExecute(conn, INSERT_GRADE_STATEMENT, params = c('EO'))
    dbExecute(conn, INSERT_GRADE_STATEMENT, params = c('HEO'))
    dbExecute(conn, INSERT_GRADE_STATEMENT, params = c('SEO'))
    dbExecute(conn, INSERT_GRADE_STATEMENT, params = c('G7'))
    dbExecute(conn, INSERT_GRADE_STATEMENT, params = c('G6'))
    dbExecute(conn, INSERT_GRADE_STATEMENT, params = c('G5'))
    
    # Profession options:
    dbExecute(conn, INSERT_PROFESSION_STATEMENT, params = c('GSS'))
    dbExecute(conn, INSERT_PROFESSION_STATEMENT, params = c('GSR'))
    dbExecute(conn, INSERT_PROFESSION_STATEMENT, params = c('GORS'))
    dbExecute(conn, INSERT_PROFESSION_STATEMENT, params = c('GES'))
    
    ges_id = dbGetQuery(conn, GET_PROFESSION_ID_STATEMENT, params = c('GES'))[[1]][1]
    gss_id = dbGetQuery(conn, GET_PROFESSION_ID_STATEMENT, params = c('GSS'))[[1]][1]
    
    # Unit options:
    dbExecute(conn, INSERT_UNIT_STATEMENT, params = c('Borders Analysis'))
    dbExecute(conn, INSERT_UNIT_STATEMENT, params = c('Central Economics Unit'))
    
    # Skills and categories:
    dbExecute(conn, INSERT_SKILL_CATEGORY_STATEMENT, params = c('GES-Specific Skills Category 1', NA, ges_id))
    dbExecute(conn, INSERT_SKILL_CATEGORY_STATEMENT, params = c('GES-Specific Skills Category 2', NA, ges_id))
    ges_specific_skills_category_1_id = dbGetQuery(conn, GET_SKILL_CATEGORY_ID_STATEMENT, params = c('GES-Specific Skills Category 1'))[[1]][1]
    ges_specific_skills_category_2_id = dbGetQuery(conn, GET_SKILL_CATEGORY_ID_STATEMENT, params = c('GES-Specific Skills Category 2'))[[1]][1]
    
    dbExecute(conn, INSERT_SKILL_STATEMENT, params = c('GES Example Skill 1', ges_specific_skills_category_1_id))
    dbExecute(conn, INSERT_SKILL_STATEMENT, params = c('GES Example Skill 2', ges_specific_skills_category_1_id))
    dbExecute(conn, INSERT_SKILL_STATEMENT, params = c('GES Example Skill 3', ges_specific_skills_category_1_id))
    dbExecute(conn, INSERT_SKILL_STATEMENT, params = c('GES Example Skill 4', ges_specific_skills_category_2_id))
    dbExecute(conn, INSERT_SKILL_STATEMENT, params = c('GES Example Skill 5', ges_specific_skills_category_2_id))
    dbExecute(conn, INSERT_SKILL_STATEMENT, params = c('GES Example Skill 6', ges_specific_skills_category_2_id))
    
    dbExecute(conn, INSERT_SKILL_CATEGORY_STATEMENT, params = c('GSS-Specific Skills', NA, gss_id))
    ges_specific_skills_id = dbGetQuery(conn, GET_SKILL_CATEGORY_ID_STATEMENT, params = c('GSS-Specific Skills'))[[1]][1]
    dbExecute(conn, INSERT_SKILL_STATEMENT, params = c('GSS Example Skill 1', ges_specific_skills_id))
    dbExecute(conn, INSERT_SKILL_STATEMENT, params = c('GSS Example Skill 2', ges_specific_skills_id))
    dbExecute(conn, INSERT_SKILL_STATEMENT, params = c('GSS Example Skill 3', ges_specific_skills_id))
    
    dbExecute(conn, INSERT_SKILL_CATEGORY_STATEMENT, params = c('Hard Skills', NA, NA))
    hard_skills_id = dbGetQuery(conn, GET_SKILL_CATEGORY_ID_STATEMENT, params = c('Hard Skills'))[[1]][1]
    dbExecute(conn, INSERT_SKILL_CATEGORY_STATEMENT, params = c('Technical Skills', hard_skills_id, NA))
    technical_skills_id = dbGetQuery(conn, GET_SKILL_CATEGORY_ID_STATEMENT, params = c('Technical Skills'))[[1]][1]
    
    dbExecute(conn, INSERT_SKILL_CATEGORY_STATEMENT, params = c('Office Software', technical_skills_id, NA))
    office_software_id = dbGetQuery(conn, GET_SKILL_CATEGORY_ID_STATEMENT, params = c('Office Software'))[[1]][1]
    
    dbExecute(conn, INSERT_SKILL_STATEMENT, params = c('Accounting', office_software_id))
    dbExecute(conn, INSERT_SKILL_STATEMENT, params = c('Word Processing', office_software_id))
    dbExecute(conn, INSERT_SKILL_STATEMENT, params = c('Spreadsheet Building', office_software_id))
    
    dbExecute(conn, INSERT_SKILL_CATEGORY_STATEMENT, params = c('Coding', technical_skills_id, NA))
    coding_id = dbGetQuery(conn, GET_SKILL_CATEGORY_ID_STATEMENT, params = c('Coding'))[[1]][1]
    
    dbExecute(conn, INSERT_SKILL_CATEGORY_STATEMENT, params = c('Coding', technical_skills_id, NA))
    coding_id = dbGetQuery(conn, GET_SKILL_CATEGORY_ID_STATEMENT, params = c('Coding'))[[1]][1]
    
    dbExecute(conn, INSERT_SKILL_STATEMENT, params = c('C++', coding_id))
    dbExecute(conn, INSERT_SKILL_STATEMENT, params = c('Python', coding_id))
    dbExecute(conn, INSERT_SKILL_STATEMENT, params = c('R', coding_id))
    dbExecute(conn, INSERT_SKILL_STATEMENT, params = c('C#', coding_id))
    
    dbExecute(conn, INSERT_SKILL_CATEGORY_STATEMENT, params = c('Soft Skills', NA, NA))
    soft_skills_id = dbGetQuery(conn, GET_SKILL_CATEGORY_ID_STATEMENT, params = c('Soft Skills'))[[1]][1]
    dbExecute(conn, INSERT_SKILL_CATEGORY_STATEMENT, params = c('Communication Skills', soft_skills_id, NA))
    communication_skills_id = dbGetQuery(conn, GET_SKILL_CATEGORY_ID_STATEMENT, params = c('Communication Skills'))[[1]][1]
    dbExecute(conn, INSERT_SKILL_STATEMENT, params = c('Active Listening', communication_skills_id))
    dbExecute(conn, INSERT_SKILL_STATEMENT, params = c('Storytelling', communication_skills_id))
    dbExecute(conn, INSERT_SKILL_STATEMENT, params = c('Written Communication', communication_skills_id))

    dbExecute(conn, INSERT_SKILL_CATEGORY_STATEMENT, params = c('Interpersonal Skills', soft_skills_id, NA))
    interpersonal_skills_id = dbGetQuery(conn, GET_SKILL_CATEGORY_ID_STATEMENT, params = c('Interpersonal Skills'))[[1]][1]
    dbExecute(conn, INSERT_SKILL_STATEMENT, params = c('Patience', interpersonal_skills_id))
    dbExecute(conn, INSERT_SKILL_STATEMENT, params = c('Positivity', interpersonal_skills_id))
    dbExecute(conn, INSERT_SKILL_STATEMENT, params = c('Conflict Management', interpersonal_skills_id))
    dbExecute(conn, INSERT_SKILL_STATEMENT, params = c('Active Listening', interpersonal_skills_id))
    
  },
  finally = {
    dbDisconnect(conn)
  }
)