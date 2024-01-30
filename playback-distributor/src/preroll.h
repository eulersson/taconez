/**
 * Chooses a preroll file randomly from the /app/prerolls folder.
 * 
 * NOTE: Remember to free the returned string.
 *
 * NOTE: It could be implemented with a linked list but I do not consider worth the
 * effort because it might sacrifice readibility for such a simple task and we would
 * need to iterate over the list to locate and free the items anyway.
 */
char *randomly_choose_preroll_file();