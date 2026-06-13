
-- Replace project_status enum with new values
ALTER TABLE public.projects ALTER COLUMN status DROP DEFAULT;
ALTER TABLE public.projects ALTER COLUMN status TYPE text USING status::text;
DROP TYPE public.project_status;
CREATE TYPE public.project_status AS ENUM (
  'studying',
  'submitted_to_medial_man',
  'submitted_to_client',
  'waiting_for_reply',
  'inquiries_sent',
  'answers_received',
  'on_hold',
  'client_rejected',
  'construction_ongoing',
  'construction_complete',
  'finished',
  'closed'
);
-- Map any old values to new ones
UPDATE public.projects SET status = CASE
  WHEN status = 'draft' THEN 'studying'
  WHEN status = 'in_progress' THEN 'construction_ongoing'
  WHEN status = 'awarded' THEN 'submitted_to_client'
  WHEN status = 'rejected' THEN 'client_rejected'
  WHEN status = 'completed' THEN 'finished'
  ELSE status
END;
ALTER TABLE public.projects ALTER COLUMN status TYPE public.project_status USING status::public.project_status;
ALTER TABLE public.projects ALTER COLUMN status SET DEFAULT 'studying'::public.project_status;
