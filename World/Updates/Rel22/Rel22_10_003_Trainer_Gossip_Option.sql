-- ----------------------------------------------------------------
-- Add the trainer gossip option.
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
    SET @cOldContent = '002';

    SET @cNewVersion = '22';
    SET @cNewStructure = '10';
    SET @cNewContent = '003';
    SET @cNewDescription = 'Trainer_Gossip_Option';
    SET @cNewComment = 'Repair trainer gossip rows that were saved as plain chat, which suppressed the default Train me option and left 75 trainers unusable';

    SET @cCurResult := (SELECT `description` FROM `db_version` ORDER BY `version` DESC, `structure` DESC, `content` DESC LIMIT 0,1);
    SET @cOldResult := (SELECT `description` FROM `db_version` WHERE `version` = @cOldVersion AND `structure` = @cOldStructure AND `content` = @cOldContent);
    SET @cNewResult := (SELECT `description` FROM `db_version` WHERE `version` = @cNewVersion AND `structure` = @cNewStructure AND `content` = @cNewContent);

    IF (@cCurResult = @cOldResult) THEN
        START TRANSACTION;

        -- `Celestine of the Harvest` (35873), the Gilneas druid trainer, offered no
        -- training option at all, and neither did 74 other trainers across the world.
        --
        -- `Player::PrepareGossipMenu` only falls back to the generic option set when a
        -- menu has NO rows of its own:
        --     // if canSeeQuests (the default, top level menu) and no menu options
        --     // exist for this, use options from default options
        --     if (pMenuItemBounds.first == pMenuItemBounds.second && canSeeQuests)
        --         pMenuItemBounds = sObjectMgr.GetGossipMenuItemsMapBounds(0);
        -- Menu 0 supplies the standard "Train me." entry
        -- (option_icon 3, option_id 5 = GOSSIP_OPTION_TRAINER, npc_option_npcflag 16).
        --
        -- Trainers whose menu is empty - Sergeant Cleese on 10694, for instance - hit
        -- that fallback and work. The broken ones each carry a single row that was
        -- saved with the flavour text and the trainer icon, but with
        -- option_id = 1 (GOSSIP_OPTION_GOSSIP) and npc_option_npcflag = 0. That row is
        -- enough to suppress the fallback, and is then discarded itself by
        --     if (!(itr->second.npc_option_npcflag & npcflags)) { continue; }
        -- because 0 masks to nothing - so the menu ends up completely empty.
        --
        -- The rows are repaired rather than deleted, which keeps the Blizzlike text
        -- ("I seek further training in the old ways of the druids.") instead of
        -- falling back to the generic "Train me.". The icon was already correct.
        --
        -- Scope was verified before widening beyond Gilneas: 35 rows over 35 menus,
        -- used by 75 trainer-flagged creatures. None of those menus already holds a
        -- proper option_id 5 row (so nothing is duplicated), none of the rows has an
        -- action_menu_id (so no submenu is broken), and no non-trainer creature shares
        -- any of those menus. Creatures that turn out to have no trainable spells stay
        -- hidden regardless, since `IsTrainerOf` is still checked per player.
        UPDATE `gossip_menu_option` gmo
        JOIN `creature_template` ct
            ON ct.`GossipMenuId` = gmo.`menu_id` AND (ct.`NpcFlags` & 16)
        SET gmo.`option_id` = 5,
            gmo.`npc_option_npcflag` = 16
        WHERE gmo.`option_icon` = 3
          AND gmo.`option_id` = 1
          AND gmo.`npc_option_npcflag` = 0
          AND gmo.`action_menu_id` = 0;

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
