library(bslib)
library(checkmate)
library(DBI)
library(hash)
library(shiny)
library(tidyverse)

create_skill_card <- function(id, name) {
  result <- card(
    card_header(
      card_title(name, class = 'accordion-title', container = h6)
    ),
    card_body(
      selectizeInput(
        inputId = paste0('proficiency_input_', id),
        label = 'Proficiency',
        choices = list(
          `-` = '',
          `No Knowledge or Experience` = 0,
          `Knowledge but no Experience` = 1,
          `Limited Experience` = 2,
          `Moderate Experience` = 3,
          `Good Experience` = 4
        )
      ),
      checkboxInput(
        inputId = paste0('used_in_last_six_months_input_', id),
        label = 'Used in the last six months?'
      )
    ),
    class = 'skill-card'
  )
  return(result)
}

create_category_accordion_panel <- function(id, node_map) {
  node = node_map[[as.character(id)]]
  subnodes = lapply(
    node$children_ids,
    create_category_accordion_panel,
    node_map = node_map
  )
  if (length(subnodes) > 0) {
    content <- list(do.call(accordion, append(subnodes, list(open = FALSE))))
  } else {
    content <- list()
  }
  if (nrow(node$skills) > 0) {
    content <- append(
      content,
      lapply(
        1:nrow(node$skills),
        function(x) {
          create_skill_card(node$skills$id[x], node$skills$name[x])
        }
      )
    )
  }
  if (length(content) == 0) {
    content = list(p('Empty category.'))
  }
  return(do.call(accordion_panel, append(content, list(title = node$name))))
}

create_accordion <- function(conn) {
  df <- conn %>% 
    tbl('skill_categories') %>% 
    arrange(name) %>%
    mutate(
      id = as.character(id),
      parent_id = as.character(parent_id)
    )
  df <- df %>% 
    as.data.frame()
  
  nodes = hash()
  
  for (i in 1:nrow(df)) {
    category_key = as.integer(df$id[i])
    skills <- conn %>% 
      tbl('skills') %>% 
      filter(category_id == category_key) %>% 
      arrange(name) %>% 
      select(id, name)
    nodes[df$id[i]] <- list(
      id = df$id[i],
      name = df$name[i],
      parent_id = df$parent_id[i],
      children_ids = c(),
      skills = as.data.frame(skills)
    )
  }
  for (i in 1:nrow(df)) {
    if (!is.na(nodes[[df$id[i]]]$parent_id)) {
      nodes[[nodes[[df$id[i]]]$parent_id]][['children_ids']] <- c(
        nodes[[nodes[[df$id[i]]]$parent_id]][['children_ids']],
        df$id[i]
      )
    }
  }
  # Create the root panels:
  roots <- df %>% 
    filter(is.na(parent_id)) %>% 
    pull(id) %>% 
    lapply(function(x) create_category_accordion_panel(x, nodes))
  
  
  return(do.call(accordion, append(roots, list(open = FALSE))))
}