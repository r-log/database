-- ----------------------------------------------------------------
-- Battle stage 1: the rally.
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
    SET @cOldContent = '021';

    SET @cNewVersion = '22';
    SET @cNewStructure = '11';
    SET @cNewContent = '022';
    SET @cNewDescription = 'Battle_Stage1_Rally';
    SET @cNewComment = 'Battle for Gilneas City stage 1: Krennan send-off + Liam never-surrender speech, six verses VO 19623-19628, FOR GILNEAS 19651 + crowd 22584, Attack';

    SET @cCurResult := (SELECT `description` FROM `db_version` ORDER BY `version` DESC, `structure` DESC, `content` DESC LIMIT 0,1);
    SET @cOldResult := (SELECT `description` FROM `db_version` WHERE `version` = @cOldVersion AND `structure` = @cOldStructure AND `content` = @cOldContent);
    SET @cNewResult := (SELECT `description` FROM `db_version` WHERE `version` = @cNewVersion AND `structure` = @cNewStructure AND `content` = @cNewContent);

    IF (@cCurResult = @cOldResult) THEN
        START TRANSACTION;

        -- The Battle for Gilneas City (24904), stage 1 - the rally. The whole
        -- battle cast already stands in phase 262144 (69485 carries the player
        -- in from Flank's turn-in); this wires Krennan's send-off and Liam's
        -- speech with the capture's voice-over ids.
        DELETE FROM `script_binding` WHERE `ScriptName` = 'npc_prince_liam_battle';
        INSERT INTO `script_binding` (`type`, `bind`, `ScriptName`) VALUES
        (0, 38218, 'npc_prince_liam_battle'),
        (0, 38611, 'npc_flank_questgiver');

        DELETE FROM `script_texts` WHERE `entry` BETWEEN -1999987 AND -1999979;
        INSERT INTO `script_texts` (`entry`, `content_default`, `sound`, `type`, `comment`) VALUES
        (-1999979, 'It''s time to join the fray, $n!  With you on our side the scales will surely tip in our favor!', 0, 1, 'battle - krennan send-off'),
        (-1999980, 'The Forsaken think we''re weak.  A broken people.  They think we''ll roll over like a scared dog.', 19623, 1, 'battle - liam speech 1'),
        (-1999981, 'How wrong they are.  We will fight them in the fields until the last trench collapses and the last cannon is silenced.', 19624, 1, 'battle - liam speech 2'),
        (-1999982, 'We will fight them on the streets until the last shot is fired.  And when there''s no more ammunition, we''ll crush their skulls with the stones that pave our city.', 19625, 1, 'battle - liam speech 3'),
        (-1999983, 'We will fight them in the alleys, until our knuckles are skinned and bloody and our rapiers lay on the ground shattered.', 19626, 1, 'battle - liam speech 4'),
        (-1999984, 'And if we find ourselves surrounded and disarmed... wounded and without hope... we will lift our heads in defiance and spit in their faces.', 19627, 1, 'battle - liam speech 5'),
        (-1999985, 'But we will... NEVER SURRENDER!!!!!', 19628, 1, 'battle - liam speech 6'),
        (-1999986, 'FOR GILNEAS!!!', 19651, 1, 'battle - for gilneas'),
        (-1999987, 'Attack!', 0, 0, 'battle - attack');

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
