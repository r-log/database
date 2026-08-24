-- ----------------------------------------------------------------
-- Gate the Godfrey chain on the seven class quests.
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
    SET @cOldContent = '010';

    SET @cNewVersion = '22';
    SET @cNewStructure = '10';
    SET @cNewContent = '011';
    SET @cNewDescription = 'Godfrey_Quest_Gating';
    SET @cNewComment = 'Stop While Youre At It being offered right after Royal Orders, and require both it and Brothers In Arms for The Rebel Lords Arsenal';

    SET @cCurResult := (SELECT `description` FROM `db_version` ORDER BY `version` DESC, `structure` DESC, `content` DESC LIMIT 0,1);
    SET @cOldResult := (SELECT `description` FROM `db_version` WHERE `version` = @cOldVersion AND `structure` = @cOldStructure AND `content` = @cOldContent);
    SET @cNewResult := (SELECT `description` FROM `db_version` WHERE `version` = @cNewVersion AND `structure` = @cNewStructure AND `content` = @cNewContent);

    IF (@cCurResult = @cOldResult) THEN
        START TRANSACTION;

        -- ---- from Godfrey_Quest_Gating ----
        -- Lord Godfrey offered `While You're At It` (24930) as soon as `Royal Orders`
        -- (14099) was handed in, long before it should exist. Retail gates it on the
        -- class-specific `Safety in Numbers`, exactly as it gates `Old Divisions`:
        --     A Old Divisions      |QID|14157| |PRE|14285^14286^14287^14288^14289^14290^14291|
        --     A While You're At It |QID|24930| |PRE|14285^14286^14287^14288^14289^14290^14291|
        -- (`^` is OR; both become available the moment Safety in Numbers is turned in
        --  to King Genn, who stands next to Godfrey.)
        --
        -- MaNGOS cannot express that twice. A quest's `prevQuests` is filled only from
        -- its own `PrevQuestId` plus every quest whose `NextQuestId` points at it, and
        -- the seven Safety in Numbers quests already spend their `NextQuestId` on
        -- 14157. There is no condition source for a quest offer to fall back on.
        --
        -- So 24930 is chained to 14157 instead, which is equivalent in practice
        -- because 14157 itself carries the seven-way requirement:
        --   * `14157.NextQuestId` = -24930 adds 14157 to 24930's prevQuests as a
        --     NEGATIVE entry, which `SatisfyQuestPreviousQuest` treats as satisfied
        --     while that quest is ACTIVE ("if any of the negative previous quests
        --     active, return true"). Godfrey's quest therefore appears as soon as the
        --     player accepts Old Divisions from King Genn beside him.
        --   * `24930.PrevQuestId` = 14157 adds the same quest as a POSITIVE entry, so
        --     the requirement also holds once Old Divisions has been rewarded. Without
        --     it, handing Old Divisions in first would make 24930 unobtainable and
        --     dead-end the chain, since 14159 below requires it.
        --
        -- Repurposing `14157.NextQuestId` is free: it pointed at 28850, which already
        -- carries `PrevQuestId` = 14157, so the link was a duplicate. Auto-offer on
        -- turn-in is unaffected - `Player::GetNextQuest` matches on `NextQuestInChain`
        -- (still 28850), never on `NextQuestId`.
        UPDATE `quest_template` SET `NextQuestId` = -24930 WHERE `entry` = 14157;
        UPDATE `quest_template` SET `PrevQuestId` = 14157 WHERE `entry` = 24930;

        -- Second defect in the same stretch: `The Rebel Lord's Arsenal` (14159) needs
        -- BOTH `Brothers In Arms` and `While You're At It` -
        --     A The Rebel Lord's Arsenal |QID|14159| |PRE|26129&24930|
        -- - but only carried `PrevQuestId` = 24930, so King Genn offered it with
        -- Brothers In Arms still outstanding. This is the same each-from-all idiom
        -- used for Royal Orders in Rel22_07_013: a negative `ExclusiveGroup` shared by
        -- the members, both pointing `NextQuestId` at the quest they gate, and the
        -- target's own `PrevQuestId` cleared so `SatisfyQuestPreviousQuest` cannot
        -- take the "branch not restricted by the group" escape at
        --     if (qInfo->GetPrevQuestId() != 0 && qPrevInfo->GetNextQuestId() != ...)
        -- and instead walks the group requiring every member rewarded.
        UPDATE `quest_template` SET `NextQuestId` = 14159, `ExclusiveGroup` = -24930 WHERE `entry` IN (24930, 26129);
        UPDATE `quest_template` SET `PrevQuestId` = 0 WHERE `entry` = 14159;

        -- ---- from Godfrey_Quest_On_Safety ----
        -- Rel22_07_018 chained `While You're At It` (24930) to `Old Divisions` (14157)
        -- so that it appeared when Old Divisions was ACCEPTED. It must appear the
        -- moment `Safety in Numbers` is HANDED IN, which is one step earlier.
        --
        -- Only one quest can hold the seven-way requirement, because a quest's
        -- `prevQuests` is filled from its own `PrevQuestId` plus every quest whose
        -- `NextQuestId` points at it - and `NextQuestId` is single valued. That gate is
        -- moved off 14157 and onto 24930, where the player-visible behaviour matters:
        -- the seven class-specific Safety in Numbers quests now point at 24930, so
        -- `SatisfyQuestPreviousQuest` sees any one of them rewarded and returns true.
        -- Godfrey therefore offers his quest the instant King Genn takes the turn-in,
        -- with the two standing five yards apart.
        --
        -- `Old Divisions` keeps working without that gate for two reasons:
        --   * The seven still carry `NextQuestInChain` = 14157, and `GetNextQuest`
        --     matches on exactly that field, so King Genn auto-offers Old Divisions on
        --     the same turn-in, as before.
        --   * It is given a `PrevQuestId` of `Royal Orders` (14099) so it is not left
        --     wide open. That is weaker than retail, which requires Safety in Numbers,
        --     but it is never blocking and it still stops a player who has not reached
        --     this chapter from taking it.
        -- The trade-off is deliberate and worth stating: a player who walks past the
        -- class trainers after Royal Orders could take Old Divisions without doing the
        -- class quest chain. The alternative - gating 14157 on 24930 - would either
        -- delay Old Divisions behind Godfrey's quest for everyone, or dead-end the
        -- chain for anyone who handed 24930 in first.
        UPDATE `quest_template` SET `NextQuestId` = 24930
            WHERE `entry` IN (14285, 14286, 14287, 14288, 14289, 14290, 14291);

        -- 14157 no longer needs the borrowed link from Rel22_07_018; restore the
        -- original pointer at 28850 (a duplicate of that quest's own PrevQuestId, so
        -- inert) and add the Royal Orders floor.
        UPDATE `quest_template` SET `NextQuestId` = 28850, `PrevQuestId` = 14099 WHERE `entry` = 14157;

        -- 24930's requirement now comes from the seven, so drop the 14157 link added
        -- by Rel22_07_018. Its `NextQuestId` = 14159 and `ExclusiveGroup` = -24930 are
        -- left untouched: together with 26129 they keep `The Rebel Lord's Arsenal`
        -- requiring BOTH members of the group.
        UPDATE `quest_template` SET `PrevQuestId` = 0 WHERE `entry` = 24930;

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
