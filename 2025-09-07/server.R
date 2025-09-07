library(glue)
library(hash)
library(lubridate)
library(purrr)
library(RSQLite)
library(tidyverse)

get_skills_map_data <- function(conn) {
  # Retrieve professions, ordered alphabetically.
  professions_df <- conn %>%
    tbl('organisation_professions') %>%
    arrange(name) %>%
    collect()

  # Create a professions hash map with space for categories.
  professions_map <- professions_df %>%
    split(.$id) %>%
    lapply(
      function(x) {
        list(
          name = x$name,
          categories = c()
        )
      }
    ) %>%
    hash()
  
  # Retrieve categories, ordered alphabetically.
  categories_df <- conn %>% 
    tbl('skill_categories') %>% 
    arrange(name) %>%
    collect()
  
  # Populate the profession map categories.
  for (row in split(categories_df, seq(nrow(categories_df)))) {
    professions_map[[as.character(row$profession_id)]][['categories']] <- c(
      professions_map[[as.character(row$profession_id)]][['categories']],
      as.character(row$id)
    )
  }
  
  # Create a categories hash map with space for children and skills.
  categories_map <- categories_df %>% 
    split(.$id) %>% 
    lapply(
      function(x) {
        list(
          name = x$name,
          parent = x$parent_id,
          children = c(),
          skills = c()
        )
      }
    ) %>% 
    hash()
  
  # Populate the category map's children.
  for (row in split(categories_df, seq(nrow(categories_df)))) {
    categories_map[[as.character(row$parent_id)]][['children']] <- c(
      categories_map[[as.character(row$parent_id)]][['children']],
      as.character(row$id)
    )
  }
  
  # Retrieve skills, ordered alphabetically.
  skills_df <- conn %>% 
    tbl('skills') %>% 
    arrange(name) %>% 
    collect()
  
  # Create a skills hash map for name lookups.
  skills_map <- skills_df %>% 
    split(.$id) %>% 
    lapply(function(x) list(name = x$name)) %>% 
    hash()
  
  # Populate the category map's skills.
  for (row in split(skills_df, seq(nrow(skills_df)))) {
    categories_map[[as.character(row$category_id)]][['skills']] <- c(
      categories_map[[as.character(row$category_id)]][['skills']],
      as.character(row$id)
    )
  }
  
  # Return all three populated maps with alphabetically ordered ids.
  return(
    list(
      professions = list(
        ids = as.character(professions_df$id),
        map = professions_map
      ),
      categories = list(
        ids = as.character(categories_df$id),
        map = categories_map
      ),
      skills = list(
        ids = as.character(skills_df$id),
        map = skills_map
      )
    )
  )
}

create_accordion_category_node <- function(id, map) {
  node = map[[as.character(id)]]
  if (length(node$skills) > 0) {
    return(
      tags$li(
        actionLink(
          inputId = glue('data_entry_category_button_{id}'),
          label = node$name
        )
      )
    )
  } else {
    subnodes <- lapply(
      node$children,
      function(x) {
        fluidRow(create_accordion_category_node(x, map))
      }
    )
    return(
      accordion_panel(
        title = node$name,
        do.call(
          accordion,
          append(
            subnodes,
            list(
              open = FALSE
            )
          )
        )
      )
    )
  }
}

conn <- dbConnect(RSQLite::SQLite(), 'database.db')
tryCatch({
  x <- get_skills_map_data(conn)
  y <- create_accordion_category_node(1, x$categories$map)
},
finally = {
  dbDisconnect(conn)
})



server <- function(input, output, session) {
  
  #### Setup ####
  
  # Connect to the database.
  conn <- dbConnect(
    drv = SQLite(),
    dbname = 'database.db'
  )
  
  # Enable foreign key constraints.
  dbExecute(conn = conn, 'PRAGMA foreign_keys=ON')
  
  # Set onSessionEnded to ensure the connection is closed later.
  session$onSessionEnded(function() {
    dbDisconnect(conn)
  })
  
  # Retrieve the user id from the session.
  user_key <- 1 # PLACEHOLDER

  ##### Profile Setup #####

  # Retrieve profile options from the database.
  
  gender_choices <- conn %>% 
    tbl('genders') %>% 
    select(id, name) %>% 
    collect() %>% 
    { setNames(as.list(.$id), .$name) }
  
  grade_choices <- conn %>% 
    tbl('organisation_grades') %>% 
    select(id, name) %>% 
    collect() %>% 
    { setNames(as.list(.$id), .$name) }
  
  profession_choices <- conn %>% 
    tbl('organisation_professions') %>% 
    select(id, name) %>% 
    arrange(name) %>% 
    collect() %>% 
    { setNames(as.list(.$id), .$name) }
  
  unit_choices <- conn %>% 
    tbl('organisation_units') %>% 
    select(id, name) %>% 
    arrange(name) %>% 
    collect() %>% 
    { setNames(as.list(.$id), .$name) }
  
  # Retrieve the current user profile, if it exists.
  
  profile <- conn %>% 
    tbl('profiles') %>% 
    filter(user_id == user_key) %>% 
    select(id, gender_id, grade_id, unit_id) %>% 
    collect() %>% 
    first()
  
  # Retrieve the user's selected professions.
  
  initial_professions <- conn %>% 
    tbl('profession_entries') %>% 
    filter(
      user_id == user_key,
      is_selected == TRUE
    ) %>% 
    pull(profession_id) %>% 
    as.character()
  
  selected_professions <- reactiveVal(initial_professions)
  
  # Populate the profile input widgets.
  
  updateCheckboxGroupInput(
    inputId = 'profile_professions_selection',
    choices = profession_choices,
    selected = initial_professions
  )

  updateRadioButtons(
    inputId = 'profile_gender_selection',
    choices = gender_choices,
    selected = profile$gender_id
  )
  
  updateRadioButtons(
    inputId = 'profile_grade_selection',
    choices = grade_choices,
    selected = profile$grade_id
  )
  
  updateRadioButtons(
    inputId = 'profile_unit_selection',
    choices = unit_choices,
    selected = profile$unit_id
  )
  
  # Create an observer for clicking the save button.
  observeEvent(
    eventExpr = input$profile_save_button,
    handlerExpr = {
      
      # Retrieve values.
      gender <- as.numeric(input$profile_gender_selection)
      grade <- as.numeric(input$profile_grade_selection)
      unit <- as.numeric(input$profile_unit_selection)
      professions <- as.numeric(input$profile_professions_selection)
      
      # Validate the inputs and take the appropriate action:
      if (length(gender) > 0 && length(grade) > 0 && length(unit) > 0) {
        tryCatch(
          expr = {
            dbExecute(
              conn = conn,
              statement = '
                INSERT INTO
                  profiles (
                    user_id,
                    gender_id,
                    grade_id,
                    unit_id
                  )
                VALUES
                  (?, ?, ?, ?)
                ON CONFLICT
                  (user_id)
                DO UPDATE SET
                  gender_id = excluded.gender_id,
                  grade_id = excluded.grade_id,
                  unit_id = excluded.unit_id',
              params = c(user_key, gender, grade, unit)
            )
            if (length(professions) > 0) {
              dbWithTransaction(
                conn = conn,
                code = {
                  dbExecute(
                    conn = conn,
                    statement = '
                      UPDATE
                        profession_entries
                      SET
                        is_selected = FALSE
                      WHERE
                        user_id = ?',
                    params = c(user_key)
                  )
                  param_placeholders <- paste(
                    rep('(?, ?, ?)', length(professions)),
                    collapse = ', '
                  )
                  dbExecute(
                    conn = conn,
                    statement = glue(
                      '
                      INSERT INTO
                        profession_entries (
                          user_id,
                          profession_id,
                          is_selected
                        )
                      VALUES
                        {param_placeholders}
                      ON CONFLICT
                        (user_id, profession_id)
                      DO UPDATE SET
                        is_selected = excluded.is_selected'
                    ),
                    params = unlist(
                      lapply(professions, function(x) { c(user_key, x, TRUE) })
                    )
                  )
                }
              )
            }
            # Update the reactive professions value only if necessary.
            if (!setequal(selected_professions(), as.character(professions))) {
              selected_professions(professions)
            }
            showNotification(
              ui = 'Profile updated.',
              type = 'message'
            )
          },
          error = function(e) {
            print(e)
            showNotification(
              ui = 'Failed to save changes. Please try again later.',
              type = 'error'
            )
          }
        )
      } else {
        if (length(gender) == 0) {
          showNotification('Please enter your gender.', type = 'error')
        }
        if (length(grade) == 0) {
          showNotification('Please enter your current grade.', type = 'error')
        }
        if (length(unit) == 0) {
          showNotification('Please enter your current unit.', type = 'error')
        }
      }
    }
  )
  
  ##### Data Entry Setup #####
  
  ###### Node Tree ######
  
  # Retrieve hierarchical maps of skills.
  skills_map_data <- get_skills_map_data(conn)
  
  # Create the (non-reactive) cross-cutting skills accordion.
  for (id in skills_map_data$professions$map[['NA']]$categories) {
    if (is.na(skills_map_data$categories$map[[id]]$parent)) {
      insertUI(
        selector = '#cross_cutting_skills_accordion',
        where = 'beforeEnd',
        ui = create_accordion_category_node(id, skills_map_data$categories$map)
      )
    }
  }
  
  # Create the (reactive) profession-specific skills accordions.
  observeEvent(
    eventExpr = selected_professions(),
    handlerExpr = {
      removeUI('#profession_specific_skills_accordion *', multiple = TRUE)
      removeUI('#other_skills_accordion *', multiple = TRUE)
      for (profession_id in skills_map_data$professions$ids) {
        if (profession_id %in% selected_professions()) {
          for (category_id in skills_map_data$professions$map[[profession_id]]$categories) {
            insertUI(
              selector = '#profession_specific_skills_accordion',
              where = 'beforeEnd',
              ui = create_accordion_category_node(category_id, skills_map_data$categories$map)
            )
          }
        } else {
          for (category_id in skills_map_data$professions$map[[profession_id]]$categories) {
            insertUI(
              selector = '#other_skills_accordion',
              where = 'beforeEnd',
              ui = create_accordion_category_node(category_id, skills_map_data$categories$map)
            )
          }
        }
      }
    }
  )
  
  # Set the current category to NULL for a landing page.
  data_entry_current_category <- reactiveVal(NULL)
  
  # Create observe events for each link button.
  walk(
    skills_map_data$categories$ids,
    function(x) {
      observeEvent(
        eventExpr = input[[glue('data_entry_category_button_{x}')]],
        handlerExpr = {
          data_entry_current_category(x)
        }
      )
    }
  )
  
  ###### Formsets ######
  
  # Cache formset UI elements in a hash map for rapid access... actually, no.
  # Define a function to retrieve a skill form, and create it otherwise.
  
  # Create the dynamic UI for the current data entry page.
  output$data_entry_formset <- renderUI({
    category_id <- data_entry_current_category()
    if (!is.null(category_id)) {
      page_skills <- skills_map_data$categories$map[[category_id]]$skills
      page_skills_numeric <- as.numeric(page_skills)
      existing_entries <- conn %>% 
        dbGetQuery(
          statement = '
            SELECT
              user_id,
              skill_id,
              proficiency,
              used_in_last_six_months,
              period
            FROM (
              SELECT
                user_id,
                skill_id,
                proficiency,
                used_in_last_six_months,
                period,
                ROW_NUMBER() OVER (
                  PARTITION BY
                    user_id,
                    skill_id
                  ORDER BY
                    period DESC
                ) as row_number
              FROM
                skill_entries
              WHERE
                user_id = ?
              ) subquery
            WHERE
              row_number = 1',
          params = c(
            user_key
          )
      ) %>% 
        filter(skill_id %in% as.numeric(page_skills)) %>% 
        split(as.character(.$skill_id))
      if (length(existing_entries) > 0) {
        existing_entries <- hash(existing_entries)
      } else {
        existing_entries <- hash()
      }
      formset <- do.call(
        tags$div,
        lapply(
          page_skills,
          function(x) {
            card(
              card_title(skills_map_data$skills$map[[x]]$name, container = h6),
              card_body(
                selectizeInput(
                  inputId = glue('proficiency_input_{x}'),
                  label = 'Proficiency',
                  choices = list(
                    `-` = '',
                    `No Knowledge or Experience` = 0,
                    `Knowledge but no Experience` = 1,
                    `Limited Experience` = 2,
                    `Moderate Experience` = 3,
                    `Good Experience` = 4
                  ),
                  selected = existing_entries[[x]]$proficiency
                ),
                checkboxInput(
                  inputId = glue('used_in_last_six_months_input_{x}'),
                  label = 'Used in the last six months?',
                  value = !is.null(existing_entries[[x]]) && existing_entries[[x]]$used_in_last_six_months
                )
              ),
              class = 'skill-card'
            )
          }
        )
      )
      walk(
        page_skills,
        function(x) {
          observeEvent(
            eventExpr = c(
              input[[glue('proficiency_input_{x}')]],
              input[[glue('used_in_last_six_months_input_{x}')]]
            ),
            handlerExpr = {
              dbExecute(
                conn = conn,
                statement = '
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
                  ON CONFLICT DO UPDATE SET
                    proficiency = excluded.proficiency,
                    used_in_last_six_months = excluded.used_in_last_six_months,
                    last_modified = excluded.last_modified',
                params = c(
                  user_key,
                  as.integer(x),
                  as.integer(input[[glue('proficiency_input_{x}')]]),
                  as.logical(input[[glue('used_in_last_six_months_input_{x}')]]),
                  floor_date(today(), unit = 'months'),
                  now()
                )
              )
            }
          )
        }
      )
      return(formset)
    } else {
      return(tags$p('Please select a category.'))
    }
  })
}
