---------------------------------------------------------- Create Database------------------
print ' Create - Degree53 Database'
go

 if not exists(select * from sys.databases where name='Degree53Database')
begin
drop database Degree53Database
end;
go

 if not exists(select * from sys.databases where name='Degree53Database')
begin
	  exec ('create database Degree53Database');
end;
 go
 --Please change Db at this point
---------------------------------------------------------- Create Schema -------------------

print 'Create - Degree53 schema';
go
if not exists ( select 1
                  from sys.schemas
                 where name = 'Degree53')
begin
  exec ('create schema Degree53 authorization [dbo]');
end;
go

print 'Create - Degree53Audit schema';
go
if not exists ( select 1
                  from sys.schemas
                 where name = 'Degree53Audit')
begin
  exec ('create schema Degree53Audit authorization [dbo]');
end;
go

---------------------------------------------------------- Drop constraints ------------

if exists (select 1 from sys.foreign_keys where name = 'FK_PostDetail_Post')
begin
  alter table Degree53.PostDetail
   drop constraint FK_PostDetail_Post;
end;
go

---------------------------------------------------------- Create Post ------------

print 'Create - Degree53.Post';
go
drop table if exists Degree53.Post;
go

create table Degree53.Post
     ( Id             int identity(1,1) not null
     , Title          nvarchar(40)          null
     , Content        nvarchar(max)         null
     , constraint PK_Post_Id primary key clustered (Id) );
go

--------------------------------------------------------------------------------------------

print 'Create - Degree53Audit.Post';
go
drop table if exists Degree53Audit.Post;
go

create table Degree53Audit.Post
     ( Id             int              not null
     , Title          nvarchar(40)         null
     , Content        nvarchar(max)        null
     , AuditedOn      datetimeoffset   not null
     , EditOperation  nvarchar(16)     not null );
go

--------------------------------------------------------------------------------------------

print 'Create Trigger - Degree53.PostTrigger';
go
drop trigger if exists Degree53.PostTrigger;
go

create trigger Degree53.PostTrigger on Degree53.Post
after insert, update
as
begin

  declare @operation int = 0;
  select top 1 @operation += 1
    from inserted;
  select top 1 @operation += 2
    from deleted;

  if(@operation in (2,3))
  begin
    insert Degree53Audit.Post
         ( Id
         , Title 
         , Content
         , AuditedOn
         , EditOperation )
    select Id
         , Title 
         , Content
         , getdate()
         , case @operation
             when 2 then 'Deleted'
             when 3 then 'Update-Pre'
             else 'Error on Deleted'
           end
      from deleted;
  end;

  if (@operation in (1, 3)) -- Inserted or Updated
  begin
    insert Degree53Audit.Post
        ( Id
         , Title 
         , Content
         , AuditedOn
         , EditOperation )
    select Id
         , Title 
         , Content
         , getdate()
         , case @operation
             when 1 then 'Inserted'
             when 3 then 'Update-Post'
             else 'Error on Inserted'
           end
      from inserted;
  end;
end;
go

--------------------------------------------------------------------------------------------

print 'Create Trigger - Degree53.PostDeleteTrigger';
go
drop trigger if exists Degree53.PostDeleteTrigger;
go

create or alter trigger Degree53.PostDeleteTrigger on Degree53.Post
instead of delete
as
begin

insert Degree53Audit.Post
         ( Id
         , Title 
         , Content
         , AuditedOn
         , EditOperation )
    select Id
         , Title 
         , Content
		 , sysdatetimeoffset()
		 , 'Deleted'
  from deleted;

delete pst
  from Degree53.Post pst
         join
       deleted        del on del.Id = pst.Id;

end;
go

---------------------------------------------------------- Create PostDetail ------------

print 'Create - Degree53.PostDetail';
go
drop table if exists Degree53.PostDetail;
go

create table Degree53.PostDetail
     ( Id             int identity(1,1)   not null
     , NumbersOfViews     int              not null
     , PostId             int              not null
     , CreationDate       datetimeoffset   not null
     , constraint PK_PostDetail_Id primary key clustered (Id) );
go

--------------------------------------------------------------------------------------------

print 'Create - Degree53Audit.PostDetail';
go
drop table if exists Degree53Audit.PostDetail;
go

create table Degree53Audit.PostDetail
     ( Id                 int              not null
     , NumbersOfViews     int              not null
     , PostId             int              not null
     , CreationDate       datetimeoffset   not null
     , AuditedOn          datetimeoffset   not null
     , EditOperation      nvarchar(16)     not null );
go

--------------------------------------------------------------------------------------------

print 'Create Trigger - Degree53.PostDetailTrigger';
go
drop trigger if exists Degree53.PostDetailTrigger;
go

create trigger Degree53.PostDetailTrigger on Degree53.PostDetail
after insert, update
as
begin

  declare @operation int = 0;
  select top 1 @operation += 1
    from inserted;
  select top 1 @operation += 2
    from deleted;

  if(@operation in (2,3))
  begin
    insert Degree53Audit.PostDetail
         ( Id
         , NumbersOfViews
         , PostId
         , CreationDate
         , AuditedOn
         , EditOperation )
    select Id
         , NumbersOfViews
         , PostId
         , CreationDate
         , getdate()
         , case @operation
             when 2 then 'Deleted'
             when 3 then 'Update-Pre'
             else 'Error on Deleted'
           end
      from deleted;
  end;

  if (@operation in (1, 3)) -- Inserted or Updated
  begin
    insert Degree53Audit.PostDetail
        ( Id
         , NumbersOfViews
         , PostId
         , CreationDate
         , AuditedOn
         , EditOperation )
    select Id
         , NumbersOfViews
         , PostId
         , CreationDate
         , getdate()
         , case @operation
             when 1 then 'Inserted'
             when 3 then 'Update-Post'
             else 'Error on Inserted'
           end
      from inserted;
  end;
end;
go

--------------------------------------------------------------------------------------------

print 'Create Trigger - Degree53.PostDetailDeleteTrigger';
go
drop trigger if exists Degree53.PostDetailDeleteTrigger;
go

create or alter trigger Degree53.PostDetailDeleteTrigger on Degree53.PostDetail
instead of delete
as
begin

insert Degree53Audit.PostDetail
         ( Id
         , NumbersOfViews
         , PostId
         , CreationDate
         , AuditedOn
         , EditOperation )
    select Id
         , NumbersOfViews
         , PostId
         , CreationDate
     , sysdatetimeoffset()
     , 'Deleted'
  from deleted;

delete pst
  from Degree53.Post pst
         join
       deleted        del on del.Id = pst.Id;

end;
go
---------------------------------------------------------- Create constraints ------------

if not exists (select 1 from sys.foreign_keys where name = 'FK_PostDetail_Post')
begin
    alter table Degree53.PostDetail
      add constraint FK_PostDetail_Post foreign key ( PostId ) references Degree53.Post ( Id );
end;
go
