import { Kysely, sql } from 'kysely';

export async function up(db: Kysely<any>): Promise<void> {
  await sql`
    DROP TABLE IF EXISTS
      "workflow_action",
      "workflow_filter",
      "workflow",
      "plugin_action",
      "plugin_filter",
      "plugin",
      "ocr_search",
      "asset_ocr",
      "face_search",
      "asset_face_audit",
      "person_audit",
      "asset_face",
      "person",
      "smart_search"
    CASCADE;
  `.execute(db);

  await sql`DROP FUNCTION IF EXISTS "asset_face_audit"() CASCADE;`.execute(db);
  await sql`DROP FUNCTION IF EXISTS "person_delete_audit"() CASCADE;`.execute(db);
  await sql`DROP TYPE IF EXISTS "asset_face_source_type" CASCADE;`.execute(db);
  await sql`DROP TYPE IF EXISTS "sourcetype" CASCADE;`.execute(db);

  await sql`
    DELETE FROM "migration_overrides"
    WHERE "name" IN (
      'enum_asset_face_source_type',
      'enum_sourcetype',
      'function_asset_face_audit',
      'function_person_delete_audit',
      'index_asset_face_personId_assetId_notDeleted_isVisible_idx',
      'index_clip_index',
      'index_face_index',
      'table_asset_face',
      'table_asset_face_audit',
      'table_asset_ocr',
      'table_face_search',
      'table_ocr_search',
      'table_person',
      'table_person_audit',
      'table_plugin',
      'table_plugin_action',
      'table_plugin_filter',
      'table_smart_search',
      'table_workflow',
      'table_workflow_action',
      'table_workflow_filter'
    )
    OR "name" LIKE '%asset_face%'
    OR "name" LIKE '%asset_ocr%'
    OR "name" LIKE '%face_search%'
    OR "name" LIKE '%ocr_search%'
    OR "name" LIKE '%person%'
    OR "name" LIKE '%plugin%'
    OR "name" LIKE '%smart_search%'
    OR "name" LIKE '%workflow%';
  `.execute(db);
}

export async function down(_db: Kysely<any>): Promise<void> {}
