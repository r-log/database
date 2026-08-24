-- ----------------------------------------------------------------
-- Swap the intact Gilneas City terrain in until Last Stand is done.
--
-- The cornerstone of the Worgen start: phase_definitions rows give the
-- client map 638 over the ruined base map 654 for the story's first act.
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
    SET @cOldContent = '004';

    SET @cNewVersion = '22';
    SET @cNewStructure = '10';
    SET @cNewContent = '005';
    SET @cNewDescription = 'Gilneas_Intact_City';
    SET @cNewComment = 'Swap the intact Gilneas City terrain in until Last Stand is completed, so the worgen intro no longer opens in the aftermath of the siege';

    SET @cCurResult := (SELECT `description` FROM `db_version` ORDER BY `version` DESC, `structure` DESC, `content` DESC LIMIT 0,1);
    SET @cOldResult := (SELECT `description` FROM `db_version` WHERE `version` = @cOldVersion AND `structure` = @cOldStructure AND `content` = @cOldContent);
    SET @cNewResult := (SELECT `description` FROM `db_version` WHERE `version` = @cNewVersion AND `structure` = @cNewStructure AND `content` = @cNewContent);

    IF (@cCurResult = @cOldResult) THEN
        START TRANSACTION;

        -- Gilneas renders its ruined, burning state from the base map (654). The
        -- intact pre-invasion city is a separate map, 638, whose 11 tiles overlap 654
        -- across the whole starting district -- it appears only if the client is told
        -- to swap terrain to it. Nothing ever sent that instruction, so a new worgen
        -- began the story standing in the aftermath of a siege that had not happened
        -- yet, with the gate already broken and the city alight.
        --
        -- Swap 638 in for Gilneas (4714) and Gilneas City (4755) while Last Stand
        -- (14222) is unfinished. That quest is where the story leaves the city, jumps
        -- several months forward and the player is transformed; from then on the
        -- ruined base map is the correct thing to see, and the player does not return
        -- until the Battle for Gilneas City, by which point it is Forsaken-occupied.
        --
        -- 638 supplies no tiles outside the city core, so this changes nothing
        -- elsewhere in the zone.

        DELETE FROM `conditions` WHERE `condition_entry` IN (57900, 57901);
        INSERT INTO `conditions` (`condition_entry`, `type`, `value1`, `value2`, `comments`) VALUES
        (57900,  8, 14222, 0, 'Last Stand (14222) has been rewarded'),
        (57901, -3, 57900,  0, 'NOT: Last Stand (14222) has not been rewarded yet');

        -- phaseId is left 0 deliberately: the core derives the client-visible Phase.dbc
        -- ids from the phasemask the player actually holds, so that the client is never
        -- told it is in a phase the server disagrees with. These rows supply only the
        -- terrain swap. phasemask is likewise unused here -- server-side visibility
        -- stays driven by the existing spell_area phase auras.
        DELETE FROM `phase_definitions` WHERE `zoneId` IN (4714, 4755);
        INSERT INTO `phase_definitions`
            (`zoneId`, `entry`, `phasemask`, `phaseId`, `terrainswapmap`, `flags`, `condition_id`, `comment`) VALUES
        (4714, 1, 0, 0, 638, 0, 57901, 'Gilneas: intact city terrain until Last Stand is completed'),
        (4755, 1, 0, 0, 638, 0, 57901, 'Gilneas City: intact city terrain until Last Stand is completed');

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
