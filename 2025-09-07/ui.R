library(bslib)
library(DBI)
library(shiny)

ui <- tagList(
  tags$head(
    tags$link(rel = 'stylesheet', type = 'text/css', href = 'styles.css')
  ),
  page_navbar(
    nav_panel(
      title = 'Data Entry',
      sidebarLayout(
        sidebarPanel = sidebarPanel(
          width = 4,
          accordion(
            open = FALSE,
            accordion_panel(
              title = 'Profession-Specific',
              accordion(
                id = 'profession_specific_skills_accordion'
              )
            ),
            accordion_panel(
              title = 'Cross-Cutting',
              accordion(
                id = 'cross_cutting_skills_accordion'
              )
            ),
            accordion_panel(
              title = 'Other',
              accordion(
                id = 'other_skills_accordion'
              )
            ),
            class = 'data-entry-skills-accordion'
          )
        ),
        mainPanel = mainPanel(
          width = 8,
          # Needs a progress bar on top
          # Then a scrollable form
          # Couple of action buttons
          fluidRow(
            column(
              width = 12,
              uiOutput(outputId = 'data_entry_formset')
            )
          ),
          fluidRow(
            column(
              width = 3,
              actionButton(
                inputId = 'data_entry_save_button',
                label = 'Save and Exit'
              )
            ),
            column(
              width = 2,
              offset = 5,
              actionButton(
                inputId = 'data_entry_back_button',
                label = 'Back'
              )
            ),
            column(
              width = 2,
              actionButton(
                inputId = 'data_entry_next_button',
                label = 'Next'
              )
            )
          )
        ),
        position = 'left'
      )
    ),
    nav_panel(
      title = 'My Details',
      tags$div(
        class = 'profile-form',
        accordion(
          open = FALSE,
          multiple = FALSE,
          accordion_panel(
            title = 'Current Professions (select all that apply)',
            checkboxGroupInput(
              inputId = 'profile_professions_selection',
              label = NULL
            )
          ),
          accordion_panel(
            title = 'Gender',
            radioButtons(
              inputId = 'profile_gender_selection',
              label = NULL,
              choices = c('Placeholder'),
              selected = character(0)
            )
          ),
          accordion_panel(
            title = 'Grade',
            radioButtons(
              inputId = 'profile_grade_selection',
              label = NULL,
              choices = c('Placeholder'),
              selected = character(0)
            )
          ),
          accordion_panel(
            title = 'Unit',
            radioButtons(
              inputId = 'profile_unit_selection',
              label = NULL,
              choices = c('Placeholder'),
              selected = character(0)
            )
          )
        ),
        actionButton(
          inputId = 'profile_save_button',
          label = 'Save',
          icon = icon('floppy-disk')
        )
      )
    ),
    title = 'Skillscape'
  )
)
