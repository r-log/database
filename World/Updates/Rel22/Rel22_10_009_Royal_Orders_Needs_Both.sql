-- ----------------------------------------------------------------
-- Royal Orders requires both objectives.
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
    SET @cOldContent = '008';

    SET @cNewVersion = '22';
    SET @cNewStructure = '10';
    SET @cNewContent = '009';
    SET @cNewDescription = 'Royal_Orders_Needs_Both';
    SET @cNewComment = 'Require BOTH Merchant Square quests before Royal Orders, via the each-from-all exclusive group MaNGOS uses for converging chains';

    SET @cCurResult := (SELECT `description` FROM `db_version` ORDER BY `version` DESC, `structure` DESC, `content` DESC LIMIT 0,1);
    SET @cOldResult := (SELECT `description` FROM `db_version` WHERE `version` = @cOldVersion AND `structure` = @cOldStructure AND `content` = @cOldContent);
    SET @cNewResult := (SELECT `description` FROM `db_version` WHERE `version` = @cNewVersion AND `structure` = @cNewStructure AND `content` = @cNewContent);

    IF (@cCurResult = @cOldResult) THEN
        START TRANSACTION;

        -- `All Hell Breaks Loose` (14093) and `Evacuate the Merchant Square` (14098)
        -- are the two Merchant Square tasks; `Royal Orders` (14099) then moves the
        -- player out of the district. Both carry `NextQuestId` = 14099, which is the
        -- only link that existed, and MaNGOS reads that as **one-of**: the first of the
        -- pair to be handed in satisfied the requirement and Royal Orders was offered
        -- with the other still untouched.
        --
        -- The each-from-all form is a negative `ExclusiveGroup` shared by the members
        -- of the set, named after the first quest in it. `SatisfyQuestPreviousQuest`
        -- then walks the group and refuses until every member is rewarded. This DB
        -- already uses the idiom 291 times, in exactly this shape - Sharptalon's Claw
        -- (2) / Ursangous's Paw (23) / Shadumbra's Head (24) all sit in group -2 and
        -- all point at 247; the Mastery trio 188/193/197 sit in -188 and point at 208.
        --
        -- A negative group does NOT make the quests mutually exclusive:
        -- `SatisfyQuestExclusiveGroup` returns true immediately for any group <= 0, so
        -- both remain independently takeable and can sit in the log together.
        UPDATE `quest_template` SET `ExclusiveGroup` = -14093 WHERE `entry` IN (14093, 14098);

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
