// Enable CSS Styling via userChrome.css
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);

// Import Bookmarks & Icons
user_pref("browser.places.importBookmarksHTML", true);
user_pref(
  "browser.bookmarks.file",
  "{{ firefox_profile_path }}/bookmarks.html",
);
