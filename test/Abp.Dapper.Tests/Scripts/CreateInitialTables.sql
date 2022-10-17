 CREATE TABLE IF NOT EXISTS Products (
											Id INTEGER PRIMARY KEY
										,	Name varchar(100) 
										,	IsDeleted BOOLEAN
										,	DeleterUserId NVARCHAR(1024)
										,	DeletionTime DATETIME
										,	LastModificationTime DATETIME
										,	LastModifierUserId NVARCHAR(1024)
										,	CreationTime DATETIME
										,	CreatorUserId NVARCHAR(1024)
										,	TenantId NVARCHAR(1024)
										, Status BOOLEAN
									);

 CREATE TABLE IF NOT EXISTS ProductDetails (
											Id INTEGER PRIMARY KEY
										,	Gender varchar(100) 
										,	IsDeleted BOOLEAN
										,	DeleterUserId NVARCHAR(1024)
										,	DeletionTime DATETIME
										,	LastModificationTime DATETIME
										,	LastModifierUserId NVARCHAR(1024)
										,	CreationTime DATETIME
										,	CreatorUserId NVARCHAR(1024)
										,	TenantId NVARCHAR(1024)
									);

  CREATE TABLE IF NOT EXISTS Person (
											Id INTEGER PRIMARY KEY
										,	Name varchar(100) 
										,	TenantId NVARCHAR(1024)
									);

 CREATE TABLE IF NOT EXISTS Goods (
											Id INTEGER PRIMARY KEY
										,	Name varchar(100) 
										,	IsDeleted BOOLEAN
										,	DeleterUserId NVARCHAR(1024)
										,	DeletionTime DATETIME
										,	LastModificationTime DATETIME
										,	LastModifierUserId NVARCHAR(1024)
										,	CreationTime DATETIME
										,	CreatorUserId NVARCHAR(1024)
										,	ParentId INTEGER NULLABLE
										,	TenantId NVARCHAR(1024)
									);

 
