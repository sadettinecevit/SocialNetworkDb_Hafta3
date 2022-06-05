create database SocialNetwork

use SocialNetwork

create table Users (
			Id uniqueidentifier DEFAULT NEWID() primary key
			, NickName varchar(50) not null unique
			, Name varchar(50) not null
			, Lastname varchar(50) not null
			, EMail nvarchar(50) not null unique
			, Password varchar(50) not null
			)

create table Groups (
			Id uniqueidentifier DEFAULT NEWID() primary key
			, Name varchar(50) not null
			)

create table GroupMembers (
			Id uniqueidentifier DEFAULT NEWID()
			, GroupId uniqueidentifier not null
			, UserId uniqueidentifier not null
			, Constraint GroupMembers_pk primary key (Id)
			, Constraint fk_Groups foreign key (GroupId) references Groups(Id)
			, Constraint fk_Users foreign key (UserId) references Users(Id)
			)

create table Comments (
			Id uniqueidentifier DEFAULT NEWID()
			, FromId uniqueidentifier not null
			, ToId uniqueidentifier not null
			, IsPrivate bit not null
			, Comment Text not null
			, CommentTime datetime not null
			, Constraint Comments_pk primary key (Id)
			, Constraint fk_UsersFrom foreign key (FromId) references Users(Id)
			, Constraint fk_UsersTo foreign key (ToId) references Users(Id)
			)

--bu hatalı ahmet mehmet le arkadaş mehmette ahmetle
create table Friends (
			Id uniqueidentifier DEFAULT NEWID()
			, UserId uniqueidentifier not null
			, FriendId uniqueidentifier not null
			, TimeToBeFriend datetime not null
			, Constraint Friends_pk primary key (Id)
			, Constraint fk_UsersFriends foreign key (UserId) references Users(Id)
			, Constraint fk_UsersFriendId foreign key (FriendId) references Users(Id)
			)

create table FriendRequests (
			Id uniqueidentifier DEFAULT NEWID()
			, FromId uniqueidentifier not null
			, ToId uniqueidentifier not null
			, RequestTime datetime not null
			, Response bit -- 1 : Accepted 0 : Rejected
			, ResponseTime datetime 
			, Constraint FriendRequests_pk primary key (Id)
			, Constraint fk_UsersFriendReqFrom foreign key (FromId) references Users(Id)
			, Constraint fk_UsersFriendToId foreign key (ToId) references Users(Id)
			)

create table MessageTypes (
			Id uniqueidentifier DEFAULT NEWID()
			, Type varchar(50)
			, Constraint MessageTypes_pk primary key (Id)
			)

create table Messages (
			Id uniqueidentifier DEFAULT NEWID()
			, MessageTypeId uniqueidentifier not null
			, FromId uniqueidentifier not null
			, ToId uniqueidentifier not null
			, TimeToSent datetime not null
			, MessageText nvarchar(max) 
			, ImageUrl varchar(500)
			, VideoUrl varchar(500)
			, Constraint Messages_pk primary key (Id)
			, Constraint fk_MessageFrom foreign key (FromId) references Users(Id)
			, Constraint fk_MessageType foreign key (MessageTypeId) references MessageTypes(Id)
			)

create table UpdatedMessages (
			Id uniqueidentifier DEFAULT NEWID()
			, MessageId uniqueidentifier not null
			, OldMessageTypeId uniqueidentifier not null
			, SendTime datetime not null
			, UpdateTime datetime not null default getdate()
			, OldMessageText nvarchar(max) 
			, OldImageUrl varchar(500)
			, OldVideoUrl varchar(500)
			, Constraint UpdatedMessages_pk primary key (Id)
			, Constraint fk_UpdatedMessagesId foreign key (MessageId) references Messages(Id)
			, Constraint fk_OldMessageTypeId foreign key (OldMessageTypeId) references MessageTypes(Id)
			)

create trigger Update_FriendRequest 
ON FriendRequests
after update as
begin
	if Exists(select 1 from deleted where Response = 0)
	begin
		declare @userid uniqueidentifier, @FriendId uniqueidentifier
		select @userid = FromId, @FriendId = ToId from deleted
		
		insert into Friends(UserId, FriendId, TimeToBeFriend) values(@userid, @FriendId, GETDATE())
		insert into Friends(UserId, FriendId, TimeToBeFriend) values(@FriendId, @userid, GETDATE())
	end
end

create trigger Update_MessageUpdate 
ON Messages
after update as
begin
	declare @MessageId uniqueidentifier, @MessageTypeId uniqueidentifier, @UpdateTime datetime, @ImageUrl varchar(500), @VideoUrl varchar(500), @SendTime datetime, @MessageText nvarchar(max) --text -- bundan dolayı hata alıyorum
	select
		@MessageId = d.Id
		, @MessageTypeId = d.MessageTypeId
		, @UpdateTime = getdate()
		, @MessageText = d.MessageText
		, @ImageUrl = d.ImageUrl
		, @VideoUrl = d.VideoUrl
		, @SendTime = d.TimeToSent
	from
		deleted d

	insert into 
		UpdatedMessages (MessageId, OldMessageTypeId, SendTime, UpdateTime, OldMessageText, OldImageUrl, OldVideoUrl)
	values
		(
			@MessageId
			, @MessageTypeId
			, @SendTime
			, @UpdateTime
			, @MessageText
			, @ImageUrl
			, @VideoUrl
		)
end

create proc USERS_MOSTTEXT
as
	declare @maxQuantity int
	set @maxQuantity = (select top(1) Count(*) as Quantity from Messages group by FromId order by Quantity desc)

	select * from 
	(
		select 
			FromId
			, Count(*) as Quantity 
		from	 
			Messages
		group by 
			FromId 
	) as tbl
	where 
		tbl.Quantity = @maxQuantity 