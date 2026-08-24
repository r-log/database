-- ----------------------------------------------------------------
-- Add the prison roof event caster.
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
    SET @cOldContent = '013';

    SET @cNewVersion = '22';
    SET @cNewStructure = '10';
    SET @cNewContent = '014';
    SET @cNewDescription = 'Prison_Event_Caster';
    SET @cNewComment = 'Let the player cast the Gilneas Prison periodic so the timer buff and quest credit land on them instead of Lord Darius Crowley';

    SET @cCurResult := (SELECT `description` FROM `db_version` ORDER BY `version` DESC, `structure` DESC, `content` DESC LIMIT 0,1);
    SET @cOldResult := (SELECT `description` FROM `db_version` WHERE `version` = @cOldVersion AND `structure` = @cOldStructure AND `content` = @cOldContent);
    SET @cNewResult := (SELECT `description` FROM `db_version` WHERE `version` = @cNewVersion AND `structure` = @cNewStructure AND `content` = @cNewContent);

    IF (@cCurResult = @cOldResult) THEN
        START TRANSACTION;

        -- `By the Skin of His Teeth` (14154) never completed. The wave script itself
        -- is fine - a server trace of an accept confirmed all 54 rows firing on time,
        -- summoning without error - but the quest is `SpecialFlags` = 2, so it can only
        -- finish when something reports the event, and that never happened.
        --
        -- The reporting chain is entirely in the DBC and entirely self-targeted:
        --   66894 `Gilneas Prison Periodic`  TargetA = TARGET_SELF (1)
        --         -> triggers 68218 and 66853
        --   68218 `By the Skin of His Teeth` APPLY_AURA, aura 23 periodic trigger,
        --         the two minute timer buff, triggers 66915
        --   66915 `Skin of His Teeth Complete` SPELL_EFFECT_QUEST_COMPLETE (16),
        --         MiscValue 14154
        --
        -- Because every step targets the caster, whoever casts 66894 receives the
        -- timer and, two minutes later, the credit. The start script had Lord Darius
        -- Crowley cast it: `ScriptsStart(DBS_ON_QUEST_START, ..., questGiver, this)`
        -- passes the quest giver as source, and SCRIPT_COMMAND_CAST_SPELL casts from
        -- `resSource` at `resTarget`. So Crowley buffed himself and the player got
        -- nothing - which is why no 68218 ever appeared in the trace.
        --
        -- SCRIPT_FLAG_REVERSE_DIRECTION (0x02) swaps source and target, exactly as
        -- used for the Merchant Square aura scripts, so the player casts it on
        -- themselves and the whole chain lands where it belongs.
        UPDATE `db_scripts` SET `data_flags` = 2,
            `comments` = 'By the Skin of His Teeth - player casts Gilneas Prison Periodic on self'
        WHERE `script_type` = 0 AND `id` = 14154 AND `command` = 15 AND `datalong` = 66894;

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
