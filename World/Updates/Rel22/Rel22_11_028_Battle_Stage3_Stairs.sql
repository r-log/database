-- ----------------------------------------------------------------
-- Battle stage 3: the stairs and the cannon delivery.
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
    SET @cOldContent = '027';

    SET @cNewVersion = '22';
    SET @cNewStructure = '11';
    SET @cNewContent = '028';
    SET @cNewDescription = 'Battle_Stage3_Stairs';
    SET @cNewComment = 'Battle stage 3: Liam descends the stairs, Lorna arrives with the cannons (VO 19684/19610), voiced prevail 19685 before Attack, march to the Gorerot';

    SET @cCurResult := (SELECT `description` FROM `db_version` ORDER BY `version` DESC, `structure` DESC, `content` DESC LIMIT 0,1);
    SET @cOldResult := (SELECT `description` FROM `db_version` WHERE `version` = @cOldVersion AND `structure` = @cOldStructure AND `content` = @cOldContent);
    SET @cNewResult := (SELECT `description` FROM `db_version` WHERE `version` = @cNewVersion AND `structure` = @cNewStructure AND `content` = @cNewContent);

    IF (@cCurResult = @cOldResult) THEN
        START TRANSACTION;

        -- ---- from Battle_Stage3_Stairs ----
        -- Battle stage 3: the stairs and the abomination lure. Lorna's battle
        -- copy stood in phase 1 at the wrong end of the city - she stands with
        -- her cannons now. Texts from the capture: her arrival (VO 19684),
        -- Liam's reply ordering the guns manned (VO 19610), and his voiced
        -- rallying cry (19685) heard from the stairs before the Attack.
        UPDATE `creature` SET `phaseMask` = 262144, `position_x` = -1578.20,
            `position_y` = 1319.50, `position_z` = 35.67, `orientation` = 5.55
            WHERE `guid` = 222860;

        DELETE FROM `script_texts` WHERE `entry` BETWEEN -1999994 AND -1999992;
        INSERT INTO `script_texts` (`entry`, `content_default`, `sound`, `type`, `comment`) VALUES
        (-1999992, 'The villagers were thankful to have Emberstone back.  They brought us a little something to help against those monstrosities.', 19684, 0, 'battle - lorna cannons'),
        (-1999993, 'You''re a sight for sore eyes, Lorna.  Let''s get those cannons manned!  The rest of you, lure the abominations away from the entrance!', 19610, 1, 'battle - liam man the cannons'),
        (-1999994, 'Gilneas will prevail!', 19685, 0, 'battle - prevail voiced');

        -- ---- from Cannon_Delivery ----
        -- The cannon delivery (capture 12:41:44-12:42:00): guns roll up from
        -- Emberstone with villagers hauling, one pushed down the stairs toward
        -- the bridge. npc_emberstone_cannon drives the rolling gun; emplaced
        -- cannons never receive the signal and stay inert vehicles.
        DELETE FROM `script_binding` WHERE `ScriptName` = 'npc_emberstone_cannon';
        INSERT INTO `script_binding` (`type`, `bind`, `ScriptName`) VALUES
        (0, 38424, 'npc_emberstone_cannon');

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
