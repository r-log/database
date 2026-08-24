-- ----------------------------------------------------------------
-- Widen gameobject.phaseMask to 32 bits and promote the Gilneas rows.
--
-- STRUCTURE bump: this alters a column. Gilneas phases run above bit 16
-- (the observatory is 131072), which a smallint cannot hold, so the
-- column is widened to match creature.phaseMask before the promotion.
-- ----------------------------------------------------------------
DROP PROCEDURE IF EXISTS `update_mangos`;

DELIMITER $$

CREATE PROCEDURE `update_mangos`()
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SHOW ERRORS;
        SELECT '* UPDATE FAILED *' AS `===== Status =====`,
               @cCurResult AS `===== DB is on Version: =====`;
        RESIGNAL;
    END;

    SET @cCurVersion := (SELECT `version` FROM `db_version` ORDER BY `version` DESC, `structure` DESC, `content` DESC LIMIT 0,1);
    SET @cCurStructure := (SELECT `structure` FROM `db_version` ORDER BY `version` DESC, `structure` DESC, `content` DESC LIMIT 0,1);
    SET @cCurContent := (SELECT `content` FROM `db_version` ORDER BY `version` DESC, `structure` DESC, `content` DESC LIMIT 0,1);

    SET @cOldVersion = '22';
    SET @cOldStructure = '10';
    SET @cOldContent = '044';

    SET @cNewVersion = '22';
    SET @cNewStructure = '11';
    SET @cNewContent = '001';
    SET @cNewDescription = 'GO_PhaseMask_Width';
    SET @cNewComment = 'Gilneas phaseMask 65535 means only the LOW 16 phase bits - everything always-visible vanished at the 131072 chapter; promote to full mask';

    SET @cCurResult := (SELECT `description` FROM `db_version` ORDER BY `version` DESC, `structure` DESC, `content` DESC LIMIT 0,1);
    SET @cOldResult := (SELECT `description` FROM `db_version` WHERE `version` = @cOldVersion AND `structure` = @cOldStructure AND `content` = @cOldContent);
    SET @cNewResult := (SELECT `description` FROM `db_version` WHERE `version` = @cNewVersion AND `structure` = @cNewStructure AND `content` = @cNewContent);

    IF (@cCurResult = @cOldResult) THEN
        START TRANSACTION;

        -- ---- from Gilneas_Phase_65535 ----
        -- Gilneas (map 654) uses chapter phasemasks above 16 bits (the observatory
        -- chapter is 131072). The DB's old "always visible" convention, phaseMask
        -- 65535, silently excludes those - so the King's telescope, the manor
        -- furniture and every other "all phases" object vanished the moment The
        -- King's Observatory was rewarded. The capture shows the telescope present
        -- in those chapters. Promote the convention to the true all-phases mask.
        UPDATE `gameobject` SET `phaseMask` = 4294967295 WHERE `map` = 654 AND `phaseMask` = 65535;
        UPDATE `creature`   SET `phaseMask` = 4294967295 WHERE `map` = 654 AND `phaseMask` = 65535;

        -- ---- from GO_PhaseMask_Width ----
        -- gameobject.phaseMask was SMALLINT UNSIGNED: physically capped at 65535,
        -- so the previous promotion silently clamped and no gameobject could ever
        -- live in a phase above bit 16 (Gilneas observatory = 131072). Widen the
        -- column to match creature.phaseMask, then re-run the promotion.
        ALTER TABLE `gameobject` MODIFY `phaseMask` int(10) unsigned NOT NULL DEFAULT 1 COMMENT 'phase mask';

        UPDATE `gameobject` SET `phaseMask` = 4294967295 WHERE `map` = 654 AND `phaseMask` = 65535;

        INSERT INTO `db_version` VALUES (@cNewVersion, @cNewStructure,
            @cNewContent, @cNewDescription, @cNewComment);
        SET @cNewResult := (SELECT `description` FROM `db_version`
            WHERE `version` = @cNewVersion AND `structure` = @cNewStructure
              AND `content` = @cNewContent);
        COMMIT;
        SELECT '* UPDATE COMPLETE *' AS `===== Status =====`,
               @cNewResult AS `===== DB is now on Version =====`;
    ELSE
        IF (@cCurResult = @cNewResult) THEN
            SELECT '* UPDATE SKIPPED *' AS `===== Status =====`,
                   @cCurResult AS `===== DB is already on Version =====`;
        ELSE
            IF (@cCurResult IS NULL) THEN
                SELECT '* UPDATE FAILED *' AS `===== Status =====`,
                       'Unable to locate DB Version Information' AS `============= Error Message =============`;
            ELSE
                SET @cCurOutput = CONCAT(@cCurVersion, '_', @cCurStructure,
                    '_', @cCurContent, ' - ', @cCurResult);
                SET @cOldOutput = CONCAT(@cOldVersion, '_', @cOldStructure,
                    '_', @cOldContent, ' - ',
                    COALESCE(@cOldResult, 'IS NOT APPLIED'));
                SELECT '* UPDATE SKIPPED *' AS `===== Status =====`,
                       @cOldOutput AS `=== Expected ===`,
                       @cCurOutput AS `===== Found Version =====`;
            END IF;
        END IF;
    END IF;
END $$

DELIMITER ;

CALL update_mangos();

DROP PROCEDURE IF EXISTS `update_mangos`;
