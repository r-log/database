-- ----------------------------------------------------------------
-- Make Genn's crowd stand and watch.
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
    SET @cOldContent = '011';

    SET @cNewVersion = '22';
    SET @cNewStructure = '10';
    SET @cNewContent = '012';
    SET @cNewDescription = 'Genn_Crowd_Audience';
    SET @cNewComment = 'Stop the Gilnean Survivors gathered at King Genn from wandering and turn them to face him, as an audience rather than a milling crowd';

    SET @cCurResult := (SELECT `description` FROM `db_version` ORDER BY `version` DESC, `structure` DESC, `content` DESC LIMIT 0,1);
    SET @cOldResult := (SELECT `description` FROM `db_version` WHERE `version` = @cOldVersion AND `structure` = @cOldStructure AND `content` = @cOldContent);
    SET @cNewResult := (SELECT `description` FROM `db_version` WHERE `version` = @cNewVersion AND `structure` = @cNewStructure AND `content` = @cNewContent);

    IF (@cCurResult = @cOldResult) THEN
        START TRANSACTION;

        -- The refugees gathered around King Genn Greymane are meant to be listening to
        -- him, but the thirteen `Gilnean Survivor` (35233) spawns beside him carried
        -- `MovementType` = 1 (random) with `spawndist` = 3, so they milled about the
        -- square. The `Gilnean Royal Guard` (35232) spawns standing among them are
        -- already `MovementType` = 0, which is what gave the scene away.
        --
        -- Their stored `orientation` values were already roughly aimed at the king -
        -- 5.65 against a computed 5.60, 5.90 against 5.82, and so on - which confirms
        -- the spawns were authored as an audience and only the random movement walked
        -- them off their marks. The facing is recomputed exactly rather than trusted,
        -- since a few had drifted further (4.82 against 5.60).
        --
        -- Scope is the gathering only. `MovementType` is keyed off King Genn's own
        -- position with a 20 yard radius, which takes in all thirteen (the furthest is
        -- 14.5 yards) and excludes the four Gilnean Survivors 137+ yards away at the
        -- bridge, who belong to a different scene and already stand still.
        --
        -- There are no `creature_movement` waypoint rows for this entry, so dropping to
        -- idle movement leaves nothing orphaned.
        SET @gx := (SELECT `position_x` FROM `creature` WHERE `guid` = 219746);
        SET @gy := (SELECT `position_y` FROM `creature` WHERE `guid` = 219746);

        UPDATE `creature`
        SET `MovementType` = 0,
            `spawndist` = 0,
            `orientation` = MOD(ATAN2(@gy - `position_y`, @gx - `position_x`) + 2 * PI(), 2 * PI())
        WHERE `id` = 35233
          AND `phaseMask` = 2
          AND SQRT(POW(`position_x` - @gx, 2) + POW(`position_y` - @gy, 2)) <= 20;

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
