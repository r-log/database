-- ----------------------------------------------------------------
-- Liberation Day: the release, the gate and the consumable.
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
    SET @cOldStructure = '11';
    SET @cOldContent = '013';

    SET @cNewVersion = '22';
    SET @cNewStructure = '11';
    SET @cNewContent = '014';
    SET @cNewDescription = 'Liberation_Day';
    SET @cNewComment = 'Liberation Day (24575): freed villagers thank the player (three capture lines) and walk off - go_ball_and_chain hands the release to';

    SET @cCurResult := (SELECT `description` FROM `db_version` ORDER BY `version` DESC, `structure` DESC, `content` DESC LIMIT 0,1);
    SET @cOldResult := (SELECT `description` FROM `db_version` WHERE `version` = @cOldVersion AND `structure` = @cOldStructure AND `content` = @cOldContent);
    SET @cNewResult := (SELECT `description` FROM `db_version` WHERE `version` = @cNewVersion AND `structure` = @cNewStructure AND `content` = @cNewContent);

    IF (@cCurResult = @cOldResult) THEN
        START TRANSACTION;

        -- ---- from Liberation_Release ----
        -- Liberation Day (24575): unlocking a Ball and Chain freed nobody -
        -- the villager just stood chained. Capture: the freed villager speaks
        -- one of three thanks lines and walks clear; the shared 60s respawn
        -- re-chains the pair.
        DELETE FROM `script_binding` WHERE `ScriptName` IN ('npc_enslaved_villager', 'go_ball_and_chain');
        INSERT INTO `script_binding` (`type`, `bind`, `ScriptName`) VALUES
        (0, 37694, 'npc_enslaved_villager'),
        (1, 201775, 'go_ball_and_chain');

        DELETE FROM `script_texts` WHERE `entry` BETWEEN -1999978 AND -1999976;
        INSERT INTO `script_texts` (`entry`, `content_default`, `type`, `comment`) VALUES
        (-1999976, 'Thank you!', 0, 'freed villager - thanks'),
        (-1999977, 'It''s true then?  Even those afflicted by the Curse are fighting the Forsaken!', 0, 'freed villager - curse'),
        (-1999978, 'The Forsaken will pay for what they''ve done!', 0, 'freed villager - pay');

        -- ---- from Chain_Quest_Gate ----
        -- Ball and Chain (201775): the goober carried NO quest id (data1=0),
        -- so chains sparkled and worked forever - after 5/5, after turn-in,
        -- and repeatedly on one spot. data1=24575 makes the core highlight and
        -- accept the use only while Liberation Day is incomplete; the script
        -- consumes each chain into the 60s respawn cycle beside its villager.
        UPDATE `gameobject_template` SET `data1` = 24575 WHERE `entry` = 201775;

        -- ---- from Chain_Consumable ----
        -- Ball and Chain, second half: the deactivation path only DESPAWNS a
        -- goober when goober.consumable (data5) is set - without it the state
        -- machine cycles the chain back to READY and it stays re-clickable no
        -- matter who deactivates it. Consumable chains despawn on use and ride
        -- the 60s respawn beside their villager.
        UPDATE `gameobject_template` SET `data5` = 1 WHERE `entry` = 201775;

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
