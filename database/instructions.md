## Migration Instructions for AI Agent

**Goal:**
Migrate the database layer from GORM to Bun (https://bun.uptrace.dev/) in the `database/` folder. All functionality must remain the same, but the ORM will be Bun instead of GORM.

**Step-by-step plan:**
1. Keep all existing GORM code as-is for now.
2. Implement Bun-based versions of the same functionality in new files, using the naming pattern `bundb_*.go`.
3. Do not remove or modify the GORM code at this stage.
4. Only make changes in the `database/` folder.
5. Later, implement tests for the Bun-based code.

**Constraints:**
- Do not change code outside the `database/` folder.
- Ensure all features and logic are preserved in the Bun implementation.
- Use clear, idiomatic Go code and follow project style guidelines.

**Summary:**
Migrate to Bun ORM by duplicating GORM functionality in new Bun-specific files within the `database/` folder. Maintain both implementations until the migration is complete and tested.