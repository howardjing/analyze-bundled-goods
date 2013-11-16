Notes for Julian
----------------
This is a quick standalone program for analyzing the bundled goods data. You're going to have to create a database.yml file in the root folder of this project to connect to the appopriate data set. An example yml file is provided as ```database.example.yml```.

If you don't have the bundled goods data on your computer:

- Creating a postgres database
```createdb {db-name} -O {user-name}```
- Restoring a .sql file to postgres
```psql -U {user-name} -d {db-name} -f {path/to/dumpfilename.sql}```

Once you have the database config file set up, you can run the program from the command line by cding into the analyze-bundled-goods directly and typing the following command:

```ruby analyze.rb```

Type a question id to view the partial values of each step. Type q to quit the program (or just ctrl+c).