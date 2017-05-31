GM.Name =   "/bash/";
GM.Author = "LilSumac";

-- Process the game directories.
bash.util.includeDir("config");
bash.util.includeDir("external");
bash.util.includeDir("obj");
bash.util.includeDir("lib");

-- Entry point for the SQL DB.
bash.sql.connect();
