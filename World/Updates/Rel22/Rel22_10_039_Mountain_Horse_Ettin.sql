-- ----------------------------------------------------------------
-- The Hungry Ettin: the mountain horse ride and delivery.
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
    SET @cOldContent = '038';

    SET @cNewVersion = '22';
    SET @cNewStructure = '10';
    SET @cNewContent = '039';
    SET @cNewDescription = 'Mountain_Horse_Ettin';
    SET @cNewComment = 'The Hungry Ettin - the Mountain Horse spellclick must MOUNT (94654), not grant the credit (68917); the rope chain is served in core';

    SET @cCurResult := (SELECT `description` FROM `db_version` ORDER BY `version` DESC, `structure` DESC, `content` DESC LIMIT 0,1);
    SET @cOldResult := (SELECT `description` FROM `db_version` WHERE `version` = @cOldVersion AND `structure` = @cOldStructure AND `content` = @cOldContent);
    SET @cNewResult := (SELECT `description` FROM `db_version` WHERE `version` = @cNewVersion AND `structure` = @cNewStructure AND `content` = @cNewContent);

    IF (@cCurResult = @cOldResult) THEN
        START TRANSACTION;

        -- ---- from Mountain_Horse_Ride ----
        -- The Hungry Ettin (14416). The Mountain Horse (36540) spellclick row
        -- carried 68917 - the KILL-CREDIT spell - instead of the ride. The capture
        -- shows the click casting 94654 (aura 236: the player mounts the horse),
        -- and the credit only arriving through the ROPE chain when a loose horse
        -- is lassoed from the saddle (68903, served in core at cast-receive).
        UPDATE `npc_spellclick_spells` SET `spell_id` = 94654 WHERE `npc_entry` = 36540;

        -- ---- from Mountain_Horse_Delivery ----
        -- The Hungry Ettin (14416), delivery half. Retail registers the horses when
        -- the string REACHES Lorna Crowley - the capture shows the ridden horse
        -- casting 68917 at its rider there, era comments confirm "she will accept
        -- the horses in 2s or 3s" and that the ridden horse counts. Bind the
        -- delivery script; the lasso itself no longer credits.
        DELETE FROM `script_binding` WHERE `ScriptName` = 'npc_mountain_horse';
        INSERT INTO `script_binding` (`type`, `bind`, `ScriptName`) VALUES (0, 36540, 'npc_mountain_horse');

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
