SET NOCOUNT ON
DECLARE @pktable TABLE(
    TABLE_QUALIFIER sysname, 
    TABLE_OWNER sysname, 
    TABLE_NAME sysname, 
    COLUMN_NAME sysname, 
    KEY_SEQ smallint, 
    PK_NAME sysname)

INSERT INTO @pktable (TABLE_QUALIFIER, TABLE_OWNER, TABLE_NAME, COLUMN_NAME, KEY_SEQ, PK_NAME)
EXEC sp_pkeys 'AspNetUsers'

SELECT TABLE_NAME AS 'Table', COLUMN_NAME AS 'Column', PK_NAME AS 'Primary key'
FROM @pktable