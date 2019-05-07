if not exists (select 1 from sys.databases where name = 'SpWhoDemo')
	create database [SpWhoDemo];
go

use [SpWhoDemo]
go

set nocount on;

if not exists (select 1 from sys.schemas where name = 'who')
begin
	declare @sql nvarchar(500);
	set @sql = 'Create Schema Who;';
	exec sp_executeSQL @sql;
end;
go

if not exists (select 1 from sys.procedures where name like 'SpWhoTestProc%')
begin
	declare @sql nvarchar(500);
	declare @counter int;
	set @counter = 001
	declare @limit int = 100;
	
	while @counter <= @limit
	begin
		set @sql = 
		'create proc Who.SpWhoTestProc'+ 
			right(( '00' +cast(@counter as nvarchar(3))), 3)
			+ ' as 
		set nocount on; 

		select StatusText from Who.SpWhoTestTable where ID = 1;
		waitfor delay ''00:20:00''
		select StatusText from Who.SpWhoTestTable where ID = 2;';
		exec sp_executesql @sql;
		--select @sql

		set @sql = '';
		set @counter += 1;
	end;
end;
go


if not exists (Select 1 from sys.tables where name = 'SpWhoTestTable')
begin
	declare @sql nvarchar(500);

	set @sql = 
	'set nocount on;
	create table Who.SpWhoTestTable 
	(
		ID tinyint identity(1,1) primary key clustered
		, StatusText varchar(200)
	);

	Insert into Who.SpWhoTestTable (StatusText)
	values 
		(''This is good code.'')
		, (''This is good code, too, but it''''s blocked by bad code!'');';
				
	exec sp_executesql @sql;
end;
go