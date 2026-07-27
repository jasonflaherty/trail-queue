-- Ensure extensions schema exists for hosted Supabase compatibility
CREATE SCHEMA IF NOT EXISTS extensions;

-- PostGIS for geography/geometry columns and spatial indexes
CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA extensions;

-- UUID generation helpers
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA extensions;

-- pgvector for issue embeddings and duplicate detection
CREATE EXTENSION IF NOT EXISTS vector WITH SCHEMA extensions;
