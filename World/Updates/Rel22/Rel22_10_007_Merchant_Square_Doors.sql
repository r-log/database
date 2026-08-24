-- ----------------------------------------------------------------
-- Bind the Merchant Square door script and its targets.
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
    SET @cOldContent = '006';

    SET @cNewVersion = '22';
    SET @cNewStructure = '10';
    SET @cNewContent = '007';
    SET @cNewDescription = 'Merchant_Square_Doors';
    SET @cNewComment = 'Bind the Merchant Square door script so knocking turns a citizen out of the house and credits Evacuate the Merchant Square';

    SET @cCurResult := (SELECT `description` FROM `db_version` ORDER BY `version` DESC, `structure` DESC, `content` DESC LIMIT 0,1);
    SET @cOldResult := (SELECT `description` FROM `db_version` WHERE `version` = @cOldVersion AND `structure` = @cOldStructure AND `content` = @cOldContent);
    SET @cNewResult := (SELECT `description` FROM `db_version` WHERE `version` = @cNewVersion AND `structure` = @cNewStructure AND `content` = @cNewContent);

    IF (@cCurResult = @cOldResult) THEN
        START TRANSACTION;

        -- ---- from Merchant_Square_Door ----
        -- Evacuate the Merchant Square (14098) counts creature 35830, the evacuation
        -- marker standing at each of the fourteen doors. Game object 195327 is a
        -- goober with an empty spell field, and the credit a goober awards is for its
        -- own entry, so knocking played the animation but could never advance the
        -- quest and nobody came out.
        --
        -- The script casts Blizzard's own summon spells - 68087 alone, or 68070 which
        -- brings a rampaging worgen too - from the player, so the summoned citizen can
        -- credit them once it reaches the marker.
        --
        -- Type 1 is SCRIPTED_GAMEOBJECT.
        DELETE FROM `script_binding` WHERE `ScriptName` = 'go_merchant_square_door';
        INSERT INTO `script_binding` (`type`, `ScriptName`, `bind`, `data`) VALUES
        (1, 'go_merchant_square_door', 195327, 0);

        -- ---- from Merchant_Square_Door_Targets ----
        -- All three Merchant Square summon spells declare EffectImplicitTargetA 46,
        -- TARGET_SCRIPT_COORDINATES: they take their summon position from a nearby
        -- object named in `spell_script_target` rather than from the caster. With no
        -- row the cast is refused outright, so the door script would fire and still
        -- produce nothing.
        --
        --   68087  Just Citizen              summons 34981 Frightened Citizen
        --   68070  Summon Citizen and Worgen summons 35836 and triggers 80281
        --   80281  Summon Citizen and Worgen summons 35660 Rampaging Worgen
        --
        -- Type 0 is SPELL_TARGET_TYPE_GAMEOBJECT, so the position comes from the
        -- nearest Merchant Square Door - the one just knocked on. That also puts the
        -- citizen in the doorway rather than on top of the player.
        DELETE FROM `spell_script_target` WHERE `entry` IN (68070, 68087, 80281);
        INSERT INTO `spell_script_target` (`entry`, `type`, `targetEntry`, `inverseEffectMask`) VALUES
        (68070, 0, 195327, 0),
        (68087, 0, 195327, 0),
        (80281, 0, 195327, 0);

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
