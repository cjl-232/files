#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    https://shiny.posit.co/
#

library(shiny)

source('create_tables.R')
source('load_dummies.R')
source('get_tree.R')

INSERT_SKILL_ENTRY_STATEMENT = '
  INSERT INTO
    skill_entries (
      user_id,
      skill_id,
      proficiency,
      used_in_last_six_months,
      last_modified
    )
  VALUES
    (?, ?, ?, ?, ?)
  ON CONFLICT DO UPDATE SET
    proficiency = excluded.proficiency,
    used_in_last_six_months = excluded.used_in_last_six_months,
    last_modified = excluded.last_modified'

conn <- dbConnect(RSQLite::SQLite(), 'database.db')
# Define UI for application that draws a histogram
ui <- page_navbar(
  title = 'Skills Dashboard',
  header = includeCSS('www/styles.css'),
  nav_panel(title = 'My Skills', create_accordion(conn)),
  nav_panel(title = 'Other', p('Empty'))
)
dbDisconnect(conn)

# Define server logic required to draw a histogram
server <- function(input, output, session) {
  conn <- dbConnect(RSQLite::SQLite(), 'database.db')
  
  # Determine user id from session:
  user_key <- 1
  
  # Retrieve existing entries and populate the tree:
  entries <- conn %>% 
    tbl('skill_entries') %>% 
    filter(user_id == user_key) %>% 
    as.data.frame()
  if (nrow(entries) > 0) {
    for (i in 1:nrow(entries)) {
      updateSelectizeInput(
        inputId = paste0('proficiency_input_', entries$skill_id[i]),
        selected = entries$proficiency[i]
      )
      print(paste0('used_in_last_six_months_input_', entries$skill_id[i]))
      print(entries$used_in_last_six_months[i])
      updateCheckboxInput(
        inputId = paste0('used_in_last_six_months_input_', entries$skill_id[i]),
        value = entries$used_in_last_six_months[i] == "TRUE"
      )
    }
  }
  
  # Every skill needs to have a reactive component...
  skill_reactives <- conn %>% 
    tbl('skills') %>% 
    pull(id) %>%
    lapply(function(x) {
      observe({
        proficiency <- input[[paste0('proficiency_input_', x)]]
        if (proficiency != '') {
          used_in_last_six_months <- input[[paste0('used_in_last_six_months_input_', x)]]
          dbExecute(
            conn = conn,
            statement = INSERT_SKILL_ENTRY_STATEMENT,
            params = c(user_key, x, proficiency, used_in_last_six_months, now())
          )
        }
      })
    })
  
  session$onSessionEnded(function() {
    dbDisconnect(conn)
  })
}

# Run the application 
shinyApp(ui = ui, server = server)
