SELECT	LEFT(physical_name, 1) AS volume_letter
	, type_desc
	, COUNT(*)
FROM	sys.master_files
GROUP	BY LEFT(physical_name, 1), type_desc

EXEC xp_fixeddrives

SELECT	*
FROM	sys.master_files