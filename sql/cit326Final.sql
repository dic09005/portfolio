/*



SHOW 1:  the commands or steps used to accomplish everything in step 1.	

	docker pull mcr.microsoft.com/mssql/server:2019-latest
	docker run -e "ACCEPT_EULA=Y" -e "MSSQL_SA_PASSWORD=Pa55word88*" -p 1433:1433 -d mcr.microsoft.com/mssql/server:2019-latest

Explain the benefits of using docker.

SHOW 2: your connection and the method you used to migrate your database.

	docker cp pokemon.bak stupefied_carver:/home

	Server Name: something,1433 //IP changes, don't panic
	Login:    sa
	Password: Pa55word88*

	// Note for when you try to restart and your container isn't there, and how to fix it for good

	docker ps -a  //showes all containers
	docker restart [container name]
	docker update --restart=always [container name]

SHOW 3: the commands or steps used to accomplish everything in step 3.
Create at least two new schemas
Transfer at least two tables of your choice into each of the new schemas
Issue a grant command that will give select rights on one schema to a new final_test_user login.
		Test this by logging into the database with this new login and prove that the account can only see the one schema granted and not the other (you must run select statements on tables from both schemas - one schema should work, the other select should fail).
Explain why using schemas is a good security practice.
*/


USE [dickson_pokemon_final]

CREATE SCHEMA [pokemon]

CREATE SCHEMA [item]

CREATE SCHEMA [move]

/* ALTER SCHEMA "schema" TRANSFER "Table"; */

ALTER SCHEMA pokemon TRANSFER pokemon;
ALTER SCHEMA pokemon TRANSFER pokemon_abilities;
ALTER SCHEMA pokemon TRANSFER pokemon_dex_numbers;
ALTER SCHEMA pokemon TRANSFER pokemon_egg_groups;
ALTER SCHEMA pokemon TRANSFER pokemon_form_generations;
ALTER SCHEMA pokemon TRANSFER pokemon_items;

ALTER SCHEMA pokemonColor TRANSFER pokemon_color_names;
ALTER SCHEMA pokemonColor TRANSFER pokemon_colors;
ALTER SCHEMA pokemonColor TRANSFER pokemon_types;
ALTER SCHEMA pokemonColor TRANSFER pokemon_evolution;


ALTER SCHEMA item TRANSFER items;
ALTER SCHEMA item TRANSFER item_categories;
ALTER SCHEMA item TRANSFER item_category_prose;
ALTER SCHEMA item TRANSFER item_flag_map;
ALTER SCHEMA item TRANSFER item_flags;
ALTER SCHEMA item TRANSFER item_flag_prose;
ALTER SCHEMA item TRANSFER item_flavor_summaries;
ALTER SCHEMA item TRANSFER item_flavor_text;



USE [master]
CREATE LOGIN [final_test_user] WITH PASSWORD=N'Password', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
USE [dickson_pokemon_final]
CREATE USER [final_test_user] FOR LOGIN [final_test_user]
USE [dickson_pokemon_final]
GRANT SELECT ON SCHEMA::[pokemon] TO [final_test_user]

/* Good */
SELECT * FROM pokemon.pokemon
WHERE weight <= 25;

/* Bad */
SELECT * FROM item.item_categories
WHERE pocket_id = 7;



/*
4. Create a view that combines (joins) data from two tables - 
one table should be in the schema from 3b and the other table 
should be in the schema you have not granted any access to. 
	a) The view should be created using the same schema name as the schema you granted SELECT to in step 3b. 
	b) Then, grant SELECT on this view to the account created in step 3b. 
	c) Prove that this view works by logging in to the database as final_test_user and selecting from the view.

SHOW 4:  the commands or steps used to accomplish everything in step 4.
Explain why using views is a good security practice.
*/


USE [dickson_pokemon_final];

CREATE VIEW pokemon.pokemon_species_names_vs_Item
AS
SELECT pokemon.pokemon_species.identifier AS "Pokemon", item.items.identifier AS "Item" 
FROM pokemon.pokemon_species
JOIN pokemon.pokemon_items
ON pokemon.pokemon_items.pokemon_id = pokemon.pokemon_species.id
JOIN item.items
ON item.items.id = pokemon.pokemon_items.item_id
WHERE pokemon.pokemon_items.version_id = 7
ORDER BY Pokemon;

GRANT SELECT ON pokemon.pokemon_species_names_vs_Item TO final_test_user;

SELECT TOP (1000) [Pokemon]
      ,[Item]
  FROM [dickson_pokemon_final].[pokemon].[pokemon_species_names_vs_Item]


/*
5. Create a new database level role (example at this link under “Listing 8” OR review where we did this in week 3 
when we read chapter 12). This role should include the following privileges:
	a) SELECT on the schema from step 3b.
	b) SELECT on the view from step 4b.
	c) SELECT on a table of your choice that is NOT inside the schema from 3b.
	d) Then, create a list of all the needed DCL (grant commands) from steps a through c and assign all of 
	these privileges to this role. 
	e) Create another new login, final_running_buddy, and add it as a member of this new role.

SHOW 5:  the commands or steps used to accomplish everything in step 5.
Explain why using roles is a good security practice.
*/

USE [dickson_pokemon_final];
CREATE ROLE [trainer]

GRANT SELECT ON SCHEMA::[pokemon] TO [trainer]

GRANT SELECT ON [pokemon].[pokemon_species_names_vs_Item] TO [trainer]

GRANT SELECT ON [dbo].[version_names] TO [trainer]


USE [dickson_pokemon_final];

CREATE LOGIN [final_running_buddy] WITH PASSWORD=N'Password', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF

USE [dickson_pokemon_final]
CREATE USER [final_running_buddy] FOR LOGIN [final_running_buddy]

USE [dickson_pokemon_final]
ALTER ROLE [trainer] ADD MEMBER [final_running_buddy]



/* 
6. Set up column level encryption:
	a) Choose one of the tables the final_running_buddy login should now 
	have access to from the role membership in step 5e. 
	b) Encrypt a column in the chosen table as done in week 5. (If you are using the 
	Pokemon database, you may need to select columns without constraints.)
SHOW 6: that the encryption is working.
*/

/*
Right Click TABLE
	Encrypt Columns
		Next
			Choose Columns for Encryption
			Encryption Type = Randomized
			Encryption Key Auto
				Next Next Finish
				*/

/*As User final_running_buddy */
SELECT TOP * FROM [dickson_pokemon_final].[pokemon].[pokemon]

/* 
SHOW 7:  that you can backup AND then restore your database using full recovery model.

Right Click Database
	Tasks
		Backup
			General
				Backup Type: Full
				DoubleCheck File Path
			Media Options
				Reliability: Verify Backup When Finished
			Backup Options
				//
*/

BACKUP DATABASE [dickson_pokemon_final] TO  DISK = N'/var/opt/mssql/data/dickson_pokemon_final.bak' WITH NOFORMAT, NOINIT,  NAME = N'dickson_pokemon_final-Full Database Backup', SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO
declare @backupSetId as int
select @backupSetId = position from msdb..backupset where database_name=N'dickson_pokemon_final' and backup_set_id=(select max(backup_set_id) from msdb..backupset where database_name=N'dickson_pokemon_final' )
if @backupSetId is null begin raiserror(N'Verify failed. Backup information for database ''dickson_pokemon_final'' not found.', 16, 1) end
RESTORE VERIFYONLY FROM  DISK = N'/var/opt/mssql/data/dickson_pokemon_final.bak' WITH  FILE = @backupSetId,  NOUNLOAD,  NOREWIND
GO

/*
SHOW 8: Engage in some testing with a business partner (running buddy):
	A) Help a classmate (preferably your running buddy) establish a connection to your new database 
	using the final_running_buddy login. Ask them to post a screenshot of a successful connection in 
	the Final Project Teams channel and their post and screenshot in your video. NOTE: They do not 
	have to show or prove anything other than a successful connection. Please make sure you post your 
	IP, port, and password with enough time for someone to reply to you.

	B) Also include in YOUR video what you were able to see in your classmate’s database (for the video 
	you could refer to your buddy as a business partner). Explore the following:
		- Could you find an encrypted column?
		- Did you have SELECT access to all tables in only ONE schema? (You should only be able to 
		  SELECT from one additional table outside the schema which was granted in step 5c.)
		- Did you have SELECT access to one view?
		- Report these findings to your classmate and include them in your video, BUT they do not 
		  have to be included in their video.
*/

/*
SHOW 9: Address the following in your video for the investor: 
	a) What strategies could you explore if the company grows and you were asked to create many database 
	   copies for testing purposes or future deployments? 
	b) What are some factors or options to consider regarding cloud hosting strategies? 


Kubernetties!!!!








*/