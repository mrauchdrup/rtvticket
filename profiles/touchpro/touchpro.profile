<?php
function touchpro_install_tasks() {
  $tasks['touchpro_sql_to_drupal'] = array(
    'display_name' => st('Import StarterKit'),
    'display' => TRUE,
    'type' => 'normal',
    'run' => INSTALL_TASK_RUN_IF_NOT_COMPLETED,
  );
  return $tasks;
}

/**
 * @code
 *  Borrowed from demo module
 * @see
 *  _demo_reset() in demo.admin.inc ~ #283
 */
function touchpro_sql_to_drupal() {
  // Load data from snapshot.
  $fp = fopen(dirname(__FILE__).'/starterkit.sql', 'r');
  $success = TRUE;
  $query = '';
  while (!feof($fp)) {
    $line = fgets($fp, 16384);
    if ($line && $line != "\n" && strncmp($line, '--', 2) && strncmp($line, '#', 1)) {
      $query .= $line;
      if (substr($line, -2) == ";\n") {
        $options = array(
          'target' => 'default',
          'return' => Database::RETURN_NULL,
          // 'throw_exception' => FALSE,
        );
        $stmt = Database::getConnection($options['target'])->prepare($query);
        if (!$stmt->execute(array(), $options)) {
          if ($verbose) {
            // Don't use t() here, as the locale_* tables might not (yet) exist.
            drupal_set_message(strtr('Query failed: %query', array('%query' => $query)), 'error');
          }
          $success = FALSE;
        }
        $query = '';
      }
    }
  }
  fclose($fp);

  // Fix database, needed because of this core issue http://drupal.org/node/1170362
  // to fix afer install in case it fails:
  // UPDATE {system} SET status=1 WHERE filename = 'profiles/touchpro/touchpro.profile'
  $profile = db_insert('system')
  ->fields(array(
    'filename' => 'profiles/touchpro/touchpro.profile',
    'name' => 'touchpro',
    'type' => 'module',
    'status' => 1,
    'bootstrap' => 0,
    'schema_version' => -1,
  ))
  ->execute();

  // We keep the sql file small by omitting menu_router data
  // and rebuild it after install.
  menu_router_build();
}

/**
 * @file
 * Demonstration site installation profile.
 */

/**
 * Implements hook_install_tasks_alter().
 */
function touchpro_install_tasks_alter(&$tasks, &$install_state) {

  // Remove the tasks from the list and execution.
  // We cannot implement hook_install_tasks(), because we want to intercept the
  // installation process before it even begins (except database settings).
  unset(
    //$tasks['install_system_module'],
    //$tasks['install_bootstrap_full'],
    //$tasks['install_profile_modules'],
    $tasks['install_import_locales'],
    //$tasks['install_configure_form'],
    $tasks['install_import_locales_remaining']
    //$tasks['install_finished']
  );
}
