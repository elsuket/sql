	BEGIN CATCH
		DECLARE @err_msg nvarchar(4000) = COALESCE('Procedure : ' + ERROR_PROCEDURE(), '')
			+ ' - Line ' + CAST(ERROR_LINE() AS varchar(10))
			+ ' - Error Number : ' + CAST(ERROR_NUMBER() AS varchar(10))
			+ ' - ' + ERROR_MESSAGE()
			, @err_svt int = ERROR_SEVERITY()
			, @err_stt int = ERROR_STATE()

		IF XACT_STATE() <> 0
		BEGIN
			ROLLBACK TRANSACTION;
		END

		RAISERROR(@err_msg, @err_svt, @err_stt);
		RETURN;
	END CATCH