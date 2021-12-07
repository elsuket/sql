-- In order to benefit from the optimization when a function is schemabound
-- a scalar function needs to have the IsDeterministic, IsPrecise and IsSystemVerified properties
DECLARE @function_object_id int = OBJECT_ID('dbo.filt_get_search_string')

SELECT	OBJECTPROPERTYEX(@function_object_id, 'IsDeterministic') AS IsDeterministic 
	, OBJECTPROPERTYEX(@function_object_id, 'IsPrecise') AS IsPrecise
	, OBJECTPROPERTYEX(@function_object_id, 'IsSystemVerified') AS IsSystemVerified
	, OBJECTPROPERTYEX(@function_object_id, 'UserDataAccess') AS UserDataAccess
	, OBJECTPROPERTYEX(@function_object_id, 'SystemDataAccess') AS SystemDataAccess