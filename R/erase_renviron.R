#' Erase Environment Variables from .Renviron File
#'
#' Removes specified environment variables from the user's .Renviron file. This function
#' is useful when you want to unset previously configured environment variables, allowing 
#' the package to fall back to runtime defaults or when cleaning up package configuration.
#'
#' Note: This function only modifies the .Renviron file, not the current R session.
#' To also remove these variables from the current session, use `sync_env_vars()` after 
#' calling this function.
#'
#' @param var_names Character vector of variable names to erase from the .Renviron file.
#' @param package Character string with the package name. Used for validation if provided.
#' @param renviron_path Path to the .Renviron file. Defaults to the user's home directory.
#' @param validate Logical; if TRUE (default), validates variable names against the
#'   package's YAML configuration. Only applies if package is provided.
#' @param allowed_vars Optional character vector of allowed variable names for validation.
#'   If NULL (default), the function will use the names from the package's YAML configuration.
#'
#' @return Invisibly returns NULL.
#'
#' @examples
#' \dontrun{
#' # Remove specific environment variables
#' erase_renviron(c("MY_PACKAGE_DATA_DIR", "MY_PACKAGE_API_KEY"),
#'                package = "mypackage")
#' 
#' # Remove all package variables at once
#' var_names <- get_var_names(package = "mypackage")
#' erase_renviron(var_names, package = "mypackage")
#' 
#' # After erasing, sync the current session to reflect changes
#' sync(var_names)
#' 
#' # Using in a package configuration reset function
#' reset_package_config <- function() {
#'   pkg <- "mypackage"
#'   var_names <- get_var_names(package = pkg)
#'   erase_renviron(var_names, package = pkg)
#'   sync(var_names)
#'   cat("Package configuration has been reset. Runtime defaults will be used.\n")
#' }
#' }
#'   
#' @export
erase_renviron <- function(var_names,
                           package = NULL,
                           renviron_path = get_renviron_path(),
                           validate = TRUE,
                           allowed_vars = NULL) {
  
  # Validate variable names if requested
  if (validate && !is.null(package)) {
    validate(package = package, var_names = var_names, warn = FALSE, allowed_vars = allowed_vars)
  }
  
  # Make sure the file exists, but don't create it if it doesn't
  if (!file.exists(renviron_path)) {
    cli::cli_abort(".Renviron file not found at {.file {renviron_path}}")
  }
  
  # Read existing content
  lines <- readLines(renviron_path, warn = FALSE)
  
  # Track which variables were erased for messaging
  erased_vars <- character(0)
  
  for (var_name in var_names) {
    # Create pattern to match the variable definition
    var_pattern <- paste0("^\\s*", var_name, "\\s*=")
    # Check if variable exists
    matches <- grep(var_pattern, lines)
    
    if (length(matches) > 0) {
      # Remove the variable from the file
      lines <- lines[-matches]
      erased_vars <- c(erased_vars, var_name)
    }
  }
  
  # Write back to file if any variables were erased
  if (length(erased_vars) > 0) {
    writeLines(lines, renviron_path)
    cli::cli_alert_success("Erased variables from .Renviron: {.val {erased_vars}}")
  }
  
  return(invisible(NULL))
}
