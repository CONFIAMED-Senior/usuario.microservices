-- ============================================================
-- tbl_user
-- ============================================================
CREATE TABLE tbl_user
(
    id_us          INT              IDENTITY(1,1)   NOT NULL,
    name_us        VARCHAR(100)                     NOT NULL,
    lastname_us    VARCHAR(100)                     NOT NULL,
    dni_us         CHAR(10)                         NOT NULL,
    phone_us       VARCHAR(20)                          NULL,
    address_us     VARCHAR(255)                         NULL,
    age_us         INT                              NOT NULL,
    password_us    VARCHAR(255)                     NOT NULL,
    username_us    VARCHAR(50)                      NOT NULL,
    email_us       VARCHAR(255)                     NOT NULL,
    email_verified BIT              DEFAULT 0       NOT NULL,
    created_at     DATETIMEOFFSET   DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    update_at      DATETIMEOFFSET                       NULL,
    status_us      CHAR(1)                          NOT NULL,

    CONSTRAINT PK_tbl_user PRIMARY KEY (id_us)
);

CREATE UNIQUE INDEX ix_tbl_user_dni      ON tbl_user (dni_us);
CREATE UNIQUE INDEX ix_tbl_user_email    ON tbl_user (email_us);
CREATE UNIQUE INDEX ix_tbl_user_username ON tbl_user (username_us);
GO


-- ============================================================
-- tbl_user_audit_delete
-- ============================================================
CREATE TABLE tbl_user_audit_delete
(
    audit_id    INT            IDENTITY(1,1)  NOT NULL,
    id_us       INT                           NOT NULL,
    name_us     VARCHAR(100)                  NOT NULL,
    lastname_us VARCHAR(100)                  NOT NULL,
    dni_us      CHAR(10)                      NOT NULL,
    phone_us    VARCHAR(20)                       NULL,
    address_us  VARCHAR(255)                      NULL,
    status_us   CHAR(1)                       NOT NULL,
    age_us      INT                           NOT NULL,
    username_us VARCHAR(50)                   NOT NULL,
    email_us    VARCHAR(255)                  NOT NULL,
    deleted_at  DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    deleted_by  VARCHAR(50)                       NULL,

    CONSTRAINT PK_tbl_user_audit_delete PRIMARY KEY (audit_id)
);

CREATE INDEX ix_tbl_user_audit_delete_user ON tbl_user_audit_delete (id_us);
GO


-- ============================================================
-- tbl_user_audit_update
-- ============================================================
CREATE TABLE tbl_user_audit_update
(
    audit_id   INT            IDENTITY(1,1)  NOT NULL,
    id_us      INT                           NOT NULL,
    field_name VARCHAR(50)                   NOT NULL,
    old_value  VARCHAR(MAX)                      NULL,
    new_value  VARCHAR(MAX)                      NULL,
    changed_at DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    changed_by VARCHAR(50)                       NULL,

    CONSTRAINT PK_tbl_user_audit_update PRIMARY KEY (audit_id)
);

CREATE INDEX ix_tbl_user_audit_update_user ON tbl_user_audit_update (id_us);
GO


-- ============================================================
-- tbl_work_items
-- ============================================================
CREATE TABLE tbl_work_items
(
    id_wi           INT            IDENTITY(1,1)  NOT NULL,
    code_wi         VARCHAR(MAX)                      NULL,
    description_wi  VARCHAR(MAX)                      NULL,
    status_wi       CHAR(1)                           NULL,
    relevance       INT                               NULL,
    created_at      DATETIME2                         NULL,
    expiration_date DATETIME2                         NULL,

    CONSTRAINT tbl_work_items_pk PRIMARY KEY (id_wi)
);
GO


-- ============================================================
-- tbl_user_work_items
-- ============================================================
CREATE TABLE tbl_user_work_items
(
    id_uwi          INT        IDENTITY(1,1)              NOT NULL,
    id_us           INT                                   NOT NULL,
    id_wi           INT                                   NOT NULL,
    assignment_date DATETIME2  DEFAULT CURRENT_TIMESTAMP  NOT NULL,
    status          CHAR(1)                               NOT NULL,

    CONSTRAINT pk_tbl_user_work_items          PRIMARY KEY (id_uwi),
    CONSTRAINT fk_tbl_user_work_items_user     FOREIGN KEY (id_us)
        REFERENCES tbl_user (id_us)      ON DELETE CASCADE,
    CONSTRAINT fk_tbl_user_work_items_wi       FOREIGN KEY (id_wi)
        REFERENCES tbl_work_items (id_wi) ON DELETE CASCADE
);
GO

-- ============================================================
-- TRIGGERS
-- ============================================================

CREATE OR ALTER TRIGGER trg_assign_work_item
ON tbl_work_items
AFTER INSERT, UPDATE
                                  AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @v_user_id          INT;
    DECLARE @v_pending_count    INT;
    DECLARE @v_already_assigned BIT;
    DECLARE @v_item_low_id      INT;
    DECLARE @v_item_high_id     INT;
    DECLARE @v_id_wi            INT;
    DECLARE @v_created_at       DATETIME;
    DECLARE @v_status_wi        CHAR(1);

    -- Iterar sobre cada fila insertada/actualizada
    DECLARE cur_inserted CURSOR LOCAL FAST_FORWARD FOR
SELECT id_wi, created_at, status_wi FROM inserted;

OPEN cur_inserted;
FETCH NEXT FROM cur_inserted INTO @v_id_wi, @v_created_at, @v_status_wi;

WHILE @@FETCH_STATUS = 0
BEGIN
BEGIN TRY

            -- 1. Solo actuar si el work item lleva más de 3 días como pendiente
IF @v_created_at > DATEADD(DAY, -3, GETDATE())
BEGIN
FETCH NEXT FROM cur_inserted INTO @v_id_wi, @v_created_at, @v_status_wi;
CONTINUE;
END

            -- 2. Solo procesar ítems en estado 'P'
            IF @v_status_wi <> 'P'
BEGIN
FETCH NEXT FROM cur_inserted INTO @v_id_wi, @v_created_at, @v_status_wi;
CONTINUE;
END

            -- 3. Verificar que este ítem no esté ya asignado
            SET @v_already_assigned = 0;
            IF EXISTS (SELECT 1 FROM tbl_user_work_items WHERE id_wi = @v_id_wi)
                SET @v_already_assigned = 1;

            IF @v_already_assigned = 1
BEGIN
FETCH NEXT FROM cur_inserted INTO @v_id_wi, @v_created_at, @v_status_wi;
CONTINUE;
END

            -- 4. Recorrer usuarios activos
            DECLARE cur_users CURSOR LOCAL FAST_FORWARD FOR
SELECT id_us FROM tbl_user
WHERE  status_us = 'A'
ORDER BY id_us;

OPEN cur_users;
FETCH NEXT FROM cur_users INTO @v_user_id;

WHILE @@FETCH_STATUS = 0
BEGIN
                -- Contar tareas pendientes del usuario
SELECT @v_pending_count = COUNT(*)
FROM   tbl_user_work_items
WHERE  id_us  = @v_user_id
  AND  status = 'P';

-- Caso A: usuario saturado (> 3 pendientes)
IF @v_pending_count > 3
BEGIN
UPDATE tbl_user SET status_us = 'S'
WHERE  id_us = @v_user_id;

FETCH NEXT FROM cur_users INTO @v_user_id;
CONTINUE;
END

                -- Caso B: usuario SIN ninguna tarea → asignar 1 baja + 1 alta
                IF @v_pending_count = 0
BEGIN
                    -- Ítem de baja relevancia (< 5)
SELECT TOP 1 @v_item_low_id = id_wi
FROM   tbl_work_items
WHERE  status_wi  = 'P'
  AND  relevance  < 5
  AND  created_at <= DATEADD(DAY, -3, GETDATE())
  AND  id_wi NOT IN (SELECT id_wi FROM tbl_user_work_items)
ORDER BY relevance DESC;

-- Ítem de alta relevancia (>= 5)
SELECT TOP 1 @v_item_high_id = id_wi
FROM   tbl_work_items
WHERE  status_wi  = 'P'
  AND  relevance  >= 5
  AND  created_at <= DATEADD(DAY, -3, GETDATE())
  AND  id_wi NOT IN (SELECT id_wi FROM tbl_user_work_items)
ORDER BY relevance DESC;

IF @v_item_low_id IS NOT NULL
BEGIN
INSERT INTO tbl_user_work_items (id_us, id_wi, assignment_date, status)
VALUES (@v_user_id, @v_item_low_id, GETDATE(), 'P');

UPDATE tbl_work_items SET status_wi = 'A'
WHERE  id_wi = @v_item_low_id;
END

                    IF @v_item_high_id IS NOT NULL
BEGIN
INSERT INTO tbl_user_work_items (id_us, id_wi, assignment_date, status)
VALUES (@v_user_id, @v_item_high_id, GETDATE(), 'P');

UPDATE tbl_work_items SET status_wi = 'A'
WHERE  id_wi = @v_item_high_id;
END

FETCH NEXT FROM cur_users INTO @v_user_id;
CONTINUE;
END

                -- Caso C: usuario CON tareas pero < 3 pendientes → solo 1 baja
                IF @v_pending_count BETWEEN 1 AND 3
BEGIN
SELECT TOP 1 @v_item_low_id = id_wi
FROM   tbl_work_items
WHERE  status_wi  = 'P'
  AND  relevance  < 5
  AND  created_at <= DATEADD(DAY, -3, GETDATE())
  AND  id_wi NOT IN (SELECT id_wi FROM tbl_user_work_items)
ORDER BY relevance DESC;

IF @v_item_low_id IS NOT NULL
BEGIN
INSERT INTO tbl_user_work_items (id_us, id_wi, assignment_date, status)
VALUES (@v_user_id, @v_item_low_id, GETDATE(), 'P');

UPDATE tbl_work_items SET status_wi = 'A'
WHERE  id_wi = @v_item_low_id;
END
END

FETCH NEXT FROM cur_users INTO @v_user_id;
END

CLOSE cur_users;
DEALLOCATE cur_users;

END TRY
BEGIN CATCH
IF CURSOR_STATUS('local', 'cur_users') >= 0
BEGIN
CLOSE cur_users;
DEALLOCATE cur_users;
END

            PRINT 'trg_assign_work_item: error en id_wi=' 
                + CAST(@v_id_wi AS VARCHAR) 
                + ' → ' + ERROR_MESSAGE();
END CATCH

FETCH NEXT FROM cur_inserted INTO @v_id_wi, @v_created_at, @v_status_wi;
END

CLOSE cur_inserted;
DEALLOCATE cur_inserted;
END;
GO

CREATE OR ALTER TRIGGER trg_check_saturation
ON tbl_user_work_items
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- Para cada usuario afectado por el INSERT,
    -- si supera 3 pendientes → marcarlo como saturado
UPDATE u
SET    u.status_us = 'S'
    FROM   tbl_user u
WHERE  u.id_us IN (SELECT DISTINCT id_us FROM inserted)
  AND (
    SELECT COUNT(*)
    FROM   tbl_user_work_items uwi
    WHERE  uwi.id_us  = u.id_us
  AND  uwi.status = 'P'
    ) > 3;
END;
GO


CREATE OR ALTER TRIGGER trg_user_delete
ON tbl_user
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;

INSERT INTO tbl_user_audit_delete (
    id_us, name_us, lastname_us, dni_us, phone_us, address_us,
    status_us, age_us, username_us, email_us, deleted_at
)
SELECT
    id_us, name_us, lastname_us, dni_us, phone_us, address_us,
    status_us, age_us, username_us, email_us, CURRENT_TIMESTAMP
FROM deleted;
END;
GO


CREATE OR ALTER TRIGGER trg_user_update_advanced
ON tbl_user
AFTER UPDATE
                          AS
BEGIN
    SET NOCOUNT ON;

    -- name_us
INSERT INTO tbl_user_audit_update (id_us, field_name, old_value, new_value, changed_at)
SELECT d.id_us, 'name_us', d.name_us, i.name_us, CURRENT_TIMESTAMP
FROM   deleted d
           JOIN   inserted i ON d.id_us = i.id_us
WHERE  (d.name_us <> i.name_us)
   OR  (d.name_us IS NULL AND i.name_us IS NOT NULL)
   OR  (d.name_us IS NOT NULL AND i.name_us IS NULL);

-- lastname_us
INSERT INTO tbl_user_audit_update (id_us, field_name, old_value, new_value, changed_at)
SELECT d.id_us, 'lastname_us', d.lastname_us, i.lastname_us, CURRENT_TIMESTAMP
FROM   deleted d
           JOIN   inserted i ON d.id_us = i.id_us
WHERE  (d.lastname_us <> i.lastname_us)
   OR  (d.lastname_us IS NULL AND i.lastname_us IS NOT NULL)
   OR  (d.lastname_us IS NOT NULL AND i.lastname_us IS NULL);

-- dni_us
INSERT INTO tbl_user_audit_update (id_us, field_name, old_value, new_value, changed_at)
SELECT d.id_us, 'dni_us', d.dni_us, i.dni_us, CURRENT_TIMESTAMP
FROM   deleted d
           JOIN   inserted i ON d.id_us = i.id_us
WHERE  (d.dni_us <> i.dni_us)
   OR  (d.dni_us IS NULL AND i.dni_us IS NOT NULL)
   OR  (d.dni_us IS NOT NULL AND i.dni_us IS NULL);

-- phone_us
INSERT INTO tbl_user_audit_update (id_us, field_name, old_value, new_value, changed_at)
SELECT d.id_us, 'phone_us', d.phone_us, i.phone_us, CURRENT_TIMESTAMP
FROM   deleted d
           JOIN   inserted i ON d.id_us = i.id_us
WHERE  (d.phone_us <> i.phone_us)
   OR  (d.phone_us IS NULL AND i.phone_us IS NOT NULL)
   OR  (d.phone_us IS NOT NULL AND i.phone_us IS NULL);

-- address_us
INSERT INTO tbl_user_audit_update (id_us, field_name, old_value, new_value, changed_at)
SELECT d.id_us, 'address_us', d.address_us, i.address_us, CURRENT_TIMESTAMP
FROM   deleted d
           JOIN   inserted i ON d.id_us = i.id_us
WHERE  (d.address_us <> i.address_us)
   OR  (d.address_us IS NULL AND i.address_us IS NOT NULL)
   OR  (d.address_us IS NOT NULL AND i.address_us IS NULL);

-- status_us
INSERT INTO tbl_user_audit_update (id_us, field_name, old_value, new_value, changed_at)
SELECT d.id_us, 'status_us', d.status_us, i.status_us, CURRENT_TIMESTAMP
FROM   deleted d
           JOIN   inserted i ON d.id_us = i.id_us
WHERE  (d.status_us <> i.status_us)
   OR  (d.status_us IS NULL AND i.status_us IS NOT NULL)
   OR  (d.status_us IS NOT NULL AND i.status_us IS NULL);

-- age_us (CAST a VARCHAR para coincidir con old_value/new_value)
INSERT INTO tbl_user_audit_update (id_us, field_name, old_value, new_value, changed_at)
SELECT d.id_us, 'age_us', CAST(d.age_us AS VARCHAR(10)), CAST(i.age_us AS VARCHAR(10)), CURRENT_TIMESTAMP
FROM   deleted d
           JOIN   inserted i ON d.id_us = i.id_us
WHERE  (d.age_us <> i.age_us)
   OR  (d.age_us IS NULL AND i.age_us IS NOT NULL)
   OR  (d.age_us IS NOT NULL AND i.age_us IS NULL);

-- username_us
INSERT INTO tbl_user_audit_update (id_us, field_name, old_value, new_value, changed_at)
SELECT d.id_us, 'username_us', d.username_us, i.username_us, CURRENT_TIMESTAMP
FROM   deleted d
           JOIN   inserted i ON d.id_us = i.id_us
WHERE  (d.username_us <> i.username_us)
   OR  (d.username_us IS NULL AND i.username_us IS NOT NULL)
   OR  (d.username_us IS NOT NULL AND i.username_us IS NULL);

-- email_us
INSERT INTO tbl_user_audit_update (id_us, field_name, old_value, new_value, changed_at)
SELECT d.id_us, 'email_us', d.email_us, i.email_us, CURRENT_TIMESTAMP
FROM   deleted d
           JOIN   inserted i ON d.id_us = i.id_us
WHERE  (d.email_us <> i.email_us)
   OR  (d.email_us IS NULL AND i.email_us IS NOT NULL)
   OR  (d.email_us IS NOT NULL AND i.email_us IS NULL);

END;
GO