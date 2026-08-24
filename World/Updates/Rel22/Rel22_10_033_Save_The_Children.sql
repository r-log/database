-- ----------------------------------------------------------------
-- Save The Children.
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
    SET @cOldContent = '032';

    SET @cNewVersion = '22';
    SET @cNewStructure = '10';
    SET @cNewContent = '033';
    SET @cNewDescription = 'Save_The_Children';
    SET @cNewComment = 'Save the Children rescue scene - player line, child answer, cellar run, credit; capture-verified against TC coordinates';

    SET @cCurResult := (SELECT `description` FROM `db_version` ORDER BY `version` DESC, `structure` DESC, `content` DESC LIMIT 0,1);
    SET @cOldResult := (SELECT `description` FROM `db_version` WHERE `version` = @cOldVersion AND `structure` = @cOldStructure AND `content` = @cOldContent);
    SET @cNewResult := (SELECT `description` FROM `db_version` WHERE `version` = @cNewVersion AND `structure` = @cNewStructure AND `content` = @cNewContent);

    IF (@cCurResult = @cOldResult) THEN
        START TRANSACTION;

        -- `Save the Children!` (14368). The three children's spellclick rows were in
        -- place and the click cast its rescue spell - which is an empty shell (SCRIPT
        -- + DUMMY), so nothing happened and rapid clicking only earned the GCD's
        -- "not ready yet". `npc_gilneas_child` now runs the scene, cross-checked line
        -- by line against the 18019 capture (TC's escape coordinates match it to the
        -- decimal): the player speaks first, the child answers, runs to its cellar -
        -- James one leg, Ashley two, Cynthia three - and fades inside; credit is the
        -- child's own entry, given to the clicker. Cynthia cries until rescued.
        DELETE FROM `script_texts` WHERE `entry` IN (-1999958, -1999959, -1999960, -1999961, -1999962, -1999963);
        INSERT INTO `script_texts` (`entry`, `content_default`, `sound`, `type`, `language`, `emote`, `comment`) VALUES
        (-1999958, 'You are scary!  I just want my mommy!', 0, 0, 0, 0, 'cynthia - rescued'),
        (-1999959, 'Are you one of the good worgen, $g mister:ma''am;?  Did you see Cynthia hiding in the sheds outside?', 0, 0, 0, 0, 'ashley - rescued'),
        (-1999960, 'Don''t hurt me!  I was just looking for my sisters!  I think Ashley''s inside that house!', 0, 0, 0, 0, 'james - rescued'),
        (-1999961, 'It''s not safe here.  Go to the Allens'' basement.', 0, 0, 0, 0, 'player - to cynthia'),
        (-1999962, 'Join the others inside the basement next door.  Hurry!', 0, 0, 0, 0, 'player - to ashley'),
        (-1999963, 'Your mother''s in the basement next door.  Get to her now!', 0, 0, 0, 0, 'player - to james');

        DELETE FROM `script_binding` WHERE `ScriptName` = 'npc_gilneas_child';
        INSERT INTO `script_binding` (`type`, `ScriptName`, `bind`, `data`) VALUES
        (0, 'npc_gilneas_child', 36287, 0),
        (0, 'npc_gilneas_child', 36288, 0),
        (0, 'npc_gilneas_child', 36289, 0);

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
