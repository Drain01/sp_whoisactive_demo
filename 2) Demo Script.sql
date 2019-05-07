use [SpWhoDemo]
go

/* sp_whoisactive requires no input parameters. Just running this will return a snapshot of all current activity on the server.

one result - one active request right now. Note that sp_whoisactive filters out system spids and activity */
exec sp_whoisactive;


SELECT   
	DISTINCT SCHEMA_NAME(o.schema_id) as SchemaName
	,o.name as ProcName
FROM     syscomments AS c
         INNER JOIN sys.objects AS o ON c.id = o.[object_id]
         INNER JOIN sys.schemas AS s ON o.schema_id = s.schema_id
WHERE    text LIKE '%waitfor delay ''00:20:00''%'
ORDER BY  SCHEMA_NAME(o.schema_id),o.name;

/* @Get_full_inner_text example. This will return either the stored proc or batch the current query is a part of. */
exec sp_WhoIsActive @get_full_inner_text = 1;
go

create proc [Who].[SpWhoTestProc001] as 
		set nocount on; 

		/* Good Code */
		select StatusText from who.SpWhoTestTable where ID = 1;

		/* Substitute for bad code */
		waitfor delay '00:20:00';

		/* Another bit of Good Code */
		select StatusText from who.SpWhoTestTable where ID = 2;
GO

/* @Get_plans with a value of 1 will return the plan for the currently executing query */
exec sp_WhoIsActive @get_plans = 1;

/* This will get the plans for all the current stored procs */
exec sp_WhoIsActive @get_full_inner_text = 1, @get_plans = 2;

/* Find Deltas - this runs sp_whoisactive, waits five seconds, then runs it again. It then returns info on certain metrics during that time.

Most sp_whoisactive metric are cumulative, delta gets you a measurement over time. Helps you find what is currently eating up server resources instead
of what WAS doing that.  */
exec sp_WhoIsActive  @delta_interval = 5

/* Use @Filter and @Filter_Type to [Shocked Face] filter result sets!
   
Use the @Not_filter variables to remove things from the resultset. 
   
   This will filter out anything from Mangement Studio - note the use of wildcards
   
   other @not_filter_types: session (SPID), program, database, login, and host    */
exec sp_whoisactive @not_filter_type = 'program', @not_filter = '%Management Studio%';


/*   This only returns results for Management Studio! */
exec sp_whoisactive @filter_type = 'program', @filter = '%Management Studio%';



/* What if you only care about certain columns? Only return those columns! */
exec sp_whoisactive @output_column_list = '[dd hh:mm:ss.mss][login_name][cpu][reads][writes][sql_text]';


/* Again, this works fine with columns added by other input parameters */
exec sp_whoisactive @output_column_list = '[dd hh:mm:ss.mss][login_name][cpu][reads][writes][sql_text][query_plan]', @get_plans = 1;

/* Create your own lightweight monitoring tool using sp_whoisactive! 

We can do this by using @return_schema to create a table to hold the output. */
declare @schemaout VARCHAR(MAX)

exec sp_whoisactive @output_column_list = '[dd hh:mm:ss.mss][login_name][cpu][reads][writes][sql_text][query_plan]', @get_plans = 1
	, @return_schema = 1, @schema = @schemaout output;

select @schemaout

/* Now we create the table itself. By default the table is a heap - if you are persisting data over a long period of time, best to add
a PK / CI. */
if not exists (Select 1 from sys.tables where  Schema_id = schema_id('Who') and name = 'SPActiveOutput')
create table Who.SPActiveOutput 
(
	 ID int identity(1,1) primary key clustered
	 , [dd hh:mm:ss.mss] varchar(8000) NULL
	 ,[login_name] nvarchar(128) NOT NULL
	 ,[CPU] varchar(30) NULL
	 ,[reads] varchar(30) NULL
	 ,[writes] varchar(30) NULL
	 ,[sql_text] xml NULL
	 ,[query_plan] xml NULL
 );

 else
	truncate table Who.SPActiveOutput;

 /* Now, we call sp_whoisactive and we point it to the table we just created.
 
 @destination_table supports 3 part names [DB].[Schema].Table], but it will assume the current DB and DBO if those parts aren't provided. 
 
 It does NOT check to ensure the table exists before inserting or that columns match - that's up to you. Adding an ID column for a PK / CI is fine. */

 exec sp_whoisactive @output_column_list = '[dd hh:mm:ss.mss][login_name][cpu][reads][writes][sql_text][query_plan]', @get_plans = 1,
	@destination_table = 'Who.SpActiveOutput';
go 5

select * from Who.SPActiveOutput;

/* Perhaps the most important input parameter that for anyone who wants to know more about sp_whoisactive */

exec sp_whoisactive @help = 1;

/* Additional options to create scenarios for

@filter

@output_column_list

@return_schema and @destination_table */
