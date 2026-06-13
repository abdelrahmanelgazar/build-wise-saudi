
CREATE SEQUENCE IF NOT EXISTS public.projects_no_seq START 1;

ALTER TABLE public.projects
  ADD COLUMN IF NOT EXISTS project_no BIGINT NOT NULL DEFAULT nextval('public.projects_no_seq'),
  ADD COLUMN IF NOT EXISTS code TEXT,
  ADD COLUMN IF NOT EXISTS area TEXT,
  ADD COLUMN IF NOT EXISTS scope_of_work TEXT,
  ADD COLUMN IF NOT EXISTS contract_type TEXT,
  ADD COLUMN IF NOT EXISTS tender_entry_date DATE,
  ADD COLUMN IF NOT EXISTS last_submit_date DATE,
  ADD COLUMN IF NOT EXISTS last_rfi_date DATE,
  ADD COLUMN IF NOT EXISTS note TEXT;

ALTER SEQUENCE public.projects_no_seq OWNED BY public.projects.project_no;
